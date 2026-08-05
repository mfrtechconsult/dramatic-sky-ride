-- Dramatic Sky Ride entry point.
-- Source chunks are line-preserving and concatenated before compilation.

local mod = ...
local index = mod:read("src/parts.txt")
if not index then
  error("DRAMATIC_SKY_RIDE: missing src/parts.txt — reinstall the mod", 0)
end

local source = {}
for filename in index:gmatch("[^\r\n]+") do
  local relative = "src/" .. filename
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
