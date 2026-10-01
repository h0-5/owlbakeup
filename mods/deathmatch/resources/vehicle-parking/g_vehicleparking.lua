-- ============================================================================
-- vehicle-parking / g_vehicleparking.lua        (Fix #64)
-- ----------------------------------------------------------------------------
-- Player vehicle storage ("Parking Area") restored from the old Owl client:
--   /home/daytona/backupm/[rp]/vehicle-parking/client_decompiled.lua
--
-- The backup only kept the client.  The client's contract is:
--
--   server -> client  vehparking:showParking(lotID)      "Park the car in this parking"
--   server -> client  vehparking:showList(rows, lotID)   rows = { {ID=, Name=}, ... }
--   client -> server  vehparking:park(lotID)
--   client -> server  vehparking:getOut(vehicleID)
--
-- Parking a car moves it into the lot's private dimension (so it is safe from
-- theft and damage, exactly what the panel promises) and remembers it in
-- `vehicle_parking`; taking it out puts it back at the lot's exit.
-- ============================================================================

PARKING = {}

-- Purely internal dimension used to store parked cars.  Chosen far away from
-- any real interior/dimension in use.
PARKING.hiddenDimensionBase = 6000

-- ---------------------------------------------------------------------------
-- Parking lots.  `pos` is the marker (radius below), `spawn` is where a car is
-- placed when it is taken out, `slots` is where cars are stored while parked.
-- Add/adjust freely - everything else is driven by this table.
-- ---------------------------------------------------------------------------
PARKING.markerRadius = 4.0

PARKING.lots = {
	{
		name = { en = "Idlewood Parking", ar = "موقف إيدلوود" },
		dimension = 0,
		pos = { 1810.0, -1830.0, 13.6 },
		spawn = { 1810.0, -1830.0, 13.6, 270.0 },
		slots = {
			{ 1795.0, -1830.0, 13.6, 270.0 },
			{ 1785.0, -1830.0, 13.6, 270.0 },
			{ 1775.0, -1830.0, 13.6, 270.0 },
			{ 1765.0, -1830.0, 13.6, 270.0 },
			{ 1755.0, -1830.0, 13.6, 270.0 },
			{ 1745.0, -1830.0, 13.6, 270.0 },
		},
	},
	{
		name = { en = "Grove Street Parking", ar = "موقف شارع غروف" },
		dimension = 0,
		pos = { 2495.0, -1687.0, 13.5 },
		spawn = { 2495.0, -1687.0, 13.5, 180.0 },
		slots = {
			{ 2485.0, -1693.0, 13.5, 180.0 },
			{ 2475.0, -1693.0, 13.5, 180.0 },
			{ 2465.0, -1693.0, 13.5, 180.0 },
			{ 2455.0, -1693.0, 13.5, 180.0 },
			{ 2445.0, -1693.0, 13.5, 180.0 },
			{ 2435.0, -1693.0, 13.5, 180.0 },
		},
	},
	{
		name = { en = "Downtown Parking", ar = "موقف وسط المدينة" },
		dimension = 0,
		pos = { 1350.0, -1750.0, 13.5 },
		spawn = { 1350.0, -1750.0, 13.5, 90.0 },
		slots = {
			{ 1356.0, -1740.0, 13.5, 90.0 },
			{ 1356.0, -1730.0, 13.5, 90.0 },
			{ 1356.0, -1720.0, 13.5, 90.0 },
			{ 1356.0, -1710.0, 13.5, 90.0 },
			{ 1356.0, -1700.0, 13.5, 90.0 },
			{ 1356.0, -1690.0, 13.5, 90.0 },
		},
	},
	{
		name = { en = "San Fierro Parking", ar = "موقف سان فييرو" },
		dimension = 0,
		pos = { -1970.0, 300.0, 35.0 },
		spawn = { -1970.0, 300.0, 35.0, 180.0 },
		slots = {
			{ -1980.0, 294.0, 35.0, 180.0 },
			{ -1990.0, 294.0, 35.0, 180.0 },
			{ -2000.0, 294.0, 35.0, 180.0 },
			{ -2010.0, 294.0, 35.0, 180.0 },
			{ -2020.0, 294.0, 35.0, 180.0 },
			{ -2030.0, 294.0, 35.0, 180.0 },
		},
	},
	{
		name = { en = "Las Venturas Parking", ar = "موقف لاس فينتوراس" },
		dimension = 0,
		pos = { 2070.0, 1400.0, 10.5 },
		spawn = { 2070.0, 1400.0, 10.5, 0.0 },
		slots = {
			{ 2060.0, 1406.0, 10.5, 0.0 },
			{ 2050.0, 1406.0, 10.5, 0.0 },
			{ 2040.0, 1406.0, 10.5, 0.0 },
			{ 2030.0, 1406.0, 10.5, 0.0 },
			{ 2020.0, 1406.0, 10.5, 0.0 },
			{ 2010.0, 1406.0, 10.5, 0.0 },
		},
	},
}

PARKING.blip = { icon = 63, name = { en = "Parking Area", ar = "موقف سيارات" } }

PARKING.EVENTS = {
	showParking = "vehparking:showParking",
	showList    = "vehparking:showList",
	park        = "vehparking:park",
	getOut      = "vehparking:getOut",
}

function getParkingLots()
	return PARKING.lots
end

function getParkingLot(id)
	return PARKING.lots[tonumber(id) or -1]
end

function getHiddenDimension(lotID)
	return PARKING.hiddenDimensionBase + (tonumber(lotID) or 0)
end
