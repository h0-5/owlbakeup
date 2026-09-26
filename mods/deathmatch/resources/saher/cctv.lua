rRoot = getResourceRootElement(getThisResource())
cctvT = {}
cctvC = {}
cctvO = {}
playerG = {}
wallcam = 2921
ceilcam = 1886
unfreezeDelay = 500
markerType = "cylinder"
offsets = {}
offsets.wallAngle = -53
offsets.wallZ = 0.225
offsets.wallLens = 1.03  
offsets.ceilAngle = -180
offsets.ceilZ = -0.525
offsets.ceilLens = 0.33

function cctvInit()
  cctvDB("create")
  cctvDB("load")
  cctvSpawn("camera", "_all")
  cctvSpawn("terminal", "_all")
end

function cctvDB(action, id, data)
  if action == "create" then
    executeSQLCreateTable("cctvcameras", "name TEXT, type INTEGER, terminal TEXT, loc TEXT, interior INTEGER, target TEXT, color TEXT, scan TEXT, zoom BOOL, motor BOOL")
    executeSQLCreateTable("cctvterminals", "name TEXT, loc TEXT, interior INTEGER, restricted INTEGER, access TEXT")   
  elseif action == "load" then
    local term = executeSQLSelect("cctvterminals", "name, loc, interior, restricted, access")
    cctvT = nil
    cctvC = nil
    cctvT = {}
    cctvC = {}
    if #term > 0 then
      for id,terminal in ipairs(term) do
        cctvT[terminal.name] = {}
        cctvT[terminal.name].name = terminal.name
        cctvT[terminal.name].x = tonumber(gettok(terminal.loc,1,32)) 
        cctvT[terminal.name].y = tonumber(gettok(terminal.loc,2,32)) 
        cctvT[terminal.name].z = tonumber(gettok(terminal.loc,3,32)) 
        cctvT[terminal.name].rz = tonumber(gettok(terminal.loc,4,32)) 
        cctvT[terminal.name].mr = tonumber(gettok(terminal.loc,5,32)) or 1
        cctvT[terminal.name].mg = tonumber(gettok(terminal.loc,6,32)) or 200
        cctvT[terminal.name].mb = tonumber(gettok(terminal.loc,7,32)) or 200
        cctvT[terminal.name].ma = tonumber(gettok(terminal.loc,8,32)) or 127
        cctvT[terminal.name].interior = tonumber(terminal.interior)
        cctvT[terminal.name].restricted = tonumber(terminal.restricted)
        cctvT[terminal.name].access = tostring(terminal.access)
        cctvT[terminal.name].camcount = 0
      end
    end    
    local cams = executeSQLSelect("cctvcameras", "name, type, terminal, loc, interior, target, color, scan, zoom, motor")
    if #cams > 0 then
      for id,camera in ipairs(cams) do
        cctvC[camera.name] = {}
        cctvC[camera.name].name = camera.name
        cctvC[camera.name].type = tonumber(camera.type) 
        cctvC[camera.name].terminal = camera.terminal
        cctvC[camera.name].x = tonumber(gettok(camera.loc,1,32))
        cctvC[camera.name].y = tonumber(gettok(camera.loc,2,32))
        cctvC[camera.name].z = tonumber(gettok(camera.loc,3,32))
        cctvC[camera.name].interior = tonumber(camera.interior)
        cctvC[camera.name].angle = tonumber(gettok(camera.target,1,32))
        cctvC[camera.name].height = tonumber(gettok(camera.target,2,32))
        cctvC[camera.name].fov = tonumber(gettok(camera.target,3,32))
        cctvC[camera.name].r = tonumber(gettok(camera.color,1,32))
        cctvC[camera.name].g = tonumber(gettok(camera.color,2,32))
        cctvC[camera.name].b = tonumber(gettok(camera.color,3,32))
        cctvC[camera.name].scanlines = tonumber(gettok(camera.scan,1,32))
        cctvC[camera.name].scansize = tonumber(gettok(camera.scan,2,32))
        cctvC[camera.name].flicker = tonumber(gettok(camera.scan,3,32))
        cctvC[camera.name].zoom = camera.zoom
        cctvC[camera.name].motor = camera.motor
        if cctvT[camera.terminal] then cctvT[camera.terminal].camcount = cctvT[camera.terminal].camcount + 1 end
      end
    end    
  elseif action == "addcam" then
    local cname = id
    local ctype = data.type
    local cterminal = data.terminal
    local cloc = data.x.." "..data.y.." "..data.z
    local cinterior = data.interior
    local ctarget = data.angle.." "..data.height.." "..data.fov
    local ccolor = data.r.." "..data.g.." "..data.b
    local cscan = data.scanlines.." "..data.scansize.." "..data.flicker
    local zoom = tonumber(data.zoom)
    local motor = tonumber(data.motor)
    executeSQLDelete("cctvcameras", "name = '"..id.."'")
    executeSQLInsert("cctvcameras", "'"..cname.."', '"..ctype.."', '"..cterminal.."', '"..cloc.."', '"..cinterior.."', '"..ctarget.."', '"..ccolor.."', '"..cscan.."', '"..zoom.."', '"..motor.."'") 
  elseif action == "delcam" then
    executeSQLDelete("cctvcameras", "name = '"..id.."'")
  elseif action == "addterm" then
    local tname = id
    local tloc = data.x.." "..data.y.." "..data.z.." "..data.rz.." "..data.mr.." "..data.mg.." "..data.mb.." "..data.ma
    local tinterior = data.interior
    local trestricted = data.restricted
    local taccess = tostring(data.access)
    executeSQLDelete("cctvterminals", "name = '"..id.."'")
    executeSQLInsert("cctvterminals", "'"..tname.."', '"..tloc.."', '"..tinterior.."', '"..trestricted.."', '"..taccess.."'") 
  elseif action == "delterm" then
    executeSQLDelete("cctvterminals", "name = '"..id.."'")
  elseif action == "reset" then
    executeSQLDropTable("cctvcameras")
    executeSQLDropTable("cctvterminals")  
    cctvDB("create")
  end
