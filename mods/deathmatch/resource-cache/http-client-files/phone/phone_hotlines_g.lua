--MAXIME

hotlines = {
	[911] = "|| وزارة الداخلية ||", 
	[311] = "غير طوارئ",
	[411] = "LSFD Non-Emergency",
	[511] = "حكومة لوس سانتوز",
	[711] = "Report Stolen Vehicle",
	[9021] = "Rapid Towing",
	[8294] = "Yellow Cab Company",
	[7332] = "Los Santos Network",
	[7331] = "LSN - Advertisment",
	[2552] = "RS Haul",
	[5555] = "Federal Aviation Administration",
	[211] = "Los Santos Courts",
	[7233] = "|| شركة البضائع ||",
	[611] = "SASD Non-Emergency",
	[8800] = "San Andreas Public Transport",
}

function isNumberAHotline(theNumber)
	local challengeNumber = tonumber(theNumber)
	return hotlines[challengeNumber]
end