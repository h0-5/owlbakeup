-- owlbakeup Fix #63 - Trucker job config, RECONSTRUCTED server data (the
-- old config was lost with the dump; the decompile only shows the SCHEMA:
-- trailer_markers = array of {x, y, z} triples unpacked into createMarker,
-- locations = array of {col_points = {x, y, ... polygon}, position = {x, y, z}}).
-- Points chosen around Las Venturas + LS/SF docks (documented reconstruction).

TRUCKER_CONFIG = {
	trailer_markers = {
		{ 2188.5, 1735.2, 11.2 },
		{ 2242.0, 1848.5, 10.9 },
		{ 2468.3, 1976.4, 10.8 },
		{ 2601.5, 1815.9, 10.8 }
	},
	locations = {
		{
			col_points = { 2460.3, 2071.5, 2490.3, 2071.5, 2490.3, 2101.5, 2460.3, 2101.5 },
			position = { 2475.3, 2086.5, 10.8 }
		},
		{
			col_points = { -1702.2, -2.5, -1672.2, -2.5, -1672.2, 27.5, -1702.2, 27.5 },
			position = { -1687.2, 12.5, 3.9 }
		},
		{
			col_points = { 2303.5, -1675.0, 2333.5, -1675.0, 2333.5, -1645.0, 2303.5, -1645.0 },
			position = { 2318.5, -1660.0, 14.2 }
		},
		{
			col_points = { 2298.0, 857.0, 2328.0, 857.0, 2328.0, 887.0, 2298.0, 887.0 },
			position = { 2313.0, 872.0, 11.0 }
		}
	}
}

-- trucks the job accepts (var5[getElementModel] gate): Linerunner / Tank
-- Truck / Roadtrain - the three standard SA haulers
TRUCKER_TRUCK_MODELS = {
	[403] = true,
	[514] = true,
	[515] = true
}

TRUCKER_DELIVERY_PAY = 400 -- flat per delivery (reconstructed - no reward
-- field exists in the decompile's locations schema)
