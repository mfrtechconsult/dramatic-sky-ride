;(function()
-- Battle-scene compatibility ordering.
-- Battle Art Voxel Fork (and upstream staged battles) temporarily replace the
-- overworld cast when battle.started fires, then restore it on battle.ended.
-- DSR must remove a Ground Ride rider BEFORE that cast is captured, otherwise
-- the restored cast can resurrect a stale pre-battle rider entity. Event
-- priorities make the lifecycle deterministic instead of relying on equal-
-- priority listener insertion order.

mod.events:on("battle.started", function()
  if ground.active then
    ground.resumeAfterBattle = ground.mon
    stopGroundRide(Game, "battle", true)
  end
end, 100)

-- Run after normal battle-ending listeners (Battle Art uses priority 0). This
-- is intentionally idempotent: it only reconciles DSR's own visual entities
-- after the voxel provider has restored its cast and released its battle camera.
mod.events:on("battle.ended", function()
  local ow = Game.overworld
  if not ow then return end
  if flight.active then
    purgeFollowersDuringFlight(ow)
    if showRiderEnabled() then ensureRiderEntity(ow) else removeRiderEntity(ow) end
    ensureGroundFxEntity(ow)
  end
end, -100)
end)();
