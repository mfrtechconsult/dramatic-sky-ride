(function()
-- -------------------------------------------------------------------------
-- Native Stadium 2 -> provider StadiumRig bridge.
--
-- main_41 deliberately began as a self-contained proof of concept. Once the
-- DSM4 path was confirmed compatible, duplicating Stadium's pose/skin engine
-- became the larger risk: the provider already owns interpolation, N64 bone
-- semantics, body anchoring, animated material streams and the exact Voxel3D
-- mesh contract. This layer keeps DSR's Crystal-251 cache reader and mount
-- placement, but delegates the per-frame skeleton work to that provider when
-- its public StadiumRig module is available.
-- -------------------------------------------------------------------------

local NONE16 = 0xFFFF
local MODEL_FPS = 30
local TRAVEL_LIMIT = 0.75
local warned = {}

local function warnOnce(key, fmt, ...)
  if warned[key] then return end
  warned[key] = true
  if mod.log and mod.log.warn then pcall(mod.log.warn, mod.log, fmt, ...) end
end

local function findUpvalue(fn, wanted)
  if type(fn) ~= "function" or not (debug and debug.getupvalue) then return nil end
  for index = 1, 96 do
    local name, value = debug.getupvalue(fn, index)
    if not name then break end
    if name == wanted then return index, value end
  end
  return nil
end

local function setUpvalue(fn, index, value)
  if not (type(fn) == "function" and index and debug and debug.setupvalue) then
    return false
  end
  return pcall(debug.setupvalue, fn, index, value)
end

local function currentEnsureRuntime()
  local _, ensure = findUpvalue(Player and Player.pose, "ensureRuntime")
  return ensure
end

-- main_42 wraps main_41's original ensureRuntime. Peel that one wrapper when
-- present so we can replace the actual create/pose seams without bypassing the
-- safety checks main_42 intentionally put around the call.
local ensureWrapper = currentEnsureRuntime()
local _, rawEnsureRuntime = findUpvalue(ensureWrapper, "rawEnsureRuntime")
if type(rawEnsureRuntime) ~= "function" then rawEnsureRuntime = ensureWrapper end

local createIndex, rawCreateRuntime = findUpvalue(rawEnsureRuntime, "createRuntime")
local ensurePoseIndex, rawPoseRuntime = findUpvalue(rawEnsureRuntime, "poseRuntime")
local updatePoseIndex = select(1, findUpvalue(
  OverworldState and OverworldState.update, "poseRuntime"))

local ownerIndex = select(1, findUpvalue(rawCreateRuntime, "ownerByMesh"))

local function ownerTable()
  if not (ownerIndex and debug and debug.getupvalue) then return nil end
  local _, value = debug.getupvalue(rawCreateRuntime, ownerIndex)
  return type(value) == "table" and value or nil
end

local function idleAnimation(model)
  local raw = model and model.ctx and model.ctx[1]
  if raw ~= nil and raw ~= NONE16 and model.anims and model.anims[raw + 1] then
    return raw + 1
  end
  return model and model.anims and model.anims[1] and 1 or nil
end

local function faceYaw(facing)
  if facing == "up" then return math.pi end
  if facing == "right" then return math.pi / 2 end
  if facing == "left" then return -math.pi / 2 end
  return 0
end

local function normaliseModelForRig(model)
  if type(model) ~= "table" then return false end
  for _, prim in ipairs(model.prims or {}) do
    if not prim.index then prim.index = prim.indices end
    if not prim.uv then
      local uv = {}
      for vertex = 1, tonumber(prim.vertCount) or 0 do
        uv[vertex * 2 - 1] = prim.u and prim.u[vertex] or 0
        uv[vertex * 2] = prim.v and prim.v[vertex] or 0
      end
      prim.uv = uv
    end
  end
  return true
end

local StadiumRig = dramaticModule and dramaticModule("StadiumRig") or nil
local providerAvailable = type(StadiumRig) == "table"
  and type(StadiumRig.new) == "function"

local function providerCreateRuntime(model, species, dex, variant, provider)
  if not providerAvailable or not normaliseModelForRig(model) then
    return type(rawCreateRuntime) == "function"
      and rawCreateRuntime(model, species, dex, variant, provider) or nil
  end
  -- StadiumMon deliberately declines models whose importer marked the idle
  -- pose corrupt. Do the same before allocating meshes for an overworld mount.
  if model.staticPose then return nil end

  local ok, rig = pcall(StadiumRig.new, model)
  if not ok or not rig or not rig.parts or not rig.parts[1]
      or not rig.parts[1].mesh then
    warnOnce("rig:" .. tostring(dex),
      "Provider StadiumRig could not build Stadium 2 model #%s: %s",
      tostring(dex), tostring(rig))
    return type(rawCreateRuntime) == "function"
      and rawCreateRuntime(model, species, dex, variant, provider) or nil
  end

  local runtime = {
    model = model,
    species = species,
    dex = dex,
    variant = variant,
    rig = rig,
    parts = rig.parts,
    -- Keep the proof-of-concept scratch arrays available as an emergency
    -- fallback if a provider-specific pose path fails for one species.
    pivot = {},
    drawM = {},
    accX = {},
    accY = {},
    accZ = {},
    time = 0,
    frame = -1,
    facing = "down",
    anim = idleAnimation(model),
    providerRig = true,
  }
  runtime.sentinel = runtime.parts[1].mesh
  local owners = ownerTable()
  if owners then owners[runtime.sentinel] = runtime end
  return runtime
end

local function providerPoseRuntime(runtime, provider)
  local rig = runtime and runtime.rig
  if not (runtime and runtime.providerRig and rig) then
    return type(rawPoseRuntime) == "function"
      and rawPoseRuntime(runtime, provider) or false
  end

  local model = runtime.model
  local anim = runtime.anim
  local record = anim and model and model.anims and model.anims[anim] or nil
  local elapsed = math.max(0, tonumber(runtime.time) or 0)
  local previous = tonumber(runtime.providerPoseTime) or elapsed
  local dt = math.max(0, elapsed - previous)
  runtime.providerPoseTime = elapsed

  local ok, err = pcall(function()
    -- StadiumRig accepts a FLOAT source frame and handles the source's loop
    -- seam/interpolation itself. This is the important fidelity gain over the
    -- original proof-of-concept's integer 30 Hz sampler.
    local frame = elapsed * MODEL_FPS
    rig:pose(anim, frame, true)
    if type(rig.anchor) == "function" then rig:anchor(TRAVEL_LIMIT, dt) end
    if type(rig.skin) == "function" then rig:skin(faceYaw(runtime.facing)) end
    if type(rig.textures) == "function" then
      rig:textures(record and record.aux or nil)
    end
  end)
  if not ok then
    warnOnce("pose:" .. tostring(runtime.dex),
      "Provider StadiumRig failed for Stadium 2 model #%s: %s; falling back to DSR skinning",
      tostring(runtime.dex), tostring(err))
    runtime.providerRig = false
    runtime.providerPoseTime = nil
    return type(rawPoseRuntime) == "function"
      and rawPoseRuntime(runtime, provider) or false
  end

  -- Preserve the diagnostic fields main_41/main_42 expose even though the
  -- provider now owns the actual pose cache.
  runtime.frame = math.floor(elapsed * MODEL_FPS)
  runtime.posedFacing = runtime.facing
  return true
end

local createPatched = false
local posePatched = false
if providerAvailable and type(rawEnsureRuntime) == "function" then
  createPatched = setUpvalue(rawEnsureRuntime, createIndex, providerCreateRuntime)
  posePatched = setUpvalue(rawEnsureRuntime, ensurePoseIndex, providerPoseRuntime)
  if updatePoseIndex then
    posePatched = setUpvalue(OverworldState.update,
      updatePoseIndex, providerPoseRuntime) and posePatched
  end
end

local hardening = mod.exports and mod.exports.stadium3DHardening or nil
if hardening then
  hardening.providerRigAvailable = providerAvailable
  hardening.providerRigCreatePatched = createPatched
  hardening.providerRigPosePatched = posePatched
end

mod.exports.stadium3DProviderRig = {
  api = 1,
  available = function() return providerAvailable end,
  active = function() return providerAvailable and createPatched and posePatched end,
  createPatched = createPatched,
  posePatched = posePatched,
  travelLimit = TRAVEL_LIMIT,
}

if providerAvailable and createPatched and posePatched then
  log("Stadium 2 provider rig bridge loaded (interpolated skeleton + anchor + animated textures)")
elseif providerAvailable then
  warnOnce("patch", "StadiumRig is available but DSR could not install the Stadium 2 provider bridge")
else
  log("Stadium 2 provider rig unavailable; hardened native fallback remains active")
end
end)();
