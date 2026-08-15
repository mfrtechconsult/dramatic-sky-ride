;(function()
-- -------------------------------------------------------------------------
-- Bundled PokePC follower sheets used only as DSR's final 2D fallback.
--
-- External providers are still preferred by main_27. This small resolver is
-- intentionally read-only: none of PokePC's follower controller is imported.
-- -------------------------------------------------------------------------
local ROOT = "assets/pokepc_followers"
local MAX_DEX = 251
local pathCache = {}

local function dexForSpecies(species)
  if type(species) == "number" then
    local dex = math.floor(species)
    return dex >= 1 and dex <= MAX_DEX and dex or nil
  end
  if type(species) ~= "string" or species == "" then return nil end

  local cfg = ELIGIBLE and ELIGIBLE[species] or nil
  local dex = cfg and tonumber(cfg.dex) or nil
  if not dex then
    local pokemon = Game and Game.data and Game.data.pokemon or nil
    local def = pokemon and (pokemon[species] or pokemon[species:upper()]) or nil
    dex = def and tonumber(def.dex) or nil
  end
  dex = dex and math.floor(dex) or nil
  return dex and dex >= 1 and dex <= MAX_DEX and dex or nil
end

local function assetPathForDex(dex)
  dex = tonumber(dex) and math.floor(tonumber(dex)) or nil
  if not (dex and dex >= 1 and dex <= MAX_DEX) then return nil end
  if pathCache[dex] ~= nil then return pathCache[dex] or nil end

  local relative = string.format("%s/follower_%03d.png", ROOT, dex)
  local okRead, bytes = pcall(mod.read, mod, relative)
  if not okRead or type(bytes) ~= "string" or bytes == "" then
    pathCache[dex] = false
    return nil
  end

  local path = nil
  if mod.assets and type(mod.assets.path) == "function" then
    local okPath, value = pcall(mod.assets.path, mod.assets, relative)
    if okPath and type(value) == "string" and value ~= "" then path = value end
  end
  pathCache[dex] = path or false
  return path
end

local function definition(species)
  local dex = dexForSpecies(species)
  local path = assetPathForDex(dex)
  if not path then return nil end
  return {
    id = string.format("DSR_BUNDLED_FOLLOWER_%03d", dex),
    image = path,
    frames = 6,
    walker = true,
    trueColor = true,
    providerId = "DRAMATIC_SKY_RIDE_BUNDLED_POKEPC",
    dex = dex,
  }
end

mod.exports.bundledFollowerSprites = {
  api = 1,
  sourceRepository = "mfrtechconsult/PokePCFollowers",
  maxDex = MAX_DEX,
  dexForSpecies = dexForSpecies,
  path = function(species)
    local def = definition(species)
    return def and def.image or nil
  end,
  resolveFollowerSprite = function(opts)
    local species = type(opts) == "table" and (opts.species or opts.dex) or opts
    return definition(species)
  end,
  clearCache = function() pathCache = {} end,
}

log("Bundled PokePC 2D fallback ready (National Dex 1-251)")
end)();
