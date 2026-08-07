;(function()
-- 0.1.1 compatibility bridge for multiple DRAMATIC_SHAPE providers.
-- Both the upstream Dramatic Shape mod and community-compatible forks use
-- the same manifest id. Never identify a provider by repository/folder name;
-- detect only the public modules and capabilities it actually exposes.

local function providerHandle()
  if not mod.find then return nil end
  local ok, handle = pcall(mod.find, mod, "DRAMATIC_SHAPE")
  return ok and handle or nil
end

local handle = providerHandle()
local exports = handle and handle.exports or nil
local providerVersion = exports and tostring(exports.version or "") or ""
local voxelState = dramaticModule("VoxelState")
local tileShape = dramaticModule("TileShape")
local voxel3D = dramaticModule("Voxel3D")
local spriteBillboards = dramaticModule("SpriteBillboards")
local firstPerson = dramaticModule("FirstPerson")
local freeMove = dramaticModule("FreeMove")

-- Derive camera levels from the installed provider instead of assuming the
-- current upstream 1.7 layout. The Battle-Art-compatible 1.3.1 fork stops at
-- the orbit camera rungs, while newer upstream builds add 1ST and 3RD.
if type(voxelState) == "table" then
  MAX_VOXEL_LEVEL = tonumber(voxelState.MAX_LEVEL) or MAX_VOXEL_LEVEL
  FIRST_PERSON_LEVEL = tonumber(voxelState.FP_LEVEL) or -1001
  THIRD_PERSON_LEVEL = tonumber(voxelState.TP_LEVEL) or -1002
end

-- Keep the helpers capability-driven too. This means future forks can add
-- free cameras at different rung numbers without DSR needing a repository-
-- specific branch.
isFirstPerson = function()
  if type(voxelState) == "table" and type(voxelState.isFirstPerson) == "function" then
    local ok, yes = pcall(voxelState.isFirstPerson, voxelLevel())
    if ok then return yes == true end
  end
  return FIRST_PERSON_LEVEL >= 0 and voxelLevel() == FIRST_PERSON_LEVEL
end

isThirdPerson = function()
  if type(voxelState) == "table" and type(voxelState.isThirdPerson) == "function" then
    local ok, yes = pcall(voxelState.isThirdPerson, voxelLevel())
    if ok then return yes == true end
  end
  return THIRD_PERSON_LEVEL >= 0 and voxelLevel() == THIRD_PERSON_LEVEL
end

isFreeCamera = function()
  if type(voxelState) == "table" and type(voxelState.isFreeCam) == "function" then
    local ok, yes = pcall(voxelState.isFreeCam, voxelLevel())
    if ok then return yes == true end
  end
  return isFirstPerson() or isThirdPerson()
end

isSupportedVoxelMode = function(level)
  level = tonumber(level) or voxelLevel()
  return level >= VOXEL_FULL_LEVEL and level <= (tonumber(MAX_VOXEL_LEVEL) or 0)
end

local capabilities = {
  providerVersion = providerVersion ~= "" and providerVersion or nil,
  maxVoxelLevel = tonumber(MAX_VOXEL_LEVEL),
  voxelState = type(voxelState) == "table",
  tileShape = type(tileShape) == "table" and type(tileShape.forMap) == "function",
  voxel3D = type(voxel3D) == "table"
    and type(voxel3D.newMesh) == "function"
    and type(voxel3D.pushQuad) == "function",
  spriteBillboards = type(spriteBillboards) == "table"
    and type(spriteBillboards.mesh) == "function",
  firstPerson = type(firstPerson) == "table",
  thirdPerson = type(voxelState) == "table"
    and (type(voxelState.isThirdPerson) == "function" or tonumber(voxelState.TP_LEVEL) ~= nil),
  freeMove = type(freeMove) == "table",
}

function capabilities.supportsCameraAltitude()
  return capabilities.firstPerson and type(firstPerson.update) == "function"
end

mod.exports.dramaticShapeCompatibility = capabilities

if not (capabilities.voxelState and capabilities.tileShape
        and capabilities.voxel3D and capabilities.spriteBillboards) then
  log("DRAMATIC_SHAPE provider %s is missing one or more core DSR APIs",
      providerVersion ~= "" and providerVersion or "unknown")
elseif capabilities.firstPerson and capabilities.freeMove then
  log("DRAMATIC_SHAPE %s: full DSR camera/free-move integration available",
      providerVersion ~= "" and providerVersion or "compatible provider")
else
  log("DRAMATIC_SHAPE %s: orbit-mode DSR compatibility active; 1ST/3RD hooks unavailable",
      providerVersion ~= "" and providerVersion or "compatible provider")
end
end)();
