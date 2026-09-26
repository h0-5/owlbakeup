mysql = exports.mysql

function recoveryLicense(licensetext, cost, itemID, npcName)
	if not exports.global:takeMoney(source, cost) then
		exports.hud:sendBottomNotification(source, npcName, "هل أستطيع الحصول على $"..exports.global:formatMoney(cost).." رسوم لاسترداد "..licensetext.." رجاء?")
		return false
	end

	if exports.global:giveItem(source, itemID, getPlayerName(source):gsub("_", " ")) then
		exports.hud:sendBottomNotification(source, npcName, "كنت قد دفعت $"..exports.global:formatMoney(cost).." مجانا لاسترجاع ال "..licensetext..".")
	end
end
addEvent("license:recover", true)
addEventHandler("license:recover", root, recoveryLicense)

function onLicenseServer()
	local gender = getElementData(source, "gender")
	if (gender == 0) then
		exports.global:sendLocalText(source, "،مرحبا سيدي هل تريد التقديم على رخصة?", 255, 255, 255, 10)
	else
		exports.global:sendLocalText(source, "،مرحبا سيدتي هل تريدين التقديم على رخصة?", 255, 255, 255, 10)
	end
end
addEvent("onLicenseServer", true)
addEventHandler("onLicenseServer", getRootElement(), onLicenseServer)

function payFee(amount, reason)
	if exports.global:takeMoney(source, amount) then
		if not reason then
			reason = "a license"
		end
		exports.hud:sendBottomNotification(source, "شركة عمل الرخص", "لقد دفعت $"..exports.global:formatMoney(amount).." .")
	end
end
addEvent("payFee", true)
addEventHandler("payFee", getRootElement(), payFee)

function showLicenses(thePlayer, commandName, targetPlayer)
	--outputChatBox("This command is deprecated. Please show actual license/certificate from your inventory.", thePlayer, 255, 194, 14)
	--return false

	local loggedin = getElementData(thePlayer, "loggedin")
	if (loggedin==1) then
		if not (targetPlayer) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Player Partial Nick / ID]", thePlayer, 255, 194, 14)
		else
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, targetPlayer)

			if targetPlayer then
				local logged = getElementData(targetPlayer, "loggedin")

				if (logged==0) then
					outputChatBox("لم يتم تسجيل دخول اللاعب.", thePlayer, 255, 0, 0)
				elseif (logged==1) then
					local x, y, z = getElementPosition(thePlayer)
					local tx, ty, tz = getElementPosition(targetPlayer)

					if (getDistanceBetweenPoints3D(x, y, z, tx, ty, tz)>5) then -- Are they standing next to each other?
						outputChatBox("أنت بعيد جدًا لتظهر لك رخصة سلاحك '".. targetPlayerName .."'.", thePlayer, 255, 0, 0)
					else
						outputChatBox("لقد أظهرت تراخيص الأسلحة الخاصة بك إلى " .. targetPlayerName .. ".", thePlayer, 255, 194, 14)
						outputChatBox(getPlayerName(thePlayer) .. " أظهر لك تراخيص الأسلحة الخاصة بهم.", targetPlayer, 255, 194, 14)

						local gunlicense = getElementData(thePlayer, "license.gun")
						local gun2license = getElementData(thePlayer, "license.gun2")
						--[[local carlicense = getElementData(thePlayer, "license.car")
						local bikelicense = getElementData(thePlayer, "license.bike")
						local boatlicense = getElementData(thePlayer, "license.boat")
						local pilotlicense = getElementData(thePlayer, "license.pilot")
						local fishlicense = getElementData(thePlayer, "license.fish")]]

						local guns, guns2, cars, bikes, boats, pilots, fish

						if (gunlicense<=0) then
							guns = "No"
						else
							guns = "Yes"
						end

						if (gun2license<=0) then
							guns2 = "No"
						else
							guns2 = "Yes"
						end

						--[[if (carlicense<=0) then
							cars = "No"
						elseif (carlicense==3)then
							cars = "Theory test passed"
						else
							cars = "Yes"
						end

						if (bikelicense<=0) then
							bikes = "No"
						elseif (bikelicense==3)then
							bikes = "Theory test passed"
						else
							bikes = "Yes"
						end

						if (boatlicense<=0) then
							boats = "No"
						else
							boats = "Yes"
						end

						if (pilotlicense<=0) then
							pilots = "No"
						elseif (pilotlicense==1)then
							pilots = "ROT"
						elseif (pilotlicense==2)then
							pilots = "SER"
						elseif (pilotlicense==3)then
							pilots = "ROT+SER"
						elseif (pilotlicense==4)then
							pilots = "MER"
						elseif (pilotlicense==5)then
							pilots = "TER"
						elseif (pilotlicense==6)then
							pilots = "ROT+MER"
						elseif (pilotlicense==7)then
							pilots = "ROT+TER"
						else
							pilots = "No"
						end

						if (fishlicense<=0) then
							fishs = "No"
						else
							fishs = "Yes"
						end ]]

						--REQUIRES FUNCTION IN C_LICENSE_SYSTEM TO BE FIXED... triggerClientEvent ( "showLicenses", getRootElement(), showLicensesWindow)
						--triggerEvent("showLicenses", thePlayer, targetPlayer)

						outputChatBox("----- " .. getPlayerName(thePlayer) .. "'s Weapon Licenses -----", targetPlayer, 255, 194, 14)
						outputChatBox("        Tier 1 Firearms License: " .. guns, targetPlayer, 255, 194, 14)
						outputChatBox("        Tier 2 Firearms License: " .. guns2, targetPlayer, 255, 194, 14)
					--[[	outputChatBox("        Driver License: " .. cars, targetPlayer, 255, 194, 14)
						outputChatBox("        Motorcycle License: " .. bikes, targetPlayer, 255, 194, 14)
						outputChatBox("        Boat License: " .. boats, targetPlayer, 255, 194, 14)
						outputChatBox("        Pilots License: " .. pilots, targetPlayer, 255, 194, 14)
						outputChatBox("        Fishing Permit: " .. fishs, targetPlayer, 255, 194, 14) ]]
					end
				end
			end
		end
	end

end
addCommandHandler("showlicenses", showLicenses, false, false)
