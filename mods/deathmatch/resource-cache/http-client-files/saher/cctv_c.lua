rRoot = getResourceRootElement(getThisResource())
sw, sh = guiGetScreenSize()
cctvC = {}
cctvT = {}
localC = {}
localT = {}
playerMatrix = {}
viewList = {}
viewID = 0
localObject = false
localMarker = false
markerType = "cylinder"
wallcam = 2921
ceilcam = 1886
terminalModel = 2190
inMarker = false
offsets = {}
offsets.wallAngle = -53
offsets.wallZ = 0.225
offsets.wallLens = 1.03  
offsets.ceilAngle = -180
offsets.ceilZ = -0.525
offsets.ceilLens = 0.33
offsets.interference = 1
black = tocolor(0, 0, 0, 255)
white = tocolor(255, 255, 255, 255)
gray = tocolor(128, 128, 128, 255)
viewCamera = false
scan = "gfx/scanlines.png"
flicker = 1
camDist = 50
placing = false

addEventHandler("onClientResourceStart", rRoot, 
	function ()
    sw, sh = guiGetScreenSize()
    addEventHandler("onClientRender", getRootElement(), cctvView)
    
    -- error window
		cctvErrorWindow = guiCreateWindow(sw/2 - 200, sh/2 - 50, 400, 100, "Error!", false)
    cctvErrorText = guiCreateLabel(.1, .35, .94, .3, "Error:",true, cctvErrorWindow)
    cctvErrorClose = guiCreateButton(.3, .7, .4, .3, "OK", true, cctvErrorWindow)    
    guiLabelSetColor(cctvErrorText, 255, 5, 5)
    guiSetFont(cctvErrorText, "default-bold-small")
    guiWindowSetSizable(cctvErrorWindow, false)	
    guiSetVisible(cctvErrorWindow, false)
    
    -- camera view controls
    cctvControl = guiCreateWindow(sw-220, sh-150, 200, 130, "CCTV", false)
    guiWindowSetSizable(cctvControl, false)	
    cctvControlP = guiCreateButton(.05, .6, .25, .2, "<<<", true, cctvControl)    
    cctvControlQuit = guiCreateButton(.37, .6, .25, .2, "QUIT", true, cctvControl)    
    cctvControlN = guiCreateButton(.7, .6, .25, .2, ">>>", true, cctvControl)    
    guiSetFont(cctvControlQuit, "default-small")
    cctvControlPan = guiCreateScrollBar(.05, .2, .9, .15, true, true, cctvControl)
    cctvControlZoom = guiCreateScrollBar(.05, .4, .9, .15, true, true, cctvControl)
    cctvControlID = guiCreateLabel(.05,.83,.9,.1, "Info", true, cctvControl)
    guiSetFont(cctvControlID, "default-small")
    guiSetVisible(cctvControl, false)
    
    -- main setup window   
    cctvWindow = guiCreateWindow(sw/2-250, sh/2-160, 500, 320, "CCTV Setup", false)
    guiWindowSetSizable(cctvWindow, false)	
    cctvTabs = guiCreateTabPanel(0, .09, 1, .8, true, cctvWindow) 
    cctvSetup = guiCreateTab("Management", cctvTabs)  
    cctvAddCam = guiCreateTab("Add/Edit camera", cctvTabs)  
    cctvAddTerminal = guiCreateTab("Add/Edit terminal", cctvTabs)  
    cctvRR = guiCreateTab("Reset/Reload", cctvTabs)  
    cctvClose = guiCreateButton(.82, .9, .2, .1, "Close", true, cctvWindow)    
    cctvBB = guiCreateLabel(.03,.91,.6,.08, "Big Brother is watching you.", true, cctvWindow)
    guiLabelSetColor(cctvBB, 55, 55, 55)
    cctvClr = guiCreateButton(.67, .9, .14, .1, "Clear", true, cctvWindow)    
    
    -- Management tab
    guiSetFont(guiCreateLabel(.03,.03,.44,.07, "Terminals (doubleclick for cameras):", true, cctvSetup),"default-bold-small")
    guiSetFont(guiCreateLabel(.53,.03,.44,.07, "Cameras (doubleclick to view all):", true, cctvSetup),"default-bold-small")
    cctvTList = guiCreateGridList(.03, .1, .44, .75, true, cctvSetup)
    cctvTListName = guiGridListAddColumn(cctvTList, "Terminal ID", .6)
    cctvTListCams = guiGridListAddColumn(cctvTList, "Cams", .31)
    cctvCList = guiCreateGridList(.53, .1, .44, .75, true, cctvSetup)
    cctvCListName = guiGridListAddColumn(cctvCList, "Camera ID", .5)
    cctvCListTerminal = guiGridListAddColumn(cctvCList, "Connected to", .41)
    guiSetFont(cctvTList,"default-small")
    guiSetFont(cctvCList,"default-small")
    cctvFreeCams = guiCreateButton(.47, .1, .055, .22, "---", true, cctvSetup)    
    cctvCamList = guiCreateButton(.47, .33, .055, .22, "All", true, cctvSetup)    
    cctvConnect = guiCreateButton(.47, .56, .055, .22, "<<", true, cctvSetup)    
    guiSetFont(cctvPort,"default-small")
    cctvTDelete = guiCreateButton(.03, .87, .11, .1, "Delete", true, cctvSetup)    
    cctvTView = guiCreateButton(.15, .87, .1, .1, "View", true, cctvSetup)    
    cctvTEdit = guiCreateButton(.26, .87, .1, .1, "Edit", true, cctvSetup)    
    cctvPort = guiCreateButton(.37, .87, .1, .1, "Port", true, cctvSetup)    
    cctvCDelete = guiCreateButton(.53, .87, .14, .1, "Delete", true, cctvSetup)    
    cctvCDisc = guiCreateButton(.68, .87, .14, .1, "Disconnect", true, cctvSetup)    
    cctvCEdit = guiCreateButton(.83, .87, .14, .1, "Edit", true, cctvSetup)    
    
    -- Add camera tab
    guiSetFont(guiCreateLabel(.03,.04,.22,.06, "Camera ID:", true, cctvAddCam),"default-small")
    cctvAddCamName = guiCreateEdit(.03, .1, .22, .1, "", true, cctvAddCam)
    guiEditSetMaxLength(cctvAddCamName, 10)
    guiSetFont(guiCreateLabel(.25,.04,.22,.06, "Terminal ID (optional):", true, cctvAddCam),"default-small")
    cctvAddCamTerminal = guiCreateEdit(.25, .1, .22, .1, "", true, cctvAddCam)
    guiEditSetMaxLength(cctvAddCamTerminal, 10)
    guiSetFont(guiCreateLabel(.03,.22,.4,.06, "Camera options:", true, cctvAddCam),"default-bold-small")
    cctvAddCamMotor = guiCreateCheckBox(.03,.28,.22,.1, "Motorized", false, true, cctvAddCam)
    cctvAddCamZoom = guiCreateCheckBox(.25,.28,.22,.1, "Zoom enabled", false, true, cctvAddCam)
    cctvAddCamIR = guiCreateCheckBox(.03,.36,.22,.1, "Thermal (IR)", false, true, cctvAddCam)
    cctvAddCamNight = guiCreateCheckBox(.25,.36,.22,.1, "Nightvision", false, true, cctvAddCam)
    guiSetEnabled(cctvAddCamIR, false)    
    guiSetEnabled(cctvAddCamNight, false)    
    
    -- 1.1 begin: need to remove this when 1.1 released and thermal/night vision implemented
    cctvNote11 = guiCreateLabel(.03,.44,.44,.05, "* thermal/nightvision setting reserved for MTA 1.1", true, cctvAddCam)
    guiSetFont(cctvNote11,"default-small")
    guiLabelSetColor(cctvNote11, 111, 111, 111)
    -- 1.1 end

    guiSetFont(guiCreateLabel(.03,.5,.4,.06, "Camera placement:", true, cctvAddCam),"default-bold-small")
    cctvWall = guiCreateRadioButton(.03, .55, .22, .1, "Wall mount",true,cctvAddCam)
    cctvCeiling = guiCreateRadioButton(.25, .55, .22, .1, "Ceiling mount",true,cctvAddCam)
    guiRadioButtonSetSelected(cctvWall, true)
    cctvAddCamX = guiCreateEdit(.03, .65, .11, .1, "", true, cctvAddCam)
    cctvAddCamY = guiCreateEdit(.14, .65, .11, .1, "", true, cctvAddCam)
    cctvAddCamZ = guiCreateEdit(.25, .65, .11, .1, "", true, cctvAddCam)
    cctvAddCamPlace = guiCreateButton(.36, .65, .11, .1, "Place", true, cctvAddCam)
    guiSetFont(guiCreateLabel(.03,.76,.44,.06, "* X/Y/Z of the camera, click 'Place' to place camera", true, cctvAddCam),"default-small")
    cctvAddCamLive = guiCreateCheckBox(.03,.85,.22,.1, "Setup live view", false, true, cctvAddCam)
    cctvAddCamSave = guiCreateButton(.25,.85,.22,.1, "SAVE CAMERA", true, cctvAddCam)
    guiSetFont(cctvAddCamSave, "default-bold-small")
    guiSetFont(guiCreateLabel(.95,.04,.1,.06, "U/D", true, cctvAddCam),"default-small")
    cctvAddCamUp = guiCreateScrollBar(.95, .1, .033, .86, false, true, cctvAddCam)
    guiSetFont(guiCreateLabel(.5,.04,.4,.06, "Scanlines RGB colorization:", true, cctvAddCam),"default-small")
    cctvAddCamR = guiCreateScrollBar(.5, .1, .44, .07, true, true, cctvAddCam)
    cctvAddCamG = guiCreateScrollBar(.5, .17, .44, .07, true, true, cctvAddCam)
    cctvAddCamB = guiCreateScrollBar(.5, .24, .44, .07, true, true, cctvAddCam)
    guiSetFont(guiCreateLabel(.5,.31,.4,.06, "Scanlines intensity:", true, cctvAddCam),"default-small")
    cctvAddCamS = guiCreateScrollBar(.5, .37, .44, .07, true, true, cctvAddCam)
    guiSetFont(guiCreateLabel(.5,.44,.4,.06, "Scanline size:", true, cctvAddCam),"default-small")
    cctvAddCamSS = guiCreateScrollBar(.5, .5, .44, .07, true, true, cctvAddCam)
    guiSetFont(guiCreateLabel(.5,.57,.4,.06, "Flicker level:", true, cctvAddCam),"default-small")
    cctvAddCamF = guiCreateScrollBar(.5, .63, .44, .07, true, true, cctvAddCam)
    guiSetFont(guiCreateLabel(.5,.7,.4,.06, "Field of View:", true, cctvAddCam),"default-small")
    cctvAddCamFov = guiCreateScrollBar(.5, .76, .44, .07, true, true, cctvAddCam)
    guiScrollBarSetScrollPosition(cctvAddCamFov, 90)
    guiSetFont(guiCreateLabel(.5,.83,.4,.06, "Horizontal angle:", true, cctvAddCam),"default-small")
    cctvAddCamPan = guiCreateScrollBar(.5, .89, .44, .07, true, true, cctvAddCam)

    
    guiSetFont(guiCreateLabel(.03,.04,.22,.06, "Terminal ID:", true, cctvAddTerminal),"default-small")
    cctvAddTerName = guiCreateEdit(.03, .1, .22, .1, "", true, cctvAddTerminal)
    guiEditSetMaxLength(cctvAddTerName, 10)
    guiSetFont(guiCreateLabel(.25,.04,.22,.06, "Password/Team/ACL:", true, cctvAddTerminal),"default-small")
    cctvAddTerAccess = guiCreateEdit(.25, .1, .22, .1, "", true, cctvAddTerminal)
    guiEditSetMaxLength(cctvAddTerAccess, 32)
    guiSetFont(guiCreateLabel(.03,.22,.4,.06, "Terminal access restriction:", true, cctvAddTerminal),"default-bold-small")
    cctvAddTerPublic = guiCreateRadioButton(.03,.28,.22,.1, "Public", true, cctvAddTerminal)
    cctvAddTerPass = guiCreateRadioButton(.25,.28,.22,.1, "by Password*", true, cctvAddTerminal)
    cctvAddTerTeam = guiCreateRadioButton(.03,.36,.22,.1, "by Team*", true, cctvAddTerminal)
    cctvAddTerAcl = guiCreateRadioButton(.25,.36,.22,.1, "by ACL Group*", true, cctvAddTerminal)
    guiRadioButtonSetSelected(cctvAddTerPublic, true)
    guiSetFont(guiCreateLabel(.03,.46,.44,.2, "* Don't forget to specify Password/Team/ACL in\nthe field above according to the selected option!", true, cctvAddTerminal),"default-small")
    guiSetFont(guiCreateLabel(.03,.83,.4,.06, "Rotation:", true, cctvAddTerminal),"default-small")
    cctvAddTerRot = guiCreateScrollBar(.03, .89, .44, .07, true, true, cctvAddTerminal)
    guiSetFont(guiCreateLabel(.03,.57,.4,.06, "Terminal placement:", true, cctvAddTerminal),"default-bold-small")
    cctvAddTerX = guiCreateEdit(.03, .65, .11, .1, "", true, cctvAddTerminal)
    cctvAddTerY = guiCreateEdit(.14, .65, .11, .1, "", true, cctvAddTerminal)
    cctvAddTerZ = guiCreateEdit(.25, .65, .11, .1, "", true, cctvAddTerminal)
    cctvAddTerPlace = guiCreateButton(.36, .65, .11, .1, "Place", true, cctvAddTerminal)
    guiSetFont(guiCreateLabel(.03,.76,.44,.06, "* X/Y/Z of the terminal, click 'Place' to place it", true, cctvAddTerminal),"default-small")
    guiSetFont(guiCreateLabel(.5,.04,.4,.06, "Terminal marker RGB color:", true, cctvAddTerminal),"default-small")
    cctvAddTerR = guiCreateScrollBar(.5, .1, .44, .07, true, true, cctvAddTerminal)
    cctvAddTerG = guiCreateScrollBar(.5, .17, .44, .07, true, true, cctvAddTerminal)
    cctvAddTerB = guiCreateScrollBar(.5, .24, .44, .07, true, true, cctvAddTerminal)
    guiSetFont(guiCreateLabel(.5,.31,.4,.06, "Marker opacity:", true, cctvAddTerminal),"default-small")
    cctvAddTerA = guiCreateScrollBar(.5, .37, .44, .07, true, true, cctvAddTerminal)
    guiScrollBarSetScrollPosition(cctvAddTerA, 50)
    cctvAddTerSave = guiCreateButton(.75,.85,.23,.1, "SAVE TERMINAL", true, cctvAddTerminal)
    cctvAddTerMView = guiCreateCheckBox(.5,.85,.22,.1, "Preview marker", false, true, cctvAddTerminal)
    guiSetFont(cctvAddTerSave, "default-bold-small")
    
    -- Reset tab
    cctvRReload = guiCreateButton(.03,.85,.46,.1, "Reload everything from DB", true, cctvRR)
    cctvRReset = guiCreateButton(.51,.85,.46,.1, "Reset/delete everything", true, cctvRR)
    
    guiSetVisible(cctvWindow, false)
    
    addEventHandler("onClientGUIScroll", source, 
      function(bar)
        if bar == cctvAddCamR then localC.r = guiScrollBarGetScrollPosition(cctvAddCamR)*2  
        elseif bar == cctvAddCamG then localC.g = guiScrollBarGetScrollPosition(cctvAddCamG)*2 
        elseif bar == cctvAddCamB then localC.b = guiScrollBarGetScrollPosition(cctvAddCamB)*2 
        elseif bar == cctvAddCamS then localC.scanlines = guiScrollBarGetScrollPosition(cctvAddCamS) 
        elseif bar == cctvAddCamF then localC.flicker = 1 + math.floor(guiScrollBarGetScrollPosition(cctvAddCamF)/10) 
        elseif bar == cctvAddCamSS then localC.scansize = guiScrollBarGetScrollPosition(cctvAddCamSS)*5 
        elseif bar == cctvAddCamFov then
          localC.fov = 20+guiScrollBarGetScrollPosition(cctvAddCamFov)
          if viewCamera then updateCam() end
        elseif bar == cctvAddCamUp then
          localC.height = guiScrollBarGetScrollPosition(cctvAddCamUp)
          if viewCamera then updateCam() end
        elseif bar == cctvAddCamPan then
          localC.angle = math.floor(guiScrollBarGetScrollPosition(cctvAddCamPan)*3.6)
          local offA = 0
          if localC.type == wallcam then offA = offsets.wallAngle
          else offA = offsets.ceilAngle end
          if localObject and isElement(localObject) then setElementRotation(localObject, 0, 0, offA - localC.angle) end
          if viewCamera then updateCam() end
        elseif bar == cctvControlZoom then cctvController("zoom")
        elseif bar == cctvControlPan then cctvController("pan")
        elseif bar == cctvAddTerRot then 
          localT.rz = math.floor(guiScrollBarGetScrollPosition(cctvAddTerRot)*3.6)
          if localObject and isElement(localObject) then setElementRotation(localObject, 0, 0, localT.rz) end
          if localMarker and isElement(localMarker) then
            local mx, my = getRotation(localT.x, localT.y, 0.7, 195 - localT.rz)      
            setElementPosition(localMarker, mx, my, localT.z-0.5)
          end
        elseif bar == cctvAddTerR then 
          localT.mr = math.floor(guiScrollBarGetScrollPosition(cctvAddTerR)*2.5) 
          if isElement(localMarker) then setMarkerColor(localMarker, localT.mr, localT.mg, localT.mb, localT.ma) end
        elseif bar == cctvAddTerG then 
          localT.mg = math.floor(guiScrollBarGetScrollPosition(cctvAddTerG)*2.5) 
          if isElement(localMarker) then setMarkerColor(localMarker, localT.mr, localT.mg, localT.mb, localT.ma) end
        elseif bar == cctvAddTerB then 
          localT.mb = math.floor(guiScrollBarGetScrollPosition(cctvAddTerB)*2.5) 
          if isElement(localMarker) then setMarkerColor(localMarker, localT.mr, localT.mg, localT.mb, localT.ma) end
        elseif bar == cctvAddTerA then 
          localT.ma = math.floor(guiScrollBarGetScrollPosition(cctvAddTerA)*2.5) 
          if isElement(localMarker) then setMarkerColor(localMarker, localT.mr, localT.mg, localT.mb, localT.ma) end
        end  
      end
    )
    addEventHandler("onClientGUIClick", source,
			function(button, state)
				if source == cctvErrorClose then guiSetVisible(cctvErrorWindow, false)
        elseif source == cctvRReload then sendServer(true, "dbreload")
        elseif source == cctvRReset then sendServer(true, "dbreset")
				elseif source == cctvControlQuit then cctvController("close")
				elseif source == cctvControlP then cctvController("prev")
				elseif source == cctvControlN then cctvController("next")
        elseif source == cctvClr then cctvGUIClear()
				elseif source == cctvClose then 
          toggleCCTV(false)
          if guiCheckBoxGetSelected(cctvAddCamLive) then cctvSetLiveView("EDIT", false) end
          cctvGUIClear()
        elseif source == cctvCDelete then
          local cid = guiGridListGetItemText(cctvCList, guiGridListGetSelectedItem(cctvCList), 1)   
          if cid and cctvC[cid] then sendServer(true, "delcam", cid) end
        elseif source == cctvTDelete then
          local tid = guiGridListGetItemText(cctvTList, guiGridListGetSelectedItem(cctvTList), 1)   
          if tid and cctvT[tid] then sendServer(true, "delterm", tid) end
        elseif source == cctvCEdit then
          local cid = guiGridListGetItemText(cctvCList, guiGridListGetSelectedItem(cctvCList), 1)   
          if cid and cctvC[cid] then
            localC = nil
            localC = table.copy(cctvC[cid])
            localToGUI()
            guiSetSelectedTab(cctvTabs,cctvAddCam)
          end
        elseif source == cctvConnect then
          local tid = guiGridListGetItemText(cctvTList, guiGridListGetSelectedItem(cctvTList), 1)   
          local cid = guiGridListGetItemText(cctvCList, guiGridListGetSelectedItem(cctvCList), 1)   
          if (cid ~= "") and (tid ~= "") then sendServer(true, "c2t", cid, tid) end
        elseif source == cctvPort then
          local tid = guiGridListGetItemText(cctvTList, guiGridListGetSelectedItem(cctvTList), 1)   
          if tid and (tid ~= "") then 
            sendServer(true, "port2t", tid) 
          end  
        elseif source == cctvCDisc then
          local cid = guiGridListGetItemText(cctvCList, guiGridListGetSelectedItem(cctvCList), 1)   
          if cid and cid ~= "" then sendServer(true, "c2t", cid, "--------") end
        elseif source == cctvFreeCams then
          cctvListRefresh("--------")
        elseif source == cctvCamList then
          cctvListRefresh("--------", true)
				elseif source == cctvTView then 
          local tid = guiGridListGetItemText(cctvTList, guiGridListGetSelectedItem(cctvTList), 1)      
          if tid and cctvT[tid] then
            viewList = nil
            viewList = {}
            for id, cam in pairs(cctvC) do
              if cam.terminal == tid then table.insert(viewList, id) end
            end  
            if #viewList > 0 then
              cctvSetLiveView("VIEW", true, viewList[1])
              toggleCCTV(false)
              cctvController("open", viewList[1])
              if guiCheckBoxGetSelected(cctvAddCamLive) then cctvSetLiveView("EDIT", false) end
              if isElement(localObject) then destroyElement(localObject) end            
            end  
          end  
        elseif source == cctvTEdit then
          local tid = guiGridListGetItemText(cctvTList, guiGridListGetSelectedItem(cctvTList), 1)   
          if tid and cctvT[tid] then
            localT = nil
            localT = table.copy(cctvT[tid])
            localToGUI(tid)
            guiSetSelectedTab(cctvTabs,cctvAddTerminal)
          end
        elseif source == cctvAddCamLive then
          cctvSetLiveView("EDIT", guiCheckBoxGetSelected(cctvAddCamLive))
        elseif source == cctvAddCamSave then
          if guiCheckBoxGetSelected(cctvAddCamLive) then cctvSetLiveView("EDIT", false) end
          if guiToLocal() then 
            sendServer(true, "savecam", localC.name, localC)
            guiSetSelectedTab(cctvTabs,cctvSetup)
            if isElement(localObject) then destroyElement(localObject) end
          else cctvError("Not enough parameters to save camera!")
          end
        elseif source == cctvAddTerSave then
          if guiToLocal(true) then 
            sendServer(true, "saveterm", localT.name, localT)
            guiSetSelectedTab(cctvTabs,cctvSetup)
            if isElement(localObject) then destroyElement(localObject) end
            if isElement(localMarker) then destroyElement(localMarker) end
            if guiCheckBoxGetSelected(cctvAddTerMView) then guiCheckBoxSetSelected(cctvAddTerMView, false) end
          else cctvError("Not enough parameters to save terminal!")
          end
        elseif source == cctvWall then
          if guiRadioButtonGetSelected(cctvWall) then localC.type = wallcam end
        elseif source == cctvCeiling then
          if guiRadioButtonGetSelected(cctvCeiling) then localC.type = ceilcam end
        elseif source == cctvAddCamPlace and state == "up" then
          if placing then 
            guiSetText(cctvAddCamPlace, "Place")
            guiSetInputEnabled(true)
            placing = false
          else 
            local x,y,z = getElementPosition(getLocalPlayer())
            local model = wallcam
            if guiRadioButtonGetSelected(cctvCeiling) then model = ceilcam end
            if isElement(localObject) then destroyElement(localObject) end
            localObject = createObject(model, x, y, z)
            setElementInterior(localObject, getCameraInterior())
            guiSetText(cctvAddCamPlace, "---")
            guiSetInputEnabled(false)
            guiSetVisible(cctvWindow,false)
            placing = true
          end
        elseif source == cctvAddTerPlace and state == "up" then
          if placing then 
            guiSetText(cctvAddTerPlace, "Place")
            guiSetInputEnabled(true)
            placing = false
          else 
            local x,y,z = getElementPosition(getLocalPlayer())
            if isElement(localObject) then destroyElement(localObject) end
            localObject = createObject(terminalModel, x, y, z-100)
            setElementInterior(localObject, getCameraInterior())
            setElementCollisionsEnabled(localObject, false)
            guiSetText(cctvAddTerPlace, "---")
            guiSetInputEnabled(false)
            guiSetVisible(cctvWindow,false)
            placing = "terminal"
          end
        elseif source == cctvAddTerMView then
          if guiCheckBoxGetSelected(cctvAddTerMView) and guiToLocal(true) then
            if localMarker and isElement(localMarker) then destroyElement(localMarker) end
            local mx, my = getRotation(localT.x, localT.y, 0.7, 195 - localT.rz)      
            localMarker = createMarker(mx, my, localT.z-0.5, markerType, 2, localT.mr, localT.mg, localT.mb, localT.ma)
            setElementInterior(localMarker, getCameraInterior())
          else 
            if localMarker and isElement(localMarker) then destroyElement(localMarker) end
          end
        end
      end
    ) 
    addEventHandler("onClientGUIDoubleClick", source,
      function()
				if source == cctvCList then 
          local cid = guiGridListGetItemText(cctvCList, guiGridListGetSelectedItem(cctvCList), 1)      
          if cid and cctvC[cid] then
            viewList = nil
            viewList = {}
            for id, cam in pairs(cctvC) do
              table.insert(viewList, id)
            end  
            cctvSetLiveView("VIEW", true, cid)
            toggleCCTV(false)
            cctvController("open", cid)
            if guiCheckBoxGetSelected(cctvAddCamLive) then cctvSetLiveView("EDIT", false) end
            if isElement(localObject) then destroyElement(localObject) end            
          end  
				elseif source == cctvTList then 
          local tid = guiGridListGetItemText(cctvTList, guiGridListGetSelectedItem(cctvTList), 1)      
          if tid and cctvT[tid] then
            cctvListRefresh(tid)
          end
        end   
      end
    )      
  end
)  

