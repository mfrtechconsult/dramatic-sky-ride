  return true
end

local function drawLandingPoints(G, state)
  local nearestSpawn = state.nearest and state.nearest.row
    and state.nearest.row.spawn or nil
  for _, point in ipairs(visitedPoints(state.region)) do
    local anchor = point and point.anchor
    if anchor then
      local x, y = project(state.region, anchor.x, anchor.y)
      local selected = nearestSpawn ~= nil and point.row
        and point.row.spawn == nearestSpawn
      if selected then
        G.setColor(1, 1, 1, 0.98)
        G.circle("line", x, y, 4.5)
      end
      G.setColor(1, 1, 1, 0.95)
      G.circle("fill", x, y, selected and 2.0 or 1.35)
    end
  end
end

local function drawMountMiniature(G, state, x, y)
  local sprite = flight.sprite
  local drawn = false
  if sprite and type(sprite.draw) == "function" then
    G.push()
    G.translate(math.floor(x), math.floor(y))
    G.scale(0.42, 0.42)
    G.setColor(1, 1, 1, 1)
    local phase = (tonumber(state.anim) or 0) >= 16 and 1 or 0
    local ok = pcall(sprite.draw, sprite, -8, -8, 0, 0,
      state.facing or "right", phase, false)
    drawn = ok
    G.pop()
  end

  if not drawn then
    G.setColor(1, 1, 1, 1)
    G.polygon("fill", x, y - 4, x + 4, y + 4,
      x, y + 2, x - 4, y + 4)
  end
end

local function drawHud(G, state)
  G.setColor(0.08, 0.12, 0.16, 0.92)
  G.rectangle("fill", 0, 0, SCREEN_W, MAP_TOP)
  G.rectangle("fill", 0, MAP_BOTTOM, SCREEN_W, SCREEN_H - MAP_BOTTOM)
  G.setColor(1, 1, 1, 1)
  if type(G.print) ~= "function" then return end

  local region = state.region == "kanto" and "KANTO" or "JOHTO"
  local altitude = math.floor((tonumber(state.virtualAltitude) or 88) + 0.5)
  local speed = math.floor((tonumber(state.speed) or 0) + 0.5)
  pcall(G.print, "SOAR " .. region .. " A" .. tostring(altitude)
    .. " S" .. tostring(speed), 4, 4)

  local bottom = state.notice
  if not bottom then
    local name = state.nearest and state.nearest.row
      and (state.nearest.row.name or state.nearest.row.landmark)
    if name and (tonumber(state.nearestDistance) or math.huge) <= 11 then
      bottom = "A LAND - " .. cleanMapName(name)
    else
      bottom = "B BOOST  L/R STEER  R2/L2 ALT"
    end
  end
  bottom = tostring(bottom)
  if #bottom > 28 then bottom = bottom:sub(1, 28) end
  pcall(G.print, bottom, 4, 128)
end

local function drawPanel(state)
  local G = love.graphics
  -- Always establish a complete 160x144 picture. No G.clear() is used here:
  -- this function works both as the standalone widescreen page and as the base
  -- state when a TextBox is stacked on top of it.
  G.setColor(0.58, 0.80, 0.96, 1)
  G.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
  drawBackdrop(G, state)
  drawLandingPoints(G, state)
  local x, y = project(state.region, state.x, state.y)
  drawMountMiniature(G, state, x, y)
  drawHud(G, state)
end

local function fitScale(winW, winH)
  local raw = math.min((tonumber(winW) or SCREEN_W) / SCREEN_W,
    (tonumber(winH) or SCREEN_H) / SCREEN_H)
  if raw >= 1 then return math.max(1, math.floor(raw)) end
  return math.max(0.01, raw)
end

local function emergencyWidescreen(state, winW, winH)
  local G = love.graphics
  local pushed = false
  pcall(function()
    G.push("all")
    pushed = true
    G.origin()
    G.setColor(0.08, 0.12, 0.16, 1)
    G.rectangle("fill", 0, 0, winW, winH)
    local scale = fitScale(winW, winH)
    local ox = math.floor((winW - SCREEN_W * scale) * 0.5)
    local oy = math.floor((winH - SCREEN_H * scale) * 0.5)
    G.translate(ox, oy)
    G.scale(scale, scale)
    G.setColor(0.58, 0.80, 0.96, 1)
    G.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
    G.setColor(0.08, 0.12, 0.16, 0.92)
    G.rectangle("fill", 0, 0, SCREEN_W, 18)
    G.rectangle("fill", 0, 124, SCREEN_W, 20)
    local x, y = project(state.region, state.x, state.y)
    G.setColor(1, 1, 1, 1)
    G.polygon("fill", x, y - 5, x + 5, y + 5,
      x, y + 2, x - 5, y + 5)
  end)
  if pushed then pcall(G.pop) end
end

local function drawWidescreen(state, winW, winH)
  if not (love and love.graphics) then return end
  local G = love.graphics
  winW = tonumber(winW) or select(1, G.getDimensions()) or SCREEN_W
  winH = tonumber(winH) or select(2, G.getDimensions()) or SCREEN_H

  local pushed = false
  local ok, err = pcall(function()
    G.push("all")
    pushed = true
    G.origin()

    -- Own the whole window. This prevents Game2's opaque-page safety path from
    -- painting a white field around (or instead of) Open Sky.
    G.setColor(0.08, 0.12, 0.16, 1)
    G.rectangle("fill", 0, 0, winW, winH)

    local scale = fitScale(winW, winH)
    local ox = math.floor((winW - SCREEN_W * scale) * 0.5)
    local oy = math.floor((winH - SCREEN_H * scale) * 0.5)
    G.translate(ox, oy)
    G.scale(scale, scale)
    drawPanel(state)
  end)

  if pushed then pcall(G.pop) end
  if not ok then
    rememberDrawError("widescreen", err)
    emergencyWidescreen(state, winW, winH)
  end
end

local function patchState(state)
  if type(state) ~= "table" or patchedStates[state] then return end
  patchedStates[state] = true

  local fallback = state.draw
  state.draw = function(self)
    local ok, err = pcall(drawPanel, self)
    if not ok then
      rememberDrawError("panel", err)
      if type(fallback) == "function" then pcall(fallback, self) end
    end
  end

  -- Native Gold full-page contract. Game2:drawScene sees this before its
  -- opaque-page white safety net and calls drawWidescreen directly.
  state.wantsFillScale = function() return true end