end

function cctvReloadFromDB()
  cctvDB("load")
  cctvSpawn("delete", "_all")
  cctvSpawn("camera", "_all")
  cctvSpawn("terminal", "_all")
  triggerClientEvent(getRootElement(), "cctvListUpdate", getRootElement(), cctvT, cctvC) 
end

function cctvAddCamera(id, data, keep)
  if keep then 
    local previousTerminal = nil
    if cctvC[id] then previousTerminal = cctvC[id].terminal end
    cctvC[id].terminal = data
    if cctvT[data] then cctvT[data].camcount = cctvCamCount(data) end
    if previousTerminal and previousTerminal ~= "--------" and data ~= previousTerminal then cctvT[previousTerminal].camcount = cctvCamCount(previousTerminal) end
    cctvDB("addcam", id, cctvC[id])
    triggerClientEvent(getRootElement(), "cctvListUpdate", getRootElement(), cctvT, cctvC) 
  else
    local previousTerminal = nil
    if cctvC[id] then previousTerminal = cctvC[id].terminal end
    cctvC[id] = data
    if cctvT[data.terminal] then cctvT[data.terminal].camcount = cctvCamCount(data.terminal) end
    if previousTerminal and previousTerminal ~= "--------" and data.terminal ~= previousTerminal then cctvT[previousTerminal].camcount = cctvCamCount(previousTerminal) end
    cctvSpawn("delete", id)
    cctvSpawn("camera", id)
    cctvDB("addcam", id, data)
    triggerClientEvent(getRootElement(), "cctvListUpdate", getRootElement(), cctvT, cctvC) 
  end  
end

function cctvDelCamera(id)
  local camTerminal = cctvC[id].terminal
  cctvSpawn("delete", id)
  cctvDB("delcam", id)
  cctvC[id] = nil
  if cctvT[camTerminal] then cctvT[camTerminal].camcount = cctvCamCount(camTerminal) end
  triggerClientEvent(getRootElement(), "cctvListUpdate", getRootElement(), cctvT, cctvC) 
end

