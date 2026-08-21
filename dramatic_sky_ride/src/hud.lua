local mod = ...

local Hud = {}
local runtime, settings
local lastAltitude = nil
local altitudeTimer = 0

local function safePush(g)
  if not (g and g.push) then return false end
  local ok = pcall(g.push, "all")
  if not ok then pcall(g.push) end
  return true
end

local function bar(g, x, y, w, h, ratio)
  ratio = math.max(0, math.min(1, tonumber(ratio) or 0))
  g.setColor(0,0,0,0.65)
  g.rectangle("fill",x-1,y-1,w+2,h+2)
  g.setColor(1,1,1,0.85)
  g.rectangle("line",x,y,w,h)
  g.rectangle("fill",x+2,y+2,math.max(0,(w-4)*ratio),math.max(1,h-4))
end

function Hud.install(deps)
  runtime, settings = deps.runtime, deps.settings

  mod.hooks:wrap("core.update", function(nextFn, game, dt)
    nextFn(game,dt)
    local s=runtime.public.state()
    if s.mode == "flight" then
      if lastAltitude == nil or math.abs((s.altitude or 0)-lastAltitude) > 0.25 then
        altitudeTimer=2.0
        lastAltitude=s.altitude
      else
        altitudeTimer=math.max(0,altitudeTimer-(tonumber(dt) or 1/60))
      end
    else
      lastAltitude=nil
      altitudeTimer=0
    end
  end,1200)

  mod.hooks:wrap("render.hud", function(nextFn, game, viewport)
    local result=nextFn(game,viewport)
    local g=love and love.graphics
    if not (g and viewport and safePush(g)) then return result end
    local s=runtime.public.state()
    local scale=tonumber(viewport.scale) or 1
    local x=(tonumber(viewport.gameX) or 0)+8*scale
    local y=(tonumber(viewport.gameY) or 0)+8*scale

    if s.mode == "flight" then
      local mode=tostring(settings.get("altitude_display","temporary"))
      if mode == "always" or (mode == "temporary" and altitudeTimer > 0) then
        local ratio=((tonumber(s.altitude) or 20)-20)/(96-20)
        bar(g,x,y,44*scale,5*scale,ratio)
        y=y+10*scale
      end
    end

    if s.mode == "ground" and settings.bool("ground_hud",true) then
      if s.gallop or (tonumber(s.stamina) or 1) < 0.999 then
        bar(g,x,y,44*scale,5*scale,s.stamina)
      end
    end

    g.pop()
    return result
  end,1200)
end

return Hud
