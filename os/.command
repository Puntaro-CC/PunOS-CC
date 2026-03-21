-- PunOS Command Line
-- Works on whatever terminal is currently active (computer or monitor).

local UI = dofile("/os/loadTheme.lua")
local w, h = term.getSize()

term.setBackgroundColor(UI.background)
term.clear()

-- Header
paintutils.drawFilledBox(1, 1, w, 2, UI.border)
term.setCursorPos(2, 1)
term.setTextColor(UI.primary)
term.write("PunOS")
term.setCursorPos(2, 2)
term.setTextColor(UI.subtext)
term.write("Command Line  |  type 'back' to return")

-- Output area starts at row 3
local outY = 3

local function println(msg, col)
    if outY > h - 2 then
        -- Scroll: clear body and reset
        for y = 3, h - 2 do
            term.setCursorPos(1, y)
            term.setBackgroundColor(UI.background)
            term.clearLine()
        end
        outY = 3
    end
    term.setCursorPos(2, outY)
    term.setBackgroundColor(UI.background)
    term.setTextColor(col or UI.text)
    term.write(msg)
    outY = outY + 1
end

local function drawPrompt()
    paintutils.drawFilledBox(1, h - 1, w, h - 1, UI.border)
    term.setCursorPos(2, h - 1)
    term.setBackgroundColor(UI.border)
    term.setTextColor(UI.primary)
    term.write("> ")
    term.setTextColor(UI.text)
end

println("Command prompt ready.", UI.subtext)
println("Run any program or Lua expression.", UI.subtext)
println("", UI.subtext)

drawPrompt()

-- Input loop
local input = ""

while true do
    drawPrompt()
    term.setCursorPos(4 + #input, h - 1)
    term.setBackgroundColor(UI.border)
    term.setTextColor(UI.text)
    term.write(input .. "_")

    local e, p1 = os.pullEvent()

    if e == "char" then
        input = input .. p1
        term.setCursorPos(4, h - 1)
        term.setBackgroundColor(UI.border)
        term.setTextColor(UI.text)
        local display = input .. "_"
        if #display > w - 5 then display = display:sub(#display - (w - 6)) end
        term.write(display)

    elseif e == "key" then
        if p1 == keys.backspace then
            if #input > 0 then
                input = input:sub(1, -2)
                term.setCursorPos(4, h - 1)
                term.setBackgroundColor(UI.border)
                term.setTextColor(UI.text)
                local display = input .. "_ "
                if #display > w - 5 then display = display:sub(#display - (w - 6)) end
                term.write(display)
            end

        elseif p1 == keys.enter then
            local cmd = input:gsub("^%s+", ""):gsub("%s+$", "")
            input = ""

            if cmd == "" then
                -- do nothing

            elseif cmd == "back" then
                break

            elseif cmd == "clear" then
                for y = 3, h - 2 do
                    term.setCursorPos(1, y)
                    term.setBackgroundColor(UI.background)
                    term.clearLine()
                end
                outY = 3

            else
                println("> " .. cmd, UI.subtext)

                -- Try as a shell command first
                local ok, err = pcall(shell.run, cmd)
                if not ok then
                    -- Try as a Lua expression
                    local fn, lerr = load("return " .. cmd)
                    if fn then
                        local sok, result = pcall(fn)
                        if sok and result ~= nil then
                            println(tostring(result), UI.success)
                        elseif not sok then
                            println("Error: " .. tostring(result), UI.error)
                        end
                    else
                        -- Try as a Lua statement
                        local fn2, lerr2 = load(cmd)
                        if fn2 then
                            local sok2, serr2 = pcall(fn2)
                            if not sok2 then
                                println("Error: " .. tostring(serr2), UI.error)
                            end
                        else
                            println("Unknown command: " .. cmd, UI.error)
                        end
                    end
                end
            end
        end
    end
end

term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(1, 1)
shell.run(".menu")
