;(function()
-- DSR accepts either the upstream Dramatic Shape provider or the community
-- Battle Art Voxel Fork. The engine manifest format has no "dependency A OR
-- dependency B" expression, so both providers are optional ordering edges and
-- this small compatibility layer aliases the selected provider only inside DSR.
-- No other mod sees this alias and neither provider is modified.

if type(mod.find) ~= "function" then return end

local nativeFind = mod.find
local function rawFind(id)
  local ok, handle = pcall(nativeFind, mod, id)
  return ok and handle or nil
end

local upstream = rawFind("DRAMATIC_SHAPE")
local battleArt = rawFind("BATTLE_ART_VOXEL_FORK")
local state = {
  upstream = upstream,
  battleArt = battleArt,
  conflict = upstream ~= nil and battleArt ~= nil,
  handle = upstream or battleArt,
}
state.id = state.handle and state.handle.id or nil
state.version = state.handle and state.handle.version or nil
mod.exports._dramaticProviderState = state

-- Existing DSR code deliberately talks to the long-standing DRAMATIC_SHAPE
-- public seam. When only Battle Art is installed, make that lookup resolve to
-- its equivalent public handle. All other mod.find calls are passed through.
mod.find = function(first, second)
  local requested = second == nil and first or second
  if requested == "DRAMATIC_SHAPE" and upstream == nil and battleArt ~= nil then
    return battleArt
  end
  return nativeFind(first, second)
end
end)();
