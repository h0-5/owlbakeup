-- Decompiled by Owl Decompiler v1.0 (job-system/job_c_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #61) with decompiler artifacts repaired:
--   * var0/var1 merged globals split back into the JOBS cache table
--     (jobs_list / jobs_data / picked name / picked entry) - showTakeJob
--     iterated var1.jobs_data while the response filled var0.jobs_data.
--   * table.sort comparator indexed the cache table itself
--     (`var0[arg0].requirements`) instead of the jobs_data map - restored.
--   * the two `function UIKitReady()` definitions overrode each other
--     (only the second window set would ever build) - split into
--     UIKitReady (jobs center) + UIKitReadyJob (current-job window).
--   * the gridlist fill inlined uiGridListAddRow into every Set* call
--     (4 rows per job) - restored with a `local row`.
--   * showTakeJob: the matched-entry leak (`if forvar8 then`) restored as
--     an explicit `found`; the label fallback `label or label` restored to
--     `label or name`.
--   * button[3] read var0.data.code while showTakeJob set .job_code - both
--     supported (server entries also carry `code`).
--   * getJobRankByEXP: the loop index leaked from a broken for-loop -
--     restored as the highest rank whose required_exp <= exp.
--   * showJobDetails / job_current label: the decompile inlined
--     getJobRankByEXP calls and lost the 2nd/3rd return picks (next rank
--     name/salary/required_exp) - restored with explicit locals.
--   * jobs:get_character_data:response: forvar7/forvar8 leaks restored
--     (the current-job record comes from the server records list).

addEvent("onClientPlayerStartJob", true)
addEventHandler("onClientPlayerStartJob", localPlayer, function(job)
end)

addEvent("onClientPlayerQuitJob", true)
addEventHandler("onClientPlayerQuitJob", localPlayer, function(job)
        if isPedInVehicle(localPlayer) and getElementData(getPedOccupiedVehicle(localPlayer), "vehicle:owner.name") and string.find(getElementData(getPedOccupiedVehicle(localPlayer), "vehicle:owner.name"), "job:", 1, true) and isVehicleLocked((getPedOccupiedVehicle(localPlayer))) then
                setPedExitVehicle(localPlayer)
        end
        if isElement(UI.label.job_current) then
                eui:uiSetText(UI.label.job_current, {
                        en = "Not currently employed",
                        ar = "غير موظف حالياً"
                })
                eui:uiSetVisible(UI.button.start_job, false)
                eui:uiSetVisible(UI.button.quit_job, false)
        end
end)

addCommandHandler("jobhelp", function()
        if getElementData(localPlayer, "job") then
                triggerEvent("onClientShowJobHelp", localPlayer, (getElementData(localPlayer, "job")))
        end
end, false, false)
addEvent("onClientShowJobHelp", true)
addEventHandler("onClientShowJobHelp", localPlayer, function(job)
end)

function giveJobSalary(amount, reason)
        if amount and reason then
                exports.security:triggerServerEvent("jobs:giveJobSalary", localPlayer, localPlayer, amount, reason)
        end
end

-- [Fix #63] REAL Owl contract is (jobName, amount) - every decompiled job
-- calls it that way: givePlayerJobEXP("Postman", 1) / ("Bus Driver", 1) /
-- ("Dustman", 1) / ("Pizza Deliverer", 1) (fuel/forklift/firefighter pass
-- the name as a var). The previous (amount, reason) guess was wrong.
function givePlayerJobEXP(jobName, amount)
        if jobName and amount then
                exports.security:triggerServerEvent("jobs:givePlayerJobEXP", localPlayer, jobName, amount)
        end
end

JOBS = {
        list = {},
        data = {},
        name = nil,
        entry = nil
}

UIM = {
        window = {},
        label = {},
        button = {},
        gridlist = {}
}

function UIKitReady()
        eui = exports.UIKit
        UIM.window[1] = eui:uiCreateWindow(false, false, 500, 450, {
                en = "Jobs",
                ar = "الوظائف"
        }, _, ":assets/icons/suitcase.png")
        eui:uiSetVisible(UIM.window[1], false)
        eui:uiWindowSetMovable(UIM.window[1], false)
        UIM.button[1] = eui:uiCreateButton(10, 360, 480, 35, {
                en = "Take Job",
                ar = "أخذ الوظيفة"
        }, "primary", UIM.window[1])
        UIM.button[2] = eui:uiCreateButton(10, 405, 480, 35, {en = "Cancel", ar = "إلغاء"}, _, UIM.window[1])
        UIM.gridlist[1] = eui:uiCreateGridList(5, 50, 490, 300, tocolor(10, 10, 10, 0), UIM.window[1])
        eui:uiGridListAddColumn(UIM.gridlist[1], "Job name", 0.7)
        eui:uiGridListAddColumn(UIM.gridlist[1], "Required Level", 0.3)
        eui:uiSetProperty(UIM.gridlist[1], "row_height", 25)
        UIM.window[2] = eui:uiCreateWindow(false, false, 450, 400, {
                en = "Job Name",
                ar = "اسم الوظيفة"
        })
        eui:uiSetVisible(UIM.window[2], false)
        eui:uiWindowSetMovable(UIM.window[2], false)
        UIM.label.job_requirements = eui:uiCreateLabel(15, 40, 420, 60, {
                en = "•${color.primary}  Minimum Required Level:  #ffffff10\n•${color.primary}  Require vehicles license #ffffff\n•${color.primary}  Minimum Salary:  #00ff00$100\n\t",
                ar = "•${color.primary}  أدنى مستوى مطلوب:  #ffffff10\n•${color.primary}  يتطلب رخصة قيادة #ffffff\n•${color.primary}  أدنى راتب:  #00ff00$100\n\t"
        }, tocolor(255, 255, 255, 255), "left", "top", UIM.window[2])
        eui:uiCreateRectangle(15, 110, 420, 1, tocolor(255, 255, 255, 20), false, false, false, false, UIM.window[2])
        eui:uiCreateRectangle(15, 290, 420, 1, tocolor(255, 255, 255, 20), false, false, false, false, UIM.window[2])
        UIM.label.job_description = eui:uiCreateLabel(0, 110, 450, 170, {
                en = "Job Description",
                ar = "وصف الوظيفة"
        }, tocolor(255, 255, 255, 255), "center", "center", UIM.window[2])
        UIM.button[3] = eui:uiCreateButton(10, 310, 430, 35, {
                en = "Take Job",
                ar = "أخذ الوظيفة"
        }, "primary", UIM.window[2])
        UIM.button[4] = eui:uiCreateButton(10, 355, 430, 35, {en = "Cancel", ar = "إلغاء"}, _, UIM.window[2])
        eui:uiSetProperty(UIM.button[4], "HoverTextColor", tocolor(255, 48, 48))
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEvent("onClientUIKitReady", true)
addEventHandler("onClientUIKitReady", root, UIKitReady)

addEvent("onClientElementMenuClick", true)
addEventHandler("onClientElementMenuClick", root, function(element, text, data)
        if not isElement(element) then
                return
        end
        if getElementType(element) == "ped" and getElementData(element, "ped:interact") == "jobs" and text == "Talk" then
                eui:uiSetVisible(UIM.window[1], true)
                showCursor(true)
                requestJobs()
                exports.public:loading("jobs:get", true)
        end
end)

function requestJobs()
        triggerServerEvent("jobs:get", localPlayer, md5(toJSON(JOBS.list)))
end

addEvent("jobs:get:response", true)
addEventHandler("jobs:get:response", localPlayer, function(jobsList, jobsData)
        if not jobsList then
                jobsList = JOBS.list
                jobsData = JOBS.data
        else
                JOBS.list = jobsList
                JOBS.data = jobsData
        end
        exports.public:loading("jobs:get", false)
        table.sort(jobsList, function(a, b)
                return JOBS.data[a] and JOBS.data[b] and JOBS.data[a].requirements.min_level < JOBS.data[b].requirements.min_level
        end)
        eui:uiGridListClear(UIM.gridlist[1])
        for _, code in ipairs(jobsList) do
                local jobData = jobsData[code]
                if jobData.jobs_center then
                        -- decompiler lost the `local row` (inlined AddRow into every Set*)
                        local row = eui:uiGridListAddRow(UIM.gridlist[1])
                        eui:uiGridListSetItemData(UIM.gridlist[1], row, 1, tostring(jobData.name))
                        eui:uiGridListSetItemText(UIM.gridlist[1], row, 1, jobData.label and tostring(jobData.label) or tostring(jobData.name))
                        eui:uiGridListSetItemText(UIM.gridlist[1], row, 2, tostring(jobData.requirements.min_level))
                        eui:uiGridListSetItemData(UIM.gridlist[1], row, 2, jobData)
                        if exports["level-system"]:getPlayerLevel() >= tonumber(jobData.requirements.min_level) then
                                eui:uiGridListSetItemColor(UIM.gridlist[1], row, 1, tocolor(0, 255, 0))
                                eui:uiGridListSetItemColor(UIM.gridlist[1], row, 2, tocolor(0, 255, 0))
                        else
                                eui:uiGridListSetItemColor(UIM.gridlist[1], row, 1, tocolor(255, 0, 0))
                                eui:uiGridListSetItemColor(UIM.gridlist[1], row, 2, tocolor(255, 0, 0))
                        end
                end
        end
end)

function showTakeJob(name, label, description)
        eui:uiSetText(UIM.window[2], label)
        eui:uiSetText(UIM.label.job_description, description)
        eui:uiSetVisible(UIM.window[2], true)
        showCursor(true)
        JOBS.name = name
        local found
        for code, data in pairs(JOBS.data) do
                if name == data.name then
                        data.job_code = code
                        found = data
                        break
                end
        end
        if found then
                JOBS.entry = found
                eui:uiSetText(UIM.label.job_requirements, {
                        en = ("" .. "•${color.primary}  Minimum Required Level:  #ffffff" .. found.requirements.min_level .. "\n") .. "•${color.primary}  Require vehicles license #ffffff\n",
                        ar = ("" .. "•${color.primary}  أدنى مستوى مطلوب:  #ffffff" .. found.requirements.min_level .. "\n") .. "•${color.primary}  يتطلب رخصة قيادة #ffffff\n"
                })
        end
end

function takeJob(name)
        triggerServerEvent("jobs:take_job", localPlayer, name)
end

addEventHandler("onClientUIClick", root, function()
        if source == UIM.button[1] then
                if eui:uiGridListGetSelectedItem(UIM.gridlist[1]) ~= -1 then
                        if exports["level-system"]:getPlayerLevel() < tonumber((eui:uiGridListGetItemText(UIM.gridlist[1], eui:uiGridListGetSelectedItem(UIM.gridlist[1]), 2))) then
                                exports.notifications:output({
                                        en = "Your level must be " .. tostring((eui:uiGridListGetItemText(UIM.gridlist[1], eui:uiGridListGetSelectedItem(UIM.gridlist[1]), 2))) .. " or above",
                                        ar = "مستواك يجب أن يكون " .. tostring((eui:uiGridListGetItemText(UIM.gridlist[1], eui:uiGridListGetSelectedItem(UIM.gridlist[1]), 2))) .. " أو أعلى"
                                }, 5000, "error")
                                return
                        end
                        if not getElementData(localPlayer, "job") then
                                if eui:uiGridListGetItemData(UIM.gridlist[1], eui:uiGridListGetSelectedItem(UIM.gridlist[1]), 2).requirements.driving_license then
                                        if not exports["driving-license"]:isPlayerHaveLicense(localPlayer, eui:uiGridListGetItemData(UIM.gridlist[1], eui:uiGridListGetSelectedItem(UIM.gridlist[1]), 2).requirements.driving_license_type or "Vehicles") then
                                                exports.notifications:output({
                                                        en = "You must have a driving license to take this job",
                                                        ar = "يجب أن يكون لديك رخصة قيادة لأخذ هذه الوظيفة"
                                                }, 5000, "error")
                                                return
                                        end
                                end
                                eui:uiSetVisible(UIM.window[1], false)
                                showCursor(false)
                                triggerServerEvent("jobs:take_job", localPlayer, (eui:uiGridListGetItemData(UIM.gridlist[1], eui:uiGridListGetSelectedItem(UIM.gridlist[1]), 1)))
                        elseif getElementData(localPlayer, "job") == eui:uiGridListGetItemData(UIM.gridlist[1], eui:uiGridListGetSelectedItem(UIM.gridlist[1]), 1) then
                                exports.notifications:output({
                                        en = "You are already working in this job",
                                        ar = "أنت تعمل بالفعل في هذه الوظيفة"
                                }, 5000, "error")
                        else
                                exports.notifications:output({
                                        en = "You must quit your job first",
                                        ar = "يجب عليك ترك وظيفتك أولا"
                                }, 5000, "error")
                        end
                end
        elseif source == UIM.button[2] then
                eui:uiSetVisible(UIM.window[1], false)
                showCursor(false)
        elseif source == UIM.button[3] then
                if not getElementData(localPlayer, "job") then
                        -- safety repair: the decompile would index a nil entry if the
                        -- detail window was somehow open without a matched job
                        if JOBS.entry and not checkJobRequirements(JOBS.entry.code or JOBS.entry.job_code, true) then
                                return
                        end
                        eui:uiSetVisible(UIM.window[2], false)
                        showCursor(false)
                        triggerEvent("onClientRequestTakeJob", localPlayer, JOBS.name)
                elseif getElementData(localPlayer, "job") == JOBS.name then
                        exports.notifications:output({
                                en = "You are already working in this job",
                                ar = "أنت تعمل بالفعل في هذه الوظيفة"
                        }, 5000, "info")
                else
                        exports.notifications:output({
                                en = "You must quit your job first",
                                ar = "يجب عليك ترك وظيفتك أولا"
                        }, 5000, "error")
                end
        elseif source == UIM.button[4] then
                eui:uiSetVisible(UIM.window[2], false)
                showCursor(false)
        end
end)

UI = {
        tab = {},
        progressbar = {},
        edit = {},
        window = {},
        label = {},
        checkbox = {},
        switch = {},
        button = {},
        tabpanel = {},
        radiobutton = {},
        gridlist = {},
        memo = {},
        scrollbar = {},
        combobox = {},
        rectangle = {},
        container = {}
}

function UIKitReadyJob()
        eui = exports.UIKit
        UI.window[1] = eui:uiCreateWindow(false, false, 420, 260, {
                en = "Your Current Job",
                ar = "وظيفتك الحالية"
        })
        eui:uiSetVisible(UI.window[1], false)
        eui:uiWindowSetMovable(UI.window[1], false)
        UI.label.Info = eui:uiCreateLabel(10, 40, 232, 20, "", tocolor(255, 255, 255, 255), "left", "top", UI.window[1])
        UI.button[1] = eui:uiCreateButton(315, 225, 100, 30, {en = "Close", ar = "إغلاق"}, tocolor(0, 0, 0, 255), UI.window[1])
        UI.button[2] = eui:uiCreateButton(5, 225, 100, 30, {
                en = "Start Job",
                ar = "بدأ العمل"
        }, tocolor(0, 0, 0, 255), UI.window[1])
        UI.button[3] = eui:uiCreateButton(110, 225, 150, 30, {
                en = "Quit Job",
                ar = "الخروج من الوظيفة"
        }, tocolor(0, 0, 0, 255), UI.window[1])
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReadyJob)
addEventHandler("onClientUIKitReady", root, UIKitReadyJob)

function closeUIWindows()
        eui:uiSetVisible(UIM.window[1], false)
        eui:uiSetVisible(UI.window[1], false)
        showCursor(false)
end
addEvent("onClientPlayerQuitFromCharacter", true)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, closeUIWindows)
addEventHandler("onClientPlayerWasted", localPlayer, closeUIWindows)