function cctvAddTerminal(id, data, keep)
  cctvT[id] = data
  if not keep then 
    cctvSpawn("delete", id)
    cctvSpawn("terminal", id)
  end  
  cctvDB("addterm", id, data)
  cctvT[id].camcount = cctvCamCount(id)
  triggerClientEvent(getRootElement(), "cctvListUpdate", getRootElement(), cctvT, cctvC) 
end

function cctvDelTerminal(id)
  cctvSpawn("delete", id)
  cctvDB("delterm", id)
  cctvT[id] = nil
  for cid,cam in pairs(cctvC) do
    if cam.terminal == id then
      cctvC[cid].terminal = "--------"
      cctvDB("addcam", cid, cctvC[cid])    
    end
  end
  triggerClientEvent(getRootElement(), "cctvListUpdate", getRootElement(), cctvT, cctvC) 
end

function cctvCamCount(terminal)
  local cCount = 0
  for id,camera in pairs(cctvC) do
    if camera.terminal == terminal then cCount = cCount + 1 end
  end
  return cCount
end

function cctvSpawn(action, id)
  if action == "delete" then
    if id == "_all" then
      local oCount = 0 
      for id,object in pairs(cctvO) do -- deleting all objects
        if isElement(object) then
          destroyElement(cctvO[id])
          cctvO[id] = nil
          oCount = oCount + 1
        end
      end
      cctvO = {}
      if oCount > 0 then outputChatBox("CCTV: Deleted "..oCount.." object(s)", getRootElement(), 0, 222, 222, true) end
    elseif id then
      if isElement(cctvO["camera_"..id]) then 
        destroyElement(cctvO["camera_"..id]) 
        outputChatBox("CCTV: Deleted camera object: "..id, getRootElement(), 0, 222, 222, true)
      end  
      if isElement(cctvO["terminal_"..id]) then 
        destroyElement(cctvO["terminal_"..id]) 
        outputChatBox("CCTV: Deleted terminal object: "..id, getRootElement(), 0, 222, 222, true)
      end  
      if isElement(cctvO["marker_"..id]) then destroyElement(cctvO["marker_"..id]) end  
      cctvO["terminal_"..id] = nil
      cctvO["marker_"..id] = nil
      cctvO["camera_"..id] = nil
    end
  elseif action == "terminal" then
    if id == "_all" then
      local tCount = 0
      for id,terminal in pairs(cctvT) do -- creating objects: terminals
        cctvO["terminal_"..id] = createObject(2190, terminal.x, terminal.y, terminal.z)
        setElementRotation(cctvO["terminal_"..id], 0, 0, terminal.rz) 
        local mx, my = getRotation(terminal.x, terminal.y, 0.7, 195 - terminal.rz)      
        cctvO["marker_"..id] = createMarker(mx, my, terminal.z-0.5, markerType, 2, terminal.mr, terminal.mg, terminal.mb, terminal.ma)
        setElementData(cctvO["marker_"..id], "cctv.tid", id)
        if terminal.interior ~= 0 then 
          setElementInterior(cctvO["terminal_"..id], terminal.interior) 
          setElementInterior(cctvO["marker_"..id], terminal.interior) 
        end
        tCount = tCount + 1
      end
      outputChatBox("CCTV: Spawned "..tCount.." terminal(s)", getRootElement(), 0, 222, 222, true)
    elseif id then
      cctvO["terminal_"..id] = createObject(2190, cctvT[id].x, cctvT[id].y, cctvT[id].z)
      setElementRotation(cctvO["terminal_"..id], 0, 0, cctvT[id].rz)
      local mx, my = getRotation(cctvT[id].x, cctvT[id].y, 0.7, 195 - cctvT[id].rz)      
      cctvO["marker_"..id] = createMarker(mx, my, cctvT[id].z-0.5, markerType, 2, cctvT[id].mr, cctvT[id].mg, cctvT[id].mb, cctvT[id].ma)
      setElementData(cctvO["marker_"..id], "cctv.tid", id)
      if cctvT[id].interior ~= 0 then 
        setElementInterior(cctvO["terminal_"..id], cctvT[id].interior) 
        setElementInterior(cctvO["marker_"..id], cctvT[id].interior) 
      end
      outputChatBox("CCTV: Spawned terminal: "..id, getRootElement(), 0, 222, 222, true)
    end  
  elseif action == "camera" then
    if id == "_all" then
      local cCount = 0
      for id,camera in pairs(cctvC) do -- creating objects: cameras
        local offA = 0
        if camera.type == wallcam then offA = offsets.wallAngle
        else offA = offsets.ceilAngle end
        cctvO["camera_"..id] = createObject(camera.type, camera.x, camera.y, camera.z)
        setElementRotation(cctvO["camera_"..id], 0, 0, offA - camera.angle)  
        if camera.interior ~= 0 then 
          setElementInterior(cctvO["camera_"..id], camera.interior) 
        end
        cCount = cCount + 1
      end
      outputChatBox("CCTV: Spawned "..cCount.." camera(s)", getRootElement(), 0, 222, 222, true)
    elseif id then
      local offA = 0
      if cctvC[id].type == wallcam then offA = offsets.wallAngle
      else offA = offsets.ceilAngle end
      cctvO["camera_"..id] = createObject(cctvC[id].type, cctvC[id].x, cctvC[id].y, cctvC[id].z)
      setElementRotation(cctvO["camera_"..id], 0, 0, offA - cctvC[id].angle)  
      if cctvC[id].interior ~= 0 then 
        setElementInterior(cctvO["camera_"..id], cctvC[id].interior) 
      end
      outputChatBox("CCTV: Spawned camera: "..id, getRootElement(), 0, 222, 222, true)
    end  
  end
