-- PunOS loadTheme helper
local f = fs.open("/os/theme.lua", "rb")
if not f then return dofile("/os/theme.lua") end
local raw = f.readAll()
f.close()
raw = raw:gsub("^\?+", "")
raw = raw:gsub("\r", "")
local fn = load(raw, "theme.lua")
if not fn then return dofile("/os/theme.lua") end
return fn()
