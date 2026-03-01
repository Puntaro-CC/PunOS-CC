-- PunOS Startup
-- First boot: full logo animation + theme selection
-- Subsequent boots: quick wake animation

local w, h = term.getSize()
local BOOT_FLAG   = "/.punos_booted"
local THEME_FILE  = "/.theme"
local VER_FILE    = "/.punos_version"

local function readVersion()
    if not fs.exists(VER_FILE) then return "?" end
    local f = fs.open(VER_FILE, "r")
    local v = f.readAll():gsub("%s+", "")
    f.close()
    return v
end

local VERSION = readVersion()

local function loadTheme()
    if not fs.exists("/os/theme.lua") then
        return { primary = colors.orange, background = colors.black,
                 text = colors.white, subtext = colors.lightGray,
                 border = colors.gray, success = colors.lime }
    end
    return dofile("/os/loadTheme.lua")
end

-- ---- Quick wake animation (subsequent boots) ----
local function quickBoot()
    local UI = loadTheme()

    term.setBackgroundColor(colors.black)
    term.clear()

    local logo = "PunOS"
    local lx = math.floor((w - #logo) / 2)
    local ly = math.floor(h / 2) - 1

    for i = 1, #logo do
        term.setCursorPos(lx + i - 1, ly)
        term.setTextColor(UI.primary)
        term.write(logo:sub(i, i))
        sleep(0.04)
    end

    local ver = "v" .. VERSION
    term.setCursorPos(math.floor((w - #ver) / 2), ly + 1)
    term.setTextColor(UI.subtext)
    term.write(ver)

    local barW = 24
    local barX = math.floor((w - barW) / 2)
    local barY = ly + 3

    paintutils.drawFilledBox(barX, barY, barX + barW - 1, barY, UI.border)
    for i = 1, barW do
        paintutils.drawFilledBox(barX, barY, barX + i - 1, barY, UI.primary)
        sleep(0.025)
    end

    sleep(0.1)
    term.setBackgroundColor(colors.black)
    term.clear()
end

-- ---- First boot: full logo animation + theme selection ----
local function firstBoot()
    local logoLines = {
        " ____  _   _ _   _  ___  ____  ",
        "|  _ \\| | | | \\ | |/ _ \\/ ___| ",
        "| |_) | | | |  \\| | | | \\___ \\ ",
        "|  __/| |_| | |\\  | |_| |___) |",
        "|_|    \\___/|_| \\_|\\___/|____/ ",
    }

    term.setBackgroundColor(colors.black)
    term.clear()

    local logoX = math.floor((w - #logoLines[1]) / 2)
    local logoY = math.floor(h / 2) - 5

    for i, line in ipairs(logoLines) do
        term.setCursorPos(logoX, logoY + i - 1)
        term.setTextColor(colors.orange)
        for c = 1, #line do
            term.write(line:sub(c, c))
            sleep(0.01)
        end
    end

    sleep(0.3)

    local tagline = "Your ComputerCraft OS"
    term.setCursorPos(math.floor((w - #tagline) / 2), logoY + #logoLines + 1)
    term.setTextColor(colors.lightGray)
    for c = 1, #tagline do
        term.write(tagline:sub(c, c))
        sleep(0.02)
    end

    local ver = "Version " .. VERSION
    term.setCursorPos(math.floor((w - #ver) / 2), logoY + #logoLines + 2)
    term.setTextColor(colors.gray)
    term.write(ver)

    sleep(0.6)

    -- ---- Theme selection ----
    term.setBackgroundColor(colors.black)
    term.clear()

    local welcome = "Welcome to PunOS v" .. VERSION
    local prompt  = "Choose your colour theme:"
    term.setCursorPos(math.floor((w - #welcome) / 2), 2)
    term.setTextColor(colors.orange)
    term.write(welcome)
    term.setCursorPos(math.floor((w - #prompt) / 2), 3)
    term.setTextColor(colors.lightGray)
    term.write(prompt)

    local themes = {
        {key="classic",  name="Classic",  primary=colors.orange,  border=colors.gray},
        {key="popos",    name="Pop_OS",   primary=colors.purple,  border=colors.gray},
        {key="hacker",   name="Hacker",   primary=colors.lime,    border=colors.gray},
        {key="ocean",    name="Ocean",    primary=colors.cyan,    border=colors.gray},
        {key="midnight", name="Midnight", primary=colors.blue,    border=colors.gray},
    }

    local selected = 1
    local tileW   = math.floor((w - 2) / #themes)
    local tStartY = 5
    local tBtns   = {}

    local function drawTiles()
        tBtns = {}
        for i, t in ipairs(themes) do
            local x1 = 2 + (i - 1) * tileW
            local x2 = x1 + tileW - 1
            local y1, y2 = tStartY, tStartY + 4
            paintutils.drawFilledBox(x1, y1, x2, y2, t.border)
            paintutils.drawFilledBox(x1, y1, x2, y1, t.primary)
            term.setCursorPos(x1 + 1, y1 + 1)
            term.setBackgroundColor(t.border)
            term.setTextColor(t.primary)
            local nm = t.name
            if #nm > tileW - 2 then nm = nm:sub(1, tileW - 3) end
            term.write(nm)
            term.setCursorPos(x1 + 1, y1 + 2)
            term.setTextColor(colors.white)
            term.write("Text")
            term.setCursorPos(x1 + 1, y1 + 3)
            term.setTextColor(colors.lightGray)
            term.write("Sub")
            if i == selected then
                paintutils.drawBox(x1, y1, x2, y2, t.primary)
            end
            tBtns[i] = {x1=x1, y1=y1, x2=x2, y2=y2}
        end
    end

    local function drawConfirm()
        local row = tStartY + 7
        local hint = "Left/Right or click to choose  |  Enter to confirm"
        term.setCursorPos(math.floor((w - #hint) / 2), row)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.lightGray)
        term.write(hint)
        local lbl = " Confirm "
        local cx  = math.floor((w - #lbl) / 2)
        local cy  = row + 2
        paintutils.drawFilledBox(cx, cy, cx + #lbl - 1, cy, themes[selected].primary)
        term.setCursorPos(cx, cy)
        term.setTextColor(colors.black)
        term.write(lbl)
        return {x1=cx, y1=cy, x2=cx+#lbl-1, y2=cy}
    end

    drawTiles()
    local confirmBtn = drawConfirm()

    while true do
        local e, p1, p2, p3 = os.pullEvent()
        if e == "key" then
            if p1 == keys.left  or p1 == keys.a then if selected > 1 then selected = selected - 1 end end
            if p1 == keys.right or p1 == keys.d then if selected < #themes then selected = selected + 1 end end
            if p1 == keys.enter then break end
            drawTiles(); confirmBtn = drawConfirm()
        elseif e == "mouse_click" then
            local mx, my = p2, p3
            for i, r in ipairs(tBtns) do
                if mx >= r.x1 and mx <= r.x2 and my >= r.y1 and my <= r.y2 then
                    selected = i; drawTiles(); confirmBtn = drawConfirm(); break
                end
            end
            if mx >= confirmBtn.x1 and mx <= confirmBtn.x2 and my == confirmBtn.y1 then break end
        end
    end

    local f = fs.open(THEME_FILE, "w")
    f.write(themes[selected].key)
    f.close()

    -- Inline the selected theme colors directly -- theme.lua may not exist yet
    local UI = {
        primary    = themes[selected].primary,
        border     = themes[selected].border,
        subtext    = colors.lightGray,
        background = colors.black,
    }
    term.setBackgroundColor(colors.black)
    term.clear()

    local apMsg = "Theme applied: " .. themes[selected].name
    term.setCursorPos(math.floor((w - #apMsg) / 2), math.floor(h / 2) - 1)
    term.setTextColor(UI.primary)
    term.write(apMsg)

    local msgs = {
        "Initializing filesystem...",
        "Loading configuration...",
        "Starting services...",
        "Ready.",
    }

    local barW = math.floor(w * 0.7)
    local barX = math.floor((w - barW) / 2)
    local barY = math.floor(h / 2) + 1
    local msgY  = barY - 1

    paintutils.drawFilledBox(barX, barY, barX + barW - 1, barY, UI.border)

    for i, msg in ipairs(msgs) do
        term.setCursorPos(barX, msgY)
        term.setBackgroundColor(colors.black)
        term.setTextColor(UI.subtext)
        term.clearLine()
        term.write(msg)
        local segW = math.floor(barW * (i / #msgs))
        paintutils.drawFilledBox(barX, barY, barX + segW - 1, barY, UI.primary)
        sleep(0.3)
    end

    sleep(0.4)

    local flag = fs.open(BOOT_FLAG, "w")
    flag.write("1")
    flag.close()

    term.setBackgroundColor(colors.black)
    term.clear()
end

-- ---- Entry point ----
if fs.exists(BOOT_FLAG) then
    quickBoot()
else
    firstBoot()
end

shell.run(".menu")
