  local ax, ay = project(region, xa, y)
  local bx, by = project(region, xb, y)
  local cx, cy = project(region, x, ya)
  local dx, dy = project(region, x, yb)
  local xden, yden = math.max(1e-6, xb - xa), math.max(1e-6, yb - ya)
  local j11, j21 = (bx - ax) / xden, (by - ay) / xden
  local j12, j22 = (dx - cx) / yden, (dy - cy) / yden
  local det = j11 * j22 - j12 * j21
  if math.abs(det) < 1e-6 then return wantX, wantY end
  local mx = (wantX * j22 - j12 * wantY) / det
  local my = (j11 * wantY - wantX * j21) / det
  local ml = math.sqrt(mx * mx + my * my)
  if ml < 1e-6 then return wantX, wantY end
  return mx / ml, my / ml
end

local function drawBackdrop(G, state)
  local image = imageFor(state.region)
  local drew = false
  if image then
    G.setColor(1, 1, 1, 1)
    G.draw(image, 0, 0, 0, MAP_W / image:getWidth(), MAP_H / image:getHeight())
    drew = true
  else
    G.setColor(0.08, 0.34, 0.58, 1)
    G.rectangle("fill", 0, 0, MAP_W, MAP_H)
    G.setColor(0.24, 0.58, 0.31, 1)
    G.rectangle("fill", 32, 28, MAP_W - 64, MAP_H - 56)
  end
  local preview = state and state.regionPreview or nil
  local side = state and state.regionPreviewSide or nil
  local progress = clamp(state and state.regionPreviewProgress or 0, 0, 1)
  local adjacent = preview and imageFor(preview) or nil
  if adjacent and progress > 0.001 and (side == "left" or side == "right") then
    local reveal = MAP_W * 0.40 * progress
    local ox = side == "left" and (-MAP_W + reveal) or (MAP_W - reveal)
    G.setColor(1, 1, 1, 0.98)
    G.draw(adjacent, ox, 0, 0, MAP_W / adjacent:getWidth(), MAP_H / adjacent:getHeight())
    G.setColor(0.94, 0.97, 1.0, 0.92)
    local seamX = side == "left" and reveal or (MAP_W - reveal)
    G.rectangle("fill", seamX - 0.7, 0, 1.4, MAP_H)
  end
  return drew
end

local function drawLandingPoints(G, state)
  local nearestId = state.nearestLanding and state.nearestLanding.anchor and state.nearestLanding.anchor.id or nil
  for _, point in ipairs(landingIndicators(state.region)) do
    local anchor = point and point.anchor
    if anchor then
      local x, y = project(state.region, anchor.x, anchor.y)
      local selected = nearestId ~= nil and anchor.id == nearestId
      if point.visited then
        G.setColor(0.20, 0.95, 0.38, 0.98); G.circle("fill", x, y, 2.4); G.setColor(1, 1, 1, 0.98); G.circle("line", x, y, 3.0)
      else
        G.setColor(0.95, 0.30, 0.26, 0.96); G.circle("line", x, y, 2.8); G.line(x - 1.8, y - 1.8, x + 1.8, y + 1.8); G.line(x - 1.8, y + 1.8, x + 1.8, y - 1.8)
      end
      if selected and (state.nearestLandingDistance or math.huge) <= 11 then G.setColor(1,1,1,0.98); G.circle("line",x,y,7) end
    end
  end
end
local function drawMount(G, state, x, y)
  local sprite = flight and flight.sprite or nil
  local drawn = false
  if sprite and type(sprite.draw) == "function" then
    G.push(); G.translate(math.floor(x), math.floor(y)); G.rotate(math.rad(clamp(tonumber(state.bank) or 0, -18, 18)) * 0.40); G.scale(0.72, 0.72); G.setColor(1,1,1,1)
    local phase = (tonumber(state.anim) or 0) >= 16 and 1 or 0
    drawn = pcall(sprite.draw, sprite, -8, -8, 0, 0, state.facing or "right", phase, false)
    G.pop()
  end
  if not drawn then G.setColor(1,0.85,0.20,1); G.polygon("fill",x,y-7,x+7,y+6,x,y+3,x-7,y+6); G.setColor(0.10,0.10,0.12,1); G.polygon("line",x,y-7,x+7,y+6,x,y+3,x-7,y+6) end
