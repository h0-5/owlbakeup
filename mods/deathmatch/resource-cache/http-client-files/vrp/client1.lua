-- Edited By DireYT

function checkHunger()
	local hunger = tonumber(getElementData(localPlayer, "hunger"))
	if hunger and hunger > 0 then
		setElementData(localPlayer, "hunger", hunger - 1)
	end
	
	if hunger == 0 then	
			setElementHealth(localPlayer, 100)
			setElementData(source, "hunger", 100)
		end
	end
setTimer(checkHunger, 60000, 0) -- configure o tempo

function checkSede()
	local sede = tonumber(getElementData(localPlayer, "sede"))
	if sede and sede > 0 then
		setElementData(localPlayer, "sede", sede - 1)
	end
	
	if sede == 0 then	
			setElementHealth(localPlayer, 100)
			setElementData(source, "sede", 100)
		end
	end
setTimer(checkSede, 60000, 0) -- configure o tempo