-- SPDX-FileCopyrightText: 2017 Daniel Ratcliffe
-- SPDX-License-Identifier: LicenseRef-CCPL

local tArgs = { ... }
local UI = dofile("/os/loadTheme.lua")
UI.system = UI.secondary

local sSpeaker = peripheral.find("speaker")
local function blip()
    if sSpeaker then sSpeaker.playNote("bit", 1, 12) end
end

local function printUsage()
    local p = arg[0] or fs.getName(shell.getRunningProgram())
    print("Usages:")
    print(p .. " host <channel>")
    print(p .. " join [channel] [nickname]")
end

local sOpenedModem = nil
local function openModem()
    for _, sModem in ipairs(peripheral.getNames()) do
        if peripheral.getType(sModem) == "modem" then
            if not rednet.isOpen(sModem) then
                rednet.open(sModem); sOpenedModem = sModem
            end
            return true
        end
    end
    print("No modems found."); return false
end

local function closeModem()
    if sOpenedModem then rednet.close(sOpenedModem); sOpenedModem = nil end
end

local highlightColour, textColour
if term.isColour() then
    textColour = UI.text; highlightColour = UI.primary
else
    textColour = colours.white; highlightColour = colours.white
end

local w, h = term.getSize()
local MAX_HISTORY = 30
local sCommand = tArgs[1]