addCommandHandler("job", function()
        if not getElementData(localPlayer, "character:id") then
                return
        end
        if not getElementData(localPlayer, "job") then
                return
        end
        eui:uiSetVisible(UI.window[1], true)
        showCursor(true)
        eui:uiSetText(UI.label.Info, {
                en = "${color.primary}• Job Name  »  #FFFFFF" .. getElementData(localPlayer, "job") .. "\n${color.primary}• In job since  »  #FFFFFF" .. ((getElementData(localPlayer, "job:data") or {})[getElementData(localPlayer, "job")] or {}).tDate or "-" .. "\n${color.primary}• Total taken salary  »  #00FF00$" .. ((getElementData(localPlayer, "job:data") or {})[getElementData(localPlayer, "job")] or {}).total_salary or "-" .. "\n" .. "\n${color.primary}• Commands:" .. "\n#FFFFFF   »»   /startjob   to    #FFFF00Start Job" .. "\n#FFFFFF   »»   /quitjob    to    #FF0000Quit Job" .. "\n#FFFFFF   »»   /jobhelp     to    ${color.primary}Show Job Help" .. "",
                ar = "${color.primary}• اسم الوظيفة  »  #FFFFFF" .. getElementData(localPlayer, "job") .. "\n${color.primary}• في الوظيفة منذ  »  #FFFFFF" .. ((getElementData(localPlayer, "job:data") or {})[getElementData(localPlayer, "job")] or {}).tDate or "-" .. "\n${color.primary}• مجموع الرواتب المأخوذة  »  #00FF00$" .. ((getElementData(localPlayer, "job:data") or {})[getElementData(localPlayer, "job")] or {}).total_salary or "-" .. "\n" .. "\n${color.primary}• أوامر:" .. "\n#FFFFFF   »»   /startjob   لـ    #FFFF00بدأ العمل" .. "\n#FFFFFF   »»   /quitjob    لـ    #FF0000الخروج من الوظيفة" .. "\n#FFFFFF   »»   /jobhelp     لـ    ${color.primary}إظهار المساعدة للوظيفة" .. ""
        })
end, false, false)