addEventHandler("onClientGUITabSwitched", getRootElement(), 
  function(tab)
    if tab ~= cctvAddCam then
      if guiCheckBoxGetSelected(cctvAddCamLive) then cctvSetLiveView("EDIT", false) end
    end  
    if tab ~= cctvAddTerminal then
      if isElement(localMarker) then destroyElement(localMarker) end
      if guiCheckBoxGetSelected(cctvAddTerMView) then guiCheckBoxSetSelected(cctvAddTerMView, false) end
    end  
  end
)

function guiToLocal(terminal)
  if terminal then
    localT.name = idFormat(guiGetText(cctvAddTerName), true) 
    guiSetText(cctvAddTerName, localT.name)
    if not guiGetText(cctvAddTerX) or guiGetText(cctvAddTerX) == "" then return false end
    localT.mr = math.floor(guiScrollBarGetScrollPosition(cctvAddTerR)*2.5)
    localT.mg = math.floor(guiScrollBarGetScrollPosition(cctvAddTerG)*2.5)
    localT.mb = math.floor(guiScrollBarGetScrollPosition(cctvAddTerB)*2.5)
    localT.ma = math.floor(guiScrollBarGetScrollPosition(cctvAddTerA)*2.5)
    localT.x = tonumber(guiGetText(cctvAddTerX)) 
    localT.y = tonumber(guiGetText(cctvAddTerY)) 
    localT.z = tonumber(guiGetText(cctvAddTerZ)) 
    localT.rz = math.floor(guiScrollBarGetScrollPosition(cctvAddTerRot)*3.6)
    if not localT.interior then localT.interior = getCameraInterior() end
    localT.restricted = 0
    if guiRadioButtonGetSelected(cctvAddTerPass) then localT.restricted = 1 
    elseif guiRadioButtonGetSelected(cctvAddTerTeam) then localT.restricted = 2 
    elseif guiRadioButtonGetSelected(cctvAddTerAcl) then localT.restricted = 3 
    end
    localT.access = tostring(cctvEscape(guiGetText(cctvAddTerAccess)))
    if not localT.access or localT.access == "" then 
      if localT.restricted ~= 0 then return false end
    end
    guiSetText(cctvAddTerAccess, localT.access)
    localT.camcount = 0  
    return true
  else
    localC.name = idFormat(guiGetText(cctvAddCamName))
    guiSetText(cctvAddCamName, localC.name)
    if guiRadioButtonGetSelected(cctvWall) then localC.type = wallcam
    else localC.type = ceilcam end
    localC.terminal = setCamTerminal(guiGetText(cctvAddCamTerminal))
    guiSetText(cctvAddCamTerminal, localC.terminal)
    if not guiGetText(cctvAddCamX) or guiGetText(cctvAddCamX) == "" then return false end
    localC.x = tonumber(guiGetText(cctvAddCamX))
    localC.y = tonumber(guiGetText(cctvAddCamY))
    localC.z = tonumber(guiGetText(cctvAddCamZ))
    if not localC.interior then localC.interior = getCameraInterior() end
    localC.angle = math.floor(guiScrollBarGetScrollPosition(cctvAddCamPan)*3.6)
    localC.height = guiScrollBarGetScrollPosition(cctvAddCamUp)
    localC.fov = 20+guiScrollBarGetScrollPosition(cctvAddCamFov)
    localC.r = guiScrollBarGetScrollPosition(cctvAddCamR)*2
    localC.g = guiScrollBarGetScrollPosition(cctvAddCamG)*2
    localC.b = guiScrollBarGetScrollPosition(cctvAddCamB)*2
    localC.scanlines = guiScrollBarGetScrollPosition(cctvAddCamS)
    localC.scansize = guiScrollBarGetScrollPosition(cctvAddCamSS)*5
    localC.flicker = 1 + math.floor(guiScrollBarGetScrollPosition(cctvAddCamF)/10)
    localC.zoom = 0
    if guiCheckBoxGetSelected(cctvAddCamZoom) then localC.zoom = 1 end
    localC.motor = 0
    if guiCheckBoxGetSelected(cctvAddCamMotor) then localC.motor = 1 end
    return true
  end  
