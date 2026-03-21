-- PunOS loadTheme helper
-- Reads theme.lua, strips BOM if present, executes it, applies palette.
-- Usage: local UI = dofile("/os/loadTheme.lua")

-- ---- Default CC palette (used to reset before applying theme palette) -------

local DEFAULTS = {
    [colors.white]     = 0xF0F0F0,
    [colors.orange]    = 0xF2B233,
    [colors.magenta]   = 0xE57FD8,
    [colors.lightBlue] = 0x99B2F2,
    [colors.yellow]    = 0xDEDE6C,
    [colors.lime]      = 0x7FCC19,
    [colors.pink]      = 0xF2B2CC,
    [colors.gray]      = 0x4C4C4C,
    [colors.lightGray] = 0x999999,
    [colors.cyan]      = 0x4C99B2,
    [colors.purple]    = 0xB266E5,
    [colors.blue]      = 0x3366CC,
    [colors.brown]     = 0x7F664C,
    [colors.green]     = 0x57A64E,
    [colors.red]       = 0xCC4C4C,
    [colors.black]     = 0x111111,
}

local function applyPalette(theme)
    -- Always reset all 16 slots to CC defaults first
    for slot, hex in pairs(DEFAULTS) do
        term.setPaletteColor(slot, hex)
    end
    -- Then apply theme overrides on top
    if theme.palette then
        for slot, hex in pairs(theme.palette) do
            term.setPaletteColor(slot, hex)
        end
    end
end

-- ---- Load theme.lua ---------------------------------------------------------

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
    btnFn      = colors.yellow,
    btnSpec    = colors.lightGray,
    btnClear   = colors.red,
    btnEqual   = colors.orange,
    selected   = colors.orange,
}

if not fs.exists(path) then
    applyPalette(fallback)
    return fallback
end

local f = fs.open(path, "rb")
if not f then
    applyPalette(fallback)
    return fallback
end

local raw = f.readAll()
f.close()

-- Strip stray leading ? or UTF-8 BOM
raw = raw:gsub("^\?+", "")
raw = raw:gsub("^\xEF\xBB\xBF", "")
raw = raw:gsub("\r", "")

local fn, err = load(raw, "theme.lua")
if not fn then
    applyPalette(fallback)
    return fallback
end

local ok, result = pcall(fn)
if not ok or type(result) ~= "table" then
    applyPalette(fallback)
    return fallback
end

applyPalette(result)
return result
