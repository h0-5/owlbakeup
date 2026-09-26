--[[
All stored here for ease of use.

New jail system by: Chaos for OwlGaming
]]

pd_offline_jail = false -- PD Offline Jailing enabled or disabled. Reminder: Always enabled for admins.

pd_update_access = 59 -- Allows this faction ID to update/remove offline prisoners

hourLimit = 0 -- 0 is infinite, otherwise this is the max they can jail in hours

gateDim = 880
gateInt = 3
objectID = 2930

speakerDimensions = { [812] = true, [851] = true, [857] = true, [861] = true, [862] = true, [880] = true, [881] = true, [882] = true }
speakerInt = 3
speakerOutX, speakerOutY, speakerOutZ = -1046.16015625, -723.65625, 32.0078125

-- Skins, ID = clothing:id
-- Male Skins 
bMale = 305
bMaleID = 1109
wMale = 305
wMaleID = 1110
aMale = 305
aMaleID = 1110

-- Female Skins
bFemale = 69
bFemaleID = 1111
wFemale = 69
wFemaleID = 1112
aFemale = 69
aFemaleID = 1112


cells = {

["1A"] = { 1049.2900390625, 1253.2626953125, 1491.3601074219, 3, 880 },
["2A"] = { 1049.3837890625, 1245.22265625, 1491.3601074219, 3, 880 },
["3A"] = { 1049.0947265625, 1235.3291015625, 1491.3601074219, 3, 880 },
["4A"] = { 1049.25390625, 1230.033203125, 1491.3601074219, 3, 880 },
["5A"] = { 1049.345703125, 1225.0263671875, 1491.3601074219, 3, 880 },
["6A"] = { 1049.2900390625, 1253.2626953125, 1495.5241699219, 3, 880 },
["7A"] = { 1049.2900390625, 1253.2626953125, 1495.5241699219, 3, 880 },
["8A"] = { 1049.3837890625, 1245.22265625, 1495.5241699219, 3, 880 },
["9A"] = { 1049.09375, 1239.6826171875, 1495.5241699219, 3, 880 },
["10A"] = { 1048.8310546875, 1235.080078125, 1495.5241699219, 3, 880 },
["11A"] = { 1049.2548828125, 1229.6875, 1495.5241699219, 3, 880 },
["12A"] = { 1049.544921875, 1224.658203125, 1495.5241699219, 3, 880 },
["1B"] = { 1024.697265625, 1252.55078125, 1491.3601074219, 3, 880 },
["2B"] = { 1024.41796875, 1244.0576171875, 1491.3601074219, 3, 880 },
["3B"] = { 1024.2490234375, 1238.84375, 1491.3601074219, 3, 880 },
["4B"] = { 1024.904296875, 1233.6982421875, 1491.3601074219, 3, 880 },
["5B"] = { 1024.4345703125, 1228.958984375, 1491.3601074219, 3, 880 },
["6B"] = { 1024.87109375, 1223.779296875, 1491.3601074219, 3, 880 },
["7B"] = { 1024.697265625, 1252.55078125, 1495.5241699219, 3, 880 },
["8B"] = { 1024.41796875, 1244.0576171875, 1495.5241699219, 3, 880 },
["9B"] = { 1024.2490234375, 1238.84375, 1495.5241699219, 3, 880 },
["10B"] = { 1024.904296875, 1233.6982421875, 1495.5241699219, 3, 880 },
["11B"] = { 1024.4345703125, 1228.958984375, 1495.5241699219, 3, 880 },
["12B"] = { 1024.87109375, 1223.779296875, 1495.5241699219, 3, 880 },
["1S"] = { 1483.5419921875, 1532.4033203125, 10.85150718689, 3, 812 },
["2S"] = { 1488.5341796875, 1532.455078125, 10.85150718689, 3, 812 },
["3S"] = { 1492.6748046875, 1532.3017578125, 10.85150718689, 3, 812 },
}

cells2 = { }

--[[for k, v in pairs( cells ) do
  local sphere = createColSphere(v[1], v[2], v[3], 90)
  setElementDimension(sphere, v[5])
  setElementInterior(sphere, v[4])
  table.insert(cells2, sphere)
end]]

local sphere = createColSphere(1432.146484375, 1496.7099609375, 10.878900527954, 12)
setElementDimension(sphere, 851)
setElementInterior(sphere, 3)

function isCloseTo( thePlayer, targetPlayer )
  if exports.integration:isPlayerTrialAdmin(thePlayer) then
    return true
  end

  local theTeam = getPlayerTeam(thePlayer)
  local factionId = tonumber(getElementData(theTeam, "id"))
  if factionId == pd_update_access then
    return true
  end

  if targetPlayer then
    local dx, dy, dz = getElementPosition(thePlayer)
    local dx1, dy1, dz1 = getElementPosition(targetPlayer)
    if getDistanceBetweenPoints3D(dx, dy, dz, dx1, dy1, dz1) < ( 30 ) then
      if getElementDimension(thePlayer) == getElementDimension(targetPlayer) then
        return true
      end
    end
  end
    return false
end

function isInArrestColshape( thePlayer )
    if isElementWithinColShape( thePlayer, sphere ) and (getElementDimension( thePlayer ) == 851) then -- Don't forget to change this
      return true
  end
  return false
end