end

function localToGUI(terminal)
  if terminal then
    guiSetText(cctvAddTerName, localT.name)
    guiScrollBarSetScrollPosition(cctvAddTerR, math.ceil(localT.mr/2.5))
    guiScrollBarSetScrollPosition(cctvAddTerG, math.ceil(localT.mg/2.5))
    guiScrollBarSetScrollPosition(cctvAddTerB, math.ceil(localT.mb/2.5))
    guiScrollBarSetScrollPosition(cctvAddTerA, math.ceil(localT.ma/2.5))
    guiSetText(cctvAddTerX, localT.x) 
    guiSetText(cctvAddTerY, localT.y) 
    guiSetText(cctvAddTerZ, localT.z) 
    guiScrollBarSetScrollPosition(cctvAddTerRot, math.ceil(localT.rz/3.6))
    if localT.restricted == 0 then guiRadioButtonSetSelected(cctvAddTerPublic, true) end
    if localT.restricted == 1 then guiRadioButtonSetSelected(cctvAddTerPass, true) end
    if localT.restricted == 2 then guiRadioButtonSetSelected(cctvAddTerTeam, true) end
    if localT.restricted == 3 then guiRadioButtonSetSelected(cctvAddTerAcl, true) end
    guiSetText(cctvAddTerAccess, tostring(localT.access)) 
  else
    guiSetText(cctvAddCamName, localC.name)
    if localC.type == wallcam then guiRadioButtonSetSelected(cctvWall, true)
    else guiRadioButtonSetSelected(cctvCeiling, true) end
    guiSetText(cctvAddCamTerminal, localC.terminal)
    guiSetText(cctvAddCamX, localC.x)
    guiSetText(cctvAddCamY, localC.y)
    guiSetText(cctvAddCamZ, localC.z)
    guiScrollBarSetScrollPosition(cctvAddCamPan, math.ceil(localC.angle/3.6))
    guiScrollBarSetScrollPosition(cctvAddCamUp, localC.height)
    guiScrollBarSetScrollPosition(cctvAddCamFov, localC.fov-20)
    guiScrollBarSetScrollPosition(cctvAddCamR, math.floor(localC.r/2))
    guiScrollBarSetScrollPosition(cctvAddCamG, math.floor(localC.g/2))
    guiScrollBarSetScrollPosition(cctvAddCamB, math.floor(localC.b/2))
    guiScrollBarSetScrollPosition(cctvAddCamS, localC.scanlines)
    guiScrollBarSetScrollPosition(cctvAddCamSS, math.floor(localC.scansize/5))
    guiScrollBarSetScrollPosition(cctvAddCamF, math.floor(localC.flicker*10)-1)
    if tonumber(localC.zoom) == 1 then guiCheckBoxSetSelected(cctvAddCamZoom, true) 
    else guiCheckBoxSetSelected(cctvAddCamZoom, false) end
    if tonumber(localC.motor) == 1 then guiCheckBoxSetSelected(cctvAddCamMotor, true) 
    else guiCheckBoxSetSelected(cctvAddCamMotor, false) end
  end  
