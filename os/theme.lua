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
    -- Magenta primary, pink secondary, orange border for warmth.
    -- Distinct from Classic by avoiding orange as the primary entirely.

    coral = {
        themeName  = "Coral",
        primary    = colors.magenta,
        secondary  = colors.pink,
        background = colors.black,
        text       = colors.white,
        subtext    = colors.pink,
        border     = colors.orange,
        success    = colors.lime,
        error      = colors.red,
        fgDark     = colors.black,
        btnNum     = colors.orange,
        btnOp      = colors.magenta,
        btnFn      = colors.pink,
        btnSpec    = colors.lightGray,
        btnClear   = colors.red,
        btnEqual   = colors.magenta,
        selected   = colors.magenta,
        palette    = {
            -- Dirty warm brown-green-yellow palette
            [colors.magenta]   = 0xC4782A,  -- primary: warm coral-brown
            [colors.pink]      = 0xD4A44C,  -- secondary/subtext: dirty yellow-gold
            [colors.orange]    = 0x8B6914,  -- border: deep earthy brown
            [colors.lightGray] = 0xB8A878,  -- text: warm off-white
            [colors.lime]      = 0x7A9B4A,  -- success: muted olive green
        },
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
        palette    = {
            [colors.orange]    = 0xC87533,  -- primary: proper copper
            [colors.yellow]    = 0xDAA520,  -- text/secondary: goldenrod
            [colors.green]     = 0x4A7C59,  -- border: verdigris green
            [colors.lime]      = 0x7CB98A,  -- subtext/success: light verdigris
        },
    },

    -- ---- Star ---------------------------------------------------------------
    -- Sleek purple and violet. Modern, almost neon.
    -- Purple primary, magenta accents, deep black background.

    star = {
        themeName  = "Star",
        primary    = colors.purple,
        secondary  = colors.magenta,
        background = colors.black,
        text       = colors.white,
        subtext    = colors.lightGray,
        border     = colors.gray,
        success    = colors.lime,
        error      = colors.red,
        fgDark     = colors.black,
        btnNum     = colors.gray,
        btnOp      = colors.purple,
        btnFn      = colors.magenta,
        btnSpec    = colors.lightBlue,
        btnClear   = colors.red,
        btnEqual   = colors.purple,
        selected   = colors.purple,
        palette    = {
            [colors.purple]    = 0x9B30FF,  -- primary: vivid neon purple
            [colors.magenta]   = 0xCC44CC,  -- secondary: bright violet-pink
            [colors.gray]      = 0x3A2A5A,  -- border: deep purple-gray
            [colors.lightGray] = 0xC4B8E0,  -- text: lavender-white
            [colors.lightBlue] = 0x8866DD,  -- spec: mid purple
        },
    },

    -- ---- Library ------------------------------------------------------------
    -- Warm mahogany, red and amber. Rich wooden tones.
    -- A nod to the Library — a planet-sized repository of knowledge.

    library = {
        themeName  = "Library",
        primary    = colors.red,
        secondary  = colors.orange,
        background = colors.black,
        text       = colors.white,
        subtext    = colors.orange,
        border     = colors.brown,
        success    = colors.lime,
        error      = colors.pink,
        fgDark     = colors.black,
        btnNum     = colors.brown,
        btnOp      = colors.red,
        btnFn      = colors.orange,
        btnSpec    = colors.yellow,
        btnClear   = colors.pink,
        btnEqual   = colors.red,
        selected   = colors.red,
        palette    = {
            [colors.black]     = 0x0F0A08,  -- background: near-black with warm tint
            [colors.red]       = 0xA0281C,  -- primary: deep mahogany red
            [colors.orange]    = 0xC8782A,  -- subtext/secondary: warm amber
            [colors.brown]     = 0x6B3A28,  -- border: rich dark wood
            [colors.yellow]    = 0xD4A84B,  -- spec: golden amber
            [colors.white]     = 0xF5E6D0,  -- text: warm parchment white
            [colors.pink]      = 0xCC5544,  -- error: muted brick red
        },
    },

    -- ---- TARDIS -------------------------------------------------------------
    -- Deep blue and cyan. Designed for the TARDIS kernel console.
    -- White text ensures values are legible against blue labels.
    -- Gray border keeps structural chrome distinct from blue subtext.

    tardis = {
        themeName  = "TARDIS",
        primary    = colors.cyan,
        secondary  = colors.lightBlue,
        background = colors.black,
        text       = colors.white,
        subtext    = colors.blue,
        border     = colors.gray,
        success    = colors.lime,
        error      = colors.red,
        fgDark     = colors.black,
        btnNum     = colors.gray,
        btnOp      = colors.cyan,
        btnFn      = colors.lightBlue,
        btnSpec    = colors.cyan,
        btnClear   = colors.red,
        btnEqual   = colors.cyan,
        selected   = colors.cyan,
        palette    = {
            [colors.black]     = 0x000814,  -- background: deep navy-black
            [colors.gray]      = 0x1A3A5C,  -- border: dark blue-gray
            [colors.blue]      = 0x1B4F8A,  -- subtext: deep TARDIS blue
            [colors.lightBlue] = 0x3A8FCC,  -- secondary: mid cyan-blue
            [colors.cyan]      = 0x00CFFF,  -- primary: bright glowing cyan
            [colors.white]     = 0xC8E8FF,  -- text: blue-tinted white
            [colors.lime]      = 0x00E676,  -- success: bright green
        },
    },

}

local name = "classic"
if fs.exists(THEME_FILE) then
    local f = fs.open(THEME_FILE, "r")
    name = f.readAll():gsub("[%s%z]", "")
    f.close()
end

return themes[name] or themes.classic