function cleanMath(number)
    if type(number) == "boolean" then
        return
    end
    local currenttime = getRealTime()
    local currentTime = currenttime.timestamp
    local remainingtime = tonumber(number) - currentTime
    local hours = (remainingtime /3600)
    local days = math.floor(hours/24)
    local remaininghours = hours - days*24
    local hours = ("%.1f"):format(hours - days*24)

    if remainingtime<0 then
        return "Awaiting", "Release", tonumber(remainingtime)
    end

    if days>999 then
      return "Life", "Sentence", tonumber(remainingtime)
    end
     
    return days, hours, tonumber(remainingtime)
end

-- Released
x, y, z = -1032.63671875, -524.0810546875, 32.0078125 -- Anumaz edit this for when they get released
dim = 0
int = 0

gates = {
  -- ["cell"] = { openx, openy, openz, openRx, openRy, openRz, closedx, closedy, closedz, closedRx, closedRy, closedRz }
["1A"] = { 1047.1, 1253.2, 1493, 0, 0, 0, 1047.1, 1254.9, 1493, 0, 0, 0 },
["2A"] = { 1047.1, 1244.7, 1493, 0, 0, 0, 1047.1, 1246.4, 1493, 0, 0, 0 },
["3A"] = { 1047.1, 1239.7, 1493, 0, 0, 0, 1047.1, 1241.4, 1493, 0, 0, 0 },
["4A"] = { 1047.1, 1234.7, 1493, 0, 0, 0, 1047.1, 1236.4, 1493, 0, 0, 0 },
["5A"] = { 1047.1, 1229.7, 1493, 0, 0, 0, 1047.1, 1231.4, 1493, 0, 0, 0 },
["6A"] = { 1047.1, 1224.7, 1493, 0, 0, 0, 1047.1, 1226.4, 1493, 0, 0, 0 },
["7A"] = { 1047.1, 1253.2, 1497.1, 0, 0, 0, 1047.1, 1254.9, 1497.1, 0, 0, 0 },
["8A"] = { 1047.1, 1244.7, 1497.1, 0, 0, 0, 1047.1, 1246.4, 1497.1, 0, 0, 0 },
["9A"] = { 1047.1, 1239.7, 1497.1, 0, 0, 0, 1047.1, 1241.4, 1497.1, 0, 0, 0 },
["10A"] = { 1047.1, 1234.7, 1497.1, 0, 0, 0, 1047.1, 1236.4, 1497.1, 0, 0, 0 },
["11A"] = { 1047.1, 1229.7, 1497.1, 0, 0, 0, 1047.1, 1231.4, 1497.1, 0, 0, 0 },
["12A"] = { 1047.1, 1224.7, 1497.1, 0, 0, 0, 1047.1, 1226.4, 1497.1, 0, 0, 0 },
     
["1B"] = { 1027.2, 1254.8, 1493, 0, 0, 0, 1027.2, 1253.1, 1493, 0, 0, 0 },
["2B"] = { 1027.2, 1246.2, 1493, 0, 0, 0, 1027.2, 1244.5, 1493, 0, 0, 0 },
["3B"] = { 1027.2, 1241.2, 1493, 0, 0, 0, 1027.2, 1239.5, 1493, 0, 0, 0 },
["4B"] = { 1027.2, 1236.2, 1493, 0, 0, 0, 1027.2, 1234.5, 1493, 0, 0, 0 },
["5B"] = { 1027.2, 1231.2, 1493, 0, 0, 0, 1027.2, 1229.5, 1493, 0, 0, 0 },
["6B"] = { 1027.2, 1226.3, 1493, 0, 0, 0, 1027.2, 1224.6, 1493, 0, 0, 0 },
["7B"] = { 1027.2, 1254.8, 1497.1, 0, 0, 0, 1027.2, 1253.1, 1497.1, 0, 0, 0 },
["8B"] = { 1027.2, 1246.2, 1497.1, 0, 0, 0, 1027.2, 1244.5, 1497.1, 0, 0, 0 },
["9B"] = { 1027.2, 1241.2, 1497.1, 0, 0, 0, 1027.2, 1239.5, 1497.1, 0, 0, 0 },
["10B"] = { 1027.2, 1236.2, 1497.1, 0, 0, 0, 1027.2, 1234.5, 1497.1, 0, 0, 0 },
["11B"] = { 1027.2, 1231.2, 1497.1, 0, 0, 0, 1027.2, 1229.5, 1497.1, 0, 0, 0 },
["12B"] = { 1027.2, 1226.3, 1497.1, 0, 0, 0, 1027.2, 1224.6, 1497.1, 0, 0, 0 },
}

--[[
----- SQL STRUCTURE -----

-- Host: 127.0.0.1
-- Generation Time: Aug 25, 2014 at 12:46 AM
-- Server version: 5.6.16
-- PHP Version: 5.5.11

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";

-- --------------------------------------------------------

--
-- Table structure for table `jailed`
--

CREATE TABLE IF NOT EXISTS `jailed` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `charid` int(11) NOT NULL,
  `charactername` text NOT NULL,
  `jail_time` bigint(12) NOT NULL,
  `convictionDate` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedBy` text NOT NULL,
  `charges` text NOT NULL,
  `cell` text NOT NULL,
  `fine` int(5) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=0 ;
]]