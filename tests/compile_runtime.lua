local root = "dramatic_sky_ride"

local function read(path)
  local file = assert(io.open(path, "rb"), "cannot open " .. path)
  local value = file:read("*a")
  file:close()
  return value
end

local parts = read(root .. "/src/parts.txt")
local chunks = {}
local previousEndsWithSemicolon = false
for filename in parts:gmatch("[^\r\n]+") do
  local text = read(root .. "/src/" .. filename)
  if previousEndsWithSemicolon then
    local first = text:find("%S")
    if first and text:sub(first, first) == ";" then
      text = text:sub(1, first - 1) .. text:sub(first + 1)
    end
  end
  chunks[#chunks + 1] = text
  previousEndsWithSemicolon = text:match(";%s*$") ~= nil
end

local source = table.concat(chunks)
assert(loadstring(source, "@dramatic_sky_ride/runtime_concat.lua"))
print("Dramatic Sky Ride runtime syntax: PASS")