end

addEvent("cctvGate", true) 
addEventHandler("cctvGate", getRootElement(), 
  function(action, id, data)
    local isAdmin = hasObjectPermissionTo(source, "command.cctv", true)
    if action == "gui" and isAdmin then
      triggerClientEvent(source, "cctvOpen", getRootElement())
      triggerClientEvent(source, "cctvListUpdate", getRootElement(), cctvT, cctvC) 
    elseif action == "viewcam" then
      if id == "exit unfreeze" then
        local defaultG = 0.008
        if playerG[source] then 
          defaultG = playerG[source] 
          playerG[source] = nil
        end
        setTimer(setPedGravity, unfreezeDelay, 1, source, defaultG)
      elseif cctvC[id] then
        triggerClientEvent(source, "cctvCamData", getRootElement(), cctvC[id], "VIEW")
        playerG[source] = getPedGravity(source)
        setPedGravity(source, 0)
      else
        triggerClientEvent(source, "cctvCamData", getRootElement(), false, "VIEW")
        playerG[source] = getPedGravity(source)
        setPedGravity(source, 0)
      end      
    elseif action == "viewterminal" and id and isElementWithinMarker(source, cctvO["marker_"..id]) then
      if isPedInVehicle(source) then 
        outputChatBox("CCTV: Get out of the car first!", source, 222, 0, 0)
        return false
      end  
      if terminalAccess(source, id, data) then
        local list = {}
        for cid,cam in pairs(cctvC) do
          if cam.terminal == id then table.insert(list, cid) end
        end
        if #list > 0 then
          triggerClientEvent(source, "cctvListUpdate", getRootElement(), cctvT, cctvC) 
          triggerClientEvent(source, "cctvCamData", getRootElement(), list, "VIEWTERMINAL")
          playerG[source] = getPedGravity(source)
          setPedGravity(source, 0)
        end  
      end
    elseif action == "editcam" and isAdmin then
      if id == "exit unfreeze" then
        local defaultG = 0.008
        if playerG[source] then 
          defaultG = playerG[source] 
          playerG[source] = nil
        end
        setTimer(setPedGravity, unfreezeDelay, 1, source, defaultG)
      elseif cctvC[id] then
        triggerClientEvent(source, "cctvCamData", getRootElement(), cctvC[id], "EDIT")
        playerG[source] = getPedGravity(source)
        setPedGravity(source, 0)
      else
        triggerClientEvent(source, "cctvCamData", getRootElement(), false, "EDIT")
        playerG[source] = getPedGravity(source)
        setPedGravity(source, 0)
      end      
    elseif action == "savecam" and isAdmin then 
      cctvAddCamera(id, data)
    elseif action == "delcam" and isAdmin then 
      cctvDelCamera(id)
    elseif action == "c2t" and isAdmin then 
      cctvAddCamera(id, data, true)
    elseif action == "saveterm" and isAdmin then 
      cctvAddTerminal(id, data)
    elseif action == "delterm" and isAdmin then 
      cctvDelTerminal(id)
    elseif action == "port2t" and isAdmin then
      local px, py, pz = getElementPosition(cctvO["marker_"..id])
      if px then 
        setElementInterior(source, getElementInterior(cctvO["marker_"..id]))
        setElementPosition(source, px, py, pz)
      end  
    --[[-- is not working properly yet
    elseif action == "port2c" and isAdmin then
      local px, py = getRotation(cctvC[id].x, cctvC[id].y, 50, cctvC[id].angle)
      if px then 
        if cctvC[id].interior ~= getElementInterior(source) then setElementInterior(source, cctvC[id].interior) end
        setElementPosition(source, px, py, data+2)
        setElementInterior(source, cctvC[id].interior)
      end  
    --]]-- end
    elseif action == "dbreset" and isAdmin then 
      cctvSpawn("delete", "_all")
      cctvDB("reset")
      cctvDB("load")
      triggerClientEvent(getRootElement(), "cctvListUpdate", getRootElement(), cctvT, cctvC) 
    elseif action == "dbreload" and isAdmin then 
      cctvReloadFromDB()
      triggerClientEvent(getRootElement(), "cctvListUpdate", getRootElement(), cctvT, cctvC) 
    end    
  end
)

