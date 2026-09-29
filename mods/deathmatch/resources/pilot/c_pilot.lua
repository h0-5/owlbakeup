-- Decompiled by Owl Decompiler v1.0 ([jobs]/pilot/client_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) with one decompiler artifact repaired:
--   * var0 was the lost job/timer-key prefix - the addEvent concatenation
--     ("pilot" .. ":start_flight") shows it was the literal "pilot", so the
--     timer id is "pilot:flight".
-- The pilot client has NO job gating and NO take-job flow anywhere in the
-- decompile - it is the flight countdown display driven by the travel
-- system (see the airport resource, which triggers both events).

var0 = "pilot"

addEvent("pilot" .. ":start_flight", true)
addEventHandler("pilot" .. ":start_flight", localPlayer, function(seconds)
	exports.public:showTimer(var0 .. ":flight", true, seconds, true)
end)
addEvent("pilot" .. ":end_flight", true)
addEventHandler("pilot" .. ":end_flight", localPlayer, function()
	exports.public:showTimer(var0 .. ":flight", false)
end)

