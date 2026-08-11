return function(game)
  local function wait(frames)
    for _ = 1, frames do coroutine.yield() end
  end

  local function shot(path)
    game.capturePath = path
    for _ = 1, 180 do
      if not game.capturePath then break end
      coroutine.yield()
    end
    wait(2)
    local file = assert(io.open(path, "rb"), "missing screenshot " .. path)
    file:close()
  end

  local function settle()
    for _ = 1, 180 do
      if game.world and game.world.player and not game.world.player.moving then
        return
      end
      coroutine.yield()
    end
    error("player movement did not settle")
  end

  local function place(x, y, facing)
    local player = game.world.player
    player.cellX, player.cellY = x, y
    player.px, player.py = x * 16, y * 16
    player.targetX, player.targetY = nil, nil
    player.moving, player.progress = false, 0
    player.turnTimer, player.turnArmed = 0, false
    player.facing = facing or "down"
  end

  local function blockedPair(map)
    local dirs = {
      { name = "up", dx = 0, dy = -1 },
      { name = "down", dx = 0, dy = 1 },
      { name = "left", dx = -1, dy = 0 },
      { name = "right", dx = 1, dy = 0 },
    }
    for y = 1, map.heightCells - 2 do
      for x = 1, map.widthCells - 2 do
        if map:isWalkable(x, y) and not map:warpAt(x, y) then
          for _, dir in ipairs(dirs) do
            local tx, ty = x + dir.dx, y + dir.dy
            if map:inBounds(tx, ty) and not map:isWalkable(tx, ty)
                and not map:warpAt(tx, ty) then
              return x, y, tx, ty, dir.name
            end
          end
        end
      end
    end
  end

  wait(90)
  assert(game.world and game.world.map, "Gold world did not boot")
  game.world:setMap("NEW_BARK_TOWN", 10, 10, "down")
  wait(45)

  local exports = assert(game.mods and game.mods.exports
    and game.mods.exports.DRAMATIC_SKY_RIDE, "DSR did not load on Gold")
  local bridge = assert(exports.gen2PlayerBridge, "Gold player bridge missing")
  local hoohScale = assert(exports.mountVisualScale("HO_OH"))
  local raikouScale = assert(exports.mountVisualScale("RAIKOU"))
  assert(hoohScale > 2 and raikouScale > 1,
    "Gen2 Pokedex sizes did not reach the live renderer")
  print(("[driver] scales HO_OH=%.4f RAIKOU=%.4f")
    :format(hoohScale, raikouScale))
  local Mon = require("src.battle.gen2.Mon")
  local hooh = assert(Mon.new(game.data, "HO_OH", 50))
  local raikou = assert(Mon.new(game.data, "RAIKOU", 50))
  local fly = game.data.moves and game.data.moves.FLY
  hooh.moves[1] = { id = "FLY", pp = (fly and fly.pp) or 15,
                    maxPp = (fly and fly.pp) or 15 }
  game.save.party = { hooh, raikou }

  local out = os.getenv("POKEPORT_SHOT_DIR") or "."
  shot(out .. "/01-unmounted.png")

  game:keypressed("h")
  wait(75)
  assert(exports.isFlying(), "H did not start Flight")
  assert(bridge.active() and bridge.visualKind() == "flight",
    "Gold bridge did not select the flight visual")
  assert(bridge.ownsPlayerSprite(), "Gold player does not own the flight sprite")
  assert(game.world.player.spriteDef
      and tostring(game.world.player.spriteDef.id):find("HO_OH", 1, true),
    "Gold player sprite is not Ho-Oh")
  assert((game.world.player.spriteYOffset or 0) < 0,
    "Gold flight sprite never rose above the ground")
  shot(out .. "/02-flight-ho-oh.png")

  local x, y, tx, ty, dir = assert(blockedPair(game.world.map))
  place(x, y, dir)
  local moved = game.world:movePlayer(dir)
  assert(moved == "moved",
    "flight did not open blocked scenery (got " .. tostring(moved) .. ")")
  settle()
  assert(game.world.player.cellX == tx and game.world.player.cellY == ty,
    "flight movement did not reach the blocked target cell")

  -- The hook must not turn an off-map verdict into a legal step: World owns
  -- route connections after Player returns "edge".
  place(0, 0, "left")
  local edge = game.world.player:tryMove("left", game.world.map,
    game.world.entities)
  assert(edge == "edge", "flight bypassed a map bound: " .. tostring(edge))

  -- The collision target is intentionally scenery and therefore cannot be a
  -- legal touchdown. Return to its known-walkable source before pressing A.
  place(x, y, "down")
  game.world:interact()
  wait(90)
  print("[driver] landing wait complete")
  assert(not exports.isFlying(), "Gold A-button landing did not finish")
  assert(not bridge.active(), "Gold bridge kept the flight sprite after landing")

  -- Return to a normal outdoor cell for Ground Ride.
  place(x, y, "down")
  print("[driver] starting Ground Ride")
  game:keypressed("g")
  print("[driver] Ground Ride key dispatched")
  wait(30)
  print("[driver] Ground Ride wait complete")
  assert(exports.isGroundRiding(), "G did not start Ground Ride")
  assert(bridge.active() and bridge.visualKind() == "ground",
    "Gold bridge did not select the ground visual")
  assert(bridge.ownsPlayerSprite(), "Gold player does not own the ground sprite")
  assert(game.world.player.spriteDef
      and tostring(game.world.player.spriteDef.id):find("RAIKOU", 1, true),
    "Gold player sprite is not Raikou")
  shot(out .. "/03-ground-raikou.png")

  place(x, y, dir)
  local blocked = game.world:movePlayer(dir)
  assert(blocked == "blocked",
    "Ground Ride incorrectly bypassed scenery (got " .. tostring(blocked) .. ")")

  -- Regression: the H wrapper ends Ground and starts Flight in the same key
  -- event. The native rider source must not be the still-installed Raikou.
  place(x, y, "down")
  game:keypressed("h")
  wait(75)
  assert(not exports.isGroundRiding(), "H kept Ground Ride active")
  assert(exports.isFlying(), "H did not switch Ground Ride to Flight")
  assert(bridge.visualKind() == "flight", "bridge kept the Ground visual")
  assert(game.world.player.spriteDef
      and tostring(game.world.player.spriteDef.id):find("HO_OH", 1, true),
    "Ground -> Flight did not install Ho-Oh")
  local riderId = tostring(bridge.riderSpriteId() or "")
  assert(not riderId:find("RAIKOU", 1, true),
    "Ground mount was cropped as the flight rider: " .. riderId)
  local native = bridge.nativePlayerSprite(game.world.player)
  assert(native and native.def
      and not tostring(native.def.id):find("RAIKOU", 1, true),
    "bridge lost Gold's native player renderer under Ground Ride")
  shot(out .. "/04-ground-to-flight.png")

  game.world:interact()
  wait(90)
  assert(not exports.isFlying(), "A did not land after Ground -> Flight")
  assert(not bridge.active(), "Gold bridge kept the flight sprite after landing")
  assert(not bridge.flightGuardsActive(), "flight guards leaked after landing")
  shot(out .. "/05-restored.png")

  print(("[driver] PASS DSR Gold visuals + movement (%d,%d -> %d,%d %s)")
    :format(x, y, tx, ty, dir))
end