end

function cctvGUIClear()
  guiSetText(cctvAddTerName, "")
  guiSetText(cctvAddTerX, "") 
  guiSetText(cctvAddTerY, "") 
  guiSetText(cctvAddTerZ, "") 
  guiScrollBarSetScrollPosition(cctvAddTerRot, 1)
  guiScrollBarSetScrollPosition(cctvAddTerR, 1)
  guiScrollBarSetScrollPosition(cctvAddTerG, 80)
  guiScrollBarSetScrollPosition(cctvAddTerB, 80)
  guiScrollBarSetScrollPosition(cctvAddTerA, 50)
  guiCheckBoxSetSelected(cctvAddTerMView, false)
  guiRadioButtonSetSelected(cctvAddTerPublic, true)
  guiSetText(cctvAddTerAccess, "") 
  guiSetText(cctvAddCamName, "")
  guiRadioButtonSetSelected(cctvWall, true)
  guiSetText(cctvAddCamTerminal, "")
  guiSetText(cctvAddCamX, "")
  guiSetText(cctvAddCamY, "")
  guiSetText(cctvAddCamZ, "")
  guiScrollBarSetScrollPosition(cctvAddCamPan, 50)
  guiScrollBarSetScrollPosition(cctvAddCamUp, 50)
  guiScrollBarSetScrollPosition(cctvAddCamFov, 50)
  guiScrollBarSetScrollPosition(cctvAddCamR, 11)
  guiScrollBarSetScrollPosition(cctvAddCamG, 22)
  guiScrollBarSetScrollPosition(cctvAddCamB, 33)
  guiScrollBarSetScrollPosition(cctvAddCamS, 11)
  guiScrollBarSetScrollPosition(cctvAddCamSS, 1)
  guiScrollBarSetScrollPosition(cctvAddCamF, 1)
  guiCheckBoxSetSelected(cctvAddCamZoom, false)
  guiCheckBoxSetSelected(cctvAddCamMotor, false)
  localC = {}
  localT = {}
  if isElement(localMarker) then destroyElement(localMarker) end
  if isElement(localObject) then destroyElement(localObject) end
