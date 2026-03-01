-- PunOS Installer
-- Run via: pastebin run <id>

local RAW_BASE = "https://raw.githubusercontent.com/Puntaro-CC/PunOS-CC/main/"
local w, h = term.getSize()

local function centered(y, text, color)
    term.setCursorPos(math.floor((w - #text) / 2), y)
    term.setTextColor(color or colors.white)
    term.write(text)
end

local function httpGet(url)
    local ok, res = pcall(http.get, url)
    if not ok or not res then return nil end
    local body = res.readAll()
    res.close()
    return body
end

-- Files to download: {repo path, local path}
local FILES = {
    {"startup.lua",          "/startup.lua"},
    {".menu",                "/.menu"},
    {"publicChat.lua",       "/publicChat.lua"},
    {"uninstall.lua",        "/uninstall.lua"},
    {"back.lua",             "/back.lua"},
    {"os/theme.lua",         "/os/theme.lua"},
    {"os/loadTheme.lua",     "/os/loadTheme.lua"},
    {"os/.programs",         "/os/.programs"},
    {"os/.audioPlayer",      "/os/.audioPlayer"},
    {"os/.calculator",       "/os/.calculator"},
    {"os/.choosePaint",      "/os/.choosePaint"},
    {"os/.diskBrowser",      "/os/.diskBrowser"},
    {"os/.doom",             "/os/.doom"},
    {"os/.download",         "/os/.download"},
    {"os/.fileManager",      "/os/.fileManager"},
    {"os/.fileShare",        "/os/.fileShare"},
    {"os/.music",            "/os/.music"},
    {"os/.paintOpen",        "/os/.paintOpen"},
    {"os/.paintViewer",      "/os/.paintViewer"},
    {"os/.settings",         "/os/.settings"},
    {"os/.tetris",           "/os/.tetris"},
    {"os/.UninstallDialog",  "/os/.UninstallDialog"},
    {"os/.upload",           "/os/.upload"},
    {"os/.updater",          "/os/.updater"},
    {"os/.command",          "/os/.command"},
    {"os/.server",           "/.server"},
    {"os/.secureChat",       "/os/.secureChat"},
}

-- ---- Intro screen -----------------------------------------------------------

term.setBackgroundColor(colors.black)
term.clear()

centered(2,  "  ____  _   _ _   _  ___  ____  ",  colors.orange)
centered(3,  " |  _ \\| | | | \\ | |/ _ \\/ ___| ", colors.orange)
centered(4,  " | |_) | | | |  \\| | | | \\___ \\ ", colors.orange)
centered(5,  " |  __/| |_| | |\\  | |_| |___) |", colors.orange)
centered(6,  " |_|    \\___/|_| \\_|\\___/|____/ ", colors.orange)
centered(8,  "PunOS Installer",                    colors.white)
centered(9,  "github.com/Puntaro-CC/PunOS-CC",     colors.lightGray)

centered(11, "This will install PunOS on this computer.", colors.white)
centered(12, "Any existing startup.lua will be replaced.", colors.lightGray)

-- Confirm prompt
local confirmY = 14
centered(confirmY, "Press Enter to install, or Ctrl+T to cancel.", colors.lightGray)

term.setCursorPos(1, h)
term.setTextColor(colors.gray)
term.write("Requires HTTP access.")

-- Wait for enter
while true do
    local e, p = os.pullEvent("key")
    if p == keys.enter then break end
end

-- ---- Check HTTP -------------------------------------------------------------

term.setBackgroundColor(colors.black)
term.clear()
centered(3, "PunOS Installer", colors.orange)

term.setCursorPos(2, 5)
term.setTextColor(colors.lightGray)
term.write("Checking connection...")

if not http then
    term.setCursorPos(2, 7)
    term.setTextColor(colors.red)
    term.write("HTTP is not enabled on this computer.")
    term.setCursorPos(2, 8)
    term.setTextColor(colors.lightGray)
    term.write("Enable it in the CC config and try again.")
    return
end

local test = httpGet(RAW_BASE .. "version.json")
if not test then
    term.setCursorPos(2, 7)
    term.setTextColor(colors.red)
    term.write("Could not reach GitHub.")
    term.setCursorPos(2, 8)
    term.setTextColor(colors.lightGray)
    term.write("Check your internet connection and try again.")
    return
end

term.setCursorPos(2, 5)
term.setTextColor(colors.lime)
term.write("Connection OK.          ")

-- ---- Create directories -----------------------------------------------------

term.setCursorPos(2, 6)
term.setTextColor(colors.lightGray)
term.write("Creating directories...")

local dirs = {"/os", "/paint", "/audio"}
for _, dir in ipairs(dirs) do
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
end

-- ---- Download files ---------------------------------------------------------

local barW = w - 4
local barX = 3
local barY = 9
local logY = 11

term.setCursorPos(2, 8)
term.setTextColor(colors.white)
term.write("Downloading files...")

paintutils.drawFilledBox(barX, barY, barX + barW - 1, barY, colors.gray)

local failed = {}

for i, pair in ipairs(FILES) do
    local repoPath, localPath = pair[1], pair[2]

    -- Log line
    term.setCursorPos(2, logY)
    term.setTextColor(colors.lightGray)
    term.clearLine()
    term.write(repoPath)

    local body = httpGet(RAW_BASE .. repoPath)

    if body then
        -- Ensure parent dir exists
        local dir = fs.getDir(localPath)
        if dir ~= "" and dir ~= "/" and not fs.exists(dir) then
            fs.makeDir(dir)
        end
        local f = fs.open(localPath, "w")
        f.write(body)
        f.close()
    else
        table.insert(failed, repoPath)
    end

    -- Progress bar
    local filled = math.floor(barW * (i / #FILES))
    paintutils.drawFilledBox(barX, barY, barX + filled - 1, barY, colors.orange)

    local pct = math.floor(100 * i / #FILES) .. "%"
    term.setCursorPos(math.floor((w - #pct) / 2), barY - 1)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.orange)
    term.write(pct)

    sleep(0.03)
end

-- ---- Write version file -----------------------------------------------------

local f = fs.open("/.punos_version", "w")
f.write("5.2")
f.close()

-- ---- Result -----------------------------------------------------------------

term.setCursorPos(2, logY)
term.setBackgroundColor(colors.black)
term.clearLine()

if #failed == 0 then
    term.setCursorPos(2, logY)
    term.setTextColor(colors.lime)
    term.write("Installation complete!")

    term.setCursorPos(2, logY + 2)
    term.setTextColor(colors.lightGray)
    term.write("On first boot you will be asked to pick a theme.")

    for i = 3, 1, -1 do
        term.setCursorPos(2, h)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.gray)
        term.clearLine()
        term.write("Rebooting in " .. i .. "...")
        sleep(1)
    end
    os.reboot()
else
    term.setCursorPos(2, logY)
    term.setTextColor(colors.yellow)
    term.write("Done with " .. #failed .. " error(s):")

    for i, name in ipairs(failed) do
        term.setCursorPos(4, logY + i)
        term.setTextColor(colors.red)
        term.write("- " .. name)
    end

    term.setCursorPos(2, logY + #failed + 2)
    term.setTextColor(colors.lightGray)
    term.write("PunOS may still work. Reboot to try.")

    term.setCursorPos(2, h)
    term.setTextColor(colors.gray)
    term.write("Press any key to reboot.")
    os.pullEvent("key")
    os.reboot()
end
