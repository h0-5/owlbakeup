-- ============================================================
-- Faction System - Client Logic (state, events, input)
-- All texts use escaped UTF-8 byte sequences
-- ============================================================

-- ============================================================
-- State (global table F, shared with UI files)
-- ============================================================
F = {
    visible = false,
    data = nil,
    section = "members",
    membersScroll = 0,
    membersSelected = 0,
    vehiclesScroll = 0,
    vehiclesSelected = 0,
    ranksSelected = 0,
    financeScroll = 0,
    dutyScroll = 0,
    dutyLocationsScroll = 0,
    dutyVehiclesScroll = 0,
    members = {},
    onlineCount = 0,
    maxMembers = 0,
    slotLimit = 20,
    isLeader = false,
    factionType = 0,
    factionID = -1,
    team = nil,
    custom = {},
    locations = {},
    finance = nil,
    financeLoaded = false,
    rankNameBuffer = "",
    rankWageBuffer = "",
    noteBuffer = "",
    motdBuffer = "",
    sub = {
        promote = false,
        addMember = false,
        addMemberText = "",
        addMemberResult = "",
        dutyPerks = false,
        dutyPerksSelected = {},
        confirm = false,
        confirmText = "",
        confirmAction = nil,
    },
    menu = {},
    cursorX = 0,
    cursorY = 0,
    cursorValid = false,
    dutyPackages = nil,
    dutyAllow = {},
}

customg = {}
locationsg = {}

-- ============================================================
-- Receive faction data from server
-- ============================================================
addEvent("showFactionMenu", true)
addEventHandler("showFactionMenu", getRootElement(),
function(motd, memberUsernames, memberRanks, memberPerks, memberLeaders, memberOnline, memberLastLogin, factionRanks, factionWages, theTeam, note, fnote, vehicleIDs, vehicleModels, vehiclePlates, vehicleLocations, memberOnDuty, towstats, phone, membersPhone, fromShowF, factionID)
    if not theTeam then return end

    F.data = {
        motd = motd,
        memberUsernames = memberUsernames,
        memberRanks = memberRanks,
        memberPerks = memberPerks,
        memberLeaders = memberLeaders,
        memberOnline = memberOnline,
        memberLastLogin = memberLastLogin,
        factionRanks = factionRanks,
        factionWages = factionWages,
        team = theTeam,
        note = note,
        fnote = fnote,
        vehicleIDs = vehicleIDs,
        vehicleModels = vehicleModels,
        vehiclePlates = vehiclePlates,
        vehicleLocations = vehicleLocations,
        memberOnDuty = memberOnDuty,
        towstats = towstats,
        phone = phone,
        membersPhone = membersPhone,
    }

    F.factionID = factionID or getElementData(localPlayer, "faction") or -1
    F.factionType = tonumber(getElementData(theTeam, "type")) or 0
    F.team = theTeam
    F.isLeader = fromShowF or false
    F.noteBuffer = note or ""
    F.motdBuffer = motd or ""
    F.phone = phone or false

    -- detect leadership from member list
    if not F.isLeader then
        local myName = getPlayerName(localPlayer)
        for k, v in ipairs(memberUsernames or {}) do
            if v == myName and memberLeaders and memberLeaders[k] then
                F.isLeader = true
            end
        end
    end

    -- build member rows
    F.members = {}
    F.onlineCount = 0
    for k, name in ipairs(memberUsernames or {}) do
        local rank = tonumber(memberRanks[k]) or 1
        local rankName = (factionRanks and factionRanks[rank]) or ("Rank " .. rank)
        local wage = (factionWages and factionWages[rank]) or 0
        local lastLogin = tonumber(memberLastLogin[k])
        local loginText = "\216\163\216\168\216\175\217\139\226\128\145"
        if lastLogin == 0 then loginText = "\216\167\217\132\217\138\217\136\217\133"
        elseif lastLogin == 1 then loginText = "\216\163\217\133\216\179"
        elseif lastLogin and lastLogin > 1 then loginText = lastLogin .. " \217\138\217\136\217\133" end

        local isOnline = memberOnline and memberOnline[k] == true
        if isOnline then F.onlineCount = F.onlineCount + 1 end

        local onDuty = memberOnDuty and memberOnDuty[k] == true
        local phoneTxt = ""
        if phone and membersPhone and membersPhone[k] then
            phoneTxt = tostring(phone) .. "-" .. tostring(membersPhone[k])
        end

        -- member perks (for duty perks window)
        local myPerks = {}
        if memberPerks and memberPerks[k] and type(memberPerks[k]) == "table" then
            for pk, pv in pairs(memberPerks[k]) do
                if pv then myPerks[tostring(pk)] = true end
            end
        end

        table.insert(F.members, {
            name = name:gsub("_", " "),
            rawName = name,
            rank = rank,
            rankName = rankName,
            wage = wage,
            login = loginText,
            online = isOnline,
            duty = onDuty,
            leader = (memberLeaders and memberLeaders[k]) or false,
            phone = phoneTxt,
            perks = myPerks,
        })
    end
    F.maxMembers = #F.members + 1
    F.slotLimit = 20

    buildMenu()
    F.section = "members"
    F.membersScroll = 0
    F.membersSelected = 0
    F.vehiclesScroll = 0
    F.vehiclesSelected = 0
    F.financeScroll = 0
    F.financeLoaded = false
    F.finance = nil

    F.visible = true
    showCursor(true)
end)