end

addCommandHandler("cctv", 
  function(cmd, action, id)
    sendServer(true, "gui")
  end
)

addCommandHandler("watch", 
  function(cmd, pass)
    sendServer(true, "viewterminal", inMarker, pass)
  end
)

addEventHandler("onClientClick", getRootElement(), 
  function(button, state, _, _, wx, wy, wz, element)
    if element and element ~= localObject and element ~= getLocalPlayer() then return false end
    if placing == "terminal" and button == "left" and state == "down" then
      guiSetText(cctvAddTerPlace, "Place")
      placing = false
      guiSetVisible(cctvWindow,true)
      guiSetInputEnabled(true)
      localT.x, localT.y, localT.z = wx, wy, wz
      guiSetText(cctvAddTerX, wx)
      guiSetText(cctvAddTerY, wy)
      guiSetText(cctvAddTerZ, wz)
    elseif placing and button == "left" and state == "down" then
      guiSetText(cctvAddCamPlace, "Place")
      placing = false
      guiSetVisible(cctvWindow,true)
      guiSetInputEnabled(true)
      localC.x, localC.y, localC.z = wx, wy, wz
      guiSetText(cctvAddCamX, wx)
      guiSetText(cctvAddCamY, wy)
      guiSetText(cctvAddCamZ, wz)
    elseif placing and button == "right" then
      guiSetText(cctvAddCamPlace, "Place")
      guiSetText(cctvAddTerPlace, "Place")
      placing = false
      guiSetVisible(cctvWindow,true)
      guiSetInputEnabled(true)
    end
  end
)  

