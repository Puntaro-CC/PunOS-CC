-- PunOS loadTheme helper
-- Reads theme.lua safely, stripping any UTF-8 BOM that text editors may add.
-- Usage: local UI = dofile("/os/loadTheme.lua")

local path = "/os/theme.lua"

local fallback = {
    themeName  = "Classic",
    primary    = colors.orange,
    secondary  = colors.yellow,
    background = colors.black,
    text       = colors.white,
    subtext    = colors.lightGray,
    border     = colors.gray,
    success    = colors.lime,
    error      = colors.red,
    fgDark     = colors.black,
    btnNum     = colors.gray,
    btnOp      = colors.orange,
    btnFn      = colors.blue,
    btnSpec    = colors.cyan,
    btnClear   = colors.red,
    btnEqual   = colors.lime,
    selected   = colors.white,
}

if not fs.exists(path) then
    return fallback
end

local f = fs.open(path, "rb")
if not f then return fallback end
local raw = f.readAll()
f.close()

-- Strip UTF-8 BOM (EF BB BF) if present
if raw:byte(1) == 0xEF and raw:byte(2) == 0xBB and raw:byte(3) == 0xBF then
    raw = raw:sub(4)
end

-- Strip Windows carriage returns
raw = raw:gsub("\r", "")

local fn, err = load(raw, "theme.lua")
if not fn then
    return fallback
end

local ok, result = pcall(fn)
if not ok or type(result) ~= "table" then
    return fallback
end

return result