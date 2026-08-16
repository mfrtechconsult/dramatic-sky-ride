return function(game)
  local function wait(n) for _ = 1, n do coroutine.yield() end end
  local function place(x, y, facing)
    local p = game.world.player
    p.cellX, p.cellY, p.px, p.py = x, y, x * 16, y * 16
    p.targetX, p.targetY, p.moving, p.progress = nil, nil, false, 0
    p.turnTimer, p.turnArmed, p.facing = 0, false, facing
  end
  local function settle()
    for _ = 1, 180 do
      if not game.world.player.moving then return end
      coroutine.yield()
    end
    error("movement did not settle")
  end
  local function shot(name)
    local dir = os.getenv("POKEPORT_SHOT_DIR")
    if not dir then return end
    game.capturePath = dir .. "/" .. name
    for _ = 1, 180 do
      if not game.capturePath then break end
      coroutine.yield()
    end
    wait(2)
  end

  wait(75)
  local Map2 = require("src.world.gen2.Map")
  local Permissions = require("src.world.gen2.Permissions")
  local Mon = require("src.battle.gen2.Mon")
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
  local ex = assert(game.mods.exports.DRAMATIC_SKY_RIDE)

  local delta = Map2.DELTA
  local opposite = { up = "down", down = "up", left = "right", right = "left" }
  local reverse
  for mapId, def in pairs(game.world.maps) do
    if def.environment == "TOWN" or def.environment == "ROUTE" then
      local map = Map2.new(def, game.world.tilesets[def.tileset])
      for y = 1, map.heightCells - 2 do
        for x = 1, map.widthCells - 2 do
          if map:isWalkable(x, y) and not map:warpAt(x, y) then
            for dir, d in pairs(delta) do
              local fx, fy = x + d[1], y + d[2]
              local lx, ly = x + d[1] * 2, y + d[2] * 2
              local facings = Permissions.ledgeFacings(map:cellCollision(lx, ly))
              if facings and facings[opposite[dir]] and map:isWalkable(lx, ly)
                  and not map:warpAt(lx, ly) then
                reverse = { map = mapId, x = x, y = y, dir = dir,
                  lx = lx, ly = ly }
                break
              end
            end
          end
          if reverse then break end
        end
        if reverse then break end
      end
    end
    if reverse then break end
  end
  assert(reverse, "no reverse Gold ledge found")
  assert(game.world:setMap(reverse.map, reverse.x, reverse.y, reverse.dir))
  wait(30)
  place(reverse.x, reverse.y, reverse.dir)
  game:keypressed("g")
  wait(30)
  assert(ex.isGroundRiding(), "Ground Ride did not start")
  local moved = game.world:movePlayer(reverse.dir)
  assert(moved == "moved", "Ground Ride could not climb reverse ledge: " .. tostring(moved))
  assert(game.world.player.jumping == true, "reverse ledge did not use a jump")
  settle()
  assert(game.world.player.cellX == reverse.lx
      and game.world.player.cellY == reverse.ly,
    "reverse ledge landed on the wrong cell")
  shot("01-ground-after-climb.png")
  print(("[driver] Ground climbed %s (%d,%d)->(%d,%d) %s")
    :format(reverse.map, reverse.x, reverse.y, reverse.lx, reverse.ly, reverse.dir))
  game:keypressed("g")
  wait(15)

  local water
  -- Stable open-water capture point: unlike the first arbitrary table entry,
  -- this keeps Gold's third-person boom outside nearby buildings so the test
  -- actually inspects the rider/mount composition.
  local preferredDef = game.world.maps.CHERRYGROVE_CITY
  if preferredDef then
    local preferred = Map2.new(preferredDef,
      game.world.tilesets[preferredDef.tileset])
    local x, y = 34, 1
    if preferred:isWaterCell(x, y) and not preferred:warpAt(x, y) then
      for dir, d in pairs(delta) do
        local tx, ty = x + d[1], y + d[2]
        if preferred:isWaterCell(tx, ty) and not preferred:warpAt(tx, ty) then
          water = { map = "CHERRYGROVE_CITY", x = x, y = y,
            dir = dir, tx = tx, ty = ty }
          break
        end
      end
    end
  end
  if not water then
    for mapId, def in pairs(game.world.maps) do
      if def.environment == "TOWN" or def.environment == "ROUTE" then
        local map = Map2.new(def, game.world.tilesets[def.tileset])
        for y = 1, map.heightCells - 2 do
          for x = 1, map.widthCells - 2 do
            if map:isWaterCell(x, y) and not map:warpAt(x, y) then
              for dir, d in pairs(delta) do
                local tx, ty = x + d[1], y + d[2]
                if map:isWaterCell(tx, ty) and not map:warpAt(tx, ty) then
                  water = { map = mapId, x = x, y = y, dir = dir,
                    tx = tx, ty = ty }
                  break
                end
              end
            end
            if water then break end
          end
          if water then break end
        end
      end
      if water then break end
    end
  end
  assert(water, "no adjacent Gold water cells found")
  assert(game.world:setMap(water.map, water.x, water.y, water.dir))
  wait(30)
  place(water.x, water.y, water.dir)
  game:keypressed("h")
  wait(75)
  assert(ex.isFlying(), "Flight did not start for water landing")
  place(water.x, water.y, water.dir)
  game.world:interact()
  wait(90)
  assert(not ex.isFlying(), "Flight did not land on water")
  assert(ex.isWaterRiding(), "water landing did not activate Visible Surf")
  assert(game.world.playerState == "surf" or game.world.playerState == "surf_pika",
    "water landing did not arm Gold Surf state: " .. tostring(game.world.playerState))
  assert(game.world.player.surfing == true, "shared Surf marker is missing")
  local bridge = assert(ex.gen2PlayerBridge)
  local waterDiag = ex.waterRideDiagnostics()
  print(("[driver] water bridge active=%s kind=%s owns=%s sprite=%s state=%s")
    :format(tostring(bridge.active()), tostring(bridge.visualKind()),
      tostring(bridge.ownsPlayerSprite()),
      tostring(game.world.player.spriteDef and game.world.player.spriteDef.id),
      tostring(game.world.playerState)))
  print(("[driver] water active=%s species=%s source=%s rider=%s failure=%s")
    :format(tostring(waterDiag.active), tostring(waterDiag.species),
      tostring(waterDiag.source), tostring(waterDiag.rider),
      tostring(waterDiag.lastFailure)))
  local voxelDiag = ex.gen2VoxelInterop.status()
  local embeddedDiag = ex.gen2EmbeddedPokeMMOMounts
    and ex.gen2EmbeddedPokeMMOMounts.status() or {}
  print(("[driver] water sprite id=%s native=%s image=%s embedded=%s style=%s error=%s")
    :format(tostring(voxelDiag.mountSpriteId), tostring(voxelDiag.mountSpriteNative),
      tostring(voxelDiag.mountSpriteImage), tostring(embeddedDiag.active),
      tostring(embeddedDiag.style), tostring(embeddedDiag.lastError)))
  assert(bridge.visualKind() == "water", "Gold bridge did not select the water mount")
  assert(tostring(bridge.riderSpriteId() or ""):find(
      "SKY_RIDE_RIDER_MEMORY_", 1, true) == 1,
    "Visible Surf rider is not the sandbox-safe seated crop")
  shot("02-flight-landed-on-water.png")
  local presentation = assert(ex.gen2Voxel2DPresentation,
    "Gen2 2D presentation policy is missing")
  local runtimeCompat = assert(ex.gen2VoxelRuntimeCompat,
    "Gen2 voxel runtime diagnostics are missing")
  local waterScale = assert(tonumber(runtimeCompat.current2DScale()),
    "Visible Surf did not report its final 2D scale")
  assert(waterScale > 0 and waterScale <= presentation.waterMaximum + 0.0001,
    "Visible Surf card exceeds the near-camera limit: " .. tostring(waterScale))
  print(("[driver] Visible Surf final 2D scale=%.4f (max=%.4f)")
    :format(waterScale, presentation.waterMaximum))
  local nativeCorrection = ex.nativePokeMMOSizeCorrection
  local mountDef = game.world.player.spriteDef
  local crop = nativeCorrection and nativeCorrection.cropForDef
    and nativeCorrection.cropForDef(mountDef) or nil
  local providerEx = game.mods.exports.STADIUM2_OVERWORLD_MODELS
  local thirdPerson = providerEx and providerEx.lib and providerEx.lib.require
    and providerEx.lib.require("ThirdPerson") or nil
  print(("[driver] water card crop=%sx%s fit=%s third-person-len=%s")
    :format(tostring(crop and crop.width), tostring(crop and crop.height),
      tostring(crop and crop.fit), tostring(thirdPerson and thirdPerson.len)))
  place(water.x, water.y, water.dir)
  local swam = game.world:movePlayer(water.dir)
  assert(swam == "moved", "water mount cannot swim: " .. tostring(swam))
  settle()
  assert(game.world.player.cellX == water.tx and game.world.player.cellY == water.ty,
    "water mount did not reach the adjacent water cell")
  print(("[driver] Visible Surf landed and moved on %s with %s")
    :format(water.map, tostring(game.world.playerState)))

  local shore
  for mapId, def in pairs(game.world.maps) do
    if def.environment == "TOWN" or def.environment == "ROUTE" then
      local map = Map2.new(def, game.world.tilesets[def.tileset])
      for y = 1, map.heightCells - 2 do
        for x = 1, map.widthCells - 2 do
          if map:isWaterCell(x, y) then
            for dir, d in pairs(delta) do
              local tx, ty = x + d[1], y + d[2]
              if map:isWalkable(tx, ty) and not map:isWaterCell(tx, ty)
                  and not map:warpAt(tx, ty) then
                shore = { map = mapId, x = x, y = y, dir = dir,
                  tx = tx, ty = ty }
                break
              end
            end
          end
          if shore then break end
        end
        if shore then break end
      end
    end
    if shore then break end
  end
  assert(shore, "no Gold water-to-land shoreline found")
  assert(game.world:setMap(shore.map, shore.x, shore.y, shore.dir))
  game.world:applyPlayerState("surf")
  game.world.player.surfing = true
  wait(15)
  place(shore.x, shore.y, shore.dir)
  local beached = game.world:movePlayer(shore.dir)
  assert(beached == "moved", "Visible Surf could not leave water: " .. tostring(beached))
  settle()
  wait(5)
  assert(game.world.playerState == "normal", "shore exit kept Gold Surf state")
  assert(not game.world.player.surfing and not ex.isWaterRiding(),
    "shore exit kept Visible Surf active")

  -- Gold's ordinary Surf menu changes only the native playerState. The late
  -- bridge must mirror it into Visible Surf without requiring a flight first.
  assert(game.world:setMap(shore.map, shore.x, shore.y, shore.dir))
  game.world:applyPlayerState("surf")
  game.world.player.surfing = false
  wait(20)
  assert(game.world.player.surfing and ex.isWaterRiding(),
    "ordinary Gold Surf did not activate Visible Surf")
  assert(bridge.visualKind() == "water",
    "ordinary Gold Surf did not install its water mount")
  print("[driver] shoreline exit + ordinary Gold Surf sync passed")

  -- Regression: starting Flight directly from Visible Surf changes Gold's
  -- player state synchronously. The rider must be cropped from SPRITE_CHRIS,
  -- never from the obsolete native Surf sheet hidden under Gyarados.
  game:keypressed("h")
  wait(75)
  assert(ex.isFlying(), "H did not switch Visible Surf to Flight")
  assert(not ex.isWaterRiding(), "Visible Surf remained active under Flight")
  assert(game.world.playerState == "normal",
    "Surf -> Flight kept Gold's native Surf state")
  assert(game.world.player.surfing == false,
    "Surf -> Flight kept the shared Surf marker")
  assert(bridge.visualKind() == "flight",
    "Surf -> Flight did not select the flight visual")
  local riderId = tostring(bridge.riderSpriteId() or "")
  assert(not riderId:find("SPRITE_SURF", 1, true),
    "Surf mount was cropped as the flight rider: " .. riderId)
  shot("03-water-to-flight.png")
  print("[driver] Visible Surf -> Flight rider source passed: " .. riderId)
  print("[driver] PASS Gold Ground wall climb + Flight water landing")
end