addEventHandler("onClientCursorMove", getRootElement(), 
  function(_, _, sx, sy, wx, wy, wz)
    if placing and localObject then
      local px, py, pz = getCameraMatrix()
      local hit, x, y, z = processLineOfSight(px, py, pz, wx, wy, wz, true, false, false, false)
      if hit then setElementPosition(localObject, x, y, z)
      else setElementPosition(localObject, wx, wy, wz) end
    end  
  end
)  

function toggleCCTV(show)
  if placing then return false end  
  if show then
	  guiSetVisible(cctvWindow, true)
		guiBringToFront(cctvWindow)
		showCursor(true)
    guiSetInputEnabled(true)
	else 
	  guiSetVisible(cctvWindow, false)
		showCursor(false)
    guiSetInputEnabled(false)
	end
end

function cctvController(action, cam)
  if action == "open" and #viewList > 0 then
    viewID = 1
    if #viewList == 1 then 
      guiSetEnabled(cctvControlP, false)
      guiSetEnabled(cctvControlN, false)
    else
      guiSetEnabled(cctvControlP, true)
      guiSetEnabled(cctvControlN, true)
    end
    if cam then while viewList[viewID] ~= cam do viewID = viewID + 1 end end
    if cctvC[viewList[viewID]].motor == 1 then 
      guiSetEnabled(cctvControlPan, true)
      guiScrollBarSetScrollPosition(cctvControlPan, 50)
    else guiSetEnabled(cctvControlPan, false) end
    if cctvC[viewList[viewID]].zoom == 1 then 
      guiSetEnabled(cctvControlZoom, true)
      guiScrollBarSetScrollPosition(cctvControlZoom, cctvC[viewList[viewID]].fov-20)
    else guiSetEnabled(cctvControlZoom, false) end
    guiSetText(cctvControlID,"Terminal ID: "..cctvC[viewList[viewID]].terminal)
    guiSetText(cctvControl,"CCTV Camera ID: "..viewList[viewID])
	  guiSetVisible(cctvControl, true)
	  guiBringToFront(cctvControl)
		showCursor(true)
  elseif action == "next" then
    viewID = viewID + 1
    if viewID > #viewList then viewID = 1 end
    if cctvC[viewList[viewID]].motor == 1 then 
      guiSetEnabled(cctvControlPan, true)
      guiScrollBarSetScrollPosition(cctvControlPan, 50)
    else guiSetEnabled(cctvControlPan, false) end
    if cctvC[viewList[viewID]].zoom == 1 then 
      guiSetEnabled(cctvControlZoom, true)
      guiScrollBarSetScrollPosition(cctvControlZoom, cctvC[viewList[viewID]].fov-20)
    else guiSetEnabled(cctvControlZoom, false) end
    guiSetText(cctvControlID,"Terminal ID: "..cctvC[viewList[viewID]].terminal)
    guiSetText(cctvControl,"CCTV Camera ID: "..viewList[viewID])
    updateCam(viewList[viewID])
  elseif action == "prev" then
    viewID = viewID - 1
    if viewID < 1 then viewID = #viewList end
    if cctvC[viewList[viewID]].motor == 1 then 
      guiSetEnabled(cctvControlPan, true)
      guiScrollBarSetScrollPosition(cctvControlPan, 50)
    else guiSetEnabled(cctvControlPan, false) end
    if cctvC[viewList[viewID]].zoom == 1 then 
      guiSetEnabled(cctvControlZoom, true)
      guiScrollBarSetScrollPosition(cctvControlZoom, cctvC[viewList[viewID]].fov-20)
    else guiSetEnabled(cctvControlZoom, false) end
    guiSetText(cctvControlID,"Terminal ID: "..cctvC[viewList[viewID]].terminal)
    guiSetText(cctvControl,"CCTV Camera ID: "..viewList[viewID])
    updateCam(viewList[viewID])
  elseif action == "zoom" then
    if localC.zoom == 1 then 
      localC.fov = 20+guiScrollBarGetScrollPosition(cctvControlZoom)
      if viewCamera then updateCam() end
    end  
  elseif action == "pan" then
    if localC.motor == 1 then 
      local angle = 50-guiScrollBarGetScrollPosition(cctvControlPan)
      localC.angle = cctvC[viewList[viewID]].angle - angle
      if viewCamera then updateCam() end
    end
  elseif action == "close" then
    viewID = 0
    viewList = {}
    localC = {}
    cctvSetLiveView("VIEW", false)
    guiSetVisible(cctvControl, false)
		showCursor(false)
	end
