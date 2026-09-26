-- Edited By DireYT

addEventHandler ("onPlayerLogin",root,function(_,Acc)
local FomeAcc2 = getAccountData (Acc,"AtualHunger") 
local SedeAcc2 = getAccountData (Acc,"AtualSede")
        if FomeAcc2 == false then
        setElementData (source,"hunger",100)
        else
        setElementData (source,"hunger",FomeAcc2)
        end
            if SedeAcc2 == false then 
            setElementData (source,"sede",100)
            else
            setElementData (source,"sede",SedeAcc2)
            end 
end)

function saveAccountData ( account )
    if isGuestAccount ( account ) then
        return false
    end
    Player = getAccountPlayer (account)
Fomes = getElementData (Player,"hunger")
Sedes = getElementData (Player,"sede")
setAccountData (account,"AtualHunger",Fomes)
setAccountData (account,"AtualSede",Sedes)
end

addEventHandler ( 'onPlayerQuit', root, function ( )
    local acc = getPlayerAccount ( source )
    saveAccountData ( acc )
end )


addEventHandler( "onResourceStart", getResourceRootElement( getThisResource() ), function( )        
 for _, plr in pairs( getElementsByType( "player" ) ) do 
 local Acc = getPlayerAccount (plr)
    if not isGuestAccount (Acc) then
    local FomeAcc = getAccountData (Acc,"AtualHunger") 
    local SedeAcc = getAccountData (Acc,"AtualSede")
        if FomeAcc == false then
        setElementData (plr,"hunger",100)
        else
        setElementData (plr,"hunger",FomeAcc)
        end
            if SedeAcc == false then
            setElementData (plr,"sede",100) 
            else
            setElementData (plr,"sede",SedeAcc)
            end 
    end    
 end
 end)
 
 
 addEventHandler ("onResourceStop",getResourceRootElement( getThisResource()),function()
for index,players in ipairs(getElementsByType("player")) do 
 local acc = getPlayerAccount ( players )
 saveAccountData ( acc )
end
end)

