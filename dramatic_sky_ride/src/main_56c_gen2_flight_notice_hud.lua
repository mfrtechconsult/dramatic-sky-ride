;(function()
-- Gold renders its final screen-space UI through the shared render.hud hook.
-- DSR's original notice panel is attached to OverworldState:drawUI, which is
-- sufficient on Gen 1 but is not a reliable final HUD seam on Game2. Mirror
-- only the existing flight.notice state here: progression rules, timers and
-- message ownership remain unchanged.

local generation = mod.exports.runtimeGeneration or {}
local state = { frames = 0, lastNotice = nil }

local function isGold()
  return type(generation.isGen2) == "function"
    and generation.isGen2(Game) == true
end

local function drawNotice(viewport)
  if not (isGold() and flight and flight.active and flight.notice
      and viewport and love and love.graphics) then
    return false
  end

  local scale = tonumber(viewport.scale) or 1
  if scale <= 0 then return false end
  local gameX = tonumber(viewport.gameX) or 0
  local gameY = tonumber(viewport.gameY) or 0
  local text = tostring(flight.notice)

  local G = love.graphics
  G.push("all")
  G.translate(gameX, gameY)
  G.scale(scale, scale)
  G.setColor(0, 0, 0, 1)
  Font.drawBox(1, 14, 18, 4)
  local width = Font.width(text)
  Font.draw(text, math.floor((160 - width) / 2), 120)
  G.pop()

  state.frames = state.frames + 1
  state.lastNotice = text
  return true
end

mod.hooks:wrap("render.hud", function(next, game, viewport)
  local result = next(game, viewport)
  drawNotice(viewport)
  return result
end, 0)

mod.exports.gen2FlightNoticeHud = {
  api = 1,
  status = function()
    return {
      frames = state.frames,
      lastNotice = state.lastNotice,
      active = isGold() and flight and flight.active == true
        and flight.notice ~= nil,
    }
  end,
}

log("Gen2 flight notice HUD bridge loaded")
end)();
