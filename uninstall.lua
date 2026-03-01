-- PunOS Uninstaller

local w, h = term.getSize()

local function loadTheme()
    if fs.exists("/os/theme.lua") then
        return dofile("/os/loadTheme.lua")
    end
    return {
        primary = colors.orange, background = colors.black,
        text = colors.white, subtext = colors.lightGray,
        border = colors.gray, error = colors.red
    }
end

local UI = loadTheme()

local function centered(y, text, color)
    term.setCursorPos(math.floor((w - #text) / 2), y)
    term.setTextColor(color or UI.text)
    term.write(text)
end

term.setBackgroundColor(UI.background)
term.clear()

-- Header
paintutils.drawFilledBox(1, 1, w, 2, UI.border)
term.setCursorPos(2, 1)
term.setTextColor(UI.primary)
term.write("PunOS")
term.setCursorPos(2, 2)
term.setTextColor(UI.subtext)
term.write("Uninstaller")

sleep(0.3)

centered(4, "Uninstalling PunOS...", UI.error)
sleep(0.4)

-- Files to delete with display names
local steps = {
    {path = "os",             label = "Removing programs..."},
    {path = "startup.lua",    label = "Removing startup..."},
    {path = "back.lua",       label = "Removing back..."},
    {path = ".menu",          label = "Removing menu..."},
    {path = ".server",        label = "Removing server..."},
    {path = ".server_files",  label = "Removing server files..."},
    {path = ".server_config", label = "Removing server config..."},
    {path = "publicChat.lua", label = "Removing chat..."},
    {path = ".chat_config",   label = "Removing chat config..."},
    {path = "/.theme",        label = "Removing theme config..."},
    {path = "/.punos_booted", label = "Clearing boot flag..."},
    {path = "uninstall.lua",  label = "Removing uninstaller..."},
    {path = "/audio",         label = "Deleting audio files..."},
    {path = "/paint",         label = "Removing paint files..."},
}

-- Progress bar setup
local barW = w - 4
local barX = 3
local barY = 7
local logY = 9

paintutils.drawFilledBox(barX, barY, barX + barW - 1, barY, UI.border)

for i, step in ipairs(steps) do
    -- Log line
    term.setCursorPos(2, logY)
    term.setBackgroundColor(UI.background)
    term.setTextColor(UI.subtext)
    term.clearLine()
    term.write(step.label)

    -- Progress bar fill
    local filled = math.floor(barW * (i / #steps))
    paintutils.drawFilledBox(barX, barY, barX + filled - 1, barY, UI.primary)

    -- Percentage
    local pct = math.floor(100 * i / #steps) .. "%"
    term.setCursorPos(math.floor((w - #pct) / 2), barY - 1)
    term.setBackgroundColor(UI.background)
    term.setTextColor(UI.primary)
    term.write(pct)

    -- Delete
    if fs.exists(step.path) then
        fs.delete(step.path)
    end

    sleep(0.2)
end

-- Final message - "corrupted" text reveal for drama
sleep(0.3)
term.setCursorPos(2, logY)
term.setBackgroundColor(UI.background)
term.setTextColor(UI.subtext)
term.clearLine()

local farewell = "PunOS has been removed. Goodbye."
local cx = math.floor((w - #farewell) / 2)

for i = 1, #farewell do
    term.setCursorPos(cx + i - 1, logY)
    -- Flicker effect: briefly show a random char before the real one
    term.setTextColor(UI.border)
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789!@#$"
    term.write(chars:sub(math.random(1, #chars), math.random(1, #chars)))
    sleep(0.02)
    term.setCursorPos(cx + i - 1, logY)
    term.setTextColor(UI.error)
    term.write(farewell:sub(i, i))
end

sleep(1.2)

-- Screen wipe downward
for y = 1, h do
    term.setCursorPos(1, y)
    term.setBackgroundColor(colors.black)
    term.clearLine()
    sleep(0.04)
end

sleep(0.3)
os.reboot()