-- SPDX-FileCopyrightText: 2017 Daniel Ratcliffe
-- SPDX-License-Identifier: LicenseRef-CCPL

local tArgs = { ... }
local UI = dofile("/os/loadTheme.lua")
UI.system = UI.secondary

local function printUsage()
    local programName = arg[0] or fs.getName(shell.getRunningProgram())
    print("Usages:")
    print(programName .. " host <hostname>")
    print(programName .. " join <hostname> <nickname>")
end

local sOpenedModem = nil
local function openModem()
    for _, sModem in ipairs(peripheral.getNames()) do
        if peripheral.getType(sModem) == "modem" then
            if not rednet.isOpen(sModem) then
                rednet.open(sModem)
                sOpenedModem = sModem
            end
            return true
        end
    end
    print("No modems found.")
    return false
end

local function closeModem()
    if sOpenedModem ~= nil then
        rednet.close(sOpenedModem)
        sOpenedModem = nil
    end
end

local highlightColour, textColour
if term.isColour() then
    textColour      = UI.text
    highlightColour = UI.primary
else
    textColour      = colours.white
    highlightColour = colours.white
end

local sCommand = tArgs[1]

if sCommand == "host" then
    local sHostname = tArgs[2]
    if sHostname == nil then printUsage(); return end
    if not openModem() then return end

    -- "chat_" prefix prevents collision with other CC programs using "chat" protocol
    rednet.host("chat", "chat_" .. sHostname)

    local monitor = peripheral.find("monitor")
    local parentTerm
    if monitor then
        parentTerm = monitor
        monitor.setTextScale(0.5)
    else
        parentTerm = term.current()
    end

    local w, h = parentTerm.getSize()
    local headerWindow  = window.create(parentTerm, 1, 1, w, 3, true)
    local historyWindow = window.create(parentTerm, 1, 4, w, h - 4, true)
    local statusWindow  = window.create(parentTerm, 1, h, w, 1, true)

    local messageHistory = {}
    local scrollPosition = 0
    local maxHistoryLines = 1000

    parentTerm.setBackgroundColor(UI.background)
    parentTerm.clear()
    term.redirect(parentTerm)

    local function drawServerHeader()
        headerWindow.setBackgroundColor(UI.border)
        headerWindow.clear()
        headerWindow.setCursorPos(2, 2)
        headerWindow.setTextColor(UI.primary)
        headerWindow.write("PublicChat Server")
        headerWindow.setCursorPos(w - 8, 2)
        headerWindow.setTextColor(UI.system)
        headerWindow.write("[SERVER]")
        headerWindow.setCursorPos(2, 3)
        headerWindow.setTextColor(UI.subtext)
        headerWindow.write("Hosting: #" .. sHostname)
        local idInfo = "ID:" .. os.getComputerID()
        headerWindow.setCursorPos(w - #idInfo - 1, 3)
        headerWindow.write(idInfo)
    end

    local function drawStatusBar(nUsers, tUsers)
        statusWindow.setBackgroundColor(UI.border)
        statusWindow.clear()
        statusWindow.setCursorPos(2, 1)
        statusWindow.setTextColor(UI.subtext)
        local statusText = nUsers .. " user" .. (nUsers == 1 and "" or "s")
        if nUsers > 0 then
            statusText = statusText .. ": "
            local names = {}
            for _, u in pairs(tUsers) do table.insert(names, u.sUsername) end
            statusText = statusText .. table.concat(names, ", ")
        end
        if scrollPosition > 0 then statusText = statusText .. " | Scrolled" end
        if #statusText > w - 4 then statusText = statusText:sub(1, w - 7) .. "..." end
        statusWindow.write(statusText)
    end

    local function redrawHistory(nUsers, tUsers)
        historyWindow.setBackgroundColor(UI.background)
        historyWindow.clear()
        historyWindow.setCursorPos(1, 1)
        local _, maxY = historyWindow.getSize()
        local startLine = math.max(1, #messageHistory - maxY + 1 - scrollPosition)
        local endLine   = math.min(#messageHistory, startLine + maxY - 1)
        for i = startLine, endLine do
            local msg = messageHistory[i]
            if msg then
                if string.match(msg, "^%*") then
                    historyWindow.setTextColour(UI.system)
                    historyWindow.write(msg)
                else
                    local sUsernameBit = string.match(msg, "^<[^>]*>")
                    if sUsernameBit then
                        historyWindow.setTextColour(highlightColour)
                        historyWindow.write(sUsernameBit)
                        historyWindow.setTextColour(UI.text)
                        historyWindow.write(string.sub(msg, #sUsernameBit + 1))
                    else
                        historyWindow.setTextColour(UI.text)
                        historyWindow.write(msg)
                    end
                end
                if i < endLine then
                    local _, y = historyWindow.getCursorPos()
                    historyWindow.setCursorPos(1, y + 1)
                end
            end
        end
        drawStatusBar(nUsers, tUsers)
    end

    local function printServerMessage(sMessage, nUsers, tUsers)
        table.insert(messageHistory, sMessage)
        if #messageHistory > maxHistoryLines then
            table.remove(messageHistory, 1)
            if scrollPosition > 0 then scrollPosition = scrollPosition - 1 end
        end
        if scrollPosition == 0 then redrawHistory(nUsers, tUsers) end
    end

    drawServerHeader()

    local tUsers = {}
    local nUsers = 0

    printServerMessage("* Server started on #" .. sHostname, nUsers, tUsers)
    drawStatusBar(nUsers, tUsers)

    local function send(sText, nUserID)
        if nUserID then
            local tUser = tUsers[nUserID]
            if tUser then
                rednet.send(tUser.nID, { sType = "text", nUserID = nUserID, sText = sText }, "chat")
            end
        else
            for nUID, tUser in pairs(tUsers) do
                rednet.send(tUser.nID, { sType = "text", nUserID = nUID, sText = sText }, "chat")
            end
        end
    end

    local tPingPongTimer = {}
    local function ping(nUserID)
        local tUser = tUsers[nUserID]
        rednet.send(tUser.nID, { sType = "ping to client", nUserID = nUserID }, "chat")
        local timer = os.startTimer(15)
        tUser.bPingPonged = false
        tPingPongTimer[timer] = nUserID
    end

    local ok, err = pcall(parallel.waitForAny,
        function()
            while true do
                local _, direction = os.pullEvent("mouse_scroll")
                local _, maxY = historyWindow.getSize()
                local maxScroll = math.max(0, #messageHistory - maxY)
                if direction == 1 then
                    scrollPosition = math.max(scrollPosition - 1, 0)
                    redrawHistory(nUsers, tUsers)
                elseif direction == -1 then
                    scrollPosition = math.min(scrollPosition + 1, maxScroll)
                    redrawHistory(nUsers, tUsers)
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
                        local msg = "* " .. tUser.sUsername .. " has timed out"
                        send(msg); printServerMessage(msg, nUsers, tUsers)
                        tUsers[nUserID] = nil; nUsers = nUsers - 1
                        drawStatusBar(nUsers, tUsers)
                    else
                        ping(nUserID)
                    end
                end
            end
        end,
        function()
            while true do
                local tCommands = {
                    ["me"] = function(tUser, sContent)
                        if #sContent > 0 then
                            local msg = "* " .. tUser.sUsername .. " " .. sContent
                            send(msg); printServerMessage(msg, nUsers, tUsers)
                        else
                            send("* Usage: /me [words]", tUser.nUserID)
                        end
                    end,
                    ["nick"] = function(tUser, sContent)
                        if #sContent > 0 then
                            local old = tUser.sUsername
                            tUser.sUsername = sContent
                            local msg = "* " .. old .. " is now known as " .. tUser.sUsername
                            send(msg); printServerMessage(msg, nUsers, tUsers)
                            drawStatusBar(nUsers, tUsers)
                        else
                            send("* Usage: /nick [nickname]", tUser.nUserID)
                        end
                    end,
                    ["users"] = function(tUser, _)
                        send("* Connected Users:", tUser.nUserID)
                        local s = "*"
                        for _, u in pairs(tUsers) do s = s .. " " .. u.sUsername end
                        send(s, tUser.nUserID)
                    end,
                    ["help"] = function(tUser, _)
                        send("* Available commands:", tUser.nUserID)
                        local s = "*"
                        for cmd in pairs(tCommands) do s = s .. " /" .. cmd end
                        send(s .. " /logout", tUser.nUserID)
                    end,
                }

                local nSenderID, tMessage = rednet.receive("chat")
                if type(tMessage) == "table" then
                    if tMessage.sType == "login" then
                        local nUserID  = tMessage.nUserID
                        local sUsername = tMessage.sUsername
                        if nUserID and sUsername then
                            tUsers[nUserID] = { nID = nSenderID, nUserID = nUserID, sUsername = sUsername }
                            nUsers = nUsers + 1
                            local msg = "* " .. sUsername .. " has joined the chat"
                            send(msg); printServerMessage(msg, nUsers, tUsers)
                            drawStatusBar(nUsers, tUsers)
                            ping(nUserID)
                        end
                    else
                        local nUserID = tMessage.nUserID
                        local tUser   = tUsers[nUserID]
                        if tUser and tUser.nID == nSenderID then
                            if tMessage.sType == "logout" then
                                local msg = "* " .. tUser.sUsername .. " has left the chat"
                                send(msg); printServerMessage(msg, nUsers, tUsers)
                                tUsers[nUserID] = nil; nUsers = nUsers - 1
                                drawStatusBar(nUsers, tUsers)
                            elseif tMessage.sType == "chat" then
                                local sMessage = tMessage.sText
                                if sMessage then
                                    local sCmd = string.match(sMessage, "^/([a-z]+)")
                                    if sCmd then
                                        local fn = tCommands[sCmd]
                                        if fn then fn(tUser, string.sub(sMessage, #sCmd + 3))
                                        else send("* Unrecognised command: /" .. sCmd, tUser.nUserID) end
                                    else
                                        local msg = "<" .. tUser.sUsername .. "> " .. tMessage.sText
                                        send(msg); printServerMessage(msg, nUsers, tUsers)
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
        end
    )
    if not ok then printError(err) end

    for nUserID, tUser in pairs(tUsers) do
        rednet.send(tUser.nID, { sType = "kick", nUserID = nUserID }, "chat")
    end
    rednet.unhost("chat", "chat_" .. sHostname)
    closeModem()

elseif sCommand == "join" then
    local sHostname = tArgs[2]
    local sUsername = tArgs[3]
    if sHostname == nil or sUsername == nil then printUsage(); return end
    if not openModem() then return end

    write("Looking up " .. sHostname .. "... ")
    local nHostID = rednet.lookup("chat", "chat_" .. sHostname)
    if nHostID == nil then print("Failed."); closeModem(); return end
    print("Success.")

    local nUserID = math.random(1, 2147483647)
    rednet.send(nHostID, { sType = "login", nUserID = nUserID, sUsername = sUsername }, "chat")

    local bPingPonged = true
    local pingPongTimer = os.startTimer(0)

    local function ping()
        rednet.send(nHostID, { sType = "ping to server", nUserID = nUserID }, "chat")
        bPingPonged = false
        pingPongTimer = os.startTimer(15)
    end

    local w, h = term.getSize()
    local parentTerm = term.current()

    local headerWindow  = window.create(parentTerm, 1, 1, w, 3, true)
    local historyWindow = window.create(parentTerm, 1, 4, w, h - 6, true)
    local inputWindow   = window.create(parentTerm, 1, h - 1, w, 1, true)
    local footerWindow  = window.create(parentTerm, 1, h, w, 1, true)

    local messageHistory = {}
    local scrollPosition = 0
    local maxHistoryLines = 1000

    historyWindow.setCursorPos(1, 1)
    term.clear()
    term.setBackgroundColor(UI.background)
    term.setTextColour(textColour)

    local function drawHeader()
        headerWindow.setBackgroundColor(UI.border)
        headerWindow.clear()
        headerWindow.setCursorPos(2, 2)
        headerWindow.setTextColor(UI.primary)
        headerWindow.write("PublicChat")
        headerWindow.setCursorPos(w - 8, 2)
        headerWindow.setTextColor(UI.primary)
        headerWindow.write("[CLIENT]")
        headerWindow.setCursorPos(2, 3)
        headerWindow.setTextColor(UI.subtext)
        local info = "User: " .. sUsername .. " | #" .. sHostname
        headerWindow.write(info)
        local idInfo = "ID:" .. os.getComputerID()
        headerWindow.setCursorPos(w - #idInfo - 1, 3)
        headerWindow.write(idInfo)
    end

    local function drawFooter()
        footerWindow.setBackgroundColor(UI.border)
        footerWindow.clear()
        footerWindow.setCursorPos(2, 1)
        footerWindow.setTextColor(UI.subtext)
        local txt = "Type to chat | /logout to exit"
        if scrollPosition > 0 then txt = txt .. " | Scrolled" end
        footerWindow.write(txt)
    end

    local function redrawHistory()
        historyWindow.setBackgroundColor(UI.background)
        historyWindow.clear()
        historyWindow.setCursorPos(1, 1)
        local _, maxY = historyWindow.getSize()
        local startLine = math.max(1, #messageHistory - maxY + 1 - scrollPosition)
        local endLine   = math.min(#messageHistory, startLine + maxY - 1)
        for i = startLine, endLine do
            local msg = messageHistory[i]
            if msg then
                if string.match(msg, "^%*") then
                    historyWindow.setTextColour(UI.system)
                    historyWindow.write(msg)
                else
                    local sUsernameBit = string.match(msg, "^<[^>]*>")
                    if sUsernameBit then
                        historyWindow.setTextColour(highlightColour)
                        historyWindow.write(sUsernameBit)
                        historyWindow.setTextColour(UI.text)
                        historyWindow.write(string.sub(msg, #sUsernameBit + 1))
                    else
                        historyWindow.setTextColour(UI.text)
                        historyWindow.write(msg)
                    end
                end
                if i < endLine then
                    local _, y = historyWindow.getCursorPos()
                    historyWindow.setCursorPos(1, y + 1)
                end
            end
        end
        drawFooter()
    end

    local function printMessage(sMessage)
        local maxWidth = w - 2
        local lines = {}
        local remaining = sMessage
        while #remaining > 0 do
            if #remaining <= maxWidth then
                table.insert(lines, remaining); break
            else
                local cut = maxWidth
                local lastSpace = remaining:sub(1, maxWidth):match("^.*()%s")
                if lastSpace and lastSpace > maxWidth / 2 then cut = lastSpace end
                table.insert(lines, remaining:sub(1, cut))
                remaining = remaining:sub(cut + 1)
            end
        end
        for _, line in ipairs(lines) do
            table.insert(messageHistory, line)
        end
        while #messageHistory > maxHistoryLines do
            table.remove(messageHistory, 1)
            if scrollPosition > 0 then scrollPosition = scrollPosition - 1 end
        end
        if scrollPosition == 0 then redrawHistory() end
    end

    drawHeader()
    drawFooter()

    local ok, err = pcall(parallel.waitForAny,
        function()
            while true do
                local _, direction = os.pullEvent("mouse_scroll")
                local _, maxY = historyWindow.getSize()
                local maxScroll = math.max(0, #messageHistory - maxY)
                if direction == 1 then
                    scrollPosition = math.max(scrollPosition - 1, 0)
                    redrawHistory()
                elseif direction == -1 then
                    scrollPosition = math.min(scrollPosition + 1, maxScroll)
                    redrawHistory()
                end
            end
        end,
        function()
            while true do
                local sEvent, timer = os.pullEvent()
                if sEvent == "timer" then
                    if timer == pingPongTimer then
                        if not bPingPonged then
                            printMessage("* Server timeout.")
                            return
                        else
                            ping()
                        end
                    end
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
            while true do
                local nSenderID, tMessage = rednet.receive("chat")
                if nSenderID == nHostID and type(tMessage) == "table" and tMessage.nUserID == nUserID then
                    if tMessage.sType == "text" then
                        if tMessage.sText then printMessage(tMessage.sText) end
                    elseif tMessage.sType == "ping to client" then
                        rednet.send(nSenderID, { sType = "pong to server", nUserID = nUserID }, "chat")
                    elseif tMessage.sType == "pong to client" then
                        bPingPonged = true
                    elseif tMessage.sType == "kick" then
                        return
                    end
                end
            end
        end,
        function()
            local tSendHistory = {}
            while true do
                term.redirect(inputWindow)
                inputWindow.setBackgroundColor(UI.border)
                inputWindow.setCursorPos(1, 1)
                inputWindow.clearLine()
                inputWindow.setTextColor(highlightColour)
                inputWindow.write(": ")
                inputWindow.setTextColor(textColour)
                local sChat = read(nil, tSendHistory)
                if string.match(sChat, "^/logout") then
                    break
                elseif sChat and sChat ~= "" then
                    rednet.send(nHostID, { sType = "chat", nUserID = nUserID, sText = sChat }, "chat")
                    table.insert(tSendHistory, sChat)
                end
            end
        end
    )

    term.redirect(parentTerm)
    local _, finalH = term.getSize()
    term.setCursorPos(1, finalH)
    term.clearLine()
    term.setCursorBlink(false)
    if not ok then printError(err) end

    rednet.send(nHostID, { sType = "logout", nUserID = nUserID }, "chat")
    closeModem()
    messageHistory = nil

    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    print("Disconnected.")
    sleep(1)
    shell.run("/.menu")

else
    printUsage()
end
