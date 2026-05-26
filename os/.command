-- PunOS Command Prompt
os.pullEvent = os.pullEventRaw

local UI = dofile("/os/loadTheme.lua")
local w, h = term.getSize()

local function readFile(path)
    if not fs.exists(path) then return "?" end
    local f = fs.open(path, "r")
    local v = f.readAll():gsub("%s+", "")
    f.close()
    return v
end

local function drawSplash()
    term.setBackgroundColor(UI.background)
    term.clear()

    local label   = os.getComputerLabel() or ("computer" .. os.getComputerID())
    local version = readFile("/.punos_version")
    local kernel  = readFile("/.punos_kernel")
    local id      = os.getComputerID()
    local day     = os.day()
    local time    = textutils.formatTime(os.time(), false)
    local theme   = UI.themeName or "classic"

    local periph = peripheral.getNames()
    local periphStr = #periph > 0 and table.concat(periph, ", ") or "none"

    local logo = {
        " ____  ",
        "|  _ \\ ",
        "| |_) |",
        "|  __/ ",
        "|_|    ",
    }
    local logoW = #logo[1]  -- 7
    local gap   = 2
    local infoX = logoW + gap + 1

    -- Two items packed per line where they fit
    local infoLines = {
        "user: " .. label .. "  os: PunOS v" .. version,
        "id: "   .. id    .. "  day: Day " .. day .. "  " .. time,
        "periph: " .. periphStr,
        "theme: " .. theme .. "  kernel: " .. kernel,
        "res: "  .. w .. "x" .. h,
    }

    for i = 1, #logo do
        term.setCursorPos(1, i)
        term.setTextColor(UI.primary)
        term.write(logo[i])
        if infoLines[i] then
            term.setCursorPos(infoX, i)
            -- Split label: value pairs and color them
            local line = infoLines[i]
            -- Print key parts in subtext, value parts in text
            for key, val in line:gmatch("([%a]+: )([^%s]+[^%a:]*[^%s]*)") do
                term.setTextColor(UI.subtext)
                term.write(key)
                term.setTextColor(UI.text)
                -- Trim trailing spaces before the next pair
                local v = val:gsub("%s+$", "")
                if #v > w - term.getCursorPos() then
                    v = v:sub(1, w - term.getCursorPos() - 3) .. "..."
                end
                term.write(v .. "  ")
            end
        end
    end

    -- Divider
    term.setCursorPos(1, #logo + 1)
    term.setTextColor(UI.border)
    term.write(string.rep("-", w))

    return #logo + 2  -- prompt starts here
end

-- ---- Command coloring ----
local builtins = {
    ["ls"]=true, ["cd"]=true, ["mkdir"]=true, ["rm"]=true,
    ["cp"]=true, ["mv"]=true, ["cat"]=true, ["echo"]=true,
    ["edit"]=true, ["run"]=true, ["lua"]=true, ["reboot"]=true,
    ["shutdown"]=true, ["id"]=true, ["label"]=true, ["time"]=true,
    ["clear"]=true, ["help"]=true, ["programs"]=true, ["alias"]=true,
    ["pastebin"]=true, ["wget"]=true, ["back"]=true,
}

local function colorForCommand(input)
    local base = input:match("^(%S+)")
    if not base or base == "" then return UI.subtext end
    if base == "back" or base == "exit" then return UI.primary end
    if builtins[base] then return UI.success or colors.lime end
    if shell.resolveProgram(base) then return UI.text end
    return UI.error or colors.red
end

-- ---- Prompt loop ----
local function promptLoop()
    local label   = os.getComputerLabel() or ("cc" .. os.getComputerID())
    local history = {}

    while true do
        local cx, cy = term.getCursorPos()
        if cx > 1 then print("") end

        term.setTextColor(UI.primary);              term.write(label)
        term.setTextColor(UI.subtext);              term.write("@PunOS")
        term.setTextColor(UI.border);               term.write(":")
        term.setTextColor(UI.secondary or UI.text); term.write("~")
        term.setTextColor(UI.border);               term.write("$ ")
        term.setTextColor(UI.text)

        local input = read(nil, history)
        if input == nil then input = "" end
        input = input:match("^%s*(.-)%s*$")

        if input == "" then
            -- skip
        elseif input == "back" or input == "exit" then
            break
        else
            table.insert(history, input)
            local ok, err = pcall(shell.run, input)
            if not ok then
                term.setTextColor(UI.error or colors.red)
                print("Error: " .. tostring(err))
            end
        end

        term.setTextColor(UI.text)
    end
end

-- ---- Main ----
drawSplash()
promptLoop()

term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(1, 1)
shell.run(".menu")
