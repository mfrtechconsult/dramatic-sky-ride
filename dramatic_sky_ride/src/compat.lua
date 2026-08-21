local mod = ...

local Compat = {}
local GameVersion
pcall(function() GameVersion = require("src.core.GameVersion") end)

local function liveGame(game)
  return game or mod.game or (mod.world and mod.world.game)
end

function Compat.game(game) return liveGame(game) end
function Compat.world(game)
  game = liveGame(game)
  return (mod.world and mod.world.current) or (game and (game.overworld or game.world)) or nil
end

function Compat.player(game)
  local world = Compat.world(game)
  return world and world.player or nil
end

function Compat.generation(game)
  game = liveGame(game)
  if GameVersion and type(GameVersion.generation) == "function" then
    local ok, value = pcall(GameVersion.generation)
    if ok and tonumber(value) then return tonumber(value) end
  end
  if game and game.world and not game.overworld then return 2 end
  return 1
end
function Compat.isGen1(game) return Compat.generation(game) == 1 end
function Compat.isGen2(game) return Compat.generation(game) == 2 end

function Compat.freeRoam(game)
  game = liveGame(game)
  local world = Compat.world(game)
  if not (game and world and world.player) then return false end
  local stack = game.stack
  if not stack or type(stack.top) ~= "function" then return true end
  local top = stack:top()
  if top == world then return true end
  if top ~= nil then return false end
  if type(world.acceptsMenuInput) == "function" then
    local ok, yes = pcall(world.acceptsMenuInput, world)
    if ok then return yes == true end
  end
  return Compat.isGen2(game)
end

function Compat.party(game)
  game = liveGame(game)
  return (game and game.save and game.save.party) or {}
end

function Compat.healthy(mon)
  return mon ~= nil and not mon.isEgg and (tonumber(mon.hp) or 1) > 0
end

function Compat.find(id)
  if not mod.find then return nil end
  local ok, handle = pcall(mod.find, mod, id)
  return ok and handle or nil
end

function Compat.say(game, text)
  game = liveGame(game)
  if mod.ui and type(mod.ui.message) == "function" then
    local ok = pcall(mod.ui.message, mod.ui, text)
    if ok then return end
  end
  mod.log:info("%s", tostring(text):gsub("\n", " "))
end

function Compat.closeMenus(game)
  game = liveGame(game)
  local stack = game and game.stack
  if not stack then return end
  if Compat.isGen2(game) and type(stack.clear) == "function" then
    pcall(stack.clear, stack)
  elseif type(stack.pop) == "function" and type(stack.top) == "function" and stack:top() ~= nil then
    pcall(stack.pop, stack)
  end
end

function Compat.crystalStatus()
  local handle = Compat.find("CRYSTAL_251")
  local ex = handle and handle.exports
  return {
    active = handle ~= nil,
    version = ex and ex.version or nil,
    dexSize = ex and tonumber(ex.dexSize) or nil,
    fingerprint = ex and ex.fingerprint or nil,
  }
end

return Compat