addEvent("hideFactionMenu", true)
addEventHandler("hideFactionMenu", getRootElement(), function()
    F.visible = false
    F.sub = {
        promote = false,
        addMember = false,
        addMemberText = "",
        addMemberResult = "",
        dutyPerks = false,
        dutyPerksSelected = {},
        confirm = false,
        confirmText = "",
        confirmAction = nil,
    }
    activeEdit = nil
    showCursor(false)
    triggerServerEvent("factionmenu:hide", localPlayer)
end)

addEventHandler("onClientPlayerWasted", localPlayer, function()
    if F.visible then
        triggerEvent("hideFactionMenu", localPlayer)
    end
end)

-- F3 closes when open (server opens it; we handle the close)
addEventHandler("onClientKey", root, function(button, press)
    if button == "F3" and press and F.visible then
        cancelEvent()
        triggerEvent("hideFactionMenu", localPlayer)
    end
end)

-- ============================================================
-- Finance data
-- ============================================================
addEvent("factionmenu:fillFinance", true)
addEventHandler("factionmenu:fillFinance", getRootElement(),
function(factionID, bankThisWeek, bankPrevWeek, bankmoney, vehiclesvalue, propertiesvalue)
    F.finance = {
        thisWeek = bankThisWeek or {},
        prevWeek = bankPrevWeek or {},
        bankmoney = bankmoney or 0,
        vehiclesvalue = vehiclesvalue or 0,
        propertiesvalue = propertiesvalue or 0,
    }
    F.financeLoaded = true
end)

function loadFinance()
    if not F.financeLoaded then
        triggerServerEvent("factionmenu:getFinance", getResourceRootElement())
    end
end

-- ============================================================
-- Duty data
-- ============================================================
addEvent("importDutyData", true)
addEventHandler("importDutyData", resourceRoot, function(custom, locations, factionID, message)
    customg = custom or {}
    locationsg = locations or {}
    if message then
        outputChatBox(message, 255, 194, 14)
    end
end)

addEvent("Duty:GotPackages", true)
addEventHandler("Duty:GotPackages", resourceRoot, function(packages)
    F.dutyPackages = packages or {}
end)

addEvent("gotAllow", true)
addEventHandler("gotAllow", resourceRoot, function(allowList)
    F.dutyAllow = allowList or {}
end)

function fetchDutyInfo()
    triggerServerEvent("fetchDutyInfo", resourceRoot, F.factionID)
end
