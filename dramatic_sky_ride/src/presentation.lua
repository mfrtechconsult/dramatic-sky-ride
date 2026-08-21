local mod = ...

local Presentation = {}
local Settings, Compat

local REF_METERS = 1.70
local GROUND_LIFT = {
  ARCANINE=6.8,RAPIDASH=7.1,DODRIO=7.2,RHYHORN=6.2,RHYDON=7.4,
  KANGASKHAN=7.8,TAUROS=6.7,SNORLAX=8.6,MEGANIUM=7.0,GIRAFARIG=7.2,
  URSARING=7.6,DONPHAN=6.4,STANTLER=7.0,RAIKOU=6.8,ENTEI=7.0,
  SUICUNE=6.8,TYRANITAR=8.0,
}
local FLIGHT_LIFT = {
  CHARIZARD=7.0,PIDGEOT=6.2,FEAROW=6.0,GOLBAT=5.8,AERODACTYL=6.4,
  ARTICUNO=6.8,ZAPDOS=6.4,MOLTRES=6.8,DRAGONAIR=6.5,DRAGONITE=7.2,
  NOCTOWL=6.2,CROBAT=5.9,XATU=6.1,SKARMORY=6.3,LUGIA=7.2,HO_OH=7.2,
}
local SURF_LIFT = {
  BLASTOISE=6.2,TENTACRUEL=5.8,GYARADOS=6.4,LAPRAS=7.0,FERALIGATR=6.6,
  MANTINE=5.8,KINGDRA=6.1,LUGIA=7.0,SUICUNE=6.6,
}

local function clamp(v,a,b) return math.max(a, math.min(b, v)) end

local function pokemonDef(game, species, dex)
  local pokemon = game and game.data and game.data.pokemon
  if type(pokemon) ~= "table" then return nil end
  if species and pokemon[species] then return pokemon[species] end
  for _, def in pairs(pokemon) do
    if type(def) == "table" and tonumber(def.dex) == tonumber(dex) then return def end
  end
end

local function heightMeters(game, species, dex)
  local def = pokemonDef(game, species, dex)
  local entry = def and def.dexEntry
  local ft = entry and tonumber(entry.heightFt)
  local inch = entry and tonumber(entry.heightIn)
  if ft and inch then
    local total = ft * 12 + inch
    if total > 0 then return total * 0.0254 end
  end
  local meters = def and tonumber(def.heightMeters or def.height)
  if meters and meters > 0 and meters < 30 then return meters end
end

function Presentation.scale(game, species, dex)
  local base = 1
  if Settings.bool("pokedex_mount_sizes", true) then
    local meters = heightMeters(game, species, dex)
    if meters then base = clamp(meters / REF_METERS, 0.50, 4.00) end
  end
  local percent = Settings.number("mount_size_" .. tostring(species):lower(), 100)
  return base * clamp(percent, 50, 200) / 100
end

local function lift(kind, species)
  if kind == "flight" then return FLIGHT_LIFT[species] or 6.5 end
  if kind == "surf" then return SURF_LIFT[species] or 6.3 end
  return GROUND_LIFT[species] or 6.7
end

local function transformedDraw(raw, self, scale, px, py, camX, camY, ...)
  local g = love and love.graphics
  if not (g and g.push and g.pop and g.translate and g.scale) or math.abs(scale-1) < 0.001 then
    return raw(self, px, py, camX, camY, ...)
  end
  local ax = (tonumber(px) or 0) - (tonumber(camX) or 0) + 8
  local ay = (tonumber(py) or 0) - (tonumber(camY) or 0) + 12
  g.push()
  g.translate(ax, ay)
  g.scale(scale, scale)
  g.translate(-ax, -ay)
  local ok, a,b,c,d = pcall(raw, self, px, py, camX, camY, ...)
  g.pop()
  if not ok then error(a) end
  return a,b,c,d
end

function Presentation.decorate(game, row, kind, mountSprite, riderSprite)
  if not (mountSprite and type(mountSprite.draw) == "function" and row) then return mountSprite end
  local raw = mountSprite.draw
  local species, dex = row.species, row.dex
  mountSprite.def = mountSprite.def or {}
  mountSprite.def.dramaticSkyRideMountSpecies = species
  mountSprite.def.dramaticSkyRideMountDex = dex

  mountSprite.draw = function(self, px, py, camX, camY, facing, walkPhase, stepFlip, topHalf)
    local scale = Presentation.scale(game, species, dex)
    transformedDraw(raw, self, scale, px, py, camX, camY, facing, walkPhase, stepFlip, topHalf)
    if Settings.bool("show_rider", true) and riderSprite and type(riderSprite.draw) == "function" then
      local riderY = (tonumber(py) or 0) - lift(kind, species) * math.max(0.75, math.min(scale, 2.5))
      -- SpriteRenderer's topHalf path is the clean built-in way to hide the
      -- trainer's lower body behind the mount card.
      pcall(riderSprite.draw, riderSprite, px, riderY, camX, camY,
        facing or "down", walkPhase or 0, stepFlip or false, true)
    end
  end
  return mountSprite
end

function Presentation.rendererWantsStadium()
  local choice = tostring(Settings.get("flight_mount_renderer", "auto"))
  if choice == "2d" then return false end
  if choice == "stadium3d" then return true end
  local h = Compat.find("STADIUM2_OVERWORLD_MODELS")
  return h ~= nil
end

function Presentation.install(deps)
  Settings, Compat = deps.settings, deps.compat
  mod.exports.mountVisualScale = Presentation.scale
  mod.exports.mountPokedexHeightMeters = heightMeters
end

return Presentation
