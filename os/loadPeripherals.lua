-- PunOS loadPeripherals helper
-- Call at the top of any TARDIS kernel file that needs peripheral access.
-- Handles keyboard init, monitor redirect, and TARDIS peripheral detection.
-- Usage: local monitor, tardis, w, h = dofile("/os/loadPeripherals.lua")

-- ---- Keyboard ---------------------------------------------------------------
-- Tom's Peripherals keyboard requires setFireNativeEvents to inject standard
-- key/char events into the computer's event queue.

local tmKeyboard = peripheral.find("tm_keyboard")
if tmKeyboard then
    pcall(tmKeyboard.setFireNativeEvents, true)
end

-- ---- Monitor ----------------------------------------------------------------
-- If a monitor is connected, redirect all terminal output to it.
-- Input from a laser pointer comes through as monitor_touch events --
-- handle these alongside mouse_click in any event loop.

local monitor = nil
for _, side in ipairs({"top","bottom","left","right","front","back"}) do
    local ok, p = pcall(peripheral.wrap, side)
    if ok and p and type(p.isColor) == "function" then
        term.redirect(p)
        p.setTextScale(0.5)
        monitor = p
        break
    end
end

-- ---- TARDIS peripheral ------------------------------------------------------
-- Only works inside the TARDIS dimension. Returns nil if not found, which
-- every caller should handle gracefully.

local tardis = nil
for _, side in ipairs({"top","bottom","left","right","front","back"}) do
    local ok, p = pcall(peripheral.wrap, side)
    if ok and p and type(p.isInFlight) == "function" then
        tardis = p
        break
    end
end

-- ---- Terminal size ----------------------------------------------------------
-- Must be read AFTER monitor redirect so w/h reflect the actual display.

local w, h = term.getSize()

return monitor, tardis, w, h
