;(function()
-- Open Sky 3D bridge for randyadr/Gen2-3D-Sprites.
-- Provider manifest id: STADIUM2_OVERWORLD_MODELS.
local playable = mod.exports.openSkyPlayable or {}
local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local HEIGHT_ASSET = "assets/open_sky_region_height.png"
local SX0, SX1, SY0, SY1 = 6, 154, 22, 138
local MX0, MX1, MZ0, MZ1 = 8, 152, 24, 112
local RECT = {
  johto = { 6, 85, 27, 104 },
  kanto = { 90, 154, 25, 104 },
}
local patched = setmetatable({}, { __mode = "k" })
local cache = { tried = false, provider = false }

local function clamp(v, lo, hi)
  return math.max(lo, math.min(hi, tonumber(v) or lo))
end
local function clean(v)
  return tostring(v or ""):gsub("\n", " "):gsub("^LANDMARK_", ""):gsub("_", " ")
end

local function provider()
  if cache.provider then return cache.provider end
  if cache.tried then return nil end
  cache.tried = true
  if type(mod.find) ~= "function" then return nil end
  local handle
  local ok, value = pcall(function() return mod.find(PROVIDER_ID) end)
  if ok then handle = value end
  if not handle then
    ok, value = pcall(mod.find, mod, PROVIDER_ID)
    if ok then handle = value end
  end
  local e = handle and handle.exports
  if type(e) ~= "table" or e.active == false or e.rendererInstalled == false
      or type(e.lib) ~= "table" or type(e.lib.require) ~= "function" then
    return nil
  end
  cache.provider = e
  return e
end

local function readHeight()
  if not (mod.read and love and love.image and love.image.newImageData
      and love.filesystem and love.filesystem.newFileData) then return nil end
  local ok, raw = pcall(mod.read, mod, HEIGHT_ASSET)
  if not ok or type(raw) ~= "string" then return nil end
  local okData, data = pcall(love.filesystem.newFileData, raw, "open_sky_region_height.png")
  if not okData or not data then return nil end
  local okImg, image = pcall(love.image.newImageData, data)
  return okImg and image or nil
end

local function build(Voxel3D)
  local image = readHeight()
  if not image then return nil, "height map unavailable" end
  local w, h = image:getDimensions()
  local verts, map, heights = {}, {}, {}
  for z = 0, h - 1 do
    local tz = z / (h - 1)
    for x = 0, w - 1 do
      local tx = x / (w - 1)
      local r = image:getPixel(x, z)
      local i = z * w + x + 1
      local y = clamp(r, 0, 1) * 24
      verts[i] = { MX0 + (MX1-MX0)*tx, y, MZ0 + (MZ1-MZ0)*tz, tx, tz, 1 }
      heights[i] = y
    end
  end
  for z = 0, h - 2 do
    for x = 0, w - 2 do
      local a = z*w+x+1; local b=a+1; local c=a+w; local d=c+1
      map[#map+1]=a; map[#map+1]=c; map[#map+1]=b
      map[#map+1]=b; map[#map+1]=c; map[#map+1]=d
    end
  end
  local mesh = Voxel3D.newMesh(verts, map)
  if not mesh then return nil, "mesh creation failed" end
  return { mesh=mesh, w=w, h=h, heights=heights }
end

local function ensure()
  if cache.ready then return cache end
  if cache.error then return nil end
  local e = provider()
  if not e then cache.error="Gen2-3D-Sprites not active"; return nil end
  local okV, V = pcall(e.lib.require, "Voxel3D")
  local okM, M = pcall(e.lib.require, "Mat4")
  if not (okV and type(V)=="table" and okM and type(M)=="table") then
    cache.error="Voxel3D/Mat4 export unavailable"; return nil
  end
  if type(V.available)=="function" then
    local okA, available = pcall(V.available)
    if not okA or not available then cache.error="3D renderer unavailable"; return nil end
  end
  local built, err = build(V)
  local texture
  if type(playable.openSkyMapImage)=="function" then
    local okT, img = pcall(playable.openSkyMapImage)
    if okT then texture=img end
  end
  if not built or not texture then cache.error=err or "map texture unavailable"; return nil end
  cache.Voxel3D=V; cache.Mat4=M; cache.mesh=built.mesh
  cache.w=built.w; cache.h=built.h; cache.heights=built.heights
  cache.texture=texture; cache.ready=true
  return cache
end

local function worldPoint(region, x, y)
  local r=RECT[region] or RECT.johto
  local nx=(clamp(x,SX0,SX1)-SX0)/(SX1-SX0)
  local ny=(clamp(y,SY0,SY1)-SY0)/(SY1-SY0)
  return r[1]+nx*(r[2]-r[1]), r[3]+ny*(r[4]-r[3])
end
local function heightAt(wx,wz)
  if not cache.ready then return 0 end
  local gx=clamp((wx-MX0)/(MX1-MX0)*(cache.w-1),0,cache.w-1)
  local gz=clamp((wz-MZ0)/(MZ1-MZ0)*(cache.h-1),0,cache.h-1)
  local x0,z0=math.floor(gx),math.floor(gz)
  local x1,z1=math.min(cache.w-1,x0+1),math.min(cache.h-1,z0+1)
  local tx,tz=gx-x0,gz-z0
  local function at(x,z) return cache.heights[z*cache.w+x+1] or 0 end
  local a=at(x0,z0)*(1-tx)+at(x1,z0)*tx
  local b=at(x0,z1)*(1-tx)+at(x1,z1)*tx
  return a*(1-tz)+b*tz
end
local function points(region)
  if type(playable.visitedPoints)~="function" then return {} end
  local ok, rows=pcall(playable.visitedPoints,region)
  return ok and type(rows)=="table" and rows or {}
end

local function mount(G,state,x,y,scale)
  local s=flight.sprite; local drawn=false
  if s and type(s.draw)=="function" then
    G.push(); G.translate(math.floor(x),math.floor(y)); G.scale(.34*clamp(scale or 1,.7,1.4))
    G.setColor(1,1,1,1)
    drawn=pcall(s.draw,s,-8,-8,0,0,state.facing or "right",(state.anim or 0)>=16 and 1 or 0,false)
    G.pop()
  end
  if not drawn then G.setColor(1,1,1,1); G.circle("fill",x,y,3) end
  G.setColor(1,1,1,.95); G.circle("line",x,y,5)
end
local function overlays(G,state,V)
  local nearest=state.nearest and state.nearest.row and state.nearest.row.spawn
  for _,p in ipairs(points(state.region)) do
    if p.anchor then
      local wx,wz=worldPoint(state.region,p.anchor.x,p.anchor.y)
      local x,y=V.project(wx,heightAt(wx,wz)+1.2,wz)
      if x and y then
        local selected=nearest and p.row and p.row.spawn==nearest
        G.setColor(1,1,1,.92); G.circle("fill",x,y,selected and 2 or 1.25)
        if selected then G.circle("line",x,y,4.5) end
      end
    end
  end
  local wx,wz=worldPoint(state.region,state.x,state.y)
  local x,y,scale=V.project(wx,heightAt(wx,wz)+9,wz)
  if x and y then mount(G,state,x,y,scale) end
end
local function hud(G,state)
  G.setColor(0,0,0,.72); G.rectangle("fill",0,0,160,18); G.rectangle("fill",0,124,160,20)
  G.setColor(1,1,1,1)
  local region=state.region=="kanto" and "KANTO" or "JOHTO"
  G.print("OPEN SKY 3D - "..region.."  ALT "..math.floor((state.virtualAltitude or 88)+.5),4,4)
  local name=state.nearest and state.nearest.row and (state.nearest.row.name or state.nearest.row.landmark)
  local bottom=state.notice or (name and ("A DESCEND - "..clean(name)) or "NO VISITED LANDING POINT")
  G.print(bottom:sub(1,28),4,128)
end

local function draw3d(state,fallback)
  local r=ensure()
  if not r or not love or not love.graphics then return fallback and fallback(state) end
  local G,V,M=love.graphics,r.Voxel3D,r.Mat4
  local oldCamera,oldTint=V.camera,V.tint
  local canvas,begun
  local ok,err=pcall(function()
    V.camera={eye={80,126,178},focus={80,4,68},fov=math.rad(37),curve=0,up={0,1,0}}
    V.tint={1,1,1}
    begun=V.beginScene(160,144,80,68,160,144,nil,"dsr_open_sky_region")
    if not begun then error("beginScene failed") end
    V.seams(false); V.glass(false)
    V.draw(r.mesh,r.texture,type(M.identity)=="function" and M.identity() or nil,0)
    canvas=V.endScene(); begun=false
  end)
  if begun then pcall(V.endScene) end
  V.camera,V.tint=oldCamera,oldTint; pcall(G.setCanvas); pcall(G.setShader); pcall(G.setDepthMode)
  if not ok or not canvas then cache.error=tostring(err or "no 3D canvas"); cache.ready=false; return fallback and fallback(state) end
  G.push("all"); G.clear(.58,.80,.96,1); G.setColor(1,1,1,1); G.draw(canvas,0,0)
  overlays(G,state,V); hud(G,state); G.pop()
end

local function patch()
  if type(playable.state)~="function" then return end
  local ok,state=pcall(playable.state)
  if not ok or type(state)~="table" or patched[state] or not provider() then return end
  patched[state]=true; local fallback=state.draw
  state.draw=function(self) return draw3d(self,fallback) end
  state._dsrOpenSkyGen2ThreeD=true
end
local previous=OverworldState.update
function OverworldState:update(dt,...)
  local out=previous(self,dt,...); patch(); return out
end
mod.events:on("game.ready",function() cache={tried=false,provider=false} end)
playable.gen2ThreeD={providerId=PROVIDER_ID,detected=function() return provider()~=nil end,
  ready=function() return ensure()~=nil end,error=function() return cache.error end,
  projectWorld=worldPoint,sampleHeight=heightAt}
log("Gen2 Open Sky 3D bridge loaded (provider=%s)",PROVIDER_ID)
end)();