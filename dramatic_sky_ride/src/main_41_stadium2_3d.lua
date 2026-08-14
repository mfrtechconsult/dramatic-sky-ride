(function()
-- Gen1Recomp 0.1.86+ sandbox compatibility.
--
-- Older DSR builds opened Crystal 251's private Stadium 2 DSM cache directly.
-- Cross-mod filesystem/storage access is intentionally unavailable now. Keep
-- the public native-renderer surface present, but report this optional path as
-- unavailable until Crystal 251 exposes a scoped mod.exports bridge.
local function no() return false end
local function clear() return false end
mod.exports.stadium3DNative = {
  api = 2,
  installed = no,
  supportsSpecies = no,
  hasModel = no,
  modelAvailable = no,
  active = no,
  cacheStatus = function()
    return {
      compatible = false,
      operational = false,
      reason = "sandbox_cross_mod_storage_unavailable",
      expectedFormat = "C2DSM10",
      count = 0,
      variants = 0,
    }
  end,
  modelInfo = function() return nil end,
  clearCache = clear,
}
log("Native Stadium 2 DSM renderer disabled under sandbox; waiting for a provider export bridge")
end)();
