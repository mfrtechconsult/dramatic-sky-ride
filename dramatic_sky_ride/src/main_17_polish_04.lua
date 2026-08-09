local function activateWaterRide(game, requested)
  if mountOption("visible_surf_mounts", true) ~= true then return false end
  local ow = game and game.overworld
  local mon = preferredWaterMount(game, requested)
  local species = waterSpecies(game, mon)
  local sprite = species and buildWaterSprite(species)
  if not (ow and ow.player and ow.player.surfing and mon and sprite) then return false end
  water.active, water.mon, water.species, water.sprite = true, mon, species, sprite
  water.riderSprite = select(1, buildRiderSprite(ow.player))
  ensureWaterRider(ow)
  playSpeciesCry(species)
  if mountOption("mount_hints", true) and not mountHintsShown.water then
    mountHintsShown.water = true
  end
  return true
end

local waterPlayerPose = Player.pose
function Player:pose()
  local sprite, px, py, facing, phase, flip, hopping = waterPlayerPose(self)
  local ow = Game.overworld
  if water.active and self.surfing and ow and ow.player == self and water.sprite then
    return water.sprite, px, py, facing, phase, flip, hopping
  end
  return sprite, px, py, facing, phase, flip, hopping
end

local alpha15SetSurfingState = setSurfingState
setSurfingState = function(ow, enabled, surfMon)
  local result = alpha15SetSurfingState(ow, enabled, surfMon)
  if enabled then
    activateWaterRide(Game, surfMon)
  else
    clearWaterRide(ow)
  end
  return result
end

local waterUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = waterUpdate(self, dt, ...)
  if Game.overworld == self and self.player then
    if self.player.surfing and mountOption("visible_surf_mounts", true) then
      if not water.active then activateWaterRide(Game) end
      if water.active then ensureWaterRider(self) end
    elseif water.active then
      clearWaterRide(self)
    end
  end
  return result
end

mod.hooks:wrap("ui.party.submenu", function(next, game, items, mon, ctx)
  local out = next(game, items, mon, ctx)
  if type(out) ~= "table" then out = items end
  if flight.active then return out end
  local species = waterSpecies(game, mon)
  if not species or not monKnowsMove(mon, "SURF") or (ctx and ctx.battle) then return out end
  table.insert(out, 1, { label = Strings("SURF & RIDE"), onSelect = function(selected, liveGame)
    if liveGame and liveGame.stack then liveGame.stack:pop() end
    for i, partyMon in ipairs(liveGame.save.party or {}) do
      if partyMon == selected then lastWaterMountIndex = i break end
    end
    if liveGame.overworld and liveGame.overworld.player.surfing then
      clearWaterRide(liveGame.overworld)
      activateWaterRide(liveGame, selected)
    else
      say(liveGame, "Selected for Surf.\nUse Surf normally.")
    end
  end })
  return out
end, 70)

-- Unified MOUNTS menu ---------------------------------------------------------
local MOUNTS_SCREEN = "DramaticSkyRideMounts"
local function partyName(game, mon, species)
  if mon and mon.nickname and mon.nickname ~= "" then return mon.nickname end
  local def = game.data and game.data.pokemon and game.data.pokemon[mon and mon.species]
  return def and def.name or species or (mon and mon.species) or "POKEMON"
end

if mod.content and mod.content.screens and mod.ui and mod.ui.ListMenu then
  mod.content.screens:register(MOUNTS_SCREEN, {
    new = function(game)
      local items = {}
      if flight.active then items[#items + 1] = { label = "LAND", value = { kind = "land" } } end
      if ground.active then items[#items + 1] = { label = "DISMOUNT", value = { kind = "dismount" } } end
      for i, mon in ipairs(game.save.party or {}) do
        local fs = healthy(mon) and mountSpecies(game, mon) or nil
        local gs = healthy(mon) and groundSpecies(game, mon) or nil
        local ws = healthy(mon) and waterSpecies(game, mon) or nil
        if gs then items[#items + 1] = { label = partyName(game, mon, gs), right = "GROUND",
          value = { kind = "ground", index = i } } end
        if fs then items[#items + 1] = { label = partyName(game, mon, fs), right = "FLY",
          value = { kind = "flight", index = i } } end
        if not flight.active and ws and monKnowsMove(mon, "SURF") then
          items[#items + 1] = { label = partyName(game, mon, ws), right = "SURF",
            value = { kind = "water", index = i } }
        end
      end
      return mod.ui.ListMenu.new(game, "MOUNTS", items, {
        pageJump = true,
        onChoose = function(item, menu)
          local value = item and item.value or {}
          menu:close()
          if value.kind == "land" then beginLanding(game, false)
          elseif value.kind == "dismount" then stopGroundRide(game, "menu")
          elseif value.kind == "ground" then
            lastGroundMountIndex = value.index
            if ground.active then stopGroundRide(game, "switch") end
            startGroundRide(game, game.save.party[value.index])
          elseif value.kind == "flight" then
            if ground.active then stopGroundRide(game, "switch_to_flight") end
            startFlight(game, game.save.party[value.index])
          elseif value.kind == "water" then
            lastWaterMountIndex = value.index
            if game.overworld and game.overworld.player.surfing then
              clearWaterRide(game.overworld)
              activateWaterRide(game, game.save.party[value.index])
            else
              say(game, "Selected for Surf.\nUse Surf normally.")
            end
          end
        end,
      })
    end,
  })

  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" or mountOption("mount_menu", true) ~= true then return out end
    return mod.ui.insertBefore(out, "SAVE", {
      label = "MOUNTS",
      onSelect = function() mod.ui.push(game, MOUNTS_SCREEN) end,
    })
  end, 75)
end

mod.exports.groundStamina = function() return ground.stamina or 0 end
mod.exports.groundGalloping = function() return ground.gallop == true end
mod.exports.waterMountSpecies = function() return water.species end
mod.exports.isWaterRiding = function() return water.active == true end
mod.exports.eligibleWaterMounts = function()
  local out = {}
  for species, cfg in pairs(WATER_ELIGIBLE) do out[#out + 1] = { species = species, dex = cfg.dex } end
  table.sort(out, function(a, b) return a.dex < b.dex end)
  return out
end

log("alpha.15 Ground Ride, visible Surf mounts and mount menu loaded")

end)()