addEventHandler("onClientUIClick", root, function()
        if source == UI.button[1] then
                eui:uiSetVisible(UI.window[1], false)
                showCursor(false)
        elseif source == UI.button[2] or source == UI.button.start_job then
                triggerServerEvent("jobs:start_job", localPlayer)
                eui:uiSetVisible(UI.window[1], false)
                showCursor(false)
        elseif source == UI.button[3] or source == UI.button.quit_job then
                triggerServerEvent("jobs:quit_job", localPlayer)
                eui:uiSetVisible(UI.window[1], false)
                showCursor(false)
        elseif source == UI.gridlist.jobs then
                if eui:uiGridListGetSelectedItem(UI.gridlist.jobs) ~= -1 then
                        showJobDetails((eui:uiGridListGetItemData(UI.gridlist.jobs, eui:uiGridListGetSelectedItem(UI.gridlist.jobs), 1)))
                else
                        eui:uiSetText(UI.label.job_details, "")
                end
        end
end)

function showJobDetails(record)
        if JOBS.data[record.job_code] then
                local rank, rankIndex, nextRank = getJobRankByEXP(record.job_code, record.exp)
                eui:uiSetText(UI.label.job_details, {
                        en = "" .. "\n" .. "${color.primary}• " .. "EXP »  #FFFFFF" .. tostring(record.exp) .. "" .. "\n" .. "${color.primary}• " .. "Rank »  #FFFFFF" .. tostring(rank.name or tostring(rank)) .. "\n" .. "${color.primary}• " .. "Salary »  #FFFFFF$" .. tostring(rank.salary) .. "" .. "\n" .. "\n" .. "${color.primary}• " .. "Next rank »  #FFFFFF" .. tostring(nextRank and nextRank.name or (rankIndex + 1)) .. "" .. "\n" .. "${color.primary}• " .. "Next rank salary »  #FFFFFF$" .. tostring(nextRank and nextRank.salary or "-") .. "" .. "\n" .. "${color.primary}• " .. "Required points for next rank »  #FFFFFF" .. tostring(nextRank and nextRank.required_exp or "-") .. "" .. "\n" .. "\n" .. "${color.primary}• " .. "First work date »  #FFFFFF" .. tostring(record.first_work or "Unknown") .. "" .. "\n" .. "${color.primary}• " .. "Last work date »  #FFFFFF" .. tostring(record.last_work or "Unknown") .. "" .. "",
                        ar = "" .. "\n" .. "${color.primary}• " .. "النقاط »  #FFFFFF" .. tostring(record.exp) .. "" .. "\n" .. "${color.primary}• " .. "الرتبة »  #FFFFFF" .. tostring(rank.name or tostring(rank)) .. "\n" .. "${color.primary}• " .. "الراتب »  #FFFFFF$" .. tostring(rank.salary) .. "" .. "\n" .. "\n" .. "${color.primary}• " .. "الرتبة التالية »  #FFFFFF" .. tostring(nextRank and nextRank.name or (rankIndex + 1)) .. "" .. "\n" .. "${color.primary}• " .. "راتب الرتبة التالية »  #FFFFFF$" .. tostring(nextRank and nextRank.salary or "-") .. "" .. "\n" .. "${color.primary}• " .. "النقاط المطلوبة للرتبة التالية »  #FFFFFF" .. tostring(nextRank and nextRank.required_exp or "-") .. "" .. "\n" .. "\n" .. "${color.primary}• " .. "تاريخ أول عمل »  #FFFFFF" .. tostring(record.first_work or "غير معروف") .. "" .. "\n" .. "${color.primary}• " .. "تاريخ آخر عمل »  #FFFFFF" .. tostring(record.last_work or "غير معروف") .. "" .. ""
                })
        end
