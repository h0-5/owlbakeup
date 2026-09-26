-- Edited By DireYT

function isElementMoving ( theElement )
    if isElement ( theElement ) then                    
        local x, y, z = getElementVelocity( theElement ) 
        return x ~= 0 or y ~= 0 or z ~= 0      
    end
 
    return false
end

function getElementSpeed(theElement, unit)
    assert(isElement(theElement), "Bad argument 1 @ getElementSpeed (element expected, got " .. type(theElement) .. ")")
    assert(getElementType(theElement) == "player" or getElementType(theElement) == "ped" or getElementType(theElement) == "object" or getElementType(theElement) == "vehicle", "Invalid element type @ getElementSpeed (player/ped/object/vehicle expected, got " .. getElementType(theElement) .. ")")
    assert((unit == nil or type(unit) == "string" or type(unit) == "number") and (unit == nil or (tonumber(unit) and (tonumber(unit) == 0 or tonumber(unit) == 1 or tonumber(unit) == 2)) or unit == "m/s" or unit == "km/h" or unit == "mph"), "Bad argument 2 @ getElementSpeed (invalid speed unit)")
    unit = unit == nil and 0 or ((not tonumber(unit)) and unit or tonumber(unit))
    local mult = (unit == 0 or unit == "m/s") and 50 or ((unit == 1 or unit == "km/h") and 180 or 111.84681456)
    return (Vector3(getElementVelocity(theElement)) * mult).length
end

function checkMoving()
   if isElementMoving(localPlayer) and getElementSpeed(localPlayer) > 5.1 then
   	   if not getPedOccupiedVehicle(localPlayer) then
          local staminalevel = tonumber(getElementData(localPlayer, "stamina") or 100)
          if staminalevel >= 0.2 then
              setElementData(localPlayer, "stamina", staminalevel - 0.11)
              if getElementData(localPlayer, "stamina->animRequested") then
			     toggleAllControls(true, true, true)
          	     setElementData(localPlayer, "stamina->animRequested", false)
				 setPedAnimation(localPlayer, "", "")
              end
          else
          	  if not getElementData(localPlayer, "stamina->animRequested") then
				         toggleAllControls(false, true, false)
          	     setPedAnimation(localPlayer, "FAT", "idle_tired", 8000, true, false, true, false)
				         setElementData(localPlayer, "stamina->animRequested", true)
              end
          end
   	   end
   else
       if tonumber(getElementData(localPlayer, "stamina") or 100) < 25 then
       	   local staminalevel = tonumber(getElementData(localPlayer, "stamina") or 100)
		   if not getElementData(localPlayer, "stamina->animRequested") then
		      toggleAllControls(false, true, false)
		      setPedAnimation(localPlayer, "FAT", "idle_tired", 8000, true, false, true, false)
              setElementData(localPlayer, "stamina->animRequested", true)
		   end
           setElementData(localPlayer, "stamina", staminalevel + 0.11)
       else
       	   local staminalevel = tonumber(getElementData(localPlayer, "stamina") or 100)
       	   if staminalevel < 100 then
               setElementData(localPlayer, "stamina", staminalevel + 0.11)
               if getElementData(localPlayer, "stamina->animRequested") then
          	      setElementData(localPlayer, "stamina->animRequested", false)
				  toggleAllControls(true, true, true)
          	      setPedAnimation(localPlayer, "", "")
               end
           end
       end
   end
end
addEventHandler("onClientRender", root, checkMoving, true, "low")