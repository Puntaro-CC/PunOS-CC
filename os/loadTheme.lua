-- PunOS loadTheme helper
local f = fs.open("/os/theme.lua", "rb")
if not f then return dofile("/os/theme.lua") end
local raw = f.readAll()
f.close()
-- Strip UTF-8 BOM (0xEF 0xBB 0xBF) if present
if raw:byte(1) == 239 and raw:byte(2) == 187 and raw:byte(3) == 191 then
    raw = raw:sub(4)
end
-- Strip stray leading ? characters
raw = raw:gsub("^[?]+", "")
raw = raw:gsub("\r", "")
local fn = load(raw, "theme.lua")
if not fn then return dofile("/os/theme.lua") end
return fn()