function terminalAccess(player, tid, pass)
  if cctvT[tid].restricted == 0 then return true
  elseif cctvT[tid].restricted == 1 and pass == tostring(cctvT[tid].access) then return true 
  elseif cctvT[tid].restricted == 2 and getPlayerTeam(player) then 
    if string.lower(tostring(cctvT[tid].access)) == string.lower(getTeamName(getPlayerTeam(player))) then return true
    else return false end
  elseif cctvT[tid].restricted == 3 then
    if not aclGetGroup(tostring(cctvT[tid].access)) then return false end  
    if isObjectInACLGroup("user."..getPlayerName(player), aclGetGroup(tostring(cctvT[tid].access))) then return true
    else return false end
  end
  return false
end

addEventHandler("onResourceStart", rRoot, cctvInit)
addEventHandler("onMarkerHit", rRoot, 
  function(player)
    if getElementData(source,"cctv.tid") then
      local id = getElementData(source,"cctv.tid")
      if cctvT[id].camcount == 0 then return false end
      if cctvT[id].restricted == 0 then
        outputChatBox("CCTV Public Terminal: Type '/watch' to check security cameras", player, 0, 222, 0)
      elseif cctvT[id].restricted == 1 then
        outputChatBox("CCTV Password Protected Terminal: Type '/watch <password>'", player, 0, 222, 222)
      elseif cctvT[id].restricted == 2 then
        if terminalAccess(player, id) then outputChatBox("CCTV "..cctvT[id].access.." Team Terminal: Type '/watch' to check security cameras", player, 0, 222, 0)
        else outputChatBox("CCTV "..cctvT[id].access.." Team Terminal: Access denied", player, 222, 0, 0) end
      elseif cctvT[id].restricted == 3 then
        if terminalAccess(player, id) then outputChatBox("CCTV "..cctvT[id].access.." Group Terminal: Type '/watch' to check security cameras", player, 0, 222, 0)
        else outputChatBox("CCTV "..cctvT[id].access.." Group Terminal: Access denied", player, 222, 0, 0) end
      end  
    end
  end
)

function getRotation(x, y, dist, angle)
  local a = math.rad(90 - angle)
  local dx = math.cos(a) * dist
  local dy = math.sin(a) * dist
  return x+dx, y+dy
end
