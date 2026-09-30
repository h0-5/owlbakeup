-- Decompiled by Owl Decompiler v1.0 (public/loading_c_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #61) with decompiler artifacts repaired:
--   * the three state tables (loading / progress / timer) were merged into
--     var0/var1/var2 inconsistently by the decompiler - split back per
--     feature (LOADING / PROGRESS / TIMER).
--   * loading(): `var0.queue[arg0] = {status = arg1, resource = ...} or nil`
--     kept the entry even when arg1 was false, so the spinner could never
--     hide - restored `arg1 and {...} or nil`.
--   * showTimer(): the countdown-sound gate `if var1 then` referenced the
--     outer progress table (always truthy) - restored to the lost sound
--     parameter (arg4).
--   * msToTimeStr: restored the lost zero-padding branches (empty
--     `if #tostring(..) == 1 then end` blocks).

local LOADING = { UI = {}, color = tocolor(255, 55, 95, 255), queue = {} }
local PROGRESS = { UI = {}, current_id = false }
local TIMER = { UI = {}, seconds = 0, timer = nil, sound = nil }

function msToTimeStr(seconds)
        seconds = tonumber(seconds)
        seconds = math.floor(seconds)
        if not seconds then
                return ""
        end
        if seconds < 0 then
                return "00:00"
        end
        local s = math.fmod(seconds, 60)
        local m = math.floor(seconds / 60)
        if #tostring(s) == 1 then
                s = "0" .. s
        end
        if #tostring(m) == 1 then
                m = "0" .. m
        end
        return m .. ":" .. s
end

function UIKitReady()
        eui = exports.UIKit
        LOADING.UI.loading = eui:uiCreateLoading(false, false, 64, 64, LOADING.color)
        eui:uiSetVisible(LOADING.UI.loading, false)
        PROGRESS.UI.container = eui:uiCreateRectangle(false, eui:uiGetReferenceScreenSize() - 80, 300, 60, "bg_default", true, true, true, true)
        eui:uiSetVisible(PROGRESS.UI.container, false)
        PROGRESS.UI.text = eui:uiCreateLabel(20, 10, 260, 20, "test", tocolor(255, 255, 255), "center", "center", PROGRESS.UI.container)
        PROGRESS.UI.progress = eui:uiCreateProgressBar(20, 40, 260, 5, _, PROGRESS.UI.container)
        eui:uiSetProperty(PROGRESS.UI.progress, "background_color", tocolor(0, 0, 0, 255))
        eui:uiSetProperty(PROGRESS.UI.progress, "progress_animation", true)
        eui:uiSetProperty(PROGRESS.UI.progress, "show_progress", false)
        TIMER.UI.container = eui:uiCreateRectangle(20, eui:uiGetReferenceScreenSize() - 400, 90, 30, "bg_default", true, true, true, true)
        eui:uiSetVisible(TIMER.UI.container, false)
        eui:uiCreateImage(5, 5, 20, 20, ":assets/icons/timer.png", TIMER.UI.container)
        TIMER.UI.text = eui:uiCreateLabel(45, 1, 45, 30, "00:00", tocolor(255, 255, 255), "left", "center", TIMER.UI.container)
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEvent("onClientUIKitReady", true)
addEventHandler("onClientUIKitReady", root, UIKitReady)

function loading(name, status, color)
        LOADING.queue[name] = status and { status = status, resource = sourceResource } or nil
        if color then
                LOADING.color = color
        end
        if status then
                eui:uiSetVisible(LOADING.UI.loading, true)
                eui:uiBringToFront(LOADING.UI.loading)
        else
                for _, entry in pairs(LOADING.queue) do
                        return
                end
                eui:uiSetVisible(LOADING.UI.loading, false)
        end
end

function progress(id, show, pct, text)
        if show then
                eui:uiProgressBarSetProgress(PROGRESS.UI.progress, pct)
                eui:uiSetText(PROGRESS.UI.text, text)
                eui:uiSetVisible(PROGRESS.UI.container, true)
                PROGRESS.current_id = id
        else
                eui:uiSetVisible(PROGRESS.UI.container, false)
                if PROGRESS.current_id == id then
                        PROGRESS.current_id = false
                end
        end
end

addEventHandler("onClientResourceStop", root, function(stoppedResource)
        for name, entry in pairs(LOADING.queue) do
                if entry and entry.resource == stoppedResource then
                        LOADING.queue[name] = nil
                        break
                end
        end
end)

function showTimer(id, show, seconds, autohide, withSound)
        if isTimer(TIMER.timer) then
                killTimer(TIMER.timer)
        end
        if TIMER.sound then
                stopSound(TIMER.sound)
                TIMER.sound = nil
        end
        if show then
                TIMER.seconds = seconds
                eui:uiSetVisible(TIMER.UI.container, true)
                eui:uiSetText(TIMER.UI.text, msToTimeStr(TIMER.seconds))
                TIMER.timer = setTimer(function(id, hide)
                        TIMER.seconds = TIMER.seconds - 1
                        eui:uiSetText(TIMER.UI.text, msToTimeStr(TIMER.seconds))
                        if TIMER.seconds == 10 then
                                if withSound then
                                        TIMER.sound = playSound(":assets/sounds/countdown_10.mp3")
                                end
                        elseif TIMER.seconds < 10 then
                                eui:uiLabelApplyShakeAnimation(TIMER.UI.text)
                        end
                        if hide and TIMER.seconds < 0 then
                                showTimer(id, false)
                        end
                end, 1000, seconds + 1, id, autohide)
        else
                eui:uiSetVisible(TIMER.UI.container, false)
        end
end
