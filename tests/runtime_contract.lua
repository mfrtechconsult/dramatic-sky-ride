local hooks = {}
local opts = { story_safe = true, flight_speed = 125, ground_speed = 130, auto_visible_surf = true }
local mod = {
  hooks = { wrap = function(_, name, fn) hooks[name] = fn end },
  options = {
    define = function() end,
    get = function(_, key) return opts[key] end,
  },
  events = { on = function() end },
  log = { info = function() end },
}

local chunk = assert(loadfile(arg[1]))
local Runtime = assert(chunk(mod))

local player = { sprite = "native_walk" }
local game = { player = player }
local surfing = false
local party = {}
local Compat = {
  player = function() return player end,
  party = function() return party end,
  healthy = function(mon) return mon and (mon.hp or 1) > 0 end,
  freeRoam = function() return true end,
  isSurfing = function() return surfing end,
  say = function() end,
  closeMenus = function() end,
}
local catalog = {
  flight = { CHARIZARD = { species="CHARIZARD", dex=6, speed=1 } },
  ground = { ARCANINE = { species="ARCANINE", dex=59, speed=1.15 } },
  surf = { LAPRAS = { species="LAPRAS", dex=131, speed=1 } },
}
function catalog.match(kind, _, mon)
  return catalog[kind] and catalog[kind][mon.species] or nil
end
local serial = 0
local Sprites = {
  build = function(_, species, _, kind)
    serial = serial + 1
    return "mount:" .. kind .. ":" .. species .. ":" .. serial,
      { providerId = "test" }
  end,
}
Runtime.install({ catalog=catalog, compat=Compat, sprites=Sprites })

local function eq(a,b,msg)
  if a ~= b then error((msg or "mismatch") .. ": " .. tostring(a) .. " ~= " .. tostring(b)) end
end
local function yes(v,msg) if not v then error(msg or "expected true") end end
local function no(v,msg) if v then error(msg or "expected false") end end

local arcanine = { species="ARCANINE", hp=10 }
yes(Runtime.public.start(game,"ground",arcanine), "ground start")
local groundMount = player.sprite
eq(Runtime.public.state().mode,"ground","ground mode")
no(groundMount == "native_walk", "ground visual changed")
yes(Runtime.public.stop("test"), "ground stop")
eq(player.sprite,"native_walk","ground restore")

local charizard = { species="CHARIZARD", hp=10 }
yes(Runtime.public.start(game,"flight",charizard), "flight start")
local collision = assert(hooks["movement.collision"])
local function downstream(allowed) return allowed end
yes(collision(downstream,false,{reason="tile"}) == true, "flight crosses terrain")
yes(collision(downstream,false,{reason="bounds"}) == false, "flight keeps bounds")
yes(collision(downstream,false,{reason="entity"}) == false, "story safe entity")
local speed = assert(hooks["movement.speed"])(function(v) return v end,16,{})
eq(speed,13,"flight speed")

local flightMount = player.sprite
player.sprite = "skin_refresh"
assert(hooks["core.update"])(function() end, game, 1/60)
eq(player.sprite,flightMount,"flight re-applied")
Runtime.public.stop("test")
eq(player.sprite,"skin_refresh","latest native visual restored")

surfing = true
player.sprite = "native_surf"
local lapras = { species="LAPRAS", hp=10 }
yes(Runtime.public.start(game,"surf",lapras,{auto=true}), "surf start")
local surfMount = player.sprite
no(surfMount == "native_surf", "surf visual changed")
surfing = false
player.sprite = "native_walk_after_surf"
assert(hooks["core.update"])(function() end, game, 1/60)
eq(Runtime.public.state().mode,nil,"surf stopped")
eq(player.sprite,"native_walk_after_surf","native dismount visual preserved")

print("runtime-contract-ok")
