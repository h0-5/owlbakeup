--------------------------------------------------------------------------------
-- [U4] SERVER FEED FOR THE ORANGE TOP-RIGHT REPORTS BOX - REMOVED.
--
-- updateUnansweredReports() / updateUnansweredReportsGMs() / updateReports()
-- used to rebuild the urAdmin / urGM / allReports row tables every 4 / 5 / 6
-- seconds for the client widget in c_top_right_box.lua (the orange rectangle
-- with the 255,194,14 header). The widget is gone, so the rows and their
-- repeating timers are gone too - nothing on the client reads them anymore.
--
-- Any element data left over from the old widget is cleared once on start so
-- no client keeps a stale "Unanswered Reports" list in memory.
--------------------------------------------------------------------------------

local thisResourceElement = getResourceRootElement(getThisResource())

addEventHandler("onResourceStart", thisResourceElement, function()
	for _, key in ipairs({ "urAdmin", "urGM", "allReports" }) do
		if getElementData(thisResourceElement, key) ~= nil then
			removeElementData(thisResourceElement, key)
		end
	end
end)