end

function getJobRankByEXP(jobCode, exp)
        if JOBS.data[jobCode] then
                local last
                for index, rank in ipairs(JOBS.data[jobCode].ranks) do
                        if exp >= rank.required_exp then
                                last = index
                        else
                                break
                        end
                end
                if JOBS.data[jobCode].ranks[last] then
                        return JOBS.data[jobCode].ranks[last], last, JOBS.data[jobCode].ranks[last + 1]
                end
        end
        return false
end

addEventHandler("onClientUIMenuSelectChange", root, function(row, toggleElement)
        if toggleElement and getElementID(source) == "main-menu" and eui:uiMenuGetItemID(source, row) == "jobs" then
                if not isElement(UI.rectangle.job_current) then
                        UI.rectangle.job_current = eui:uiCreateRectangle(15, 60, eui:uiGetSize(toggleElement) - 30, eui:uiGetSize(toggleElement) * 0.3, tocolor(9, 12, 17, 180), true, true, true, true, toggleElement)
                        eui:uiCreateRectangle((eui:uiGetSize(toggleElement) - eui:uiGetSize(toggleElement) / 2) / 2, eui:uiGetSize(toggleElement) * 0.3, eui:uiGetSize(toggleElement) / 2, 1, "primary", false, false, false, false, UI.rectangle.job_current)
                        UI.label.job_current = eui:uiCreateLabel(30, 25, 300, 20, "- #a3a3a3/ -\n" .. "\n" .. "${color.primary}• " .. "الرتبة »  #FFFFFF" .. tostring("1") .. "\n" .. "${color.primary}• " .. "النقاط »  #FFFFFF" .. tostring("0") .. "" .. "\n" .. "${color.primary}• " .. "الراتب »  #FFFFFF" .. tostring("$0") .. "" .. "", tocolor(255, 255, 255, 255), "left", "top", UI.rectangle.job_current)
                        eui:uiSetFont(UI.label.job_current, "default-large")
                        UI.button.start_job = eui:uiCreateButton(eui:uiGetSize(toggleElement) - 30 - 150 - 20, 20, 150, 35, {
                                en = "Start Job",
                                ar = "بدأ العمل"
                        }, tocolor(0, 0, 0, 255), UI.rectangle.job_current)
                        UI.button.quit_job = eui:uiCreateButton(eui:uiGetSize(toggleElement) - 30 - 150 - 20, 65, 150, 35, {
                                en = "Quit Job",
                                ar = "الخروج من الوظيفة"
                        }, tocolor(252, 40, 25, 255), UI.rectangle.job_current)
                        eui:uiSetProperty(UI.button.quit_job, "HoverGlow", true)
                        UI.container.jobs = eui:uiCreateRectangle(15, 60 + eui:uiGetSize(toggleElement) * 0.3 + 20, eui:uiGetSize(toggleElement) - 30, eui:uiGetSize(toggleElement) * 0.7 - 110, tocolor(9, 12, 17, 180), true, true, true, true, toggleElement)
                        UI.gridlist.jobs = eui:uiCreateGridList(10, 10, 200, eui:uiGetSize(toggleElement) * 0.7 - 110 - 20, tocolor(0, 0, 0, 0), UI.container.jobs)
                        eui:uiGridListAddColumn(UI.gridlist.jobs, "Job name", 1)
                        eui:uiSetProperty(UI.gridlist.jobs, "row_height", 25)
                        UI.label.job_details = eui:uiCreateLabel(240, 20, 300, 20, "", tocolor(255, 255, 255, 255), "left", "top", UI.container.jobs)
                        eui:uiCreateImage(eui:uiGetSize(toggleElement) - 30 - 240, 50, 200, 200, "briefcase.png", UI.container.jobs)
                end
                if getElementData(localPlayer, "job") then
                        eui:uiSetVisible(UI.button.start_job, true)
                        eui:uiSetVisible(UI.button.quit_job, true)
                else
                        eui:uiSetVisible(UI.button.start_job, false)
                        eui:uiSetVisible(UI.button.quit_job, false)
                end
                requestJobs()
                triggerServerEvent("jobs:get_character_data", localPlayer)
        end
end)

