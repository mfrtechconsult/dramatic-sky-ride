;(function()
-- Staged-battle compatibility ordering.
-- Battle Art Voxel Fork (and upstream staged battles) snapshots/restores the
-- overworld entity lists around a fight. DSR must dismount Ground Ride before
-- that snapshot or the restored list can resurrect the old rider entity.

local function prepareGroundRideForBattle()
  if not ground.active then return end
  ground.resumeAfterBattle = ground.mon
  stopGroundRide(Game, "battle", true)
end

-- Normal overworld wild/trainer fights enter through pushBattle. Battle Art
-- wraps this at provider priority 100 and calls OverworldBattle.begin BEFORE
-- the engine pushes the battle transition, so its cast snapshot happens before
-- battle.started. DSR loads later (priority 900), making this wrapper outermost:
-- remove our Ground Ride entity first, then let the provider snapshot the clean
-- cast. This does not alter the battle object or any battle mechanics.
if not OverworldState.dramaticSkyRideBattleProviderCompat then
  local providerPushBattle = OverworldState.pushBattle
  if type(providerPushBattle) == "function" then
    function OverworldState:pushBattle(battle, ...)
      if Game.overworld == self then prepareGroundRideForBattle() end
      return providerPushBattle(self, battle, ...)
    end
  end
  OverworldState.dramaticSkyRideBattleProviderCompat = true
end

-- Direct/script/link battle paths can bypass OverworldState:pushBattle. The
-- provider catches those on battle.started, so use a higher event priority to
-- make the same Ground Ride cleanup deterministic before its priority-0 handler.
mod.events:on("battle.started", function()
  prepareGroundRideForBattle()
end, 100)

-- Run after normal battle-ending listeners (Battle Art uses priority 0). This
-- is intentionally idempotent: it only reconciles DSR's own airborne visual
-- entities after the provider has restored its cast and released battle camera.
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
