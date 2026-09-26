
--  PURPOSE:     Advertising Panel
--  DEVELOPERS:  yAzn
------------------------------------------------------------------------------------

GUIEditor = {
    gridlist = {},
    window = {},
    button = {},
    edit = {}
}
addEventHandler("onClientResourceStart", resourceRoot,
    function()
        GUIEditor.window[1] = guiCreateWindow(477, 232, 513, 427, "Deer gaming Advertisings Panel By [yazn|", false)
        centerTheGUI( GUIEditor.window[1] )
        guiWindowSetSizable(GUIEditor.window[1], false)
    guiSetVisible ( GUIEditor.window[1], false )
        GUIEditor.gridlist[1] = guiCreateGridList(9, 27, 493, 251, false, GUIEditor.window[1])
        plrC = guiGridListAddColumn(GUIEditor.gridlist[1], "Player", 0.3)
        msgC = guiGridListAddColumn(GUIEditor.gridlist[1], "Message", 0.63)
        GUIEditor.edit[1] = guiCreateEdit(9, 288, 493, 66, "", false, GUIEditor.window[1])
        GUIEditor.button[1] = guiCreateButton(10, 364, 114, 41, "Send", false, GUIEditor.window[1])
        guiSetProperty(GUIEditor.button[1], "NormalTextColour", "FFAAAAAA")
        GUIEditor.button[2] = guiCreateButton(378, 364, 114, 41, "Close", false, GUIEditor.window[1])
        guiSetProperty(GUIEditor.button[2], "NormalTextColour", "FFAAAAAA")   
        guiEditSetMaxLength(GUIEditor.edit[1], 100) 
        addCommandHandler( "ads", openAd )
		
    end
)
----
addEvent("onCountDownEnd")
 
function GuiSetTextCountDown ( guiElement , Text, count )
    if not guiElement or not Text or not tonumber(count) then
        outputDebugString("Bad arugment @ GuiSetTextCountDown ",0,255,0,0)
    return end
    guiSetText ( guiElement ,Text..' '..tonumber( count ) )
    setTimer(
        function ( )
            -- if not tonumber ( count ) then return false end
            if count <= 0 then
                triggerEvent("onCountDownEnd", localPlayer)
                return
            end
            count = count -1
            guiSetText ( guiElement ,Text..' '..tonumber( count ) )
            end , 1000, 0)
end
----
----------------------------------------------------------
local sx, sy = guiGetScreenSize()
function centerTheGUI( guiElement )
    local width, height = guiGetSize( guiElement, false )
    local x, y = sx / 2 - width / 2, sy / 2 - height / 2
    guiSetPosition( guiElement, x, y, false )
end
----------------------------------------------------------
addEventHandler ( "onClientGUIClick", root,
function()
  if source == GUIEditor.button[2] then
    guiSetVisible ( GUIEditor.window[1], false )
    showCursor (false)
  end 
end )
----------------------------------------------------------
function openAd()
  if ( guiGetVisible ( GUIEditor.window[1] ) == true ) then              
   guiSetVisible ( GUIEditor.window[1], false )
   showCursor (false)
  else              
   guiSetVisible ( GUIEditor.window[1], true )
   showCursor (true)
  end
end
addCommandHandler( "ads", openAd )
 
----------------------------------------------------------

addEventHandler ("onClientGUIClick", root,
function ()
  if (source == GUIEditor.button[1]) then
if isTimer(theTimer) then
cancelEvent()
totalExecutes = getTimerDetails(theTimer)/1000
exports.UIPtexts:output ("You need to wait for "..totalExecutes.." seconds", 0, 255, 0)
GuiSetTextCountDown(GUIEditor.edit[1], "Time left:", 120)
guiEditSetReadOnly( GUIEditor.edit[1], true )
guiSetEnabled ( GUIEditor.button[1], false )
else
     tx = guiGetText (GUIEditor.edit[1])
       if tx == "" then return end
        triggerServerEvent ("onSendMsg", localPlayer, guiGetText (GUIEditor.edit[1]))
theTimer = setTimer ( function() 
guiSetEnabled ( GUIEditor.button[1], true)
guiEditSetReadOnly( GUIEditor.edit[1], false ) 
guiSetText (GUIEditor.edit[1], "")
end, 123000, 1)
end
end
end)

function timeOver()
--guiSetEnabled ( GUIEditor.button[1], true)
--guiEditSetReadOnly( GUIEditor.edit[1], false )
--guiSetText (GUIEditor.edit[1], "")
end
addEventHandler ("onCountDownEnd", root, timeOver)

addEvent ("onAddMsg", true)
addEventHandler ("onAddMsg", root, function (whoSend, text)
Row = guiGridListAddRow (GUIEditor.gridlist[1])
guiGridListSetItemText(GUIEditor.gridlist[1], Row, msgC, text, false, false)
guiGridListSetItemText( GUIEditor.gridlist[1], Row, plrC, getPlayerName (whoSend), false, false )
setTimer ( deleteTheRow, 86400000, 0)
guiSetText (GUIEditor.edit[1], "")
end)

function deleteTheRow ()
guiGridListClear (GUIEditor.gridlist[1])
end
addEvent ("clearAds", true)
addEventHandler ("clearAds", root, deleteTheRow) 