addEvent("jobs:get_character_data:response", true)
addEventHandler("jobs:get_character_data:response", localPlayer, function(records)
        eui:uiGridListClear(UI.gridlist.jobs)
        for _, record in ipairs(records) do
                if JOBS.data[record.job_code] then
                        -- decompiler lost the `local row` here as well
                        local row = eui:uiGridListAddRow(UI.gridlist.jobs)
                        eui:uiGridListSetItemText(UI.gridlist.jobs, row, 1, tostring(JOBS.data[record.job_code].name))
                        eui:uiGridListSetItemData(UI.gridlist.jobs, row, 1, record)
                        if getElementData(localPlayer, "job") == JOBS.data[record.job_code].name then
                                eui:uiGridListSetSelectedItem(UI.gridlist.jobs, row)
                                showJobDetails(record)
                        end
                end
        end
        local currentJob, currentRecord
        for _, record in ipairs(records) do
                local data = JOBS.data[record.job_code]
                if data then
                        data.job_code = record.job_code
                        if getElementData(localPlayer, "job") == data.name then
                                currentJob = data
                                currentRecord = record
                        end
                end
        end
        if currentJob then
                local rank = getJobRankByEXP(currentJob.job_code, currentRecord.exp or 0)
                eui:uiSetText(UI.label.job_current, {
                        en = currentJob.name .. " #a3a3a3 \n" .. "\n" .. "${color.primary}• " .. "Points »  #FFFFFF" .. tostring(currentRecord.exp or 0) .. "" .. "\n" .. "${color.primary}• " .. "Rank »  #FFFFFF" .. tostring(rank.name or tostring(rank)) .. "\n" .. "${color.primary}• " .. "Salary »  #FFFFFF" .. tostring("$" .. rank.salary) .. "" .. "",
                        ar = currentJob.name .. " #a3a3a3 \n" .. "\n" .. "${color.primary}• " .. "النقاط »  #FFFFFF" .. tostring(currentRecord.exp or 0) .. "" .. "\n" .. "${color.primary}• " .. "الرتبة »  #FFFFFF" .. tostring(rank.name or tostring(rank)) .. "\n" .. "${color.primary}• " .. "الراتب »  #FFFFFF" .. tostring("$" .. rank.salary) .. "" .. ""
                })
        else
                eui:uiSetText(UI.label.job_current, {
                        en = "Not currently employed",
                        ar = "غير موظف حالياً"
                })
        end
end)

