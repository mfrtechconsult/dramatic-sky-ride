;(function()
-- -------------------------------------------------------------------------
-- Generation II mount extension.
--
-- Species availability is capability/data-driven: DSR keys the curated mount
-- roster by National Dex but never requires a specific Gen 2 content mod.
-- Crystal 251 or any future provider can supply the actual Pokemon records;
-- Wilds of Kanto or the maintained mfrtechconsult/PokePCFollowers fork can
-- independently supply the six-frame overworld art.
-- -------------------------------------------------------------------------

local GEN2_FLIGHT = {
  NOCTOWL  = { dex = 164, label = "NOCTOWL",  lift = 6.4, eye = 18.0 },
  CROBAT   = { dex = 169, label = "CROBAT",   lift = 5.8, eye = 17.5 },
  XATU     = { dex = 178, label = "XATU",     lift = 6.2, eye = 18.0 },
  SKARMORY = { dex = 227, label = "SKARMORY", lift = 6.7, eye = 18.5 },
  LUGIA    = { dex = 249, label = "LUGIA",    lift = 8.0, eye = 21.0 },
  HO_OH    = { dex = 250, label = "HO-OH",    lift = 7.5, eye = 20.5 },
}

local GEN2_GROUND = {
  MEGANIUM  = { dex = 154, label = "MEGANIUM",  lift = 7.3 },
  GIRAFARIG = { dex = 203, label = "GIRAFARIG", lift = 7.2 },
  URSARING  = { dex = 217, label = "URSARING",  lift = 7.8 },
  DONPHAN   = { dex = 232, label = "DONPHAN",   lift = 6.5 },
  STANTLER  = { dex = 234, label = "STANTLER",  lift = 7.2 },
  RAIKOU    = { dex = 243, label = "RAIKOU",    lift = 7.0 },
  ENTEI     = { dex = 244, label = "ENTEI",     lift = 7.2 },
  SUICUNE   = { dex = 245, label = "SUICUNE",   lift = 7.0, amphibious = true },
  TYRANITAR = { dex = 248, label = "TYRANITAR", lift = 8.2 },
}

local GEN2_SURF_DEX = {
  FERALIGATR = 160,
  MANTINE = 226,
  KINGDRA = 230,
  LUGIA = 249,
}

-- The speed/stamina profiles deliberately stay close to the existing Gen 1
-- range. Suicune is fast and fluid, but not a progression-breaking teleport.
local GEN2_GROUND_PROFILES = {
  MEGANIUM  = { base = 0.96, gallop = 1.20, accel = 2.2, drain = 0.20, regen = 0.23, lift = 7.3 },
  GIRAFARIG = { base = 1.07, gallop = 1.34, accel = 3.0, drain = 0.24, regen = 0.21, lift = 7.2 },
  URSARING  = { base = 0.88, gallop = 1.16, accel = 1.5, drain = 0.19, regen = 0.25, lift = 7.8 },
  DONPHAN   = { base = 0.98, gallop = 1.30, accel = 2.4, drain = 0.22, regen = 0.22, lift = 6.5 },
  STANTLER  = { base = 1.10, gallop = 1.40, accel = 3.2, drain = 0.25, regen = 0.20, lift = 7.2 },
  RAIKOU    = { base = 1.18, gallop = 1.50, accel = 3.8, drain = 0.27, regen = 0.20, lift = 7.0 },
  ENTEI     = { base = 1.10, gallop = 1.40, accel = 3.0, drain = 0.25, regen = 0.21, lift = 7.2 },
  SUICUNE   = { base = 1.16, gallop = 1.47, accel = 3.7, drain = 0.24, regen = 0.22, lift = 7.0 },
  TYRANITAR = { base = 0.84, gallop = 1.13, accel = 1.3, drain = 0.18, regen = 0.26, lift = 8.2 },
}

for species, cfg in pairs(GEN2_FLIGHT) do
  ELIGIBLE[species] = { dex = cfg.dex, label = cfg.label }
  ELIGIBLE_BY_DEX[cfg.dex] = species
  RIDER_OFFSETS[species] = {
    lift = cfg.lift, depth = 0.35, orbitX = 0.0, orbitY = 0.35, eye = cfg.eye,
  }
end

for species, cfg in pairs(GEN2_GROUND) do
  GROUND_ELIGIBLE[species] = { dex = cfg.dex, label = cfg.label, lift = cfg.lift }
  GROUND_BY_DEX[cfg.dex] = species
end

-- main_21 reads SIZE <species> dynamically; its private species list only
-- controls which option rows are published. Add the Gen 2 rows here without
-- replacing the existing Gen 1 schema or sizing implementation.
local GEN2_SIZE_SPECIES = {
  "NOCTOWL", "CROBAT", "XATU", "SKARMORY", "LUGIA", "HO_OH",
  "MEGANIUM", "GIRAFARIG", "URSARING", "DONPHAN", "STANTLER",
  "RAIKOU", "ENTEI", "SUICUNE", "TYRANITAR",
  "FERALIGATR", "MANTINE", "KINGDRA",
}
for _, species in ipairs(GEN2_SIZE_SPECIES) do
  OPTION_SCHEMA[#OPTION_SCHEMA + 1] = {
    key = "mount_size_" .. species:lower(),
    type = "number",
    label = "SIZE " .. species:gsub("_", "-"),
    default = 100,
    min = 50,
    max = 200,
    step = 5,
    help = "100 keeps this Gen 2 mount at its Pokedex-derived size.",
  }
end
if mod.options and mod.options.define then mod.options:define(OPTION_SCHEMA) end

-- Existing alpha.15 Ground Ride sees unknown/new species as Tauros. Keep the
-- mature Ground Ride lifecycle, but correct only the final movement multiplier
-- for the curated Gen 2 profile. This leaves Gen 1 byte-for-byte behavior alone.
local TAUROS_PROFILE = { base = 1.06, gallop = 1.39 }
local function profileMotion(profile, blend)
  blend = tonumber(blend) or 0
  return profile.base * (1 + (profile.gallop - 1) * blend)
end

mod.hooks:wrap("movement.speed", function(next, frames, ctx)
  local value = next(frames, ctx)
  if not (ground.active and GEN2_GROUND_PROFILES[ground.species]) then return value end
  local profile = GEN2_GROUND_PROFILES[ground.species]
  local fallback = profileMotion(TAUROS_PROFILE, ground.speedBlend)
  local wanted = profileMotion(profile, ground.speedBlend)
  if wanted <= 0 then return value end
  return math.max(3, (tonumber(value) or tonumber(frames) or 8) * fallback / wanted)
end, 99)

-- Voxel FreeMove bypasses movement.speed. Compensate the existing Tauros
-- fallback at the input of the already-installed Ground Ride FreeMove wrapper.
if dramaticFreeMove and type(dramaticFreeMove.tick) == "function"
   and not dramaticFreeMove.dramaticGen2GroundSpeedHook then
  local previousTick = dramaticFreeMove.tick
  dramaticFreeMove.tick = function(state)
    local profile = ground.active and GEN2_GROUND_PROFILES[ground.species] or nil
    if not (profile and isFreeCamera()) then return previousTick(state) end
    local ratio = profileMotion(profile, ground.speedBlend)
      / profileMotion(TAUROS_PROFILE, ground.speedBlend)
    local oldWalk, oldBike = dramaticFreeMove.WALK, dramaticFreeMove.BIKE
    if tonumber(oldWalk) then dramaticFreeMove.WALK = oldWalk * ratio end
    if tonumber(oldBike) then dramaticFreeMove.BIKE = oldBike * ratio end
    local ok, result = pcall(previousTick, state)
    dramaticFreeMove.WALK, dramaticFreeMove.BIKE = oldWalk, oldBike
    if not ok then error(result, 0) end
    return result
  end
  dramaticFreeMove.dramaticGen2GroundSpeedHook = true
end

-- main_17/main_21 use the Tauros/default 6.5px seat for a species they did not
-- know at definition time. Correct only the returned seat position for Gen 2.
local previousGroundRiderPoseGen2 = groundRiderPose
groundRiderPose = function(entity)
  local sprite, px, py, facing, phase, flip, hopping = previousGroundRiderPoseGen2(entity)
  local profile = ground.active and GEN2_GROUND_PROFILES[ground.species] or nil
  if profile then
    local scale = 1
    if mod.exports and type(mod.exports.mountVisualScale) == "function" then
      local ok, value = pcall(mod.exports.mountVisualScale, ground.species)
      if ok and tonumber(value) then scale = tonumber(value) end
    end
    py = py - ((profile.lift or 6.5) - 6.5) * scale
  end
  return sprite, px, py, facing, phase, flip, hopping
end

-- -------------------------------------------------------------------------
-- Suicune seamless land <-> water ride.
-- -------------------------------------------------------------------------
local SUICUNE = "SUICUNE"
local SUICUNE_DEX = 245

local function suicuneRideActive()
  return ground.active == true and ground.species == SUICUNE
end

local function surfProgressionUnlocked(ow)
  if not (ow and type(ow.partyKnows) == "function") then return false end
  local ok, mon = pcall(ow.partyKnows, ow, "SURF")
  return ok and mon ~= nil and mon ~= false
end

local function currentCellIsWater(map, player)
  return map and player and map.inBounds and map:inBounds(player.cellX, player.cellY)
    and map.isWaterCell and map:isWaterCell(player.cellX, player.cellY) == true
end

local function setSuicuneWaterState(player, enabled)
  if not player then return end
  ground.amphibiousWater = enabled == true
  player.surfing = enabled == true
  if enabled then player.surfingPikachu = false end
end

local function targetWaterInMap(map, player, dir)
  if not (map and player and map.inBounds and map.isWaterCell) then return false end
  local tx, ty = Collision.target(player.cellX, player.cellY, dir)
  return map:inBounds(tx, ty) and map:isWaterCell(tx, ty) == true
end

-- Arm native Surf collision rules before Collision.canMove. We deliberately do
-- not flip movement.collision after the verdict: doing so would bypass the
-- engine's water tile-pair rules and other mods' normal collision semantics.
local gen2TryMove = Player.tryMove
function Player:tryMove(dir, map, entities)
  local ow = Game.overworld
  if not (suicuneRideActive() and ow and ow.player == self) then
    return gen2TryMove(self, dir, map, entities)
  end

  -- A pure turn must remain a pure turn. Only arm water mode on the actual
  -- same-facing step attempt immediately before native collision resolution.
  local attemptingStep = not self.moving and not self.inputLocked
    and self.facing == dir and (tonumber(self.turnTimer) or 0) <= 0
  local enteringWater = attemptingStep and not self.surfing
    and targetWaterInMap(map, self, dir)

  if enteringWater then
    if not surfProgressionUnlocked(ow) then
      notifyHud("SURF REQUIRED", 1.4)
      return gen2TryMove(self, dir, map, entities)
    end
    setSuicuneWaterState(self, true)
  end

  local result, why = gen2TryMove(self, dir, map, entities)
  if enteringWater and result ~= "moved" and not currentCellIsWater(map, self) then
    setSuicuneWaterState(self, false)
  end
  return result, why
end

-- Connection crossings are handled before Player:tryMove by the engine.
-- Pre-arm Surf semantics for a water landing on the neighbour map using the
-- same destination helpers as Gen1Recomp's own seam collision code.
local gen2CheckEdgeExit = OverworldState.checkEdgeExit
function OverworldState:checkEdgeExit(dir)
  if not (suicuneRideActive() and Game.overworld == self and self.player) then
    return gen2CheckEdgeExit(self, dir)
  end

  local p = self.player
  local tx, ty = Collision.target(p.cellX, p.cellY, dir)
  if self.map and self.map.inBounds and self.map:inBounds(tx, ty) then
    return gen2CheckEdgeExit(self, dir)
  end

  local dest, ts, x, y = self:connectionLanding(dir)
  local enteringWater = dest and ts and Map.defIsWaterCell
    and Map.defIsWaterCell(dest, ts, x, y) == true
  local armed = false
  if enteringWater and not p.surfing then
    if not surfProgressionUnlocked(self) then
      notifyHud("SURF REQUIRED", 1.4)
      return gen2CheckEdgeExit(self, dir)
    end
    setSuicuneWaterState(p, true)
    armed = true
  end

  local crossed = gen2CheckEdgeExit(self, dir)
  if armed and not crossed and not currentCellIsWater(self.map, p) then
    setSuicuneWaterState(p, false)
  end
  return crossed
end

-- Keep the ground mount as the visual/lifecycle owner. The engine's surfing
-- flag is only a traversal state, never a request to switch Suicune to the
-- separate visible-Surf mount system.
local gen2Update = OverworldState.update
function OverworldState:update(dt, ...)
  local result = gen2Update(self, dt, ...)
  local p = self.player
  if suicuneRideActive() and Game.overworld == self and p and not p.moving then
    local waterHere = currentCellIsWater(self.map, p)
    if waterHere and surfProgressionUnlocked(self) then
      setSuicuneWaterState(p, true)
    elseif not waterHere and ground.amphibiousWater then
      setSuicuneWaterState(p, false)
    end
  elseif ground.amphibiousWater and not suicuneRideActive() then
    ground.amphibiousWater = false
  end
  return result
end

-- Starting/remounting Suicune while already on native Surf is allowed as a
-- recovery path (not the normal user flow). Temporarily hide the engine flag
-- only while the mature Ground Ride initializer performs its land-only guard,
-- then immediately restore water traversal state.
local gen2StartGroundRide = startGroundRide
startGroundRide = function(game, mon)
  local ow = game and game.overworld
  local p = ow and ow.player
  local species = groundSpecies(game, mon)
  if species ~= SUICUNE or not (p and p.surfing and currentCellIsWater(ow.map, p)) then
    return gen2StartGroundRide(game, mon)
  end
  if not surfProgressionUnlocked(ow) then return false end
  p.surfing = false
  local ok = gen2StartGroundRide(game, mon)
  p.surfing = true
  if ok then ground.amphibiousWater = true end
  return ok
end

mod.exports.gen2Mounts = {
  flight = GEN2_FLIGHT,
  ground = GEN2_GROUND,
  surfDex = GEN2_SURF_DEX,
  suicuneDex = SUICUNE_DEX,
  suicuneAmphibiousActive = suicuneRideActive,
  suicuneOnWater = function()
    return suicuneRideActive() and ground.amphibiousWater == true
  end,
  surfProgressionUnlocked = function()
    return surfProgressionUnlocked(Game.overworld)
  end,
}

log("Generation II mounts loaded; Suicune seamless land/water ride enabled")
end)();
