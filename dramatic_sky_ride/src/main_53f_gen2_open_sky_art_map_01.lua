;(function()
local playable = mod.exports.openSkyPlayable or {}
local patchedStates = setmetatable({}, { __mode = "k" })
local lastDrawError = nil
local MAP_W, MAP_H = 312, 232
local PANEL_W, PANEL_H = 160, 144
local WARP_X0, WARP_Y0 = 6, 22
local WARP_W, WARP_H = 149, 117
local WARP_STRIDE = 6
local REGION = {
  johto = { image="assets/open_sky_stadium2/johto/map2d.png", warp="assets/open_sky_stadium2/johto/warp.bin", eye={-560,3300,4780}, at={-560,0,960}, modelFile=0 },
  kanto = { image="assets/open_sky_stadium2/kanto/map2d.png", warp="assets/open_sky_stadium2/kanto/warp.bin", eye={-10,2990,4540}, at={-10,0,420}, modelFile=1 },
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
local function assetPath(relative)
  if mod.assets and type(mod.assets.path)=="function" then local ok,value=pcall(mod.assets.path,mod.assets,relative); if ok and value then return value end end
  return relative
end
local function loadBundledImage(relative)
  if not Assets then return nil end
  local candidates={assetPath(relative),relative}; local seen={}
  for _,candidate in ipairs(candidates) do
    if candidate and not seen[candidate] then
      seen[candidate]=true
      if type(Assets.image)=="function" then local ok,image=pcall(Assets.image,candidate); if ok and image then pcall(image.setFilter,image,"linear","linear"); return image end end
      if type(Assets.imageData)=="function" and love and love.graphics and type(love.graphics.newImage)=="function" then
        local okData,imageData=pcall(Assets.imageData,candidate)
        if okData and imageData then local okImage,image=pcall(love.graphics.newImage,imageData); if okImage and image then pcall(image.setFilter,image,"linear","linear"); return image end end
      end
    end
  end
  return nil
end
local function rememberDrawError(kind,err)
  lastDrawError={kind=tostring(kind or "draw"),message=tostring(err or "unknown")}
  pcall(function() log("Open Sky Stadium2 2D %s failed: %s",lastDrawError.kind,lastDrawError.message) end)
end
local function loadImageFromRaw(raw,filename)
  if type(raw)~="string" or raw=="" then return nil end
  if not (love and love.graphics and love.filesystem and love.filesystem.newFileData) then return nil end
  local okFD,fd=pcall(love.filesystem.newFileData,raw,filename); if not okFD or not fd then return nil end
  local okIm,im=pcall(love.graphics.newImage,fd); if not okIm or not im then return nil end
  pcall(im.setFilter,im,"linear","linear"); return im
end
local function imageFor(region)
  region=regionKey(region); if cache.imageTried[region] then return cache.images[region] end
  cache.imageTried[region]=true; local a=REGION[region]
  cache.images[region]=loadBundledImage(a.image)
  if not cache.images[region] then cache.images[region]=loadImageFromRaw(readRaw(a.image),region.."_stadium2_map.png") end
  if not cache.images[region] then rememberDrawError("MAP_ASSET","unable to load bundled "..tostring(a.image)) end
  return cache.images[region]
end
local function warpFor(region)
  region=regionKey(region); if cache.warpTried[region] then return cache.warp[region] end
  cache.warpTried[region]=true; local raw=readRaw(REGION[region].warp)
  if raw and #raw>=WARP_W*WARP_H*WARP_STRIDE then cache.warp[region]=raw end
  return cache.warp[region]
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
  region=regionKey(region); local raw=warpFor(region)
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
  local eps=0.75; local xa,xb=math.max(6,x-eps),math.min(154,x+eps); local ya,yb=math.max(22,y-eps),math.min(138,y+eps)
