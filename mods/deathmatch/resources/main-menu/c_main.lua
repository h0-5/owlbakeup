--[[ ------------------------------------------------------------------------
        Vortex Main Menu (F1) — EXACT port of the OLD CLIENT design.

        Source of truth: the original client backup the user pointed at
        (github.com/h0-5/backupm -> [rp]/main-menu/client_decompiled.lua plus
        the help-system / report-system menu hooks). Every visible decision
        below is the OLD client's, not an invention:

          window          uiCreateRectangle(false,false, refSx*0.75-130, refSy*0.65)
          sidebar menu    uiCreateMenu(5, 15, 220, winH) with row_height 33,
                          hovered (9,12,17,100), selected (3,6,11,250),
                          white selection, icons tinted theme primary
          content panel   uiCreateRectangle(250, 5, W-250, H-10, (3,6,11,240))
                          + the four white 10x2 corner ticks
          strip draw      dark veil -> strip -> bg_gradient -> divider ->
                          logo.png (alpha 200) -> logo_text.png rotated -90
                          (alpha 50 watermark), exactly like main_menu_draw()
          sections        character_info / onlinestaff / leaderboard / rules /
                          commands / report / linkdiscord / about
                          (rules = read-only memo, commands = tabpanel with the
                          7 classic section gridlists, report = explanation +
                          type gridlist + the two Report Center windows — the
                          exact old help-system/report-system flow)

        Server rules kept (user requirements, enforced server-side):
          - reports need >= 15 words, one report per 5 minutes
            (report-system/s_reports.lua is authoritative)
          - F2 lands on the reports section
          - the "help request" section stays removed
-------------------------------------------------------------------------- ]]

local sx, sy = guiGetScreenSize()

--[[ reference screen — mirrors UIKit core/c_main.lua exactly ]]
local refSx, refSy = 1728, 972
if sx == 800 and sy == 600 then
        refSx, refSy = 1024, 768
end
local SCALE_X, SCALE_Y = sx / refSx, sy / refSy
if sx == 800 and sy == 600 then
        SCALE_X, SCALE_Y = SCALE_X * 0.7, SCALE_Y * 0.85
        refSx, refSy = sx / SCALE_X, sy / SCALE_Y
end
if sx == 1024 and sy == 768 then
        SCALE_X, SCALE_Y = SCALE_X * 1.05, SCALE_Y * 0.9
        refSx, refSy = sx / SCALE_X, sy / SCALE_Y
end

-- [Fix] UIKit may not be running yet when this script loads; a hard error
-- here would kill the whole resource. buildMainMenuUI re-resolves it (line ~482).
local eui = (function()
        local ok, t = pcall(function() return exports.UIKit end)
        if ok then return t end
        return nil
end)()

--[[ ============================== branding ============================== ]]

local LINKS = {
        discord      = "https://discord.gg/wnashtime",
        factions     = "https://discord.gg/TJPjhE8XMf",
        gangs        = "https://discord.gg/rQRMUkx7Pz",
        youtube      = "https://www.youtube.com/channel/UCAPHuNaKb1dF1zcYMH7HdCw",
        store        = "https://store.wnashtime.net",
        linkdiscord  = "https://wnashtime.net/linkdiscord",
}

local VERSION_LINE = "Version 2.1.0  -  Vortex Roleplay  -  Season 3"

--[[ ============================== sections ==============================
        The 8 sections of the old client sidebar (the ids the old
        help-system / report-system hooked: "rules", "commands", "report"). ]]

