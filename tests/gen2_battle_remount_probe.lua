return function(game)
  local function wait(n)
    for _ = 1, n do coroutine.yield() end
  end

  local function place(x, y, facing)
    local p = game.world.player
    p.cellX, p.cellY, p.px, p.py = x, y, x * 16, y * 16
    p.targetX, p.targetY, p.moving, p.progress = nil, nil, false, 0
    p.turnTimer, p.turnArmed, p.facing = 0, false, facing or "down"
  end

  local function finishTestBattle(label)
    local Runtime = require("src.mods.Runtime")
    -- Battle.new raises started while Gold is still in the overworld; ended is
    -- raised while the battle/evolution screen remains on the stack. Model
    -- exactly those ordering boundaries without depending on wipe animation
    -- timing, then expose the empty-stack free-roam frame.
    Runtime.emit("battle.started", {
      battle = { probe = label }, kind = "wild", species = "PIDGEY", level = 2,
    })
    local blocker = { update = function() end, draw = function() end }
    game.stack:push(blocker)
    Runtime.emit("battle.ended", { battle = { probe = label }, result = "win" })
    wait(10)
    assert(game.stack:top() == blocker,
      label .. " remount probe lost its battle-screen blocker")
    game.stack:pop()
    wait(45)
    assert(game.stack:top() == nil, label .. " battle did not return to Gold free roam")
  end

  wait(75)
  local Mon = require("src.battle.gen2.Mon")
  local Map2 = require("src.world.gen2.Map")
  local hooh = assert(Mon.new(game.data, "HO_OH", 50))
  local raikou = assert(Mon.new(game.data, "RAIKOU", 50))
  local gyarados = assert(Mon.new(game.data, "GYARADOS", 50))
  local function teach(mon, moveId)
    local def = game.data.moves and game.data.moves[moveId]
    mon.moves[1] = { id = moveId, pp = def and def.pp or 15,
      maxPp = def and def.pp or 15 }
  end
  teach(hooh, "FLY")
  teach(gyarados, "SURF")
  game.save.party = { hooh, raikou, gyarados }
  game.save.player = game.save.player or {}
  game.save.player.badges = game.save.player.badges or {}
  game.save.player.badges.STORM = true
  game.save.player.badges.FOG = true

  local ex = assert(game.mods.exports.DRAMATIC_SKY_RIDE)
  local bridge = assert(ex.gen2PlayerBridge)
  assert(game.world:setMap("NEW_BARK_TOWN", 10, 10, "down"))
  wait(30)
  place(10, 10, "down")

  game:keypressed("g")
  wait(30)
  assert(ex.isGroundRiding() and ex.groundMountSpecies() == "RAIKOU",
    "Raikou Ground Ride did not start")
  finishTestBattle("Ground")
  assert(ex.isGroundRiding() and ex.groundMountSpecies() == "RAIKOU",
    "Raikou was not restored after battle")
  assert(bridge.visualKind() == "ground",
    "Gold did not restore the Ground visual after battle")
  game:keypressed("g")
  wait(15)

  local water
  for mapId, def in pairs(game.world.maps) do
    if def.environment == "TOWN" or def.environment == "ROUTE" then
      local map = Map2.new(def, game.world.tilesets[def.tileset])
      for y = 1, map.heightCells - 2 do
        for x = 1, map.widthCells - 2 do
          if map:isWaterCell(x, y) and not map:warpAt(x, y) then
            water = { map = mapId, x = x, y = y }
            break
          end
        end
        if water then break end
      end
    end
    if water then break end
  end
  assert(water, "no Gold water cell found")
  assert(game.world:setMap(water.map, water.x, water.y, "down"))
  game.world:applyPlayerState("surf")
  game.world.player.surfing = true
  wait(30)
  place(water.x, water.y, "down")
  assert(ex.isWaterRiding() and ex.waterMountSpecies() == "GYARADOS",
    "custom Gyarados Visible Surf did not start")
  finishTestBattle("Visible Surf")
  assert(game.world.playerState == "surf" and game.world.player.surfing,
    "Gold Surf traversal state was not restored after battle")
  assert(ex.isWaterRiding() and ex.waterMountSpecies() == "GYARADOS",
    "custom Gyarados was not restored after battle")
  assert(bridge.visualKind() == "water",
    "Gold did not restore the custom water visual after battle")
  local waterRiderId = tostring(bridge.riderSpriteId() or "")
  assert(not waterRiderId:find("SPRITE_SURF", 1, true),
    "Gold's generic Surf sheet was cropped onto Gyarados: " .. waterRiderId)

  game.world:applyPlayerState("normal")
  game.world.player.surfing = false
  wait(15)
  assert(game.world:setMap("NEW_BARK_TOWN", 10, 10, "down"))
  place(10, 10, "down")
  game:keypressed("h")
  wait(75)
  assert(ex.isFlying() and ex.gen2VoxelInterop.mountSpecies() == "HO_OH",
    "Ho-Oh Flight did not start")
  finishTestBattle("Flight")
  assert(ex.isFlying() and ex.gen2VoxelInterop.mountSpecies() == "HO_OH",
    "Ho-Oh was not restored after battle")
  assert(bridge.visualKind() == "flight",
    "Gold did not restore the Flight visual after battle")

  print("[driver] PASS Gold Ground, Visible Surf and Flight battle remount")
end