end

function cctvSetLiveView(view, on, cid)
  if view == "EDIT" then
    if not guiToLocal() then 
      cctvError("Not enough parameters for live view, place camera first.")
      guiCheckBoxSetSelected(cctvAddCamLive, false)
      return false 
    end 
    if on then
      sendServer(true, "editcam")
      guiSetEnabled(cctvAddCamPlace, false)    
    else 
      sendServer(true, "editcam", "exit unfreeze")
      viewCamera = false 
      switchCam("player")
      guiSetEnabled(cctvAddCamPlace, true)  
      guiCheckBoxSetSelected(cctvAddCamLive, false)      
    end
  elseif view == "VIEW" then
    if on then
      sendServer(true, "viewcam", cid)
    else
      sendServer(true, "viewcam", "exit unfreeze")
      viewCamera = false 
      switchCam("player")
    end   
  end  
end

function switchCam(to,cid)
  if to == "cctv" then
    playerMatrix.x, playerMatrix.y, playerMatrix.z, playerMatrix.tx, playerMatrix.ty, playerMatrix.tz, playerMatrix.roll, playerMatrix.fov = getCameraMatrix()
    playerMatrix.interior = getElementInterior(getLocalPlayer())
    playerMatrix.px, playerMatrix.py, playerMatrix.pz = getElementPosition(getLocalPlayer())
    updateCam(cid)
  else
    setCameraMatrix(playerMatrix.x, playerMatrix.y, playerMatrix.z, playerMatrix.tx, playerMatrix.ty, playerMatrix.tz, playerMatrix.roll, playerMatrix.fov)
    setCameraInterior(playerMatrix.interior)
    setElementInterior(getLocalPlayer(), playerMatrix.interior, playerMatrix.px, playerMatrix.py, playerMatrix.pz)
    setCameraTarget(getLocalPlayer())    
  end  
end

function updateCam(cid)
  if cid and cctvC[cid] then localC = table.copy(cctvC[cid]) end
  local offZ = 0
  local offL = 0
  if localC.type == wallcam then
    offZ = offsets.wallZ
    offL = offsets.wallLens
  else 
    offZ = offsets.ceilZ
    offL = offsets.ceilLens
  end
  local tx, ty = getRotation(localC.x, localC.y, camDist, localC.angle)
  local lx, ly = getRotation(localC.x, localC.y, offL, localC.angle)
  if localC.interior ~= getElementInterior(getLocalPlayer()) then setElementInterior(getLocalPlayer(),localC.interior) end
  if getCameraInterior() ~= localC.interior then setCameraInterior(localC.interior) end
  offsets.zone = cctvZone(getZoneName(localC.x, localC.y, localC.z))
  setCameraMatrix(lx, ly, localC.z + offZ, tx, ty, (40 - localC.height) + localC.z, 0, localC.fov)
end

function sendServer(admin, action, id, data)
  local event = "cctvGate"
  -- if admin then event = "cctvAdminGate" end -- redundant
  triggerServerEvent(event, getLocalPlayer(), action, id, data)
end

function cctvListRefresh(tid, allcams)
  if tid then
    guiGridListClear(cctvCList)
    for id,cam in pairs(cctvC) do
      if cam.terminal == tid then
        local row = guiGridListAddRow(cctvCList)
        guiGridListSetItemText(cctvCList, row, cctvCListName, id, false, false)
        guiGridListSetItemText(cctvCList, row, cctvCListTerminal, cam.terminal, false, false)
      elseif allcams then 
        local row = guiGridListAddRow(cctvCList)
        guiGridListSetItemText(cctvCList, row, cctvCListName, id, false, false)
        guiGridListSetItemText(cctvCList, row, cctvCListTerminal, cam.terminal, false, false)
      end  
    end
  else
    guiGridListClear(cctvTList)
    guiGridListClear(cctvCList)
    for id,trm in pairs(cctvT) do
      local row = guiGridListAddRow(cctvTList)
      guiGridListSetItemText(cctvTList, row, cctvTListName, id, false, false)
      guiGridListSetItemText(cctvTList, row, cctvTListCams, tostring(trm.camcount), false, false)
      --outputChatBox(trm.camcount)
    end
    for id,cam in pairs(cctvC) do
      local row = guiGridListAddRow(cctvCList)
      guiGridListSetItemText(cctvCList, row, cctvCListName, id, false, false)
      guiGridListSetItemText(cctvCList, row, cctvCListTerminal, cam.terminal, false, false)
    end
  end  
