;(function()
-- -------------------------------------------------------------------------
-- Gen 2 Open Sky: official Pokemon Stadium 2 regional maps -- flat 2D pass.
-- -------------------------------------------------------------------------
local playable = mod.exports.openSkyPlayable or {}
local patchedStates = setmetatable({}, { __mode = "k" })
local lastDrawError = nil
local MAP_W, MAP_H = 312, 232
local PANEL_W, PANEL_H = 160, 144
local WARP_X0, WARP_Y0 = 6, 22
local WARP_W, WARP_H = 149, 117
local WARP_STRIDE = 6
local REGION = {
  johto = {
    image="assets/open_sky_stadium2/johto/map2d.b64",
    imagePartsPrefix="assets/open_sky_stadium2/johto/map2d_full_part",
    imageParts=5,
    eye={-560,3300,4780}, at={-560,0,960}, modelFile=0,
  },
  kanto = {
    image="assets/open_sky_stadium2/kanto/map2d.b64",
    imagePartsPrefix="assets/open_sky_stadium2/kanto/map2d_full_part",
    imageParts=6,
    eye={-10,2990,4540}, at={-10,0,420}, modelFile=1,
  },
}
local cache = { images={}, imageTried={}, warp={}, warpTried={}, basis={} }
local function regionKey(region) return region == "kanto" and "kanto" or "johto" end
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,tonumber(v) or lo)) end
local function readRaw(relative)
  if not mod.read then return nil end
  local ok,raw=pcall(mod.read,mod,relative)
  if ok and type(raw)=="string" and raw~="" then return raw end
  return nil
end
local function decodeBase64(raw)
  if type(raw)~="string" or not (love and love.data and love.data.decode) then return nil end
  local ok,value=pcall(love.data.decode,"string","base64",raw:gsub("%s+",""))
  return ok and value or nil
