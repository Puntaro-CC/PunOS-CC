-- SPDX-FileCopyrightText: 2017 Daniel Ratcliffe
--
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

-- Colours
local highlightColour, textColour
if term.isColour() then
    textColour = UI.text
    highlightColour = UI.primary
else
    textColour = colours.white
    highlightColour = colours.white
end

local sCommand = tArgs[1]
if sCommand == "host" then
    -- "chat host"
    local sHostname = tArgs[2]
    if sHostname == nil then
        printUsage()
        return
    end

    if not openModem() then return end

    -- Original host layout naming convention
    rednet.host("chat", "chat_" .. sHostname)

    term.clear()
    term.setCursorPos(1, 1)
    print("Hosting chat server '" .. sHostname .. "' on computer ID " .. os.getComputerID())
    print("Press Q to quit.")

    local tSubscribers = {}

    local function chatHostLoop()
        while true do
            local nSenderID, tMessage, sProtocol = rednet.receive("chat")
            if sProtocol == "chat" and type(tMessage) == "table" then
                local sType = tMessage.sType
                if sType == "join" then
                    local sNickname = tMessage.sNickname
                    if sNickname then
                        tSubscribers[nSenderID] = sNickname
                        rednet.send(nSenderID, { sType = "join_ack" }, "chat")
                        
                        local sJoinMessage = sNickname .. " joined the room."
                        for nSubID, _ in pairs(tSubscribers) do
                            rednet.send(nSubID, { sType = "message", sText = sJoinMessage, bSystem = true }, "chat")
                        end
                        print(sJoinMessage)
                    end
                elseif sType == "logout" then
                    local sNickname = tSubscribers[nSenderID]
                    if sNickname then
                        tSubscribers[nSenderID] = nil
                        local sLeaveMessage = sNickname .. " left the room."
                        for nSubID, _ in pairs(tSubscribers) do
                            rednet.send(nSubID, { sType = "message", sText = sLeaveMessage, bSystem = true }, "chat")
                        end
                        print(sLeaveMessage)
                    end
                elseif sType == "chat" then
                    local sNickname = tSubscribers[nSenderID]
                    local sText = tMessage.sText
                    if sNickname and sText then
                        print("<" .. sNickname .. "> " .. sText)
                        for nSubID, _ in pairs(tSubscribers) do
                            rednet.send(nSubID, { sType = "message", sNickname = sNickname, sText = sText, bSystem = false }, "chat")
                        end
                    end
                end
            end
        end
    end

    local function quitLoop()
        while true do
            local _, key = os.pullEvent("key")
            if key == keys.q then break end
        end
    end

    parallel.waitForAny(chatHostLoop, quitLoop)

    -- Broadcast closing notice
    for nSubID, _ in pairs(tSubscribers) do
        rednet.send(nSubID, { sType = "message", sText = "Server shutting down.", bSystem = true }, "chat")
    end

    rednet.unhost("chat", "chat_" .. sHostname)
    closeModem()
    term.clear()
    term.setCursorPos(1, 1)
    print("Server stopped.")

elseif sCommand == "join" then
    -- "chat join"
    local sHostname = tArgs[2]
    local sNickname = tArgs[3]
    if sHostname == nil or sNickname == nil then
        printUsage()
        return
    end

    if not openModem() then return end

    term.clear()
    term.setCursorPos(1, 1)
    print("Searching for chat server '" .. sHostname .. "'...")

    -- Original resolution matching pattern
    local nHostID = rednet.lookup("chat", "chat_" .. sHostname)
    if nHostID == nil then
        print("Could not find server.")
        closeModem()
        return
    end

    print("Connecting to ID " .. nHostID .. "...")
    rednet.send(nHostID, { sType = "join", sNickname = sNickname }, "chat")

    local timeoutTimer = os.startTimer(5)
    local bConnected = false
    local nUserID = nil

    while true do
        local sEvent, p1, p2, p3 = os.pullEvent()
        if sEvent == "timer" and p1 == timeoutTimer then
            break
        elseif sEvent == "rednet_message" and p1 == nHostID and p3 == "chat" then
            if type(p2) == "table" and p2.sType == "join_ack" then
                bConnected = true
                nUserID = p2.nUserID or os.getComputerID()
                break
            end
        end
    end

    if not bConnected then
        print("No response from server.")
        closeModem()
        return
    end

    -- Original Visual Windows Setup
    local parentTerm = term.current()
    local w, h = term.getSize()

    local logWindow = window.create(parentTerm, 1, 1, w, h - 1, true)
    local inputWindow = window.create(parentTerm, 1, h, w, 1, true)

    logWindow.setBackgroundColor(UI.background)
    logWindow.clear()

    inputWindow.setBackgroundColor(UI.border)
    inputWindow.clear()

    local messageHistory = {}
    local scrollPosition = 0

    local function redrawLog()
        logWindow.setBackgroundColor(UI.background)
        logWindow.clear()
        local _, wh = logWindow.getSize()
        
        local startIdx = #messageHistory - wh + 1 - scrollPosition
        if startIdx < 1 then startIdx = 1 end
        local endIdx = #messageHistory - scrollPosition
        if endIdx > #messageHistory then endIdx = #messageHistory end

        local y = 1
        for i = startIdx, endIdx do
            local msg = messageHistory[i]
            logWindow.setCursorPos(1, y)
            if msg.bSystem then
                logWindow.setTextColor(UI.system)
                logWindow.write(msg.sText)
            else
                logWindow.setTextColor(highlightColour)
                logWindow.write("<" .. msg.sNickname .. "> ")
                logWindow.setTextColor(textColour)
                logWindow.write(msg.sText)
            end
            y = y + 1
        end
    end

    local tSendHistory = {}

    local ok, error = pcall(
        function()
            parallel.waitForAny(
                function()
                    -- Receiving thread
                    while true do
                        local nSenderID, tMessage, sProtocol = rednet.receive("chat")
                        if nSenderID == nHostID and sProtocol == "chat" and type(tMessage) == "table" then
                            if tMessage.sType == "message" then
                                table.insert(messageHistory, tMessage)
                                redrawLog()
                            end
                        end
                    end
                end,
                function()
                    -- Original Text-Wrapping Input Thread
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
                            rednet.send(nHostID, {
                                sType = "chat",
                                nUserID = nUserID,
                                sText = sChat,
                            }, "chat")
                            table.insert(tSendHistory, sChat)
                        end
                    end
                end
            )
        end
    )

    -- Close windows gracefully and restore parent UI terminal frames
    term.redirect(parentTerm)
    local _, finalH = term.getSize()
    term.setCursorPos(1, finalH)
    term.clearLine()
    term.setCursorBlink(false)
    if not ok then
        printError(error)
    end

    -- Logout sequence
    rednet.send(nHostID, { sType = "logout", nUserID = nUserID }, "chat")
    closeModem()

    messageHistory = nil
    scrollPosition = nil

    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    print("Disconnected.")
    sleep(1)
    shell.run("/.menu")
else
    printUsage()
end