local SECTIONS = {
        { id = "character_info", en = "Personal Info",  ar = "المعلومات الشخصية",  icon = "icons/menu_person.png" },
        { id = "onlinestaff",    en = "Online Staff",   ar = "الإدارة المتصلة",    icon = "icons/menu_shield.png" },
        { id = "leaderboard",    en = "Leaderboard",    ar = "المتصدرين",          icon = "icons/menu_trophy.png" },
        { id = "rules",          en = "Rules & Terms",  ar = "قوانين ومصطلحات",    icon = "icons/verified.png" },
        { id = "radio",          en = "Radio Channels", ar = "قنوات الراديو",      icon = "icons/radio.png" },
        { id = "commands",       en = "Commands",       ar = "الأوامر",            icon = "icons/menu_chat.png" },
        { id = "report",         en = "Report",         ar = "البلاغات",           icon = "icons/reportpanel.png" },
        { id = "linkdiscord",    en = "Link Discord",   ar = "ربط الديسكورد",      icon = "icons/discord.png" },
        -- [Fix #63] awards section - the old client jumped to menu row 9 for
        -- "Level Awards" (client_decompiled.lua: uiMenuSetSelectedRow(var2, 9))
        -- and c_level.lua builds its awards tab inside UI.container["awards"]
        -- when uiMenuGetItemID == "awards" - row 9 = this section
        { id = "awards",         en = "Level Awards",    ar = "جوائز المستوى",      icon = "icons/rank.png" },
        { id = "about",          en = "About Server",   ar = "عن السيرفر",         icon = "icons/menu_globe.png" },
        { id = "jobs",           en = "Jobs",            ar = "الوظائف",            icon = "icons/menu_suitcase.png" },
}

--[[ report types — MUST stay in report-system/g_reports.lua order ]]
local REPORT_TYPES = {
        "Issue with another player",
        "Interior Issue",
        "Item Issue",
        "General Question",
        "Vehicle Related Issues",
        "Vehicle Build/Import Requests",
        "Scripting Question",
}

--[[ rules memo content — the same law text, old-client presentation ]]
local RULES_TEXT = table.concat({
        "——— القاعدة الذهبية ———\n",
        "• الاحترام أولاً: عامل الناس كما تحب أن تعامل. الإهانة أو التنمر أو الكلام العنصري يعرضك للعقوبة مهما كان سببك.\n",
        "• ساعد الجدد: مساعدة اللاعبين الجدد من أجمل ما يميز المجتمع، وكن عضواً إيجابياً فيه.\n",
        "• الحس السليم: استخدم الحس السليم أثناء اللعب وتذكر أن الجميع هنا ليتسلى ويرتاح.\n",
        "\n——— قواعد الحساب ———\n",
        "• حساب واحد فقط: ممنوع استخدام أكثر من حساب واحد. تثبيت أكثر من حساب يؤدي إلى حظر دائم مع حق النداء في الديسكورد.\n",
        "• نقل الأصول: نقل الأموال أو المركبات أو العقارات بين الشخصيات ممنوع إلا للمشتركين المميزين، ومخالفته تعني إعادة ضبط كامل للشخصيات.\n",
        "• الدعاية: إرسال روابط أو الحديث عن سيرفرات أو مجتمعات أو عصابات أخرى داخل اللعبة ممنوع منعاً باتاً.\n",
        "• انتحال الأسماء: انتحال اسم لاعب آخر أو تمثيل دور أحد الإداريين ممنوع ويعرضك لعقوبات قاسية.\n",
        "\n——— الأخطاء والعملات ———\n",
        "• استغلال البق: استغلال أي خطأ برمجي (تكرار فلوس أو مركبات أو أغراض) ممنوع. أبلغ عنه فوراً عبر البلاغات، وإخفاؤه واستغلاله يعرضك للحظر وإعادة ضبط الحساب.\n",
        "• العملات: عملات الشخصية (فلوس ومركبات وعقارات) منفصلة عن عملاتك الشخصية. تبادلها بين الواقع واللعبة ممنوع ويؤدي إلى إعادة ضبط الشخصيات.\n",
        "\n——— قواعد اللعبة ———\n",
        "• القتل العشوائي DM: قتل أي لاعب بدون سبق رول بلاي واضح ممنوع، والانتقام القتل يدخل تحت نفس القاعدة.\n",
        "• القفز الأرنب: القفز المتواصل (Bunny Hop) للتسرع بالحركة غير واقعي وممنوع.\n",
        "• الغياب AFK: الغياب في الأماكن العامة ممنوع. إن أردت الغياب فاذهب لمنزلك أو مكان هادئ.\n",
        "• كسر القانون: إن شاهدت أحداً يكسر القوانين فأبلغ عنه عبر البلاغات ولا تكسر القانون بدورك.\n",
        "\n——— الرول بلاي ———\n",
        "• الميتا جيمنج MG: استخدام معلومات من خارج اللعبة (الديسكورد أو الشات b و t) داخل الرول بلاي ممنوع، شخصيتك تعرف فقط ما جرى أمامها.\n",
        "• الباور جيمنج PG: الأفعال الخارقة عن الواقع أو التصرف بغير منطق الحياة الواقعية ممنوع.\n",
        "• حذف الشخصية CK: حذف الشخصية نهائياً والبدء بشخصية جديدة، ومن أسبابه دخول الفاشن وأخذ أمواله والهروب.\n",
        "• الرسائل الخاصة: مسموحة ما لم تزعج المتلقي، وما يخص المشاكل والبلاغات يفتح عبر نظام البلاغات فقط.\n",
        "\n——— المصطلحات ———\n",
        "• الرول بلاي RP: تمثيل دور شخصية تعيش داخل المدينة كأنها حياة حقيقية، وتتصرف بمنطق شخصيتك لا بمنطقك أنت.\n",
        "• الميتا جيمنج MG: استخدام معلومات وصلتك من خارج اللعبة (ديسكورد، شات b و t) داخل الرول بلاي. شخصيتك تعرف فقط ما جرى أمامها.\n",
        "• الباور جيمنج PG: فرض قوى خارقة أو تصرفات غير واقعية لا يمكن لشخصية عادية فعلها (تحمل طائرة بيديك، تصمد بعد قتلك).\n",
        "• القتل العشوائي DM: مهاجمة أو قتل لاعب بدون سبب رول بلاي واضح.\n",
        "• الانتقام القتل RK: الرجوع للانتقام من قاتلك بدون رول بلاي جديد. بعد موتك تفقد ذكرى الأحداث التي أدت لموتك.\n",
        "• القتل الدائم CK: موت نهائي ينهي الشخصية بقرار إداري أو باتفاق اللاعب، وتُحذف الشخصية من السيرفر.\n",
        "• قاعدة الحياة الجديدة NLR: بعد موتك انسَ سيناريو موتك ولا تعد لمكان موت لتأخذ belongings أو تواصل المشهد.\n",
        "• داخل الشخصية IC: كل ما يقال ويُفعل بأنك شخصيتك داخل عالم اللعبة.\n",
        "• خارج الشخصية OOC: الحديث الحقيقي خارج الرول بلاي، ويكون بأوامر الشات المخصصة مثل /b و /pm فقط.\n",
        "• الخوف من الموت Fear RP: شخصيتك تخاف على حياتها؛ لا تشاور سلاحاً وأنت مطروق بالأرض ولا تقاوم أربع نقاط تفتح عليك النار.\n",
})

--[[ commands — the 7 classic sections (Chat/Factions/Vehicles/Properties/
        Items/Jobs/Misc) filled with THIS server's real commands ]]
local COMMAND_SECTIONS = {
        { name = "Chat", rows = {
                { "/b",    "—", "كلام خارج الرول بلاي (OOC) لمن حولك",       "الجميع" },
                { "/w",    "—", "همسة خاصة للاعب قريب منك",                  "الجميع" },
                { "/s",    "—", "صراخ — شات عام قريب",                       "الجميع" },
                { "/do",   "—", "وصف حدث أو بيئة حول شخصيتك",                "الجميع" },
                { "/ame",  "—", "فعل يظهر فوق رأسك",                         "الجميع" },
                { "/ado",  "—", "صوت يظهر فوق رأسك",                         "الجميع" },
                { "/pm",   "—", "رسالة خاصة للاعب",                          "الجميع" },
                { "/pay",  "—", "تحويل فلوس للاعب قريب منك",                 "الجميع" },
        } },
        { name = "Factions", rows = {
                { "—", "—", "أوامر الفاشنات تُدار من داخل لوحة الفاشن (تصلك مع تحديث الفاشنات)", "الجميع" },
        } },
        { name = "Vehicles", rows = {
                { "/engine",    "—", "تشغيل / إطفاء محرك المركبة",      "الجميع" },
                { "/lights",    "—", "تشغيل / إطفاء إضاءة المركبة",     "الجميع" },
                { "/lock",      "—", "قفل / فتح المركبة",               "الجميع" },
                { "/doors",     "—", "فتح / إغلاق أبواب المركبة",       "الجميع" },
                { "/park",      "—", "إيقاف المركبة في مكانها",         "الجميع" },
                { "/int",       "—", "دخول مقصورة المركبة أو الخروج منها", "الجميع" },
        } },
        { name = "Properties", rows = {
                { "—", "—", "البيوت والمحلات تُدار من أبوابها داخل اللعبة (شراء وبيع و rent)", "الجميع" },
        } },
        { name = "Items", rows = {
                { "—", "—", "الأغراض تُدار من نظام الحقيبة (تصلك مع تحديث الحقيبة)", "الجميع" },
        } },
        { name = "Jobs", rows = {
                { "/job",     "—", "عرض الوظائف المتاحة",        "الجميع" },
                { "/myjob",   "—", "معلومات وظيفتك الحالية",     "الجميع" },
                { "/quitjob", "—", "ترك وظيفتك الحالية",         "الجميع" },
                { "/endjob",  "—", "إنهاء مهمة الوظيفة",         "الجميع" },
        } },
        { name = "Misc", rows = {
                { "F1",     "F1",    "القائمة الرئيسية والمعلومات الشخصية",        "الجميع" },
                { "F2",     "F2",    "البلاغات — فتح قسم البلاغات مباشرة",          "الجميع" },
                { "/menu",  "—",     "فتح القائمة الرئيسية (بديل F1)",             "الجميع" },
                { "/report","—",     "فتح بلاغ للإدارة (15 كلمة على الأقل، وبلاغ كل 5 دقائق)", "الجميع" },
                { "/er",    "—",     "إغلاق بلاغك الحالي",                         "الجميع" },
                { "/id",    "—",     "عرض أرقام اللاعبين المتصلين",                "الجميع" },
                { "/staffs","—",     "لوحة الهيئة الإدارية (للإداريين فقط)",       "إدارة" },
        } },
}

local GENDERS = { "Male", "Female" }
local COUNTRIES = {}

--[[ ============================== state ============================== ]]

local UI = {
        tab = {}, progressbar = {}, edit = {}, window = {}, label = {}, checkbox = {},
        switch = {}, button = {}, tabpanel = {}, radiobutton = {}, gridlist = {},
        memo = {}, scrollbar = {}, combobox = {}, container = {}, image = {}, rectangle = {},
}

local menu = false            -- ui-menu element
local currentLinkCode = false -- discord link code
local pendingCode = false     -- generate-code request in flight
local selectedReportType = 0  -- 1-based index into REPORT_TYPES

local state = {
        state = false,  -- sidebar open?
        alpha = 0,      -- current overlay alpha
        sideX = -260,   -- current branding strip width (slides)
        anim = false,
        vehicles = 0,   -- fetch throttles (tick stamps)
        interiors = 0,
        ["leaderboard:levels"] = 0,
        ["leaderboard:activities"] = 0,
}

--[[ ============================== helpers ============================== ]]

local resCache = {}
local function resRunning(name)
        if resCache[name] ~= nil then return resCache[name] end
        local res = getResourceFromName(name)
        local ok, running = false, false
        if res then
                ok, running = pcall(getResourceState, res)
        end
        resCache[name] = ok and running == "running"
        return resCache[name]
end

-- call a client export of another resource safely (nil when unavailable)
local function safeExport(resName, fnName, ...)
        if not resRunning(resName) then return nil end
        local res = getResourceFromName(resName)
        if not res then return nil end
        local ok, result = pcall(call, res, fnName, ...)
        if ok then return result end
        return nil
end

-- notifications with a chat fallback until the notifications mod is restored
local function notify(text, duration, kind)
        if type(text) ~= "table" then text = { en = tostring(text), ar = tostring(text) } end
        if resRunning("notifications") then
                local ok = pcall(function()
                        exports.notifications:output(text, duration or 3000, kind or "success")
                end)
                if ok then return end
        end
        outputChatBox(text.ar or text.en or "")
end

-- character data: exports.roleplay:getCharacter() when the mod is restored,
-- element-data fallback meanwhile
local function getCharacter()
        local c = safeExport("roleplay", "getCharacter")
        if type(c) == "table" then return c end
        local id = getElementData(localPlayer, "character:id")
                or getElementData(localPlayer, "account:character:id")
        return {
                ID = id or "-",
                Name = getPlayerName(localPlayer),
                Info = {},
                country = false,
        }
end

local function getPlayerIDStr(player)
        local id = safeExport("roleplay", "getPlayerID", player)
        if id then return tostring(id) end
        return tostring(getElementData(player, "character:id")
                or getElementData(player, "account:character:id") or "-")
end

-- number formatting with thousand separators
function convertNumber(amount)
        amount = tostring(amount)
        local formatted = amount
        while true do
                local k
                formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
                if k == 0 then break end
        end
        return formatted
end

function convertTimeToString(seconds)
        seconds = tonumber(seconds) or 0
        return math.floor(seconds / (24 * (60 * 60))) .. "d "
                .. math.floor(seconds % (24 * (60 * 60)) / (60 * 60)) .. "h "
                .. math.floor(seconds % (24 * (60 * 60)) % (60 * 60) / 60) .. "m"
end

-- linear/out-quad interpolation for the sidebar slide + overlay fade
-- anim = { start, fromAlpha, fromSideX, toAlpha, toSideX, duration, easeOut }
function animation(anim)
        local elapsed = getTickCount() - anim[1]
        local progress = math.min(elapsed / anim[6], 1)
        if anim[7] then
                progress = 1 - (1 - progress) * (1 - progress)
        end
        return anim[2] + (anim[4] - anim[2]) * progress,
                anim[3] + (anim[5] - anim[3]) * progress
end

--[[ ============================== drawing ==============================
        EXACTLY the old main_menu_draw(): veil -> strip -> gradient ->
        divider -> logo (alpha 200) -> rotated wordmark watermark (alpha 50). ]]

local logoTex
local wordmarkTex
local wordmarkAspect = 2925 / 1048 -- logo_text.png natural aspect
local bgGradient = false
if fileExists(":UIKit/images/gradient_x.png") then
        bgGradient = dxCreateTexture(":UIKit/images/gradient_x.png", "argb", true, "clamp")
end
if fileExists("images/logo.png") then
        logoTex = dxCreateTexture("images/logo.png", "argb", true, "clamp")
else
        logoTex = dxCreateTexture("logo-circle.png", "argb", true, "clamp")
end
if fileExists("images/logo_text.png") then
        wordmarkTex = dxCreateTexture("images/logo_text.png", "argb", true, "clamp")
end

local LOGO_SIZE = 110
local WORDMARK_LEN = 560 -- Fix #26: bigger wordmark (user)

--[[ [Fix #47 - FPS] RENDER-TARGET CHROME CACHE (the #2 fpsdiag culprit, 74
     FPS while the menu is open vs 32 baseline). Once the slide-in animation
     settles, the veil + strip + gradient + divider + logo + rotated wordmark
     are PIXEL-STATIC but were re-drawn every frame: 2 fullscreen alpha draws
     + a fullscreen gradient + a big ROTATED image = heavy fill-rate on weak
     GPUs. The settled chrome is now painted ONCE into a render target and
     each frame costs one dxDrawImage. While the animation runs (and whenever
     the GPU context is restored) it falls back to the live draw, so the
     motion is untouched and the layering vs UIKit's window is identical
     (the RT is drawn from the same "high-2" handler). ]]
local chromeRT = false
local chromeDirty = true

local function drawChromeLive()
        -- dark veil over the game
        dxDrawRectangle(0, 0, sx, sy, tocolor(0, 0, 0, math.max(0, state.alpha - 80)), true)
        -- branding strip sliding in from the left
        dxDrawRectangle(0, 0, state.sideX, sy, tocolor(0, 3, 8, state.alpha), true)
        if bgGradient then
                dxDrawImage(state.sideX, 0, sx, sy, bgGradient, 0, 0, 0, tocolor(0, 3, 8, state.alpha), true)
        end
        -- divider line (old: sideX + 2, 1px, alpha 10)
        if state.sideX > 0 then
                dxDrawRectangle(state.sideX + 2 * SCALE_X, 0, SCALE_X, sy, tocolor(255, 255, 255, 10), true)
        end
        if state.sideX > 60 then
                -- logo at the top of the strip, alpha 200 like the old draw
                if logoTex then
                        local size = LOGO_SIZE * SCALE_Y
                        dxDrawImage((state.sideX - size) / 2, 26 * SCALE_Y, size, size,
                                logoTex, 0, 0, 0, tocolor(255, 255, 255, 200), true)
                end
                -- wordmark watermark: rotated -90 (reads bottom -> top, V at
                -- the bottom), alpha 50, centered on the strip — the old
                -- logo_text.png treatment
                if wordmarkTex then
                        local len = WORDMARK_LEN * SCALE_Y
                        local thick = len / wordmarkAspect
                        local cx = state.sideX / 2
                        -- Fix #26: raised up (biased to 38% of the free strip)
                        local cy = 26 * SCALE_Y + LOGO_SIZE * SCALE_Y
                                + (sy - (26 * SCALE_Y + LOGO_SIZE * SCALE_Y)) * 0.38
                        dxDrawImage(cx - len / 2, cy - thick / 2, len, thick,
                                wordmarkTex, -90, 0, 0, tocolor(255, 255, 255, 85), true)
                end
        end
end

local function paintChromeRT()
        if not isElement(chromeRT) then
                local ok, rt = pcall(dxCreateRenderTarget, sx, sy, true)
                if not ok or not rt then chromeDirty = false return false end
                chromeRT = rt
        end
        local ok = pcall(function()
                dxSetRenderTarget(chromeRT, true)
                drawChromeLive()
                dxSetRenderTarget()
        end)
        chromeDirty = false
        return ok
end

addEventHandler("onClientRestore", root, function() chromeDirty = true end)

function main_menu_draw()
        state.alpha, state.sideX = animation(state.anim)
        local settled = getTickCount() - state.anim[1] >= state.anim[6]
        if settled then
                if chromeDirty then paintChromeRT() end
                if isElement(chromeRT) then
                        dxDrawImage(0, 0, sx, sy, chromeRT, 0, 0, 0,
                                tocolor(255, 255, 255, 255), true)
                        return
                end
        end
        drawChromeLive()
end

--[[ F1 / ESC-binds cancel while quitting the character ]]
function cancelBindsEvent(key, press)
        if press and (key == "F1" or key == "F2" or key == "F3" or key == "F4"
                or key == "F11" or key == "F7") then
                cancelEvent()
        end
end

-- [Fix #53] true while main_menu_draw is actually attached to onClientRender
-- (kept in sync inside showSideBarInner). MainMenuKey reads this instead of
-- isEventHandlerAdded(), which is a global that only exists INSIDE the UIKit
-- resource — every resource has its own Lua environment, so the call errored
-- with "attempt to call global 'isEventHandlerAdded' (a nil value)" exactly
-- when state.state was true (second F1 press) and aborted before showSideBar:
-- F1 opened the menu but the second press never closed it.
local menuDrawRegistered = false

local lastF1GateWarn = 0
function MainMenuKey()
        -- original gate is character:id (wnash RP core, not restored yet);
        -- this server's account system sets SYNCED loggedin=1 on character
        -- selection and 0 on quit — accept either so F1 works on both stacks.
        -- [Fix #35] accept every shape the stack actually produces (string
        -- "1", account:character:id) and REPORT the block instead of dying
        -- silently - "F1 does nothing" was un-diagnosable from chat.
        local loggedin = getElementData(localPlayer, "loggedin")
        if getElementData(localPlayer, "character:id")
                or getElementData(localPlayer, "account:character:id")
                or tonumber(loggedin) == 1 then
                -- [Fix #33] a half-closed previous frame could leave state.state
                -- stuck true with NO render handler running -> F1 then toggled
                -- an invisible menu and looked dead. Trust the real draw state.
                -- [Fix #53] isEventHandlerAdded is not defined in this resource
                -- (cross-resource globals do not exist) -> replaced with the
                -- local registration flag kept by showSideBarInner.
                local reallyOpen = state.state and menuDrawRegistered
                showSideBar(not reallyOpen)
        else
                local now = getTickCount()
                if now - lastF1GateWarn > 10000 then
                        lastF1GateWarn = now
                        outputChatBox("[F1] blocked until character select (loggedin="
                                .. tostring(loggedin) .. ")", 255, 220, 120, false)
                end
        end
end
bindKey("F1", "down", MainMenuKey)
addCommandHandler("menu", MainMenuKey, false, false)

-- F2 = reports hub (opens the same sidebar directly on the reports section)
function ReportsMenuKey()
        if getElementData(localPlayer, "character:id")
                or getElementData(localPlayer, "account:character:id")
                or tonumber(getElementData(localPlayer, "loggedin")) == 1 then
                local wasOpen = state.state
                showSideBar(not wasOpen, "report")
        end
end
bindKey("F2", "down", ReportsMenuKey)
-- /report stays owned by report-system (classic admin window)

addEvent("onClientPlayerQuitFromCharacter", true)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, function()
        showSideBar(false)
end)

function showEscapeView(show)
        showSideBar(show)
end

function isOpen()
        return state.state
end

function getMenuElement()
        return menu
end

--[=[ Fix #33 ] the open/close is pcall-wrapped: any error used to leave the
-- menu permanently dead (state flipped, window half-built, handler missing)
-- with NO trace. Now the first error is shown in chat, the half-built window
-- is dropped and one clean rebuild+retry runs immediately. ]=]
local uiBuilt = false -- rebuild guard (declared BEFORE its users - Fix #33)

local function showSideBarInner(show, openSection)
        -- [Fix #32] if the UIKit window was ever lost (a UIKit restart, or
        -- the old draw-list wipe when another resource stopped), rebuild it
        -- on demand instead of pressing F1 into nothing
        if show and (not UI.window.MainMenu or not isElement(UI.window.MainMenu)) then
                uiBuilt = false
                UIKitReady()
        end
        state.state = show
        showCursor(show)
        if show then
                state.anim = { getTickCount(), state.alpha, state.sideX, 250, 250, 350, true }
                chromeDirty = true -- [Fix #47] repaint the settled chrome RT
                if not menuDrawRegistered then
                        addEventHandler("onClientRender", root, main_menu_draw, false, "high-2")
                        menuDrawRegistered = true
                end
                eui:uiSetVisible(UI.window.MainMenu, true)
                -- optional section to land on (F2 -> reports)
                local target = 1
                if openSection then
                        for i, section in ipairs(SECTIONS) do
                                if section.id == openSection then target = i end
                        end
                end
                eui:uiMenuSetSelectedRow(menu, target)
        else
                removeEventHandler("onClientRender", root, main_menu_draw)
                menuDrawRegistered = false
                state.anim = { getTickCount(), state.alpha, state.sideX, 0, -260, 250, false }
                eui:uiSetVisible(UI.window.MainMenu, false)
                -- [Fix #47] free the fullscreen chrome RT while the menu is closed
                if isElement(chromeRT) then destroyElement(chromeRT) end
                chromeRT = false
                chromeDirty = true
        end
end

function showSideBar(show, openSection)
        local ok, err = pcall(showSideBarInner, show, openSection)
        if not ok then
                outputChatBox("#ff6b6b[F1] " .. tostring(err), 255, 107, 107, true)
                uiBuilt = false
                if UI.window.MainMenu and isElement(UI.window.MainMenu) then
                        destroyElement(UI.window.MainMenu)
                end
                UI.window.MainMenu = nil
                pcall(showSideBarInner, show, openSection)
        end
end

--[[ ===================== UIKit construction (old design) ===================== ]]

-- [Fix #33] the uiBuilt guard lives right above showSideBarInner (both it
-- and buildMainMenuUI must share the SAME local)

-- [Fix #33] F1 has been reported dead on the live server twice. Any runtime
-- error inside the ~900-line build silently aborted it and the menu never
-- came back. The whole build is now pcall-wrapped; the FIRST error is
-- printed in chat (so it can be reported) and the next F1 retries cleanly.
local function buildMainMenuUI()
        -- only one live panel per UIKit lifetime: both onClientUIReady and
        -- onClientUIKitReady fire on some start orders (and UIKit may restart
        -- while main-menu is up). A COMPLETED build is kept, an ABORTED one
        -- (UIKit not running yet) is discarded and rebuilt on the next event.
        if UI.window.MainMenu and isElement(UI.window.MainMenu) then
                if uiBuilt then return end
                destroyElement(UI.window.MainMenu)
        end
        eui = exports.UIKit

        UI.window.MainMenu = eui:uiCreateRectangle(false, false,
                refSx * 0.75 - 130, refSy * 0.65, tocolor(19, 22, 27, 0), true, true, true, true)
        eui:uiSetVisible(UI.window.MainMenu, false)
        eui:uiBringToFront(UI.window.MainMenu)

        local winW, winH = refSx * 0.75 - 130, refSy * 0.65
        local contentW, contentH = winW - 220 - 30, winH - 10

        -- sidebar menu — EXACT old client properties (row_height 33, compact
        -- rows, white selection text, primary-tinted icons)
        menu = eui:uiCreateMenu(5, 15, 220, winH, tocolor(19, 22, 27, 0), UI.window.MainMenu)
        eui:uiSetProperty(menu, "hovered_row_color", tocolor(9, 12, 17, 100))
        eui:uiSetProperty(menu, "selected_row_color", tocolor(3, 6, 11, 250))
        eui:uiSetProperty(menu, "row_height", 33)
        eui:uiSetProperty(menu, "icons_color", eui:uiGetThemeColor("primary"))
        eui:uiSetProperty(menu, "selection_color", tocolor(255, 255, 255))
        setElementID(menu, "main-menu")

        -- [Fix #59] ONE shared content panel for every section (was: an
        -- opaque panel per section, all stacked at the same coordinates ->
        -- only the LAST section could ever be seen and F1 navigation looked
        -- dead). Corner ticks are decoration -> drawn once.
        local contentPanel = eui:uiCreateRectangle(220 + 30, 5, contentW, contentH,
                tocolor(3, 6, 11, 240), true, true, true, true, UI.window.MainMenu)
        eui:uiCreateRectangle(30, 0, 10, 2, tocolor(255, 255, 255, 240),
                false, false, false, false, contentPanel)
        eui:uiCreateRectangle(contentW - 40, contentH - 2, 10, 2, tocolor(255, 255, 255, 240),
                false, false, false, false, contentPanel)
        eui:uiCreateRectangle(contentW - 40, 0, 10, 2, tocolor(255, 255, 255, 240),
                false, false, false, false, contentPanel)
        eui:uiCreateRectangle(30, contentH - 2, 10, 2, tocolor(255, 255, 255, 240),
                false, false, false, false, contentPanel)

        for _, section in ipairs(SECTIONS) do
                UI.container[section.id] = eui:uiCreateContainer(0, 0, contentW, contentH, contentPanel)
                eui:uiSetVisible(UI.container[section.id], false)

                UI.label.title = eui:uiCreateLabel(0, 10, contentW, 30,
                        { en = section.en, ar = section.ar }, tocolor(255, 255, 255, 255),
                        "center", "center", UI.container[section.id])
                eui:uiSetFont(UI.label.title, "default-large")

                eui:uiMenuAddRow(menu, { en = section.en, ar = section.ar },
                        tocolor(29, 32, 37, 0), section.icon, UI.container[section.id], section.id)
        end

        --[[ ------------------ character_info ------------------
                old tab panel: transparent bar, tab_height 60, tabs
                Info / Vehicles / Interiors, two-column identity card with
                line_spacing 35, level + play-time cards on the right ]]

        local infoPanelH = contentH - 130
        UI.tabpanel[1] = eui:uiCreateTabPanel(10, 110, contentW - 20, infoPanelH, "",
                tocolor(0, 0, 0, 0), UI.container.character_info)
        eui:uiSetProperty(UI.tabpanel[1], "tabs_bar_color", tocolor(29, 32, 37, 0))
        eui:uiSetProperty(UI.tabpanel[1], "tab_color", tocolor(19, 22, 27, 160))
        eui:uiSetProperty(UI.tabpanel[1], "tab_selected_color", tocolor(9, 12, 17, 220))
        eui:uiSetProperty(UI.tabpanel[1], "tab_hovered_color", tocolor(9, 12, 17, 100))
        eui:uiSetProperty(UI.tabpanel[1], "tab_height", 60)

        UI.tab[1] = eui:uiCreateTab({ en = "Info", ar = "المعلومات" }, "", UI.tabpanel[1])
        local infoW = (contentW - 40) * 0.7
        local infoH = infoPanelH - 40
        local cardColor = tocolor(9, 12, 17, 180)
        local rectInfoLeft = eui:uiCreateRectangle(5, 25, infoW, infoH, cardColor,
                true, true, true, true, UI.tab[1])
        UI.label[1] = eui:uiCreateLabel(15, 25, (infoW - 20) / 2, 300, "",
                tocolor(255, 255, 255, 255), "left", "top", rectInfoLeft)
        eui:uiSetProperty(UI.label[1], "line_spacing", 35)
        UI.label[4] = eui:uiCreateLabel(15 + (infoW - 20) / 2, 25, (infoW - 20) / 2, 300, "",
                tocolor(255, 255, 255, 255), "left", "top", rectInfoLeft)
        eui:uiSetProperty(UI.label[4], "line_spacing", 35)

        local sideW = (contentW - 40) * 0.3
        local sideH = (infoH - 10) * 0.5
        local rectInfoRight = eui:uiCreateRectangle(5 + infoW + 10, 25, sideW, sideH, cardColor,
                true, true, true, true, UI.tab[1])
        UI.label.level = eui:uiCreateLabel(0, 30, sideW, 30, "Level ${color.primary}1",
                tocolor(255, 255, 255, 255), "center", "top", rectInfoRight)
        UI.label.level_exp = eui:uiCreateLabel(0, 60, sideW, 30, "10000 / 10000",
                tocolor(255, 255, 255, 255), "center", "top", rectInfoRight)
        eui:uiSetFont(UI.label.level, "default-large")
        UI.progressbar[1] = eui:uiCreateProgressBar(20, 100, sideW - 40, 6, _, rectInfoRight)
        eui:uiSetProperty(UI.progressbar[1], "background_color", tocolor(20, 20, 20, 240))
        eui:uiSetProperty(UI.progressbar[1], "show_progress", false)
        eui:uiSetProperty(UI.progressbar[1], "progress_animation", true)
        UI.button.goto_level_awards = eui:uiCreateButton(15, sideH - 50, sideW - 30, 35,
                { en = "Level Awards", ar = "جوائز المستوى" }, _, rectInfoRight)

        local rectPlayTime = eui:uiCreateRectangle(5 + infoW + 10, 25 + sideH + 10,
                sideW, sideH, cardColor, true, true, true, true, UI.tab[1])
        UI.label.play_time = eui:uiCreateLabel(0, 0, sideW, sideH,
                "\nPlay Time\n\n00:00:00:00", tocolor(255, 255, 255, 255),
                "center", "center", rectPlayTime)
        eui:uiSetFont(UI.label.play_time, "default-large")

        UI.tab[2] = eui:uiCreateTab({ en = "Vehicles", ar = "المركبات" }, "", UI.tabpanel[1])
        UI.label.vehicles = eui:uiCreateLabel(10, 10, 340, 20, "",
                tocolor(255, 255, 255, 255), "left", "top", UI.tab[2])
        UI.gridlist.vehicles = eui:uiCreateGridList(0, 40, contentW - 20, infoPanelH - 48,
                tocolor(10, 10, 10, 0), UI.tab[2])
        eui:uiGridListAddColumn(UI.gridlist.vehicles, "ID", 0.2)
        eui:uiGridListAddColumn(UI.gridlist.vehicles, "Name", 0.65)
        eui:uiGridListAddColumn(UI.gridlist.vehicles, "Plate", 0.15)
        eui:uiSetAlign(UI.gridlist.vehicles, "left", "center")
        eui:uiSetProperty(UI.gridlist.vehicles, "color_coded", true)
        eui:uiSetProperty(UI.gridlist.vehicles, "row_height", 30)

        UI.tab[3] = eui:uiCreateTab({ en = "Interiors", ar = "البيوت والمحلات" }, "", UI.tabpanel[1])
        UI.label.interiors = eui:uiCreateLabel(10, 10, 340, 20, "",
                tocolor(255, 255, 255, 255), "left", "top", UI.tab[3])
        UI.gridlist.interiors = eui:uiCreateGridList(0, 40, contentW - 20, infoPanelH - 48,
                tocolor(10, 10, 10, 0), UI.tab[3])
        eui:uiGridListAddColumn(UI.gridlist.interiors, "ID", 0.2)
        eui:uiGridListAddColumn(UI.gridlist.interiors, "Name", 0.6)
        eui:uiGridListAddColumn(UI.gridlist.interiors, "Status", 0.2)
        eui:uiSetAlign(UI.gridlist.interiors, "left", "center")
        eui:uiSetProperty(UI.gridlist.interiors, "color_coded", true)
        eui:uiSetProperty(UI.gridlist.interiors, "row_height", 30)

        -- footer: separator + username + quit button (old)
        eui:uiCreateRectangle(5, contentH - 60, contentW - 10, 1, tocolor(255, 255, 255, 10),
                false, false, false, false, UI.container.character_info)
        UI.label.username = eui:uiCreateLabel(20, contentH - 50, 300, 35, "",
                tocolor(255, 255, 255, 50), "left", "center", UI.container.character_info)
        UI.button["character:quit"] = eui:uiCreateButton(contentW - 200 - 15, contentH - 50,
                200, 35, { en = "Quit Character", ar = "خروج من الشخصية" },
                "primary", UI.container.character_info)
        eui:uiSetProperty(UI.button["character:quit"], "HoverGlow", true)

        --[[ ------------------ online staff ------------------ (old) ]]

        UI.gridlist.staff = eui:uiCreateGridList(10, 50, contentW - 20, (contentH - 50) / 2,
                tocolor(0, 0, 0, 0), UI.container.onlinestaff)
        -- Fix #30 (user): EXACT old-client staff list - one line per admin:
        -- " -  [Rank] Name (account)    ID: x    On/Off-Duty" (3 columns)
        eui:uiGridListAddColumn(UI.gridlist.staff, "Admins Team", 0.56)
        eui:uiGridListAddColumn(UI.gridlist.staff, "ID", 0.2)
        eui:uiGridListAddColumn(UI.gridlist.staff, "Duty", 0.24)
        eui:uiSetAlign(UI.gridlist.staff, "left", "center")
        eui:uiSetProperty(UI.gridlist.staff, "color_coded", true)
        eui:uiSetProperty(UI.gridlist.staff, "row_height", 30)

        UI.gridlist.staff2 = eui:uiCreateGridList(10, 50 + (contentH - 50) / 2 + 10,
                contentW - 20, (contentH - 100) / 2, tocolor(0, 0, 0, 0), UI.container.onlinestaff)
        eui:uiGridListAddColumn(UI.gridlist.staff2, "Supports Team", 0.56)
        eui:uiGridListAddColumn(UI.gridlist.staff2, "ID", 0.2)
        eui:uiGridListAddColumn(UI.gridlist.staff2, "Duty", 0.24)
        eui:uiSetAlign(UI.gridlist.staff2, "left", "center")
        eui:uiSetProperty(UI.gridlist.staff2, "color_coded", true)
        eui:uiSetProperty(UI.gridlist.staff2, "row_height", 30)

        --[[ ------------------ radio channels (Fix #26) ------------------ ]]
        UI.gridlist.radio = eui:uiCreateGridList(10, 50, contentW - 20, contentH - 215,
                tocolor(10, 10, 10, 0), UI.container.radio)
        eui:uiGridListAddColumn(UI.gridlist.radio, "Channel", 0.32)
        eui:uiGridListAddColumn(UI.gridlist.radio, "Stream URL", 0.68)
        eui:uiSetAlign(UI.gridlist.radio, "left", "center")
        eui:uiSetProperty(UI.gridlist.radio, "row_height", 30)

        eui:uiCreateLabel(10, contentH - 152, contentW - 20, 20,
                { en = "Add a channel (staff only):", ar = "إضافة قناة جديدة (للإدارة فقط):" },
                tocolor(255, 255, 255, 220), "left", "center", UI.container.radio)
        UI.edit.radio_name = eui:uiCreateEdit(10, contentH - 126, 240, 28, "",
                { en = "Channel name", ar = "اسم القناة" },
                tocolor(9, 12, 17, 235), UI.container.radio)
        UI.edit.radio_url = eui:uiCreateEdit(260, contentH - 126, contentW - 260 - 175, 28, "",
                { en = "Stream URL (http...)", ar = "رابط البث (http...)" },
                tocolor(9, 12, 17, 235), UI.container.radio)
        UI.button.radio_add = eui:uiCreateButton(contentW - 165, contentH - 126, 155, 28,
                { en = "Add Channel", ar = "إضافة قناة" }, "primary", UI.container.radio)
        eui:uiSetProperty(UI.button.radio_add, "TextColor", tocolor(255, 255, 255, 255))
        UI.button.radio_refresh = eui:uiCreateButton(10, contentH - 88, 155, 28,
                { en = "Refresh", ar = "تحديث" }, tocolor(10, 10, 10, 240), UI.container.radio)
        eui:uiSetProperty(UI.button.radio_refresh, "TextColor", tocolor(255, 255, 255, 230))

        --[[ ------------------ leaderboard ------------------ (old tabs) ]]

        local lbPanelH = contentH - 130
        UI.tabpanel.leaderboard = eui:uiCreateTabPanel(10, 110, contentW - 20, lbPanelH, "",
                tocolor(0, 0, 0, 0), UI.container.leaderboard)
        eui:uiSetProperty(UI.tabpanel.leaderboard, "tabs_bar_color", tocolor(29, 32, 37, 0))
        eui:uiSetProperty(UI.tabpanel.leaderboard, "tab_color", tocolor(19, 22, 27, 160))
        eui:uiSetProperty(UI.tabpanel.leaderboard, "tab_selected_color", tocolor(9, 12, 17, 220))
        eui:uiSetProperty(UI.tabpanel.leaderboard, "tab_hovered_color", tocolor(9, 12, 17, 100))
        eui:uiSetProperty(UI.tabpanel.leaderboard, "tab_height", 50)

        UI.tab["leaderboard:levels"] = eui:uiCreateTab(
                { en = "Levels", ar = "المستويات" }, "", UI.tabpanel.leaderboard)
        UI.tab["leaderboard:activities"] = eui:uiCreateTab(
                { en = "Activities", ar = "الأنشطة" }, "", UI.tabpanel.leaderboard)

        UI.gridlist["leaderboard:levels"] = eui:uiCreateGridList(0, 30, contentW - 20,
                lbPanelH - 48, tocolor(10, 10, 10, 0), UI.tab["leaderboard:levels"])
        eui:uiGridListAddColumn(UI.gridlist["leaderboard:levels"], "", 0.2)
        eui:uiGridListAddColumn(UI.gridlist["leaderboard:levels"], "Name", 0.5)
        eui:uiGridListAddColumn(UI.gridlist["leaderboard:levels"], "Level", 0.3)
        eui:uiSetAlign(UI.gridlist["leaderboard:levels"], "left", "center")
        eui:uiSetProperty(UI.gridlist["leaderboard:levels"], "color_coded", true)
        eui:uiSetProperty(UI.gridlist["leaderboard:levels"], "row_height", 40)

        UI.gridlist["leaderboard:activities"] = eui:uiCreateGridList(0, 30, contentW - 20,
                lbPanelH - 48, tocolor(10, 10, 10, 0), UI.tab["leaderboard:activities"])
        eui:uiGridListAddColumn(UI.gridlist["leaderboard:activities"], "", 0.2)
        eui:uiGridListAddColumn(UI.gridlist["leaderboard:activities"], "Name", 0.5)
        eui:uiGridListAddColumn(UI.gridlist["leaderboard:activities"], "Points", 0.3)
        eui:uiSetAlign(UI.gridlist["leaderboard:activities"], "left", "center")
        eui:uiSetProperty(UI.gridlist["leaderboard:activities"], "color_coded", true)
        eui:uiSetProperty(UI.gridlist["leaderboard:activities"], "row_height", 40)

        --[[ ------------------ rules (old: read-only memo) ------------------ ]]

        UI.memo.rules_info = eui:uiCreateMemo(15, 50, contentW - 30, contentH - 60, "",
                tocolor(5, 5, 5, 0), UI.container.rules)
        eui:uiSetProperty(UI.memo.rules_info, "TextColor", tocolor(255, 255, 255, 255))
        eui:uiMemoSetReadOnly(UI.memo.rules_info, true)
        eui:uiSetText(UI.memo.rules_info, RULES_TEXT)

        --[[ ------------------ commands (old: tabpanel + 7 grids) ------------------ ]]

        UI.tabpanel.commands = eui:uiCreateTabPanel(10, 90, contentW - 20, contentH - 120, "",
                tocolor(30, 30, 30, 0), UI.container.commands)
        eui:uiSetProperty(UI.tabpanel.commands, "title_shown", false)
        eui:uiSetProperty(UI.tabpanel.commands, "tabs_bar_color", tocolor(29, 32, 37, 0))
        eui:uiSetProperty(UI.tabpanel.commands, "tab_color", tocolor(19, 22, 27, 160))
        eui:uiSetProperty(UI.tabpanel.commands, "tab_selected_color", tocolor(9, 12, 17, 220))
        eui:uiSetProperty(UI.tabpanel.commands, "tab_hovered_color", tocolor(9, 12, 17, 100))
        eui:uiSetProperty(UI.tabpanel.commands, "tab_height", 40)
        for _, cmdSection in ipairs(COMMAND_SECTIONS) do
                local tab = eui:uiCreateTab(
                        { en = cmdSection.name, ar = cmdSection.name }, "", UI.tabpanel.commands)
                UI.tab["commands:" .. cmdSection.name] = tab
                local grid = eui:uiCreateGridList(0, 5, contentW - 20, contentH - 180,
                        tocolor(20, 20, 20, 0), tab)
                eui:uiGridListAddColumn(grid, "Command", 0.2)
                eui:uiGridListAddColumn(grid, "Hotkey", 0.15)
                eui:uiGridListAddColumn(grid, "Explanation", 0.5)
                eui:uiGridListAddColumn(grid, "Permission", 0.15)
                eui:uiSetAlign(grid, "left", "center")
                eui:uiSetProperty(grid, "color_coded", true)
                eui:uiSetProperty(grid, "row_height", 30)
                for _, row in ipairs(cmdSection.rows) do
                        local r = eui:uiGridListAddRow(grid)
                        eui:uiGridListSetItemText(grid, r, 1, tostring(row[1]))
                        eui:uiGridListSetItemText(grid, r, 2, tostring(row[2]))
                        eui:uiGridListSetItemText(grid, r, 3, tostring(row[3]))
                        eui:uiGridListSetItemText(grid, r, 4, tostring(row[4]))
                        if row[4] == "إدارة" then
                                eui:uiGridListSetItemColor(grid, r, 4, tocolor(255, 170, 0, 255))
                        end
                end
        end

        --[[ ------------------ report (old flow, restored 1:1) ------------------
                explanation label + report-type gridlist in the sidebar, then
                the two Report Center windows (confirm 400x330 + memo 550x325).
                Server rules kept: >= 15 words, one report per 5 minutes
                (report-system s_reports.lua stays authoritative). ]]

        eui:uiCreateLabel(10, 70, contentW - 20, 80,
                "إذا واجهتك مشكلة يمكنك طلب المساعدة من الهيئة الإدارية\n"
                .. "عن طريق اختيار نوع البلاغ ثم كتابة التفاصيل\n\n"
                .. "يرجى توضيح سبب طلب المساعدة حتى تستطيع الهيئة مساعدتك بالشكل المطلوب وبأسرع وقت\n\n"
                .. "كما يمكنك التواصل مع الإدارة عبر فتح تذكرة في الديسكورد الرسمي الخاص بالسيرفر\n"
                .. "اضغط مرتين على نوع البلاغ للمتابعة",
                eui:uiGetThemeColor("primary"), "center", "top", UI.container.report)

        UI.gridlist.report_types = eui:uiCreateGridList(10, 230, contentW - 20, contentH - 250,
                tocolor(10, 10, 10, 0), UI.container.report)
        eui:uiGridListAddColumn(UI.gridlist.report_types, "Select Report Type", 1)
        eui:uiSetAlign(UI.gridlist.report_types, "center", "center")
        eui:uiSetProperty(UI.gridlist.report_types, "row_height", 35)
        for i, rtype in ipairs(REPORT_TYPES) do
                local row = eui:uiGridListAddRow(UI.gridlist.report_types)
                eui:uiGridListSetItemText(UI.gridlist.report_types, row, 1, tostring(rtype))
                eui:uiGridListSetItemColor(UI.gridlist.report_types, row, 1, tocolor(240, 255, 232, 255))
                eui:uiGridListSetItemData(UI.gridlist.report_types, row, 1, i)
        end

        -- confirm window (old window[1]: 400x330)
        UI.window.report_confirm = eui:uiCreateRectangle(false, false, 400, 330,
                tocolor(15, 15, 15, 240), true, true, true, true)
        eui:uiSetVisible(UI.window.report_confirm, false)
        UI.label.report_title = eui:uiCreateLabel(10, 10, 232, 20, "Report Center",
                tocolor(255, 255, 255, 255), "left", "top", UI.window.report_confirm)
        eui:uiSetFont(UI.label.report_title, "default-large")
        eui:uiCreateLabel(15, 110, 370, 30,
                { en = "Do you want to open a report of this type?", ar = "هل تريد فتح بلاغ من النوع التالي؟" },
                tocolor(255, 255, 255, 230), "center", "center", UI.window.report_confirm)
        UI.label.report_confirm_type = eui:uiCreateLabel(15, 145, 370, 30, "",
                eui:uiGetThemeColor("primary"), "center", "center", UI.window.report_confirm)
        eui:uiSetFont(UI.label.report_confirm_type, "default-large")
        UI.button.report_continue = eui:uiCreateButton(100, 220, 200, 40,
                { en = "Continue", ar = "متابعة" }, "primary", UI.window.report_confirm)
        eui:uiSetProperty(UI.button.report_continue, "TextColor", tocolor(255, 255, 255, 255))
        UI.button.report_cancel1 = eui:uiCreateButton(0, 300, 400, 30,
                { en = "Cancel", ar = "إلغاء" }, tocolor(10, 10, 10, 240), UI.window.report_confirm)
        eui:uiSetProperty(UI.button.report_cancel1, "TextColor", tocolor(255, 255, 255, 230))
        eui:uiSetProperty(UI.button.report_cancel1, "HoverTextColor", tocolor(255, 48, 48))

        -- memo window (old window[2]: uiCreateWindow 550x325)
        UI.window.report_center = eui:uiCreateWindow(false, false, 550, 325,
                { en = "Report Center", ar = "مركز البلاغات" })
        eui:uiWindowSetMovable(UI.window.report_center, false)
        eui:uiSetVisible(UI.window.report_center, false)
        eui:uiCreateLabel(15, 40, 200, 20,
                { en = "Write your problem:", ar = "اكتب مشكلتك:" },
                tocolor(255, 255, 255, 255), "left", "center", UI.window.report_center)
        UI.edit.report_target = eui:uiCreateEdit(10, 65, 530, 25, "",
                { en = "Player you report (optional) - name or id",
                  ar = "اللاعب المراد الإبلاغ عنه (اختياري) - الاسم أو رقمه" },
                tocolor(9, 12, 17, 235), UI.window.report_center)
        eui:uiSetProperty(UI.edit.report_target, "UnderLineVisible", "False")
        UI.memo.report_text = eui:uiCreateMemo(10, 100, 530, 175, "",
                tocolor(0, 0, 0), UI.window.report_center)
        eui:uiSetProperty(UI.memo.report_text, "TextColor", tocolor(255, 255, 255, 255))
        UI.button.report_cancel2 = eui:uiCreateButton(10, 285, 100, 30,
                { en = "Cancel", ar = "إلغاء" }, tocolor(0, 0, 0), UI.window.report_center)
        eui:uiSetProperty(UI.button.report_cancel2, "TextColor", tocolor(255, 255, 255, 230))
        UI.label.report_wordcount = eui:uiCreateLabel(120, 285, 110, 30, "0 / 15 كلمة",
                tocolor(46, 213, 115, 255), "center", "center", UI.window.report_center)
        UI.label.report_cooldown = eui:uiCreateLabel(235, 285, 150, 30, "",
                tocolor(255, 195, 15, 255), "center", "center", UI.window.report_center)
        eui:uiSetVisible(UI.label.report_cooldown, false)
        UI.button.report_submit = eui:uiCreateButton(390, 285, 150, 30,
                { en = "Submit Report", ar = "إرسال البلاغ" }, "primary", UI.window.report_center)
        eui:uiSetProperty(UI.button.report_submit, "TextColor", tocolor(255, 255, 255, 255))

        --[[ ------------------ link discord (old) ------------------ ]]

        UI.container.notlinked = eui:uiCreateContainer(0, 0, contentW, contentH, UI.container.linkdiscord)
        UI.container.linked = eui:uiCreateContainer(0, 0, contentW, contentH, UI.container.linkdiscord)
        eui:uiSetVisible(UI.container.notlinked, true)
        eui:uiSetVisible(UI.container.linked, false)

        UI.image.WT = eui:uiCreateImage(contentW / 2 - 80 - 40, 70, 80, 80, "logo-circle.png", UI.container.linkdiscord)
        UI.image.Discord = eui:uiCreateImage(contentW / 2 + 40, 70, 80, 80, "icons/discord.png", UI.container.linkdiscord)
        UI.image.Link = eui:uiCreateImage(contentW / 2 - 15, 100, 30, 30, "icons/link.png", UI.container.linkdiscord)

        eui:uiCreateLabel(15, 180, contentW - 30, 80,
                "\t\tالآن يمكنك ربط حسابك بحساب الديسكورد الخاص بك\n"
                .. "\t\tالربط سيساعدك على تأمين حسابك بشكل أفضل والحصول على ميزات عديدة\n\n"
                .. "\t\tلربط حسابك قم بإنشاء رمز جديد عن طريق الضغط على زر 'إنشاء رمز' بالأسفل\n"
                .. "\t\tثم توجه إلى الصفحة التالية\n"
                .. "${color.primary}" .. LINKS.linkdiscord .. "\n",
                tocolor(255, 255, 255, 255), "center", "top", UI.container.notlinked)
        UI.button.copy_link_url = eui:uiCreateButton((contentW - 120) / 2, 300, 120, 30,
                { en = "Copy Link", ar = "انسخ الرابط" }, tocolor(0, 0, 0, 240), UI.container.notlinked)
        UI.rectangle.code = eui:uiCreateRectangle((contentW - 350) / 2, 370, 350, 40,
                tocolor(19, 22, 27, 240), true, true, true, true, UI.container.notlinked)
        UI.label.code = eui:uiCreateLabel(0, 0, 350, 40, "* * * * * * * * * * * * * * * * * * * * * * *",
                tocolor(255, 255, 255, 255), "center", "center", UI.rectangle.code)
        eui:uiSetFont(UI.label.code, "default-large")
        UI.button.generate_code = eui:uiCreateButton((contentW - 170) / 2, 420, 170, 35,
                { en = "Generate Code", ar = "إنشاء رمز" }, "primary", UI.container.notlinked)
        eui:uiCreateLabel(15, 480, contentW - 30, 30,
                "\t\tبعد إنشاء الرمز سيكون صالح للاستخدام خلال 5 دقائق\n"
                .. "\t\tيمكن نسخ الرمز عن طريق الضغط عليه\n\t",
                tocolor(255, 255, 255, 255), "center", "top", UI.container.notlinked)

        eui:uiCreateLabel(15, 180, contentW - 30, 20,
                "\t\tحسابك مربوط بحساب الديسكورد التالي\n\t",
                tocolor(255, 255, 255, 255), "center", "top", UI.container.linked)
        UI.label.discord_tag = eui:uiCreateLabel(15, 210, contentW - 30, 30, "-",
                "primary", "center", "top", UI.container.linked)
        eui:uiSetFont(UI.label.discord_tag, "default-large")
        UI.label.discord_id = eui:uiCreateLabel(15, 240, contentW - 30, 20,
                "\n                ID: XXXXXXXXXXXXXXXXXXXX\n        ",
                tocolor(255, 255, 255, 150), "center", "top", UI.container.linked)
        eui:uiCreateLabel(15, 410, contentW - 30, 40,
                "\t\tفي حال رغبتك بتغيير حساب الديسكورد المربوط بحسابك\n"
                .. "\t\tيمكنك إلغاء الربط وإعادة ربط حسابك مع الحساب الجديد\n\t",
                tocolor(255, 255, 255, 255), "center", "top", UI.container.linked)
        UI.button.unlinkdiscord = eui:uiCreateButton((contentW - 170) / 2, 470, 170, 35,
                { en = "Unlink the Discord", ar = "إلغاء ربط الديسكورد" }, "primary", UI.container.linked)
        UI.image.avatar = eui:uiCreateBrowser((contentW - 100) / 2, 280, 100, 100, false, true, UI.container.linked)
        addEventHandler("onClientBrowserCreated", eui:uiGetBrowser(UI.image.avatar), function()
                loadBrowserURL(source, "https://i.postimg.cc/fRxyqZQ6/logo.png")
        end)

        --[[ ------------------ about (old) ------------------ ]]

        eui:uiCreateLabel(0, contentH - 40, contentW, 30, VERSION_LINE,
                tocolor(255, 255, 255, 50), "center", "center", UI.container.about)

        local linkRows = {
                { key = "discord",  y = 100, icon = "icons/discord.png",   ar = "الديسكورد الرسمي" },
                { key = "factions", y = 160, icon = "icons/discord.png",   ar = "ديسكورد الفاشنات" },
                { key = "gangs",    y = 220, icon = "icons/discord.png",   ar = "ديسكورد العصابات" },
                { key = "youtube",  y = 280, icon = "icons/youtube.png",   ar = "Vortex RolePlay" },
                { key = "store",    y = 340, icon = "logo-circle.png",     ar = "المتجر الرسمي" },
        }
        for _, row in ipairs(linkRows) do
                local rect = eui:uiCreateRectangle(10, row.y, contentW - 20, 50,
                        tocolor(19, 22, 27, 240), true, true, true, true, UI.container.about)
                UI.rectangle[row.key] = rect
                eui:uiCreateImage(10, 5, 40, 40, row.icon, rect)
                eui:uiCreateLabel(60, 0, 200, 50, row.ar, tocolor(255, 255, 255, 255),
                        "left", "center", rect)
                UI.button["copy_" .. row.key] = eui:uiCreateButton(contentW - 20 - 100, 10,
                        90, 30, { en = "Copy Link", ar = "انسخ الرابط" },
                        tocolor(9, 12, 17, 220), rect)
                eui:uiSetProperty(UI.button["copy_" .. row.key], "TextColor", tocolor(255, 255, 255, 230))
                eui:uiSetClickAction(UI.button["copy_" .. row.key], LINKS[row.key])
        end

        --[[ ------------------ handlers ------------------ ]]

        -- report flow wiring (old flow + server rules)
        local function resolveReportTarget(text)
                -- full/partial player name or player id (falls back to self)
                if type(text) ~= "string" or text == "" then return false end
                local found = false
                if tonumber(text) then
                        for _, value in ipairs(getElementsByType("player")) do
                                if tonumber(getElementData(value, "playerid")) == tonumber(text) then
                                        found = value
                                        break
                                end
                        end
                else
                        for _, value in ipairs(getElementsByType("player")) do
                                if string.find(string.lower(getPlayerName(value)), string.lower(text), 1, true) then
                                        found = value
                                        break
                                end
                        end
                end
                return found
        end

        local function reportWords()
                local text = tostring(eui:uiGetText(UI.memo.report_text) or "")
                local words = 0
                for _ in text:gmatch("%S+") do words = words + 1 end
                return words, text
        end

        local function updateReportCooldownLabel()
                if not (UI.label.report_cooldown and isElement(UI.label.report_cooldown)) then return end
                local remainMs = (UI.reportCooldownUntil or 0) - getTickCount()
                if remainMs > 0 then
                        local s = math.ceil(remainMs / 1000)
                        eui:uiSetText(UI.label.report_cooldown,
                                "بلاغ جديد بعد " .. math.floor(s / 60) .. ":" .. string.format("%02d", s % 60))
                        eui:uiSetVisible(UI.label.report_cooldown, true)
                        if UI.button.report_submit and isElement(UI.button.report_submit) then
                                eui:uiSetVisible(UI.button.report_submit, false)
                        end
                else
                        eui:uiSetVisible(UI.label.report_cooldown, false)
                        if UI.button.report_submit and isElement(UI.button.report_submit) then
                                eui:uiSetVisible(UI.button.report_submit, true)
                        end
                end
        end

        if not UI._wiredReportCounter then
                UI._wiredReportCounter = true
                addEventHandler("onClientUITextChange", root, function()
                        if source == UI.memo.report_text and isElement(UI.label.report_wordcount)
                                and isElement(UI.memo.report_text) then
                                local words = reportWords()
                                eui:uiSetText(UI.label.report_wordcount, words .. " / 15 كلمة")
                        end
                end)
        end

        if not UI._wiredReportFlow then
                UI._wiredReportFlow = true
                addEventHandler("onClientUIClick", root, function()
                        -- confirm window: Continue -> the memo window
                        if source == UI.button.report_continue then
                                if selectedReportType >= 1 then
                                        eui:uiSetVisible(UI.window.report_confirm, false)
                                        eui:uiSetVisible(UI.window.report_center, true)
                                        eui:uiBringToFront(UI.window.report_center)
                                        -- Fix #26 (user): report windows never received
                                        -- keyboard focus -> typing was impossible
                                        pcall(function() eui:uiSetFocusedElement(UI.memo.report_text) end)
                                        eui:uiSetText(UI.window.report_center,
                                                { en = "Report Center | " .. REPORT_TYPES[selectedReportType],
                                                  ar = "مركز البلاغات | " .. REPORT_TYPES[selectedReportType] })
                                        updateReportCooldownLabel()
                                        if UI.reportCdTimer and isTimer(UI.reportCdTimer) then
                                                killTimer(UI.reportCdTimer)
                                        end
                                        UI.reportCdTimer = setTimer(updateReportCooldownLabel, 1000, 330)
                                end
                        elseif source == UI.button.report_cancel1 then
                                eui:uiSetVisible(UI.window.report_confirm, false)
                        elseif source == UI.button.report_cancel2 then
                                eui:uiSetVisible(UI.window.report_center, false)
                        elseif source == UI.button.report_submit then
                                local words, text = reportWords()
                                -- [user rule] at least 15 words (server authoritative)
                                if words < 15 then
                                        notify({ en = "Report rejected: write at least 15 words (" .. words .. "/15)",
                                                 ar = "تم رفض البلاغ: اكتب 15 كلمة على الأقل (" .. words .. "/15)" }, 3500, "error")
                                        eui:uiLabelApplyShakeAnimation(UI.label.report_wordcount, tocolor(255, 65, 65, 255))
                                        return
                                end
                                -- [old cap] 250 characters max
                                if text:len() > 250 then
                                        notify({ en = "The description of the problem is too long, please shorten it",
                                                 ar = "وصف المشكلة طويل جداً، يرجى الاختصار" }, 4000, "error")
                                        return
                                end
                                local target = resolveReportTarget(tostring(eui:uiGetText(UI.edit.report_target) or ""))
                                triggerServerEvent("clientSendReport", localPlayer,
                                        target or localPlayer, text, selectedReportType)
                                -- 5-minute client cooldown (server enforces too)
                                UI.reportCooldownUntil = getTickCount() + 300000
                                updateReportCooldownLabel()
                                if UI.reportCdTimer and isTimer(UI.reportCdTimer) then
                                        killTimer(UI.reportCdTimer)
                                end
                                UI.reportCdTimer = setTimer(updateReportCooldownLabel, 1000, 330)
                                eui:uiSetVisible(UI.window.report_center, false)
                                eui:uiSetText(UI.memo.report_text, "")
                                eui:uiSetText(UI.label.report_wordcount, "0 / 15 كلمة")
                                notify({ en = "Report sent to the staff team", ar = "تم إرسال البلاغ إلى الإدارة" }, 4000, "success")
                        end
                end)
                addEventHandler("onClientUIDoubleClick", root, function()
                        -- old flow: double click a type row -> the confirm window
                        if source == UI.gridlist.report_types
                                and eui:uiGridListGetSelectedItem(UI.gridlist.report_types) ~= -1 then
                                local row = eui:uiGridListGetSelectedItem(UI.gridlist.report_types)
                                selectedReportType = eui:uiGridListGetItemData(UI.gridlist.report_types, row, 1) or (row + 1)
                                eui:uiSetText(UI.label.report_confirm_type, tostring(REPORT_TYPES[selectedReportType]))
                                eui:uiBringToFront(UI.window.report_confirm)
                                eui:uiSetVisible(UI.window.report_confirm, true)
                        end
                end)
        end

        addEventHandler("onClientUIClick", root, function()
                if source == UI.button["character:quit"] then
                        -- F1 change-character runs the EXACT old F10 flow
                        -- (accounts:logout -> updateCharacters -> character
                        -- selection screen - verified against the backup)
                        addEventHandler("onClientKey", root, cancelBindsEvent)
                        showSideBar(false)
                        if resRunning("roleplay") then
                                pcall(function() exports.roleplay:switchOutPlayer() end)
                        else
                                triggerEvent("accounts:logout", localPlayer)
                        end
                        setTimer(function()
                                removeEventHandler("onClientKey", root, cancelBindsEvent)
                        end, 3000, 1)
                elseif source == UI.button.copy_link_url then
                        setClipboard(LINKS.linkdiscord)
                        notify({ en = "Link copied", ar = "تم نسخ الرابط" }, 3000, "success")
                elseif source == UI.label.code then
                        if currentLinkCode then
                                setClipboard(currentLinkCode)
                                notify({ en = "Code copied", ar = "تم نسخ الرمز" }, 3000, "success")
                                eui:uiLabelApplyShakeAnimation(UI.label.code, tocolor(0, 255, 0, 255))
                        else
                                notify({ en = "Generate code first", ar = "قم بإنشاء رمز أولاً" }, 3000, "error")
                                eui:uiLabelApplyShakeAnimation(UI.label.code, tocolor(255, 0, 0, 255))
                        end
                elseif source == UI.button.generate_code then
                        if pendingCode then
                                notify({ en = "Please wait...", ar = "انتظر من فضلك..." }, 3000, "warning")
                                return
                        end
                        pendingCode = true
                        triggerServerEvent("main-menu:linkdiscord:generateCode", localPlayer)
                elseif source == UI.button.unlinkdiscord then
                        eui:uiSetVisible(UI.container.linked, false)
                        eui:uiSetVisible(UI.container.notlinked, true)
                        local charId = getElementData(localPlayer, "character:id")
                                or getElementData(localPlayer, "account:character:id")
                        triggerServerEvent("main-menu:linkdiscord:unlink", localPlayer, charId)
                        currentLinkCode = false
                elseif source == UI.button.goto_level_awards then
                        -- old jumped to the awards section row (row 9 in the old menu)
                        local target = 1
                        for i, section in ipairs(SECTIONS) do
                                if section.id == "awards" then target = i end
                        end
                        eui:uiMenuSetSelectedRow(menu, target)
                end
        end)

        -- the old client's about rows ALSO copied via uiSetClickAction; the
        -- onClientUIClick action branch fires before ours, so clipboard +
        -- notification are handled there. Keep the explicit handlers anyway.
        addEventHandler("onClientUIClick", root, function()
                for _, key in ipairs({ "discord", "factions", "gangs", "youtube", "store" }) do
                        if source == UI.button["copy_" .. key] then
                                setClipboard(LINKS[key])
                                notify({ en = "Link copied", ar = "تم نسخ الرابط" }, 3000, "success")
                                return
                        end
                end
        end)

        addEvent("main-menu:linkdiscord:generateCode:callback", true)
        addEventHandler("main-menu:linkdiscord:generateCode:callback", localPlayer, function(code)
                pendingCode = false
                if code then
                        eui:uiSetText(UI.label.code, code)
                        currentLinkCode = code
                        setClipboard(code)
                end
                eui:uiLabelApplyShakeAnimation(UI.label.code, code and tocolor(0, 255, 0, 255) or tocolor(255, 55, 95, 255))
                notify({ en = "Code generated and copied", ar = "تم إنشاء ونسخ الرمز" }, 6000, "success")
        end)

        addEvent("main-menu:linkdiscord:sync", true)
        addEventHandler("main-menu:linkdiscord:sync", localPlayer, function(data)
                pendingCode = false
                eui:uiSetVisible(UI.container.notlinked, false)
                eui:uiSetVisible(UI.container.linked, true)
                eui:uiSetText(UI.label.discord_tag, data.username or "-")
                eui:uiSetText(UI.label.discord_id, "ID: " .. tostring(data.id))
                if data.avatar and data.avatar ~= "" then
                        loadBrowserURL(eui:uiGetBrowser(UI.image.avatar), data.avatar)
                end
        end)

        requestBrowserDomains({ "cdn.discordapp.com", "wnashtime.net" })

        addEventHandler("onClientUIMenuSelectChange", root, function(_, container)
                if source == menu then
                        if container == UI.container.onlinestaff then
                                triggerServerEvent("admin:showStaff", localPlayer)
                        elseif container == UI.container.radio then
                                triggerServerEvent("main-menu:radio:list", localPlayer)
                        elseif container == UI.container.leaderboard then
                                if eui:uiGetSelectedTab(UI.tabpanel.leaderboard) == UI.tab["leaderboard:levels"] then
                                        updateLeaderboard("levels")
                                elseif eui:uiGetSelectedTab(UI.tabpanel.leaderboard) == UI.tab["leaderboard:activities"] then
                                        updateLeaderboard("activities")
                                end
                        end
                end
        end)

        addEventHandler("onClientUIClick", root, function()
                if source == UI.button.radio_add then
                        local nm = eui:uiGetText(UI.edit.radio_name) or ""
                        local url = eui:uiGetText(UI.edit.radio_url) or ""
                        triggerServerEvent("main-menu:radio:add", localPlayer, nm, url)
                elseif source == UI.button.radio_refresh then
                        triggerServerEvent("main-menu:radio:list", localPlayer)
                end
        end)
        addEvent("main-menu:radio:list:callback", true)
        addEventHandler("main-menu:radio:list:callback", root, function(list)
                if not UI.gridlist.radio then return end
                eui:uiGridListClear(UI.gridlist.radio)
                if type(list) ~= "table" then return end
                for _, st in ipairs(list) do
                        local row = eui:uiGridListAddRow(UI.gridlist.radio)
                        eui:uiGridListSetItemText(UI.gridlist.radio, row, 1, tostring(st[2] or "-"))
                        eui:uiGridListSetItemText(UI.gridlist.radio, row, 2, tostring(st[3] or "-"))
                end
        end)
        addEvent("main-menu:radio:added", true)
        addEventHandler("main-menu:radio:added", root, function(ok, msg)
                outputChatBox(msg, ok and 120 or 255, ok and 220 or 90, ok and 120 or 90)
                if ok then
                        pcall(function()
                                eui:uiSetText(UI.edit.radio_name, "")
                                eui:uiSetText(UI.edit.radio_url, "")
                        end)
                        triggerServerEvent("main-menu:radio:list", localPlayer)
                end
        end)
        -- Fix #30: hex helper for the color-coded staff rows
        local function staffHex(c, fallback)
                if type(c) == "table" and c[1] then
                        return string.format("#%02x%02x%02x",
                                math.min(255, math.max(0, math.floor(tonumber(c[1]) or 255))),
                                math.min(255, math.max(0, math.floor(tonumber(c[2]) or 255))),
                                math.min(255, math.max(0, math.floor(tonumber(c[3]) or 255))))
                end
                return fallback or "#ffffff"
        end

        addEvent("admin:showStaff", true)
        addEventHandler("admin:showStaff", root, function(list)
                eui:uiGridListClear(UI.gridlist.staff)
                eui:uiGridListClear(UI.gridlist.staff2)
                if type(list) ~= "table" then return end
                local adminCount, supportCount = 0, 0
                local nameHex = "#ffffff"
                -- [Fix #47] `eui:uiGetThemeColor` used as a VALUE is a syntax
                -- error ("function arguments expected") - it killed the WHOLE
                -- c_main.lua compile, so F1/F2 binds never registered and the
                -- menu was completely dead. Resolve the theme color safely and
                -- normalize the ARGB number to the {r,g,b} table staffHex wants.
                local okc, pc = pcall(function() return eui:uiGetThemeColor("primary") end)
                if okc and type(pc) == "number" then
                        pc = { bitExtract(pc, 16, 8), bitExtract(pc, 8, 8), bitExtract(pc, 0, 8) }
                else
                        pc = nil
                end
                local idHex = staffHex(pc, "#8f7bff")
                for _, entry in ipairs(list) do
                        local isSupport = entry[1] == true
                        local hidden = entry[4] == true
                        local pid = tostring(entry[2] or "-")
                        local name = tostring(entry[3] or "-")
                        local rank = tostring(entry[5] or "")
                        local line = " -  "
                        if rank ~= "" then
                                line = line .. staffHex(entry[6], "#ffffff") .. "[" .. rank .. "] "
                        end
                        -- hidden admins read as "Anonymous" (old client), no account shown
                        if hidden then
                                line = line .. staffHex(entry[6], nameHex) .. "Anonymous"
                        else
                                line = line .. nameHex .. name
                                local acc = tostring(entry[7] or "")
                                if acc ~= "" and acc ~= "-" then
                                        line = line .. " " .. idHex .. "(" .. acc .. ")"
                                end
                        end
                        local grid = isSupport and UI.gridlist.staff2 or UI.gridlist.staff
                        local row = eui:uiGridListAddRow(grid)
                        eui:uiGridListSetItemText(grid, row, 1, line)
                        eui:uiGridListSetItemText(grid, row, 2, idHex .. "ID: " .. pid)
                        eui:uiGridListSetItemText(grid, row, 3, hidden and "#c8c8c8Hidden"
                                or (entry[9] and "#00ff00On-Duty" or "#ff3c3cOff-Duty"))
                        if isSupport then supportCount = supportCount + 1 else adminCount = adminCount + 1 end
                end
                eui:uiGridListSetColumnText(UI.gridlist.staff2, 1, "Supports Team  (" .. supportCount .. ")")
                eui:uiGridListSetColumnText(UI.gridlist.staff, 1, "Admins Team  (" .. adminCount .. ")")
        end)

        addEventHandler("onClientUIVisibilityChange", root, function(visible)
                if visible and source == UI.window.MainMenu then
                        -- REAL character data from this server's account system
                        -- (keys verified against account/s_characters.lua)
                        local bullet = "${color.primary}• "

                        local charId = tonumber(getElementData(localPlayer, "dbid"))
                                or tonumber(getElementData(localPlayer, "account:character:id")) or "-"
                        local charName = tostring(getPlayerName(localPlayer)):gsub("_", " ")
                        local genderVal = tonumber(getElementData(localPlayer, "gender")) or 0
                        local gender = (genderVal == 1) and { "Female", "أنثى" } or { "Male", "ذكر" }
                        local raceVal = tonumber(getElementData(localPlayer, "race"))
                        local races = { [0] = { "Black", "أسود" }, [1] = { "White", "أبيض" }, [2] = { "Asian", "آسيوي" }, [3] = { "Latino", "لاتيني" } }
                        local race = races[raceVal] or { "-", "-" }
                        local age = tonumber(getElementData(localPlayer, "age")) or "-"
                        local height = tonumber(getElementData(localPlayer, "height")) or "-"
                        local weight = tonumber(getElementData(localPlayer, "weight")) or "-"
                        local fingerprint = tostring(getElementData(localPlayer, "fingerprint") or "-")
                        if fingerprint == "" then fingerprint = "-" end
                        local job = tostring(getElementData(localPlayer, "job") or "")
                        if job == "" then job = nil end
                        local factionRank = tostring(getElementData(localPlayer, "factionrank") or "")
                        if factionRank == "" then factionRank = nil end
                        local desc = tostring(getElementData(localPlayer, "description") or "")
                        if desc == "" then desc = nil end
                        if desc and #desc > 64 then desc = desc:sub(1, 61) .. "..." end

                        eui:uiSetText(UI.label[1], {
                                en = bullet .. "Character ID »  #FFFFFF" .. tostring(charId) .. "\n"
                                        .. bullet .. "Name »  #FFFFFF" .. tostring(charName) .. "\n"
                                        .. bullet .. "Gender »  #FFFFFF" .. gender[1] .. "\n"
                                        .. bullet .. "Age »  #FFFFFF" .. tostring(age) .. " years old\n"
                                        .. bullet .. "Height »  #FFFFFF" .. tostring(height) .. " cm\n"
                                        .. bullet .. "Weight »  #FFFFFF" .. tostring(weight) .. " kg\n"
                                        .. bullet .. "Ethnicity »  #FFFFFF" .. race[1] .. "\n"
                                        .. bullet .. "Fingerprint »  #FFFFFF" .. fingerprint .. "\n"
                                        .. bullet .. "Description »  #FFFFFF" .. tostring(desc or "-"),
                                ar = bullet .. "رقم الشخصية »  #FFFFFF" .. tostring(charId) .. "\n"
                                        .. bullet .. "الاسم »  #FFFFFF" .. tostring(charName) .. "\n"
                                        .. bullet .. "الجنس »  #FFFFFF" .. gender[2] .. "\n"
                                        .. bullet .. "العمر »  #FFFFFF" .. tostring(age) .. " سنة\n"
                                        .. bullet .. "الطول »  #FFFFFF" .. tostring(height) .. " سم\n"
                                        .. bullet .. "الوزن »  #FFFFFF" .. tostring(weight) .. " كجم\n"
                                        .. bullet .. "العِرق »  #FFFFFF" .. race[2] .. "\n"
                                        .. bullet .. "بصمة الأصابع »  #FFFFFF" .. fingerprint .. "\n"
                                        .. bullet .. "الوصف »  #FFFFFF" .. tostring(desc or "-"),
                        })
                        -- [Fix #63] REAL level from level-system (old client:
                        -- "Level ${color.primary} N" + "exp / required" + progress).
                        -- The decompile inlined getPlayerLevel() everywhere and lost
                        -- the 2nd/3rd returns (same artifact repaired in c_level.lua)
                        -- - unpacked with explicit locals here.
                        local hours = tonumber(getElementData(localPlayer, "hoursplayed")) or 0
                        local minutes = math.floor((tonumber(getElementData(localPlayer, "timeinserver")) or 0))
                        local lv, lvExp, lvReq = exports["level-system"]:getPlayerLevel()
                        if not lv or lv < 1 then lv, lvExp, lvReq = 1, 0, 50 end
                        eui:uiSetText(UI.label.level, {
                                en = "Level ${color.primary}" .. tostring(lv),
                                ar = "المستوى ${color.primary}" .. tostring(lv),
                        })
                        eui:uiSetText(UI.label.level_exp, {
                                en = tostring(lvExp) .. " / " .. tostring(lvReq),
                                ar = tostring(lvExp) .. " / " .. tostring(lvReq),
                        })
                        eui:uiProgressBarSetProgress(UI.progressbar[1], lvExp / lvReq * 100)
                        -- cash + bank balance live in the play-time card
                        -- Fix #26: this server stores money in elementData "money" (custom economy)
                        local money = tonumber(getElementData(localPlayer, "money"))
                                or getPlayerMoney() or 0
                        local bank = tonumber(getElementData(localPlayer, "bankmoney")) or 0
                        eui:uiSetText(UI.label.play_time, {
                                en = "\nPlay Time\n\n" .. tostring(math.floor(hours)) .. "h " .. (minutes % 60) .. "m\n\n"
                                        .. "Cash ${color.primary}$" .. convertNumber(money) .. "\n"
                                        .. "Bank ${color.primary}$" .. convertNumber(bank),
                                ar = "وقت اللعب\n\n" .. tostring(math.floor(hours)) .. " ساعة " .. (minutes % 60) .. " دقيقة\n\n"
                                        .. "المال ${color.primary}$" .. convertNumber(money) .. "\n"
                                        .. "البنك ${color.primary}$" .. convertNumber(bank),
                        })

                        -- licenses use the REAL keys (license.car/bike/boat/pilot/gun)
                        local function hasLicense(key)
                                return (tonumber(getElementData(localPlayer, key)) or 0) >= 1
                        end
                        eui:uiSetText(UI.label[4], {
                                en = bullet .. "Career »  #FFFFFF" .. tostring(job or "Unemployed") .. "\n"
                                        .. bullet .. "Faction Rank »  #FFFFFF" .. tostring(factionRank or "None") .. "\n"
                                        .. bullet .. "Car License:  #FFFFFF" .. (hasLicense("license.car") and "Yes" or "#FF0000No") .. "\n"
                                        .. bullet .. "Bike License:  #FFFFFF" .. (hasLicense("license.bike") and "Yes" or "#FF0000No") .. "\n"
                                        .. bullet .. "Boats License:  #FFFFFF" .. (hasLicense("license.boat") and "Yes" or "#FF0000No") .. "\n"
                                        .. bullet .. "Pilots License:  #FFFFFF" .. (hasLicense("license.pilot") and "Yes" or "#FF0000No") .. "\n"
                                        .. bullet .. "Gun License:  #FFFFFF" .. (hasLicense("license.gun") and "Yes" or "#FF0000No"),
                                ar = bullet .. "المهنة »  #FFFFFF" .. tostring(job or "عاطل") .. "\n"
                                        .. bullet .. "رتبة الفاشن »  #FFFFFF" .. tostring(factionRank or "لا يوجد") .. "\n"
                                        .. bullet .. "رخصة السيارة:  #FFFFFF" .. (hasLicense("license.car") and "نعم" or "#FF0000لا") .. "\n"
                                        .. bullet .. "رخصة الدراجة:  #FFFFFF" .. (hasLicense("license.bike") and "نعم" or "#FF0000لا") .. "\n"
                                        .. bullet .. "رخصة القوارب:  #FFFFFF" .. (hasLicense("license.boat") and "نعم" or "#FF0000لا") .. "\n"
                                        .. bullet .. "رخصة الطيار:  #FFFFFF" .. (hasLicense("license.pilot") and "نعم" or "#FF0000لا") .. "\n"
                                        .. bullet .. "رخصة السلاح:  #FFFFFF" .. (hasLicense("license.gun") and "نعم" or "#FF0000لا"),
                        })
                        local accName = getElementData(localPlayer, "account:username")
                        if type(accName) ~= "string" or accName == "" then accName = getPlayerName(localPlayer) end
                        eui:uiSetText(UI.label.username, "Current Username: " .. tostring(accName))
                end
        end)

        addEventHandler("onClientUITabSwitched", root, function(_, tab)
                if tab == UI.tab[2] then
                        if getTickCount() - state.vehicles < 10000 then return end
                        state.vehicles = getTickCount()
                        triggerServerEvent("main-menu:characterInfo:getVehicles", localPlayer)
                elseif tab == UI.tab[3] then
                        if getTickCount() - state.interiors < 10000 then return end
                        state.interiors = getTickCount()
                        triggerServerEvent("main-menu:characterInfo:getInteriors", localPlayer)
                elseif tab == UI.tab["leaderboard:levels"] then
                        updateLeaderboard("levels")
                elseif tab == UI.tab["leaderboard:activities"] then
                        updateLeaderboard("activities")
                end
        end)

        addEvent("main-menu:characterInfo:getVehicles:callback", true)
        addEventHandler("main-menu:characterInfo:getVehicles:callback", localPlayer, function(list, slots)
                eui:uiSetText(UI.label.vehicles, "Vehicles  #FFFFFF( ${color.primary}" .. tostring(#list) .. "#ffffff / " .. tostring(slots or #list) .. " )")
                eui:uiGridListClear(UI.gridlist.vehicles)
                for _, car in ipairs(list) do
                        local row = eui:uiGridListAddRow(UI.gridlist.vehicles)
                        eui:uiGridListSetItemText(UI.gridlist.vehicles, row, 1, tostring(car.ID))
                        eui:uiGridListSetItemColor(UI.gridlist.vehicles, row, 1, eui:uiGetThemeColor("primary"))
                        local name = tostring(car.Name or "?")
                        if car.impounded then
                                name = name .. "  |  #FF0000(Impounded)#FFFFFF"
                        elseif car.hidden == 1 then
                                eui:uiGridListSetItemColor(UI.gridlist.vehicles, row, 2, tocolor(180, 180, 180, 255))
                                name = name .. "  |  (Hidden)"
                        end
                        eui:uiGridListSetItemText(UI.gridlist.vehicles, row, 2, name)
                        eui:uiGridListSetItemText(UI.gridlist.vehicles, row, 3, car.plate or "")
                end
        end)

        addEvent("main-menu:characterInfo:getInteriors:callback", true)
        addEventHandler("main-menu:characterInfo:getInteriors:callback", localPlayer, function(list, slots)
                eui:uiSetText(UI.label.interiors, "Interiors  #FFFFFF( ${color.primary}" .. tostring(#list) .. "#ffffff / " .. tostring(slots or #list) .. " )")
                eui:uiGridListClear(UI.gridlist.interiors)
                for _, interior in ipairs(list) do
                        local row = eui:uiGridListAddRow(UI.gridlist.interiors)
                        eui:uiGridListSetItemText(UI.gridlist.interiors, row, 1, tostring(interior.id))
                        eui:uiGridListSetItemColor(UI.gridlist.interiors, row, 1, eui:uiGetThemeColor("primary"))
                        eui:uiGridListSetItemText(UI.gridlist.interiors, row, 2, tostring(interior.name))
                        local status = tostring(interior.status or "-")
                        if status == "rented" then
                                eui:uiGridListSetItemColor(UI.gridlist.interiors, row, 3, tocolor(255, 255, 0))
                                eui:uiGridListSetItemText(UI.gridlist.interiors, row, 3, status .. " ($" .. tostring(interior.price or 0) .. ")")
                        elseif status == "owned" then
                                eui:uiGridListSetItemColor(UI.gridlist.interiors, row, 3, tocolor(168, 255, 168))
                                eui:uiGridListSetItemText(UI.gridlist.interiors, row, 3, status)
                        else
                                eui:uiGridListSetItemText(UI.gridlist.interiors, row, 3, status)
                        end
                end
        end)

        addEvent("leaderboard:get:response", true)
        addEventHandler("leaderboard:get:response", localPlayer, function(kind, list)
                local grid = UI.gridlist["leaderboard:" .. tostring(kind)]
                if not grid then return end
                eui:uiGridListClear(grid)
                if type(list) ~= "table" then return end
                for rank, entry in ipairs(list) do
                        local row = eui:uiGridListAddRow(grid)
                        eui:uiGridListSetItemText(grid, row, 1, tostring(rank) .. ".")
                        eui:uiGridListSetItemText(grid, row, 2, tostring(entry.name))
                        eui:uiGridListSetItemText(grid, row, 3, tostring(kind == "levels" and entry.level or entry.points))
                end
        end)

        uiBuilt = true
end

function UIKitReady()
        local ok, err = pcall(buildMainMenuUI)
        if not ok then
                uiBuilt = false
                if UI.window.MainMenu and isElement(UI.window.MainMenu) then
                        destroyElement(UI.window.MainMenu)
                end
                UI.window.MainMenu = nil
                outputChatBox("#ff6b6b[F1] UI build error: #ffffff" .. tostring(err), 255, 107, 107, true)
        end
end

function updateLeaderboard(kind)
        if getTickCount() - state["leaderboard:" .. kind] < 10000 then return end
        state["leaderboard:" .. kind] = getTickCount()
        triggerServerEvent("leaderboard:get", localPlayer, kind)
end

addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEvent("onClientUIKitReady", true)
addEventHandler("onClientUIKitReady", root, UIKitReady)

--[[ Fix #26 (user): "البلاغات م تقدر تكتب بها ولاحرف" — UIKit's own pipeline
     does not always hand keyboard focus to the report edit/memo. A raw click
     on their rects focuses them explicitly (same trick the staff panel uses). ]]
addEventHandler("onClientClick", root, function(button, press)
        if not press or button ~= "left" then return end
        if not (UI.window.report_center and eui:uiGetVisible(UI.window.report_center)) then return end
        local cx, cy = getCursorPosition()
        if not cx then return end
        cx, cy = cx * sx, cy * sy
        local okM, mx, my = pcall(eui.uiGetPosition, UI.memo.report_text)
        if okM and cx >= mx and cx <= mx + 530 * SCALE_Y and cy >= my and cy <= my + 175 * SCALE_Y then
                pcall(function() eui:uiSetFocusedElement(UI.memo.report_text) end)
                return
        end
        local okE, ex, ey = pcall(eui.uiGetPosition, UI.edit.report_target)
        if okE and cx >= ex and cx <= ex + 530 * SCALE_Y and cy >= ey and cy <= ey + 25 * SCALE_Y then
                pcall(function() eui:uiSetFocusedElement(UI.edit.report_target) end)
        end
end)

--------------------------------------------------------------------------------
-- [Fix #35] load sentinel: if c_main.lua aborts at LOAD time (one bad line
-- kills the whole file and F1 dies with NO trace), the ping below never
-- fires and the server warns the player instead of leaving F1 dead silently.
--------------------------------------------------------------------------------
triggerServerEvent("mainmenu:clientLoaded", localPlayer)