end
local function readJoinedBytes(prefix,count)
  if type(prefix)~="string" or not tonumber(count) then return nil,"invalid multipart map descriptor" end
  local chunks={}
  for i=1,tonumber(count) do
    local path=string.format("%s%02d.b64",prefix,i)
    local raw=readRaw(path)
    if type(raw)~="string" or raw=="" then return nil,"missing "..path end
    local bytes=decodeBase64(raw)
    if type(bytes)~="string" or bytes=="" then return nil,"invalid base64 in "..path end
    chunks[#chunks+1]=bytes
  end
  return table.concat(chunks),nil
end
local function loadBundledImage(config,region)
  local bytes,joinErr=readJoinedBytes(config and config.imagePartsPrefix,config and config.imageParts)
  if not bytes then return nil,joinErr or "multipart map data unavailable" end
  if bytes:sub(1,8)~="\137PNG\r\n\26\n" then return nil,"decoded map is not a PNG" end
  if not (love and love.graphics and love.filesystem and love.filesystem.newFileData) then return nil,"in-memory image decoder unavailable" end
  local okFD,fd=pcall(love.filesystem.newFileData,bytes,tostring(region or "open_sky").."_map2d.png")
  if not okFD or not fd then return nil,"could not create in-memory PNG data" end
  local okIm,im=pcall(love.graphics.newImage,fd)
  if not okIm or not im then return nil,"could not create map image" end
  local okDim,w,h=pcall(function() return im:getWidth(),im:getHeight() end)
  if not okDim or tonumber(w)~=MAP_W or tonumber(h)~=MAP_H then
    pcall(function() im:release() end)
    return nil,string.format("map size %sx%s; expected %dx%d",tostring(w),tostring(h),MAP_W,MAP_H)
  end
  pcall(im.setFilter,im,"linear","linear")
  return im,nil
end
local function rememberDrawError(kind,err)
  lastDrawError={kind=tostring(kind or "draw"),message=tostring(err or "unknown")}
  pcall(function() log("Open Sky Stadium2 2D %s failed: %s",lastDrawError.kind,lastDrawError.message) end)
end
local function imageFor(region)
  region=regionKey(region)
  if cache.imageTried[region] then return cache.images[region] end
  cache.imageTried[region]=true
  local a=REGION[region]
  local image,err=loadBundledImage(a,region)
  cache.images[region]=image
  if not image then rememberDrawError("MAP_ASSET",string.format("%s: %s",region,tostring(err or "unable to decode bundled map"))) end
  return cache.images[region]
end
local function warpFor(region)
  -- The flattened Stadium 2 render is authoritative. City markers use a
  -- stable linear town-map projection and are calibrated with the F8 editor.
  region=regionKey(region)
  cache.warpTried[region]=true
  cache.warp[region]=nil
  return nil
end
local function readS16BE(raw,pos)
  local hi,lo=raw:byte(pos,pos+1); if not (hi and lo) then return 0 end
  local v=hi*256+lo; if v>=32768 then v=v-65536 end; return v
end
local function warpCell(raw,ix,iy)
  ix=math.max(0,math.min(WARP_W-1,ix)); iy=math.max(0,math.min(WARP_H-1,iy))
  local p=(iy*WARP_W+ix)*WARP_STRIDE+1
  return readS16BE(raw,p),readS16BE(raw,p+2),readS16BE(raw,p+4)
end
local function warpSample(raw,x,y)
  local gx=clamp((tonumber(x) or 80)-WARP_X0,0,WARP_W-1); local gy=clamp((tonumber(y) or 78)-WARP_Y0,0,WARP_H-1)
  local x0,y0=math.floor(gx),math.floor(gy); local x1,y1=math.min(WARP_W-1,x0+1),math.min(WARP_H-1,y0+1); local tx,ty=gx-x0,gy-y0
  local ax,az,ay=warpCell(raw,x0,y0); local bx,bz,by=warpCell(raw,x1,y0); local cx,cz,cy=warpCell(raw,x0,y1); local dx,dz,dy=warpCell(raw,x1,y1)
  local function bi(a,b,c,d) local top=a+(b-a)*tx; local bot=c+(d-c)*tx; return top+(bot-top)*ty end
  return bi(ax,bx,cx,dx),bi(ay,by,cy,dy),bi(az,bz,cz,dz)
end
local function cameraBasis(region)
  region=regionKey(region); if cache.basis[region] then return cache.basis[region] end
  local c=REGION[region]; local ex,ey,ez=c.eye[1],c.eye[2],c.eye[3]; local fx,fy,fz=c.at[1]-ex,c.at[2]-ey,c.at[3]-ez
  local fl=math.sqrt(fx*fx+fy*fy+fz*fz); fx,fy,fz=fx/fl,fy/fl,fz/fl
  local rx,ry,rz=-fz,0,fx; local rl=math.sqrt(rx*rx+ry*ry+rz*rz); rx,ry,rz=rx/rl,ry/rl,rz/rl
  local ux=ry*fz-rz*fy; local uy=rz*fx-rx*fz; local uz=rx*fy-ry*fx
  local b={ex=ex,ey=ey,ez=ez,fx=fx,fy=fy,fz=fz,rx=rx,ry=ry,rz=rz,ux=ux,uy=uy,uz=uz,tanHalf=math.tan(math.rad(30)*0.5),aspect=MAP_W/MAP_H}
  cache.basis[region]=b; return b
end
local function projectNative(region,rx,ry,rz)
  local b=cameraBasis(region); local dx,dy,dz=rx-b.ex,ry-b.ey,rz-b.ez
  local cx=dx*b.rx+dy*b.ry+dz*b.rz; local cy=dx*b.ux+dy*b.uy+dz*b.uz; local cz=dx*b.fx+dy*b.fy+dz*b.fz
  if cz<=1 then return MAP_W*0.5,MAP_H*0.5 end
  local nx=cx/(cz*b.tanHalf*b.aspect); local ny=cy/(cz*b.tanHalf)
  return (nx*0.5+0.5)*MAP_W,(0.5-ny*0.5)*MAP_H
end
local function project(region,x,y)
  region=regionKey(region)
  local raw=warpFor(region)
  if raw then local rx,ry,rz=warpSample(raw,x,y); return projectNative(region,rx,ry,rz) end
  local nx=(clamp(x,6,154)-6)/148; local ny=(clamp(y,22,138)-22)/116
  return 10+nx*(MAP_W-20),10+ny*(MAP_H-20)
end
local function cleanMapName(value) return tostring(value or ""):gsub("\n"," "):gsub("^LANDMARK_",""):gsub("_"," ") end
local function landingIndicators(region)
  if type(playable.landingIndicators)~="function" then return {} end
  local ok,rows=pcall(playable.landingIndicators,region); return ok and type(rows)=="table" and rows or {}
end
local function screenAlignedDelta(region,x,y,wantX,wantY)
  wantX,wantY=tonumber(wantX) or 0,tonumber(wantY) or 0
  local wl=math.sqrt(wantX*wantX+wantY*wantY); if wl<1e-6 then return 0,0 end
  wantX,wantY=wantX/wl,wantY/wl
  local eps=0.75
  local xa,xb=math.max(6,x-eps),math.min(154,x+eps)
  local ya,yb=math.max(22,y-eps),math.min(138,y+eps)
