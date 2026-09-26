--[[
	UIKit theme — rebuilt from the colours used by the original client files.
	Every value below was read off the decompiled server the design came from:
	primary is #FF375F, the surfaces are the 3/6/11 - 9/12/17 - 19/22/27 -
	29/32/37 family and the scrim colours are the same with lower alpha.
]]

theme = {
	COLORS = {
		primary         = tocolor(255, 55, 95),
		black           = tocolor(9, 12, 17),
		bg_default      = tocolor(3, 6, 11, 240),
		tabpanel_default= tocolor(19, 22, 27, 240),
		scrollbar_default = tocolor(255, 255, 255, 60),
		text_default    = tocolor(255, 255, 255, 255),
		grey            = tocolor(255, 255, 255, 50),
		success         = tocolor(46, 213, 115),
		warning         = tocolor(255, 176, 32),
		danger          = tocolor(255, 65, 65)
	},
	FONTS = {
		["ui-default"]   = { file = "fonts/Font2.ttf", size = 11.5 },
		["default-large"]= { file = "fonts/Font2.ttf", size = 15 },
		["PFDin"]        = { file = "fonts/PFDinDisplayPro-Regular.ttf", size = 14 },
		["PFDin-Bold"]   = { file = "fonts/PFDinDisplayPro-Bold.ttf", size = 14 },
		["PFDin-Big"]    = { file = "fonts/PFDinDisplayPro-Bold.ttf", size = 20 }
	}
}
