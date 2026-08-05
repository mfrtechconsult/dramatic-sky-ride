-- Dramatic Sky Ride entry point.
--
-- The implementation is split into line-preserving source parts so the public
-- repository remains easy to review and update. The parts are concatenated
-- before compilation, preserving the exact alpha.12 Lua program.

local mod = ...

local parts = {
  "src/main_01.lua",
  "src/main_02.lua",
  "src/main_03.lua",
  "src/main_04.lua",
  "src/main_05.lua",
  "src/main_06.lua",
  "src/main_07.lua",
  "src/main_08.lua",
  "src/main_09.lua",
  "src/main_10.lua",
  "src/main_11.lua",
  "src/main_12a.lua",
  "src/main_12b.lua",
  "src/main_13a.lua",
  "src/main_13b.lua",
  "src/main_14.lua",
}

local source = {}
for _, relative in ipairs(parts) do
  local text = mod:read(relative)
  if not text then
    error(("DRAMATIC_SKY_RIDE: missing %s — reinstall the mod"):format(relative), 0)
  end
  source[#source + 1] = text
end

local chunk, err = load(table.concat(source, ""),
                        "@" .. mod.path .. "/src/sky_ride.lua")
if not chunk then
  error("DRAMATIC_SKY_RIDE: source did not compile: " .. tostring(err), 0)
end

return chunk(mod)
