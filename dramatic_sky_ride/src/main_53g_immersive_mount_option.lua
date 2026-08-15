;(function()
-- Register the immersive first-person/VR mount presentation before the
-- settings UX snapshots OPTION_SCHEMA. Runtime hooks live in main_64 so they
-- install after every existing camera, Stadium and Gen2 compatibility layer.
local found = false
for _, row in ipairs(OPTION_SCHEMA or {}) do
  if row.key == "immersive_mount" then found = true break end
end
if not found then
  OPTION_SCHEMA[#OPTION_SCHEMA + 1] = {
    key = "immersive_mount",
    type = "toggle",
    label = "IMMERSIVE MOUNT",
    default = true,
    help = "In 1ST and VR, show the front of the ridden Pokemon from the saddle.",
  }
end
if mod.options and mod.options.define then mod.options:define(OPTION_SCHEMA) end
end)();
