;(function()
-- 0.1.1 compatibility contract for the two supported voxel providers:
--   * DRAMATIC_SHAPE (upstream)
--   * BATTLE_ART_VOXEL_FORK (absol89)
--
-- Selection happens in main_01a before any DSR module resolves Dramatic Shape.
-- From here on we validate the provider by manifest version AND public
-- capabilities, so an incompatible future build fails clearly instead of
-- partially installing hooks and corrupting camera/battle state.

local state = mod.exports._dramaticProviderState or {}
if state.conflict then
  error("DRAMATIC_SKY_RIDE: enable only one voxel provider: DRAMATIC_SHAPE or BATTLE_ART_VOXEL_FORK", 0)
end

local handle = state.handle
if not handle then
  error("DRAMATIC_SKY_RIDE: requires DRAMATIC_SHAPE or BATTLE_ART_VOXEL_FORK", 0)
end

local providerId = tostring(handle.id or "")
local providerVersion = tostring(handle.version or "")
local providerRange = providerId == "BATTLE_ART_VOXEL_FORK"
  and ">=1.7.6 <2.0.0" or ">=1.7.0 <2.0.0"

local okSemver, Semver = pcall(require, "src.mods.Semver")
if okSemver and Semver and type(Semver.satisfies) == "function" then
  local okCheck, accepted = pcall(Semver.satisfies, providerVersion, providerRange)
  if not (okCheck and accepted) then
    error(("DRAMATIC_SKY_RIDE: unsupported %s %s; expected %s")
      :format(providerId, providerVersion, providerRange), 0)
  end
end

local voxelState = dramaticModule("VoxelState")
local tileShape = dramaticModule("TileShape")
local voxel3D = dramaticModule("Voxel3D")
local spriteBillboards = dramaticModule("SpriteBillboards")
local firstPerson = dramaticModule("FirstPerson")
local freeMove = dramaticModule("FreeMove")

local capabilities = {
  providerId = providerId,
  providerVersion = providerVersion,
  supportedRange = providerRange,
  voxelState = type(voxelState) == "table",
  tileShape = type(tileShape) == "table" and type(tileShape.forMap) == "function",
  voxel3D = type(voxel3D) == "table"
    and type(voxel3D.newMesh) == "function"
    and type(voxel3D.pushQuad) == "function",
  spriteBillboards = type(spriteBillboards) == "table"
    and type(spriteBillboards.mesh) == "function",
  firstPerson = type(firstPerson) == "table"
    and type(firstPerson.update) == "function"
    and type(firstPerson.frame) == "function"
    and type(firstPerson.stickY) == "function",
  freeMove = type(freeMove) == "table",
}

capabilities.thirdPerson = capabilities.voxelState
  and type(voxelState.isThirdPerson) == "function"
  and tonumber(voxelState.TP_LEVEL) ~= nil
capabilities.freeCamera = capabilities.voxelState
  and type(voxelState.isFreeCam) == "function"
capabilities.full = capabilities.voxelState and capabilities.tileShape
  and capabilities.voxel3D and capabilities.spriteBillboards
  and capabilities.firstPerson and capabilities.thirdPerson
  and capabilities.freeCamera and capabilities.freeMove

if not capabilities.full then
  local missing = {}
  for _, key in ipairs({ "voxelState", "tileShape", "voxel3D",
      "spriteBillboards", "firstPerson", "thirdPerson", "freeCamera", "freeMove" }) do
    if not capabilities[key] then missing[#missing + 1] = key end
  end
  error(("DRAMATIC_SKY_RIDE: %s %s is missing required public APIs: %s")
    :format(providerId, providerVersion, table.concat(missing, ", ")), 0)
end

-- Derive camera rungs from the selected provider. Battle Art 1.7.6 and
-- upstream 1.7+ currently expose the same 1ST/3RD contract, but DSR does not
-- hard-code those numbers anymore.
MAX_VOXEL_LEVEL = tonumber(voxelState.MAX_LEVEL) or MAX_VOXEL_LEVEL
FIRST_PERSON_LEVEL = tonumber(voxelState.FP_LEVEL) or FIRST_PERSON_LEVEL
THIRD_PERSON_LEVEL = tonumber(voxelState.TP_LEVEL) or THIRD_PERSON_LEVEL

isFirstPerson = function()
  local ok, yes = pcall(voxelState.isFirstPerson, voxelLevel())
  return ok and yes == true
end

isThirdPerson = function()
  local ok, yes = pcall(voxelState.isThirdPerson, voxelLevel())
  return ok and yes == true
end

isFreeCamera = function()
  local ok, yes = pcall(voxelState.isFreeCam, voxelLevel())
  return ok and yes == true
end

isSupportedVoxelMode = function(level)
  level = tonumber(level) or voxelLevel()
  return level >= VOXEL_FULL_LEVEL and level <= (tonumber(MAX_VOXEL_LEVEL) or 0)
end

function capabilities.supportsCameraAltitude()
  return capabilities.firstPerson and capabilities.freeCamera
end

mod.exports.dramaticShapeCompatibility = capabilities
log("voxel provider %s %s: full DSR integration enabled",
    providerId, providerVersion)
end)();
