function thaResourceStarting5( )
  water = createWater ( 1468, -1671, 12.5, 1498, -1671, 12.5, 1468, -1654, 12.5, 1498, -1654, 12.5 )
    setWaterLevel ( water, 12 )
	
end
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), thaResourceStarting5)