addEventHandler("onClientResourceStart", root, function(startedResource)
        if getElementData(localPlayer, "job") then
                triggerEvent("onClientPlayerJobResourceReady", getResourceRootElement(startedResource), (getElementData(localPlayer, "job")))
        end
end)
addEvent("onClientPlayerJobReady", false)
addEvent("onClientPlayerJobResourceReady", false)
addEvent("onClientPrepareJob", false)

function isPlayerInJob(element, jobName)
        if getElementData(element, "job") and getElementData(element, "job") == jobName then
                return true
        end
        return false
end

function getJobRequirements(jobCode)
        return JOBS.data[jobCode] and JOBS.data[jobCode].requirements or false
end

function checkJobRequirements(jobCode, notify)
        if getJobRequirements(jobCode).min_level and exports["level-system"]:getPlayerLevel() < getJobRequirements(jobCode).min_level then
                if notify then
                        exports.notifications:output({
                                en = "Your level must be " .. tostring(getJobRequirements(jobCode).min_level) .. " or above",
                                ar = "أو أعلى " .. tostring(getJobRequirements(jobCode).min_level) .. " يجب أن يكون مستواك"
                        }, 5000, "error")
                end
                return false
        end
        if getJobRequirements(jobCode).driving_license then
                if not exports["driving-license"]:isPlayerHaveLicense(localPlayer, getJobRequirements(jobCode).driving_license_type or "Vehicles") then
                        if notify then
                                exports.notifications:output({
                                        en = "You must have a driving license",
                                        ar = "يجب أن يكون لديك رخصة قيادة"
                                }, 5000, "error")
                        end
                        return false
                end
        end
        if getJobRequirements(jobCode).off_duty and getElementData(localPlayer, "duty:data") and getElementData(localPlayer, "duty:data").Status then
                exports.notifications:output({
                        en = "You must be off duty",
                        ar = "يجب أن تكون خارج الخدمة"
                }, 5000, "error")
                return false
        end
        return true
end