end  

addEvent("cctvListUpdate", true)
addEventHandler("cctvListUpdate", getRootElement(), 
  function(ts,cs)
    cctvT = ts
    cctvC = cs
    cctvListRefresh()
  end
)  

addEvent("cctvOpen", true)
addEventHandler("cctvOpen", getRootElement(), 
  function()
	  guiSetVisible(cctvWindow, true)
		guiBringToFront(cctvWindow)
		showCursor(true)
    guiSetInputEnabled(true)
  end
)  

addEvent("cctvCamData", true)
addEventHandler("cctvCamData", getRootElement(), 
  function(camData, mode)
    if mode == "VIEWTERMINAL" then
      viewList = camData
      viewCamera = "VIEW"
      cctvController("open", viewList[1])    
      switchCam("cctv", viewList[1])
    else
      if camData then localC = camData end
      viewCamera = mode
      switchCam("cctv")
    end  
  end
)  

addEventHandler("onClientMarkerHit", getRootElement(), 
  function()
    if getElementData(source,"cctv.tid") then inMarker = getElementData(source,"cctv.tid") end
  end
)  

addEventHandler("onClientMarkerLeave", getRootElement(), 
  function()
    if getElementData(source,"cctv.tid") then inMarker = false end
  end
)  

function idFormat(text, terminal)
  local id = string.gsub(text, "%D", "")
  text = string.gsub(text, "%A", "")
  if text == "" then 
    if terminal then text = "TM" 
    else text = "CM" end
    id = math.random(100000,999999)
    while cctvT["TM"..id] or cctvC["CM"..id] do
      id = math.random(100000,999999)
    end
  end
  return string.upper(text)..id
end

function setCamTerminal(terminal)
  if not terminal or terminal == "" then return "--------" end
  terminal = string.upper(terminal)
  if not cctvT[terminal] then return "--------" end
  return terminal
end

function getTimeStamp()
  local timeT = getRealTime()  
  local hh = timeT.hour
  local mm = timeT.minute
  local ss = timeT.second
  if ss < 10 then ss = tostring("0" .. ss) end
  if mm < 10 then mm = tostring("0" .. mm) end
  if hh < 10 then hh = tostring("0" .. hh) end
  return hh..":"..mm..":"..ss
end

function getDateStamp()
  local timeT = getRealTime()  
  local fday = timeT.monthday
  if fday < 10 then fday = "0"..fday end
  local fmonth = 1 + timeT.month
  if fmonth < 10 then fmonth = "0"..fmonth end
  local fyear = timeT.year - 100
  return fday.."/"..fmonth.."/"..fyear
end

function table.copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

function cctvEscape(text)
  text = string.gsub(text, "\'", "")
  text = string.gsub(text, "\"", "")
  text = string.gsub(text, "\`", "")
  text = string.gsub(text, " ", "")
  return text
end

function getRotation(x, y, dist, angle)
  local a = math.rad(90 - angle)
  local dx = math.cos(a) * dist
  local dy = math.sin(a) * dist
  return x+dx, y+dy
end

function cctvZone(zone)
  zone = string.gsub(string.upper(zone)," ","")
  if string.len(zone) > 16 then zone = string.sub(zone, 1, 16) end
  return zone
end


function cctvError(txt)
  guiSetText(cctvErrorText, txt)
  guiSetVisible(cctvErrorWindow, true)
  guiBringToFront(cctvErrorWindow)
end

function cctvView()
  if viewCamera then
    flicker = 0 - flicker
    local tx,ty = sw/2, sh-100
    if offsets.interference > sh then offsets.interference = 0 - (87+localC.scansize/5) end
    offsets.interference = offsets.interference + 1 + localC.scansize/100
    --dxDrawRectangle(tx-300, ty, 600, 33, black)
    --dxDrawRectangle(tx-300, ty+42, 600, 33, black)
    dxDrawImage(tx-313, ty+25, 626, 49, "gfx/tcrbg.png", 0, 0, 0, black)  
    if viewCamera == "EDIT" then dxDrawText("EDIT", tx+256, ty+29, sw, sh, tocolor(255, 20, 20, 255), 1.2, "default-bold")
    else dxDrawText("VIEW", tx+254, ty+29, sw, sh, white, 1.2, "default-bold") end
    dxDrawText("TERMINAL ID: "..localC.terminal, tx-295, ty+29, sw, sh, white, 1.2, "default-bold")
    dxDrawText("ZONE: "..offsets.zone, tx-10, ty+29, sw, sh, white, 1.2, "default-bold") 
    dxDrawText(localC.name, tx-295, ty+44, sw, sh, white, 2, "default-bold")
    if not localC.motor or localC.motor == 1 then dxDrawText("R="..localC.angle, tx-100, ty+44, sw, sh, white, 2, "default-bold")
    else dxDrawText("R="..localC.angle, tx-100, ty+44, sw, sh, gray, 2, "default-bold") end
    --dxDrawText("HGT "..(100-localC.height), tx-160, ty+44, sw, sh, gray, 2, "default-bold")
    if not localC.zoom or localC.zoom == 1 then dxDrawText("F="..localC.fov, tx-11, ty+44, sw, sh, white, 2, "default-bold")
    else dxDrawText("F="..localC.fov, tx-11, ty+44, sw, sh, gray, 2, "default-bold") end
    dxDrawText(getTimeStamp(), tx+190, ty+44, sw, sh, white, 2, "default-bold")
    dxDrawText(getDateStamp(), tx+80, ty+44, sw, sh, white, 2, "default-bold")
    
    dxDrawImage(0, offsets.interference, sw, 87+localC.scansize/5, "gfx/line.png", 0, 0, 0, tocolor(50+localC.r, 50+localC.g, 50+localC.b, 20+localC.scanlines+(flicker*localC.flicker)))  
    dxDrawImage(0, 0-localC.scansize, sw, sh+localC.scansize, scan, 0, 0, 0, tocolor(50+localC.r, 50+localC.g, 50+localC.b, 50+localC.scanlines+(flicker*localC.flicker)))  
  end  
end