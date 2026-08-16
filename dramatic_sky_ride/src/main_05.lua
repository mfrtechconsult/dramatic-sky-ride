  -- happen before the mount reaches a cliff edge, while 16px walls remain
  -- below the 20px manual minimum and therefore cause no needless bobbing.
  for dy = -1, 1 do
    for dx = -1, 1 do
      terrain = math.max(terrain,
        terrainGroundHeight(map, p.cellX + dx, p.cellY + dy))
    end
  end
  return math.max(tallBuildingMinimum(ow), terrain + TERRAIN_CLEARANCE)
end

local function effectiveAltitudeTarget(ow)
  flight.safetyAltitude = safetyMinimum(ow)
  return math.max(flight.requestedAltitude or CRUISE_HEIGHT,
                  flight.safetyAltitude)
end

local function approachDt(value, target, upRate, downRate, dt)
  dt = tonumber(dt) or (1 / 60)
  if value < target then return math.min(target, value + upRate * dt) end
  if value > target then return math.max(target, value - downRate * dt) end
  return value
end

-- Standard SDL/LÖVE gamepads expose L2/R2 as trigger axes. Polling the live
-- device state avoids a held trigger becoming stuck after a disconnect or
-- lost release event. Page Up/Page Down provide the keyboard equivalent.
local function triggerDown(axis)
  local joystickApi = love and love.joystick
  if not (joystickApi and joystickApi.getJoysticks) then return false end
  local okList, joysticks = pcall(joystickApi.getJoysticks)
  if not okList or type(joysticks) ~= "table" then return false end
  for _, joystick in ipairs(joysticks) do
    local okPad, isPad = pcall(function()
      return joystick.isGamepad and joystick:isGamepad()
    end)
    if okPad and isPad then
      local okAxis, value = pcall(joystick.getGamepadAxis, joystick, axis)
      if okAxis and (tonumber(value) or 0) > TRIGGER_THRESHOLD then
        return true
      end
    end
  end
  return false
end

local function keyDown(key)
  local keyboard = love and love.keyboard
  if not (keyboard and keyboard.isDown) then return false end
  local ok, down = pcall(keyboard.isDown, key)
  return ok and down == true
end

local function altitudeInputDirection()
  local climb = keyDown("pageup") or triggerDown("triggerright")
  local descend = keyDown("pagedown") or triggerDown("triggerleft")
  if climb == descend then return 0 end
  return climb and 1 or -1
end

local function updateRequestedAltitude(dt)
  flight.verticalInput = 0
  if not manualAltitudeEnabled() or flight.phase ~= "cruise" then return end
  local dir = altitudeInputDirection()
  flight.verticalInput = dir
  if dir == 0 then return end
  local before = flight.requestedAltitude
  flight.requestedAltitude = clamp(before + dir * verticalRate()
    * (tonumber(dt) or (1 / 60)), MIN_MANUAL_HEIGHT, MAX_MANUAL_HEIGHT)
  if math.abs(flight.requestedAltitude - before) > 0.001 then
    revealAltitude()
  end
end

local function setNearest(image)
  if image and image.setFilter then image:setFilter("nearest", "nearest") end
end

-- Build the mount directly from the PokePC 16x96 follower sheet. The rider
-- is a separate entity, so disabling SHOW RIDER leaves this art
-- untouched instead of falling back to a pre-composited trainer silhouette.
local function buildMountSprite(species)
  local path = followerPath(species)
  if not path then return nil, "missing_follower_asset" end

  local okMount, mountImage = pcall(Assets.image, path)
  if not okMount or not mountImage then return nil, "mount_load_failed" end
  setNearest(mountImage)
  local mw, mh = mountImage:getDimensions()
  if mw < 16 or mh < 96 then return nil, "unexpected_sheet_size" end

  local def = {
    id = "SKY_RIDE_" .. species,
    image = path,
    frames = 6,
    walker = true,
    trueColor = true,
  }
  local sprite = SpriteRenderer.new(def, "sky_ride_" .. species)
  sprite.image = mountImage
  return sprite
end


-- The rider uses a cropped copy of the raw player sheet written into the
-- LÖVE save filesystem. Keeping it as a normal sprite asset, rather than a
-- pre-coloured Canvas, lets SpriteRenderer and Dramatic Shape recolour it on
-- every COLORS mode exactly like the original player sprite.
local function shallowCopy(source)
  local out = {}
  for k, v in pairs(source or {}) do out[k] = v end
  return out
end

local function safeAssetName(value)
  return tostring(value or "player"):gsub("[^%w_%-]", "_")
end