end
local function drawHud(G, state)
  if type(G.print) ~= "function" then return end
  local function panel(x,y,w,h) G.setColor(0.035,0.055,0.085,0.88); G.rectangle("fill",x,y,w,h); G.setColor(0.78,0.84,0.90,0.82); G.rectangle("line",x,y,w,h) end
  local nearest=state.nearest and state.nearest.row or nil; local nearestCity=state.nearestLanding; local nearCity=nearestCity and (tonumber(state.nearestLandingDistance) or math.huge)<=11
  local name=nearest and cleanMapName(nearest.name or nearest.landmark) or (nearestCity and cleanMapName(nearestCity.name)) or "OPEN SKY"; if #name>20 then name=name:sub(1,20) end
  local ready=(tonumber(state.nearestDistance) or math.huge)<=11
  panel(12,12,142,27); panel(10,193,96,29); panel(141,192,157,30)
  G.setColor(1,1,1,0.97); pcall(G.print,name,20,21); pcall(G.print,"D-PAD  B FAST",17,202)
  local bottom=state.notice
  if not bottom then
    if nearCity and nearestCity and not nearestCity.visited then bottom="LOCKED - "..name
    else bottom=ready and ("A LAND - "..name) or string.format("ALT %d  SPD %.1f",math.floor((tonumber(state.virtualAltitude) or 88)+0.5),tonumber(state.speed) or 0) end
  end
  pcall(G.print,tostring(bottom):sub(1,30),149,201)
end
local function drawNative(state)
  local G=love.graphics; G.setColor(0.05,0.08,0.12,1); G.rectangle("fill",0,0,MAP_W,MAP_H); drawBackdrop(G,state); drawLandingPoints(G,state)
  local x,y=tonumber(state.screenX),tonumber(state.screenY); if not (x and y) then x,y=project(state.region,state.x,state.y) end
  drawMount(G,state,clamp(x,0,MAP_W),clamp(y,0,MAP_H)); drawHud(G,state)
  if type(state.drawCalibrationHud)=="function" then pcall(state.drawCalibrationHud,state,G,MAP_W,MAP_H,MAP_H/144) end
end
local function drawPanel(state)
  if not (love and love.graphics) then return end
  local G=love.graphics; G.setColor(0.04,0.06,0.09,1); G.rectangle("fill",0,0,PANEL_W,PANEL_H)
  local scale=math.min(PANEL_W/MAP_W,PANEL_H/MAP_H); local ox=(PANEL_W-MAP_W*scale)*0.5; local oy=(PANEL_H-MAP_H*scale)*0.5
  G.push(); G.translate(ox,oy); G.scale(scale,scale); drawNative(state); G.pop()
end
local function drawWidescreen(state,winW,winH)
  if not (love and love.graphics) then return end
  local G=love.graphics; winW=tonumber(winW) or select(1,G.getDimensions()) or MAP_W; winH=tonumber(winH) or select(2,G.getDimensions()) or MAP_H
  local pushed=false
  local ok,err=pcall(function()
    G.push("all"); pushed=true; G.origin(); G.setColor(0.025,0.035,0.055,1); G.rectangle("fill",0,0,winW,winH)
    local scale=math.min(winW/MAP_W,winH/MAP_H); local ox=math.floor((winW-MAP_W*scale)*0.5); local oy=math.floor((winH-MAP_H*scale)*0.5)
    G.translate(ox,oy); G.scale(scale,scale); drawNative(state)
  end)
  if pushed then pcall(G.pop) end; if not ok then rememberDrawError("widescreen",err) end
end
local function patchState(state)
  if type(state)~="table" or patchedStates[state] then return end
  patchedStates[state]=true; local fallback=state.draw
  state.draw=function(self) local ok,err=pcall(drawPanel,self); if not ok then rememberDrawError("panel",err); if type(fallback)=="function" then pcall(fallback,self) end end end
  state.wantsFillScale=function() return true end
  state.drawsWidescreen=function() return true end
  state.drawWidescreen=function(self,winW,winH) drawWidescreen(self,winW,winH) end
  state._dsrOpenSkyOfficialStadium2D=true
end
local function patchCurrentState() if type(playable.state)~="function" then return end; local ok,state=pcall(playable.state); if ok and state then patchState(state) end end
local previous2DUpdate=OverworldState.update
function OverworldState:update(dt,...) local result=previous2DUpdate(self,dt,...); patchCurrentState(); return result end
mod.events:on("game.ready",function() cache={images={},imageTried={},warp={},warpTried={},basis={}}; lastDrawError=nil end)
playable.illustratedMap=function() return true end
playable.mapAsset=function(region) return REGION[regionKey(region)].image end
playable.openSkyMapImage=imageFor
playable.projectMapPoint=project
playable.screenAlignedDelta=screenAlignedDelta
playable.drawIllustratedMap=drawPanel
playable.drawOpenSkyWidescreen=drawWidescreen
playable.lastIllustratedDrawError=function() return lastDrawError end
playable.stadium2Map2D={official=true,resolution={MAP_W,MAP_H},fovDegrees=30,sourceArchive="0x4494C0..0x47B920",modelFiles={johto=0,kanto=1},cameras={johto={at=REGION.johto.at,eye=REGION.johto.eye},kanto={at=REGION.kanto.at,eye=REGION.kanto.eye}}}
log("Gen2 Open Sky official Stadium 2 flat maps loaded (312x232; collision-free screen-space mount navigation; exact FOV30 camera; Johto=model0 Kanto GenII=model1)")
end)();
