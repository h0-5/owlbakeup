
--  PURPOSE:     Advertising Panel
--  DEVELOPERS:  yazn
------------------------------------------------------------------------------------

addEvent ("onSendMsg", true)
addEventHandler ("onSendMsg", root, function (text)
for k,v in ipairs (getElementsByType ("player")) do
triggerClientEvent (v, "onAddMsg", v, source, text)
end
end)

local Group = "Clear_Managers"
function cleargs (thePlayer)
   if not ( isObjectInACLGroup( "user." .. getAccountName( getPlayerAccount( thePlayer ) ), aclGetGroup( Group ) ) ) then return end
for k,v in ipairs (getElementsByType ("player")) do
triggerClientEvent (v, "clearAds", v, source, text)
   end
   end
addCommandHandler ( "clearads", cleargs )