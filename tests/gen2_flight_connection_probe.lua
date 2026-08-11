return function(game)
  local function wait(n) for _ = 1, n do coroutine.yield() end end
  local function place(x, y, facing)
    local p = game.world.player
    p.cellX, p.cellY, p.px, p.py = x, y, x * 16, y * 16
    p.targetX, p.targetY, p.moving, p.progress = nil, nil, false, 0
    p.turnTimer, p.turnArmed, p.facing = 0, false, facing
  end

  wait(75)
  game.world:setMap("NEW_BARK_TOWN", 10, 9, "left")
  wait(30)
  local Mon = require("src.battle.gen2.Mon")
  local hooh = assert(Mon.new(game.data, "HO_OH", 50))
  local fly = game.data.moves and game.data.moves.FLY
  hooh.moves[1] = { id = "FLY", pp = fly and fly.pp or 15,
                    maxPp = fly and fly.pp or 15 }
  game.save.party = { hooh }
  local ex = assert(game.mods.exports.DRAMATIC_SKY_RIDE)
  game:keypressed("h")
  wait(60)
  assert(ex.isFlying(), "Flight did not start")

  place(0, 9, "left")
  local conn = game.world.map:connection("west")
  if conn then
    print("[driver] west conn mapId=" .. tostring(conn.mapId)
      .. " map=" .. tostring(conn.map))
  end
  game.input.state.left = true
  wait(3)
  game.input.state.left = false
  wait(30)
  print("[driver] input crossing map="
    .. tostring(game.world.map and game.world.map.id))
  assert(game.world.map.id == "ROUTE_29",
    "Flight could not cross New Bark -> Route 29")

  -- Find a real Gold connection whose destination edge is not walkable on
  -- foot. Native tryConnection rejects it; airborne traversal must keep the
  -- authored seam but ignore that ground-only landing test.
  local Map2 = require("src.world.gen2.Map")
  local dirs = {
    north = { move = "up", source = function(map) return 0, 0 end },
    south = { move = "down", source = function(map) return 0, map.heightCells - 1 end },
    west = { move = "left", source = function(map) return 0, 0 end },
    east = { move = "right", source = function(map) return map.widthCells - 1, 0 end },
  }
  local candidate
  for sourceId, sourceDef in pairs(game.world.maps) do
    local sourceMap = Map2.new(sourceDef, game.world.tilesets[sourceDef.tileset])
    for compass, cfg in pairs(dirs) do
      local conn = sourceMap:connection(compass)
      local target = conn and (conn.mapId
        or (type(conn.map) == "string" and conn.map))
      local destDef = target and game.world.maps[target]
      if destDef then
        local destMap = Map2.new(destDef, game.world.tilesets[destDef.tileset])
        local sx, sy = cfg.source(sourceMap)
        -- Search the whole source edge: connectionLanding owns the exact
        -- offset/clamp math and tells us whether native ground entry refuses.
        local limit = (cfg.move == "up" or cfg.move == "down")
          and sourceMap.widthCells - 1 or sourceMap.heightCells - 1
        for axis = 0, limit do
          if cfg.move == "up" or cfg.move == "down" then sx = axis else sy = axis end
          local lx, ly = Map2.connectionLanding(destDef, conn, cfg.move, sx, sy)
          if lx and not destMap:isWalkable(lx, ly) then
            candidate = {
              source = sourceId, target = target, x = sx, y = sy,
              dir = cfg.move, landingX = lx, landingY = ly,
            }
            break
          end
        end
      end
      if candidate then break end
    end
    if candidate then break end
  end
  assert(candidate, "Gold data has no blocked connection landing to test")
  assert(game.world:setMap(candidate.source, candidate.x, candidate.y,
    candidate.dir), "could not load blocked-seam source")
  wait(15)
  place(candidate.x, candidate.y, candidate.dir)
  local crossed = game.world:tryConnection(candidate.dir)
  assert(crossed == true, "flight did not open a blocked authored seam")
  assert(game.world.map.id == candidate.target,
    "blocked authored seam loaded the wrong destination")
  print(("[driver] airborne seam %s -> %s at (%d,%d)")
    :format(candidate.source, candidate.target,
      candidate.landingX, candidate.landingY))

  -- Flight does not invent topology: an edge with no authored connection is
  -- still a hard boundary.
  local missing
  for sourceId, sourceDef in pairs(game.world.maps) do
    local sourceMap = Map2.new(sourceDef, game.world.tilesets[sourceDef.tileset])
    for compass, cfg in pairs(dirs) do
      if not sourceMap:connection(compass) then
        local sx, sy = cfg.source(sourceMap)
        missing = { source = sourceId, x = sx, y = sy, dir = cfg.move }
        break
      end
    end
    if missing then break end
  end
  assert(missing and game.world:setMap(missing.source, missing.x, missing.y,
    missing.dir), "could not load a no-connection edge")
  wait(15)
  place(missing.x, missing.y, missing.dir)
  assert(game.world:tryConnection(missing.dir) == false,
    "flight invented a connection at an authored map boundary")

  wait(30)
  print("[driver] PASS Gold native + blocked flight connections")
end
