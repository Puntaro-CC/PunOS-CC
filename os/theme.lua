-- PunOS Theme Module
-- Returns the active UI color table based on /.theme

local THEME_FILE = "/.theme"

local themes = {

    -- ---- PunOS Classic ------------------------------------------------------
    -- Black, gray and gold. The default PunOS experience.

    classic = {
        themeName  = "PunOS Classic",
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
    },

    -- ---- Factory ------------------------------------------------------------
    -- Light mode. Crisp white and cyan, evoking the 1st Doctor's clinical,
    -- hexagonal console room.

    factory = {
        themeName  = "Factory",
        primary    = colors.cyan,
        secondary  = colors.lightBlue,
        background = colors.white,
        text       = colors.black,
        subtext    = colors.gray,
        border     = colors.lightGray,
        success    = colors.green,
        error      = colors.red,
        fgDark     = colors.white,
        btnNum     = colors.lightGray,
        btnOp      = colors.cyan,
        btnFn      = colors.lightBlue,
        btnSpec    = colors.gray,
        btnClear   = colors.red,
        btnEqual   = colors.cyan,
        selected   = colors.cyan,
    },

    -- ---- Coral --------------------------------------------------------------
    -- Warm organic tones from the 9th and 10th Doctor's coral console room.
    -- Orange primary, magenta accents, dark background.

    coral = {
        themeName  = "Coral",
        primary    = colors.orange,
        secondary  = colors.magenta,
        background = colors.black,
        text       = colors.white,
        subtext    = colors.lightGray,
        border     = colors.brown,
        success    = colors.lime,
        error      = colors.red,
        fgDark     = colors.black,
        btnNum     = colors.brown,
        btnOp      = colors.orange,
        btnFn      = colors.magenta,
        btnSpec    = colors.pink,
        btnClear   = colors.red,
        btnEqual   = colors.orange,
        selected   = colors.orange,
    },

    -- ---- Copper -------------------------------------------------------------
    -- Orange, gold and green. Warm industrial palette.

    copper = {
        themeName  = "Copper",
        primary    = colors.orange,
        secondary  = colors.yellow,
        background = colors.black,
        text       = colors.yellow,
        subtext    = colors.lime,
        border     = colors.green,
        success    = colors.lime,
        error      = colors.red,
        fgDark     = colors.black,
        btnNum     = colors.green,
        btnOp      = colors.orange,
        btnFn      = colors.yellow,
        btnSpec    = colors.lime,
        btnClear   = colors.red,
        btnEqual   = colors.lime,
        selected   = colors.yellow,
    },

    -- ---- Toyota -------------------------------------------------------------
    -- Gray, orange and blue. Clean and modern.

    toyota = {
        themeName  = "Toyota",
        primary    = colors.orange,
        secondary  = colors.lightBlue,
        background = colors.black,
        text       = colors.white,
        subtext    = colors.lightGray,
        border     = colors.gray,
        success    = colors.lime,
        error      = colors.red,
        fgDark     = colors.black,
        btnNum     = colors.gray,
        btnOp      = colors.orange,
        btnFn      = colors.lightBlue,
        btnSpec    = colors.cyan,
        btnClear   = colors.red,
        btnEqual   = colors.lightBlue,
        selected   = colors.lightBlue,
    },

    -- ---- TARDIS -------------------------------------------------------------
    -- Deep blue and cyan. Designed for the TARDIS kernel console.

    tardis = {
        themeName  = "TARDIS",
        primary    = colors.cyan,
        secondary  = colors.lightBlue,
        background = colors.black,
        text       = colors.lightBlue,
        subtext    = colors.blue,
        border     = colors.blue,
        success    = colors.lime,
        error      = colors.red,
        fgDark     = colors.black,
        btnNum     = colors.blue,
        btnOp      = colors.cyan,
        btnFn      = colors.lightBlue,
        btnSpec    = colors.cyan,
        btnClear   = colors.red,
        btnEqual   = colors.cyan,
        selected   = colors.cyan,
    },

}

local name = "classic"
if fs.exists(THEME_FILE) then
    local f = fs.open(THEME_FILE, "r")
    name = f.readAll():gsub("[%s%z]", "")
    f.close()
end

return themes[name] or themes.classic
