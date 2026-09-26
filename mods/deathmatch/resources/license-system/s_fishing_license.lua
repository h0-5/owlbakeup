mysql = exports.mysql

function giveFishLicense(usingGC)
	if usingGC then
		local success, reason = exports.donators:takeGC(source, 1)
		if not success then
			exports.hud:sendBottomNotification(source, "شركة عمل رخص", "لا يمكن اخذ الجي سي من حسابك: السبب لانك لا تملك الجي سي: " )
			return false
		end
	end

	mysql:query_free("UPDATE characters SET fish_license='1' WHERE charactername='" .. mysql:escape_string(getPlayerName(source)) .. "' LIMIT 1")
	exports.anticheat:changeProtectedElementDataEx(source, "license.fish", 1)
	exports.hud:sendBottomNotification(source, "شركة عمل رخص", "تهانينا! لديك الآن تصريح لصيد مياه سان أندرياس." )
	exports.global:giveItem(source, 154, getPlayerName(source):gsub("_"," "))
	executeCommandHandler("stats", source, getPlayerName(source))
end
addEvent("acceptFishLicense", true)
addEventHandler("acceptFishLicense", getRootElement(), giveFishLicense)