-- Gold temporarily replaces the live Player sprite with the current mount.
-- A Ground -> Flight switch can happen before the bridge's next update, so
-- player.sprite may still be Raikou when Ho-Oh asks us to build its rider.
-- Resolve the native renderer kept underneath the mount when one is exposed.
mod.exports._riderSourceSprite = function(player)
  local bridge = mod.exports and mod.exports.gen2PlayerBridge or nil
  if bridge and type(bridge.riderPlayerSprite) == "function" then
    local ok, sprite = pcall(bridge.riderPlayerSprite, player)
    if ok and sprite then return sprite end
  end
  if bridge and type(bridge.nativePlayerSprite) == "function" then
    local ok, sprite = pcall(bridge.nativePlayerSprite, player)
    if ok and sprite then return sprite end
  end
  return player and player.sprite or nil
end

local function writeRiderSheet(_player, _sourceSprite)
  -- Kept as a compatibility seam for older extensions. Runtime filesystem
  -- writes are not part of the sandbox API; buildInMemoryRiderSprite below is
  -- the normal path on current builds.
  return nil, "sandbox_runtime_asset_write_disabled"
end

local function buildInMemoryRiderSprite(sourceSprite, sourceDefOverride, seed)
  if not sourceSprite then return nil, "player_sprite_missing" end
  local sourceDef = sourceDefOverride or sourceSprite.def or {}
  local sourcePath = sourceDef.image
  if not sourcePath then return nil, "player_image_missing" end
  if not (love and love.graphics and love.graphics.newQuad) then
    return nil, "quad_api_unavailable"
  end

  local okImage, sourceImage = pcall(Assets.image, sourcePath)
  if not (okImage and sourceImage and sourceImage.getDimensions) then
    return nil, "player_image_load_failed"
  end
  local iw, ih = sourceImage:getDimensions()
  if iw < 16 or ih < 16 then return nil, "unexpected_player_sheet_size" end

  local sourceFrames = math.max(1, math.floor(ih / 16))
  local declaredFrames = tonumber(sourceDef.frames)
  if declaredFrames then
    sourceFrames = math.max(1, math.min(sourceFrames, math.floor(declaredFrames)))
  end

  local def = shallowCopy(sourceDef)
  def.id = "SKY_RIDE_RIDER_MEMORY_" .. safeAssetName(sourceDef.id or sourcePath)
  def.image = sourcePath
  def.frames = 6
  def.walker = true
  def.frameWidth = 16
  def.frameHeight = 16
  -- Provider-side renderers only receive SpriteDef, not the SpriteRenderer
  -- instance. These scalars let the voxel billboard path reproduce the exact
  -- same crop without reading pixels or creating a runtime asset.
  def.dramaticSkyRideRiderCrop = true
  def.dramaticSkyRideRiderCropHeight = RIDER_CROP_HEIGHT
  def.dramaticSkyRideRiderCropOutputY = RIDER_CROP_Y
  def.dramaticSkyRideRiderSourceStride = 16
  def.dramaticSkyRideRiderSourceFrames = sourceFrames

  local okSprite, sprite = pcall(SpriteRenderer.new, def,
    seed or ("sky_ride_rider:memory:" .. tostring(sourceDef.id or sourcePath)))
  if not (okSprite and sprite) then
    return nil, "rider_renderer_failed:" .. tostring(sprite)
  end
  sprite.image = sourceImage
  sprite.frameWidth = 16
  sprite.frameHeight = RIDER_CROP_HEIGHT
  sprite.anchorX = tonumber(sourceDef.anchorX) or 8
  sprite.anchorY = (tonumber(sourceDef.anchorY) or 16) - RIDER_CROP_Y
  sprite.frames = {}
  sprite.dramaticSkyRideRiderSourceFrames = {}

  local okQuads, quadReason = pcall(function()
    for frame = 0, 5 do
      local sourceFrame = math.min(frame, sourceFrames - 1)
      sprite.dramaticSkyRideRiderSourceFrames[frame] = sourceFrame
      sprite.frames[frame] = love.graphics.newQuad(
        0, sourceFrame * 16, 16, RIDER_CROP_HEIGHT, iw, ih)
    end
  end)
  if not okQuads then return nil, "rider_quad_failed:" .. tostring(quadReason) end

  -- SpriteRenderer's default geometry derives sheet Y from frameHeight. Our
  -- crop is 13 px high but frames remain 16 px apart in the source sheet, so
  -- report the true source rectangle to custom render pipelines.
  sprite.getFrameGeometry = function(self, frame)
    frame = math.floor(tonumber(frame) or 0)
    if frame < 0 then frame = 0 end
    if frame >= self.frameCount then frame = self.frameCount - 1 end
    local sourceFrame = self.dramaticSkyRideRiderSourceFrames[frame] or 0
    return {
      frame = frame,
      x = 0,
      y = sourceFrame * 16,
      width = 16,
      height = RIDER_CROP_HEIGHT,
      anchorX = self.anchorX,
      anchorY = self.anchorY,
      quad = self.frames[frame],
    }
  end

  if sourceSprite.objColors and type(sprite.setObjPalette) == "function" then
    sprite:setObjPalette(sourceSprite.objColors, sourceSprite.objGroup)
  end
  return sprite, "in_memory_crop"
end