-- ================================================================
-- HOST MODE
-- ================================================================
if sCommand == "host" then
    local sHostname = tArgs[2]
    if not sHostname then printUsage(); return end
    if not openModem() then return end

    rednet.host("chat", "chat_" .. sHostname)

    local HISTORY_FILE = "/.pubchat_" .. sHostname .. ".log"
    local messageLog   = {}

    if fs.exists(HISTORY_FILE) then
        local f = fs.open(HISTORY_FILE, "r")
        local line = f.readLine()
        while line do table.insert(messageLog, line); line = f.readLine() end
        f.close()
        while #messageLog > MAX_HISTORY do table.remove(messageLog, 1) end
    end

    local function appendHistory(msg)
        table.insert(messageLog, msg)
        while #messageLog > MAX_HISTORY do table.remove(messageLog, 1) end
        local f = fs.open(HISTORY_FILE, "w")
        for _, line in ipairs(messageLog) do f.writeLine(line) end
        f.close()
    end

    local monitor = peripheral.find("monitor")
    local parentTerm = monitor or term.current()
    if monitor then monitor.setTextScale(0.5) end

    local W, H = parentTerm.getSize()
    local headerWindow  = window.create(parentTerm, 1, 1, W, 3, true)
    local historyWindow = window.create(parentTerm, 1, 4, W, H - 4, true)
    local statusWindow  = window.create(parentTerm, 1, H, W, 1, true)

    local dispHistory = {}
    local scrollPos   = 0
    local tUsers      = {}
    local nUsers      = 0

    parentTerm.setBackgroundColor(UI.background)
    parentTerm.clear()
    term.redirect(parentTerm)

    local function drawServerHeader()
        headerWindow.setBackgroundColor(UI.border); headerWindow.clear()
        headerWindow.setCursorPos(2, 2); headerWindow.setTextColor(UI.primary)
        headerWindow.write("PublicChat  #" .. sHostname)
        headerWindow.setCursorPos(W - 8, 2); headerWindow.setTextColor(UI.system)
        headerWindow.write("[SERVER]")
        local id = "ID:" .. os.getComputerID()
        headerWindow.setCursorPos(W - #id - 1, 3)
        headerWindow.setTextColor(UI.subtext); headerWindow.write(id)
    end

    local function drawStatusBar()
        statusWindow.setBackgroundColor(UI.border); statusWindow.clear()
        statusWindow.setCursorPos(2, 1); statusWindow.setTextColor(UI.subtext)
        local s = nUsers .. " online"
        if nUsers > 0 then
            s = s .. ":"
            for _, u in pairs(tUsers) do s = s .. " " .. u.sUsername end
        end
        if #s > W - 3 then s = s:sub(1, W - 6) .. "..." end
        statusWindow.write(s)
    end

    local function redrawHistoryWindow()
        historyWindow.setBackgroundColor(UI.background); historyWindow.clear()
        local _, maxY = historyWindow.getSize()
        local start = math.max(1, #dispHistory - maxY + 1 - scrollPos)
        local stop  = math.min(#dispHistory, start + maxY - 1)
        local y = 1
        for i = start, stop do
            local msg = dispHistory[i]
            if msg then
                historyWindow.setCursorPos(1, y)
                if msg:match("^%*") then
                    historyWindow.setTextColour(UI.system); historyWindow.write(msg)
                else
                    local u = msg:match("^<[^>]*>")
                    if u then
                        historyWindow.setTextColour(highlightColour); historyWindow.write(u)
                        historyWindow.setTextColour(UI.text); historyWindow.write(msg:sub(#u + 1))
                    else
                        historyWindow.setTextColour(UI.text); historyWindow.write(msg)
                    end
                end
                y = y + 1
            end
        end
        drawStatusBar()
    end

    local function addToDisplay(msg)
        table.insert(dispHistory, msg)
        if #dispHistory > 1000 then table.remove(dispHistory, 1) end
        if scrollPos == 0 then redrawHistoryWindow() end
    end

    local function send(sText)
        for nUID, tUser in pairs(tUsers) do
            rednet.send(tUser.nID, { sType = "text", nUserID = nUID, sText = sText }, "chat")
        end
    end

    local function sendExcept(sText, excludeID)
        for nUID, tUser in pairs(tUsers) do
            if nUID ~= excludeID then
                rednet.send(tUser.nID, { sType = "text", nUserID = nUID, sText = sText }, "chat")
            end
        end
    end

    local tPingPongTimer = {}
    local function ping(nUserID)
        local tUser = tUsers[nUserID]
        if not tUser then return end
        rednet.send(tUser.nID, { sType = "ping to client", nUserID = nUserID }, "chat")
        local timer = os.startTimer(15)
        tUser.bPingPonged = false
        tPingPongTimer[timer] = nUserID
    end

    drawServerHeader()
    addToDisplay("* Server started on #" .. sHostname)
    drawStatusBar()

    local ok, err = pcall(parallel.waitForAny,
        function()
            while true do
                local _, direction = os.pullEvent("mouse_scroll")
                local _, maxY = historyWindow.getSize()
                local maxScroll = math.max(0, #dispHistory - maxY)
                if direction == 1 then
                    scrollPos = math.max(scrollPos - 1, 0); redrawHistoryWindow()
                elseif direction == -1 then
                    scrollPos = math.min(scrollPos + 1, maxScroll); redrawHistoryWindow()
                end
            end
        end,
        function()
            while true do
                local _, timer = os.pullEvent("timer")
                local nUserID = tPingPongTimer[timer]
                if nUserID and tUsers[nUserID] then
                    local tUser = tUsers[nUserID]
                    if not tUser.bPingPonged then
                        local msg = "* " .. tUser.sUsername .. " timed out"
                        send(msg); appendHistory(msg); addToDisplay(msg)
                        tUsers[nUserID] = nil; nUsers = nUsers - 1; drawStatusBar()
                    else
                        ping(nUserID)
                    end
                end
            end
        end,
        function()
            while true do
                local tCommands = {
                    ["me"] = function(tUser, s)
                        if #s > 0 then
                            local msg = "* " .. tUser.sUsername .. " " .. s
                            send(msg); appendHistory(msg); addToDisplay(msg)
                        else send("* Usage: /me [words]") end
                    end,
                    ["nick"] = function(tUser, s)
                        if #s > 0 then
                            local old = tUser.sUsername; tUser.sUsername = s
                            local msg = "* " .. old .. " is now known as " .. s
                            send(msg); appendHistory(msg); addToDisplay(msg); drawStatusBar()
                        else send("* Usage: /nick [name]") end
                    end,
                    ["users"] = function(tUser, _)
                        local s = "* Online:"
                        for _, u in pairs(tUsers) do s = s .. " " .. u.sUsername end
                        send(s)
                    end,
                    ["help"] = function(tUser, _)
                        send("* Commands: /me /nick /users /help /logout")
                    end,
                }

                local nSenderID, tMessage = rednet.receive("chat")
                if type(tMessage) ~= "table" then
                    -- ignore non-table messages
                elseif tMessage.sType == "login" then
                    local nUserID   = tMessage.nUserID
                    local sUsername = tMessage.sUsername
                    if nUserID and sUsername then
                        tUsers[nUserID] = { nID = nSenderID, nUserID = nUserID, sUsername = sUsername }
                        nUsers = nUsers + 1

                        local joinMsg = "* " .. sUsername .. " joined #" .. sHostname
                        appendHistory(joinMsg)

                        -- Send ack + history to new client
                        rednet.send(nSenderID, {
                            sType   = "login_ack",
                            nUserID = nUserID,
                            history = messageLog,
                        }, "chat")

                        sendExcept(joinMsg, nUserID)
                        addToDisplay(joinMsg)
                        drawStatusBar()
                        ping(nUserID)
                    end
                else
                    local nUserID = tMessage.nUserID
                    local tUser   = tUsers[nUserID]
                    if tUser and tUser.nID == nSenderID then
                        if tMessage.sType == "logout" then
                            local msg = "* " .. tUser.sUsername .. " left the chat"
                            send(msg); appendHistory(msg); addToDisplay(msg)
                            tUsers[nUserID] = nil; nUsers = nUsers - 1; drawStatusBar()

                        elseif tMessage.sType == "chat" then
                            local sText = tMessage.sText
                            if sText then
                                local sCmd = sText:match("^/([a-z]+)")
                                if sCmd and tCommands[sCmd] then
                                    tCommands[sCmd](tUser, sText:sub(#sCmd + 3))
                                elseif sCmd then
                                    send("* Unknown command: /" .. sCmd)
                                else
                                    local msg = "<" .. tUser.sUsername .. "> " .. sText
                                    send(msg); appendHistory(msg); addToDisplay(msg); blip()
                                end
                            end

                        elseif tMessage.sType == "ping to server" then
                            rednet.send(tUser.nID, { sType = "pong to client", nUserID = nUserID }, "chat")

                        elseif tMessage.sType == "pong to server" then
                            tUser.bPingPonged = true
                        end
                    end
                end
            end
        end
    )

    if not ok then printError(err) end
    for nUserID, tUser in pairs(tUsers) do
        rednet.send(tUser.nID, { sType = "kick", nUserID = nUserID }, "chat")
    end
    rednet.unhost("chat", "chat_" .. sHostname)
    closeModem()

-- ================================================================
-- JOIN MODE
-- ================================================================
elseif sCommand == "join" then
    local sHostname = tArgs[2]
    local sNickname = tArgs[3]

    -- Channel select screen when no hostname provided
    if not sHostname then
        local label = os.computerLabel() or ("User" .. os.getComputerID())
        term.setBackgroundColor(UI.background); term.clear()
        paintutils.drawFilledBox(1, 1, w, 2, UI.border)
        term.setCursorPos(2, 1); term.setTextColor(UI.primary); term.write("PunOS")
        term.setCursorPos(2, 2); term.setTextColor(UI.subtext); term.write("PublicChat")

        term.setCursorPos(2, 4); term.setTextColor(UI.subtext)
        term.write("Joining as: ")
        term.setTextColor(UI.primary); term.write(label)

        term.setCursorPos(2, 6); term.setTextColor(UI.text)
        term.write('Channel name (blank for "general"):')

        paintutils.drawFilledBox(2, 7, w - 1, 7, UI.border)
        term.setCursorPos(3, 7)
        term.setTextColor(UI.text); term.setBackgroundColor(UI.border)
        local input = read()
        term.setBackgroundColor(UI.background)

        local trimmed = input and input:match("^%s*(.-)%s*$") or ""
        sHostname = (trimmed ~= "") and trimmed or "general"
    end

    if not sNickname then
        sNickname = os.computerLabel() or ("User" .. os.getComputerID())
    end

    if not openModem() then return end

    term.setBackgroundColor(UI.background); term.clear()
    term.setCursorPos(2, 4); term.setTextColor(UI.subtext)
    term.write("Looking up #" .. sHostname .. "...")

    local nHostID = rednet.lookup("chat", "chat_" .. sHostname)
    if not nHostID then
        term.setCursorPos(2, 5); term.setTextColor(UI.error)
        term.write("No server found for #" .. sHostname .. ".")
        term.setCursorPos(2, 6); term.setTextColor(UI.subtext)
        term.write("Make sure a host is running: publicChat host " .. sHostname)
        sleep(3); closeModem()
        shell.run("/.menu"); return
    end

    local nUserID = math.random(1, 2147483647)
    rednet.send(nHostID, { sType = "login", nUserID = nUserID, sUsername = sNickname }, "chat")

    -- Wait for login_ack + history. Falls through after 4s if server is older.
    local history  = {}
    local ackTimer = os.startTimer(4)
    local waiting  = true
    while waiting do
        local ev, p1, p2, p3 = os.pullEvent()
        if ev == "timer" and p1 == ackTimer then
            waiting = false
        elseif ev == "rednet_message" and p1 == nHostID and p3 == "chat" then
            if type(p2) == "table" and p2.sType == "login_ack" and p2.nUserID == nUserID then
                history = type(p2.history) == "table" and p2.history or {}
                waiting = false
            end
        end
    end

    local bPingPonged   = true
    local pingPongTimer = os.startTimer(0)
    local function ping()
        rednet.send(nHostID, { sType = "ping to server", nUserID = nUserID }, "chat")
        bPingPonged   = false
        pingPongTimer = os.startTimer(15)
    end

    local parentTerm    = term.current()
    local headerWindow  = window.create(parentTerm, 1, 1, w, 3, true)
    local historyWindow = window.create(parentTerm, 1, 4, w, h - 6, true)
    local inputWindow   = window.create(parentTerm, 1, h - 1, w, 1, true)
    local footerWindow  = window.create(parentTerm, 1, h, w, 1, true)

    local messageHistory = {}
    local scrollPosition = 0

    term.clear()
    term.setBackgroundColor(UI.background)

    local function drawHeader()
        headerWindow.setBackgroundColor(UI.border); headerWindow.clear()
        headerWindow.setCursorPos(2, 2); headerWindow.setTextColor(UI.primary)
        headerWindow.write("PublicChat  #" .. sHostname)
        headerWindow.setCursorPos(w - 8, 2); headerWindow.setTextColor(UI.primary)
        headerWindow.write("[CLIENT]")
        headerWindow.setCursorPos(2, 3); headerWindow.setTextColor(UI.subtext)
        headerWindow.write("User: " .. sNickname)
        local id = "ID:" .. os.getComputerID()
        headerWindow.setCursorPos(w - #id - 1, 3); headerWindow.write(id)
    end

    local function drawFooter()
        footerWindow.setBackgroundColor(UI.border); footerWindow.clear()
        footerWindow.setCursorPos(2, 1); footerWindow.setTextColor(UI.subtext)
        local txt = "Type to chat | /logout to leave"
        if scrollPosition > 0 then txt = txt .. " | Scrolled" end
        footerWindow.write(txt)
    end

    local function redrawHistory()
        historyWindow.setBackgroundColor(UI.background); historyWindow.clear()
        local _, maxY = historyWindow.getSize()
        local start = math.max(1, #messageHistory - maxY + 1 - scrollPosition)
        local stop  = math.min(#messageHistory, start + maxY - 1)
        local y = 1
        for i = start, stop do
            local msg = messageHistory[i]
            if msg then
                historyWindow.setCursorPos(1, y)
                if msg:match("^%*") then
                    historyWindow.setTextColour(UI.system); historyWindow.write(msg)
                else
                    local u = msg:match("^<[^>]*>")
                    if u then
                        historyWindow.setTextColour(highlightColour); historyWindow.write(u)
                        historyWindow.setTextColour(textColour); historyWindow.write(msg:sub(#u + 1))
                    else
                        historyWindow.setTextColour(textColour); historyWindow.write(msg)
                    end
                end
                y = y + 1
            end
        end
        drawFooter()
    end

    local function addMessage(msg)
        -- Word-wrap long messages
        local maxW = w - 2
        local rem  = msg
        while #rem > 0 do
            if #rem <= maxW then
                table.insert(messageHistory, rem); break
            else
                local cut = maxW
                local sp  = rem:sub(1, maxW):match("^.*()%s")
                if sp and sp > maxW / 2 then cut = sp end
                table.insert(messageHistory, rem:sub(1, cut))
                rem = rem:sub(cut + 1)
            end
        end
        while #messageHistory > 1000 do table.remove(messageHistory, 1) end
        if scrollPosition == 0 then redrawHistory() end
    end

    -- Show history received from server, then a divider
    if #history > 0 then
        for _, msg in ipairs(history) do addMessage(msg) end
        addMessage("* --- live ---")
    end

    drawHeader(); drawFooter()

    local ok, err = pcall(parallel.waitForAny,
        function()
            -- Scroll thread
            while true do
                local _, direction = os.pullEvent("mouse_scroll")
                local _, maxY = historyWindow.getSize()
                local maxScroll = math.max(0, #messageHistory - maxY)
                if direction == 1 then
                    scrollPosition = math.max(scrollPosition - 1, 0); redrawHistory()
                elseif direction == -1 then
                    scrollPosition = math.min(scrollPosition + 1, maxScroll); redrawHistory()
                end
            end
        end,
        function()
            -- Timer / resize thread
            while true do
                local sEvent, p1 = os.pullEvent()
                if sEvent == "timer" and p1 == pingPongTimer then
                    if not bPingPonged then addMessage("* Server timeout."); return
                    else ping() end
                elseif sEvent == "term_resize" then
                    w, h = parentTerm.getSize()
                    headerWindow.reposition(1, 1, w, 3)
                    historyWindow.reposition(1, 4, w, h - 6)
                    inputWindow.reposition(1, h - 1, w, 1)
                    footerWindow.reposition(1, h, w, 1)
                    drawHeader(); drawFooter(); redrawHistory()
                end
            end
        end,
        function()
            -- Receive thread
            while true do
                local nSenderID, tMessage = rednet.receive("chat")
                if nSenderID == nHostID and type(tMessage) == "table"
                and tMessage.nUserID == nUserID then
                    if     tMessage.sType == "text"           then addMessage(tMessage.sText or ""); blip()
                    elseif tMessage.sType == "ping to client" then
                        rednet.send(nSenderID, { sType = "pong to server", nUserID = nUserID }, "chat")
                    elseif tMessage.sType == "pong to client" then bPingPonged = true
                    elseif tMessage.sType == "kick"           then return
                    end
                end
            end
        end,
        function()
            -- Input thread
            local tSendHistory = {}
            while true do
                term.redirect(inputWindow)
                inputWindow.setBackgroundColor(UI.border)
                inputWindow.setCursorPos(1, 1); inputWindow.clearLine()
                inputWindow.setTextColor(highlightColour); inputWindow.write(": ")
                inputWindow.setTextColor(textColour)
                local sChat = read(nil, tSendHistory)
                if sChat:match("^/logout") then break
                elseif sChat ~= "" then
                    rednet.send(nHostID, { sType = "chat", nUserID = nUserID, sText = sChat }, "chat")
                    table.insert(tSendHistory, sChat)
                end
            end
        end
    )

    term.redirect(parentTerm)
    local _, fh = term.getSize()
    term.setCursorPos(1, fh); term.clearLine(); term.setCursorBlink(false)
    if not ok then printError(err) end

    rednet.send(nHostID, { sType = "logout", nUserID = nUserID }, "chat")
    closeModem()
    messageHistory = nil

    term.setBackgroundColor(colors.black); term.clear(); term.setCursorPos(1, 1)
    print("Disconnected from #" .. sHostname .. ".")
    sleep(1)
    shell.run("/.menu")

else
    printUsage()
end
