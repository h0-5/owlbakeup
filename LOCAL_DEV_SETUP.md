# دليل تشغيل السيرفر محليًا (MTA:SA - Roleplay / PDZ)

آخر تحديث: تم ضبطه وتشغيله بنجاح محليًا (بدون أي أخطاء في `logs/server.log`).

---

## 1) تشغيل السيرفر

```powershell
# من مجلد D:\nta\MTA\server
Start-Process -FilePath 'D:\nta\MTA\server\MTA Server.exe' -WorkingDirectory 'D:\nta\MTA\server'
```

- كل ملفات السيرفر والإعدادات: `D:\nta\MTA\server\mods\deathmatch\`
- اللوقات: `mods\deathmatch\logs\server.log` و `logs\scripts.log`
- إيقاف السيرفر: إغلاق العملية `MTA Server` (أو `shutdown` من الكونسول).

## 2) الدخول من كلنت MTA

1. افتح MTA:SA → **Quick Connect** → اكتب: `127.0.0.1:22221` (البورت من `<serverport>` ومن `<httpport>`).
2. أول حساب: من شاشة الدخول في اللعبة اضغط زر **Register** (`accounts:register:attempt`) وأنشئ حسابك.
3. لتعطيك صلاحيات إدارية كاملة، بعد التسجيل نفّذ:

```powershell
& 'C:\xampp\mysql\bin\mysql.exe' -u root pdz -e "UPDATE accounts SET admin=10 WHERE username='USERNAME';"
```

ثم سجّل خروج ودخول داخل اللعبة (مستوى الأدمن يُقرأ من عمود `accounts.admin` عند الدخول:
`account/login-panel/server.lua` → `setElementDataEx(client, "admin_level", accountData['admin'])`).
تسميات الرتب في `resources/integration` : 1 Trial Admin، 2 Admin، 3 Senior Admin ... حتى 10 (الأعلى).

للمطورين: `debugscript 3` داخل اللعبة لعرض أخطاء الكلاينت، وتصحيح الموارد بـ `/refresh` ثم `/restart mysql`.

## 3) قاعدة البيانات (MySQL محلي - XAMPP)

- الخدمة: `mysql` (XAMPP) على `127.0.0.1:3306`، المستخدم `root` بدون باسورد.
- اسم قاعدة البيانات المحلية: **`pdz`** (تم إنشاؤها واستيراد `pdz.sql` إليها).
  - ملاحظة: القاعدة الأصلية في الدامب اسمها `stdb_user_8796_178` (الدامب لا يحتوي `CREATE DATABASE`).
- لإعادة الاستيراد من جديد:

```powershell
& 'C:\xampp\mysql\bin\mysql.exe' -u root -e "CREATE DATABASE IF NOT EXISTS pdz CHARACTER SET utf8mb4;"
cmd /c "C:\xampp\mysql\bin\mysql.exe -u root --default-character-set=utf8mb4 pdz < D:\nta\MTA\server\mods\deathmatch\pdz.sql"
cmd /c "C:\xampp\mysql\bin\mysql.exe -u root --default-character-set=utf8mb4 pdz < D:\nta\MTA\server\mods\deathmatch\pdz_missing_tables.sql"
```

### إعدادات الاتصال (مكان واحد)

`resources/mysql/connection.lua` (أعلى الملف):

```lua
local hostname = "127.0.0.1"
local username = "root"
local password = ""
local database = "pdz"
local port     = 3306
local sqlCharset = "utf8mb4"

-- قاعدة المنتدى (phpBB/IPB) اختيارية - اتركها nil إذا ما استوردتها
local forumDatabase = nil
```
## 4) أهم التعديلات التي تمت (للتطوير المستقبلي)

| الملف | التعديل |
|---|---|
| `resources/mysql/connection.lua` | **إعادة كتابة كاملة**: التحويل من موديول `dbconmy.dll` القديم إلى واجهة `dbConnect/dbQuery/dbPoll` المدمجة في MTA. كل الدوال القديمة محفوظة بنفس الأسماء (`query`, `query_free`, `fetch_assoc`, `rows_assoc`, `free_result`, `num_rows`, `result`, `insert_id`, `query_fetch_assoc`, `query_rows_assoc`, `query_insert_free`, `escape_string`, `ping`, `debugMode`, `returnQueryStats`, `unbuffered_query`, `mysql_null`). |
| `resources/mysql/connection.lua` | إضافة الدوال الناقصة التي كانت تُستدعى ولا وجود لها: `insert`, `select`, `select_one`, `update`, `delete`, `lazyQuery`, و `forum_query_free / forum_query_insert_free / forum_query_fetch_assoc` (للمنتدى، اختيارية). |
| `resources/mysql/meta.xml` | تصدير كل الدوال الجديدة. |
| `mtaserver.conf` | تعطيل سطر الموديول القديم (`dbconmy.dll` لا يعمل على نسخ السيرفر الحديثة - `Unable to initialize`)؛ `<serverip>` صار فارغًا للتشغيل المحلي؛ `<maxplayers>` صار 32. |
| 21 ملفًا لوا | استبدال `mysql_null()` بـ `nil` (نفس النتيجة: `dbPoll` يرجّع `NULL` كـ `nil`، والمتغيرات العامة غير مشتركة بين الموارد في MTA). |
| `vehicle-system/s_vehicle_system.lua` | إصلاح `resume()` ليتجاهل الكوروتينات المنتهية (كان يملأ اللوق بـ `cannot resume dead coroutine`). |
| `ticket-system/s_vehticket.lua:389` | تصليح سطر مشوّه كان يمنع تحميل المورد: `if (getTeamName(team) == "Los Santos Police Department") or (getTeamName(team) == "San Andreas State Police") then`. |
| `admin-system/Player/s_player_commands.lua` | تحويل قيمة `maximum_clip_ammo` إلى رقم (`tonumber`) لإزالة تحذير `setWeaponProperty` المتكرر. |
| `LSB` / `LSgate` / `dumpsite` meta.xml | تصحيح أسماء ملفات الماب لتطابق الملفات الموجودة فعليًا (`lsbuilding_office.map`, `lspd_gates.map`, `dumpsite.map`). |
| `mtaserver.conf` | تعطيل 10 موارد غير موجودة على القرص: `serialwhitelist, fbi-system, hardwaresurvey, shader_car_paint, shader_water, astro-clothing, shader_lights, hdradar, w-job, farmarjob`. |
| `pdz_missing_tables.sql` (ملف جديد) | جداول كانت ناقصة من الدامب: `applications`, `applications_questions` (+ أسئلة تقديم افتراضية 8 لـ part 1 و 6 لـ part 2)، `dancers`, `logtable`, `owl_logs`. |
| `resources/vehicle-tuning/` (Fix #63 - مورد جديد) | **مودات السيارات**: استرجاع كامل من كلاينت Owl القديم (`backupm/[rp]/vehicle-tuning`). واجهة UIKit مطابقة حرفياً (نفس الإحداثيات والألوان والأعمدة): نافذة "Vehicles Tuning" + لوحة الإحصائيات اليمنى (Max Speed / Acceleration / Engine Inertia / Drive Type / Engine Type مع شريطي تقدم) + نافذة "Vehicles Handling" بـ13 شريط تحكم بنفس min/max/step. الأقسام: Engines / Vehicle Tinting / Neon / Back-fire / Lock Replacement بنفس أسعار الكلاينت (تظليل 20000 وإزالة 5000، نيون 50000 والحذف 1000، باك فاير 500000 وإزالة 5000، تغيير القفل 10000). السيرفر: تحقق ملكية + قرب من الكراج + خصم المال + حفظ دائم (المحرك يُحفظ في `vehicles_custom.handling` بنفس ترتيب قيم الـ33 التي يقرأها `vehicle-manager`, وبقية الإضافات في عمود `vehicles_custom.tuning` الجديد). التظليل يستخدم نفس تخزين أمر `/setvehtint` (`vehicles.tintedwindows` + عنصر البيانات `tinted`). تغيير القفل يحذف كل مفاتيح المركبة (itemID 3) لدى كل اللاعبين ويعطي المالك مفتاحاً جديداً. |
| `resources/vehicle-parking/` (Fix #64 - مورد جديد) | **سكنات/مواقف اللاعبين**: استرجاع من `backupm/[rp]/vehicle-parking`. واجهة UIKit مطابقة حرفياً (نافذتان 400x500 و400x185، أيقونة `parking-area.png`، شريطا (41,71,204)، جدول ID/Vehicle Name بلون (255,234,176)). السيرفر: جدول `vehicle_parking` الجديد + 5 مواقف قابلة للتعديل من أعلى `g_vehicleparking.lua`؛ السيارة الموقوفة تُنقل لديمنشن خاص (6000+رقم الموقف) وتُجمّد وتُقفل (`parked` element data) وتُحفظ في قاعدة البيانات، والإخراج يعيدها لمخرج الموقف. |
| `UIKit/addons/c_rangeslider.lua` (Fix #63) | تفعيل الدالة المصدَّرة `uiRangeSliderSetValue` (كان جسمها فارغاً في الملف المُصرَّف) ليمكن تحميل قيمة الشريط مسبقاً - يستخدمها شريط المحركات في نافذة الـHandling. |
| `pdz_missing_tables.sql` (Fix #63/#64) | إضافة عمود `vehicles_custom.tuning` (JSON: engine/neon/neonOn/backfire) وجدول `vehicle_parking`. **يجب إعادة استيراد الملف مرة واحدة**: `mysql -u root pdz < pdz_missing_tables.sql` (الملف قابل للتشغيل أكثر من مرة). |
| `mtaserver.conf` (Fix #63/#64) | تشغيل الموردين الجديدين `vehicle-tuning` و `vehicle-parking` بعد `vehicle-manager`. |
| `resources/skin-system/` (Fix #65 - مورد جديد) | **سكنات اللاعبين**: استرجاع كامل من كلاينت Owl القديم (`backupm/[rp]/skin-system/skin_c_decompiled.lua`). واجهة UIKit مطابقة حرفياً: نافذة "Fashion Dupont" (350x400) بجدول SkinID/Description/Price (0.15/0.65/0.2) وخيار "My private skins." وزرّي Buy Skin و Close، ولوحة AddSkin (380x220) بحقول Skin ID / Description / URL (.png) / Price + خيار Private skin + أزرار Add و Close و Remove (تُفتح نافذة التعديل بالنقر المزدوج على صف تملكه). السيرفر: الكتالوج هو جدول `clothing` نفسه الذي يستخدمه متجر الملابس وأنبوب الصور (item 16 "Clothes" بقيمة `skin:id`)، وأُضيف له حقلان `private`/`owner` مثل الكلاينت القديم. الأحداث بنفس أسماء الكلاينت القديم: `skins:getSkinsDatabase`, `skins:sendSkinsDatabaseToClient`, `skins:buySkin`, `skins:addNewSkin`, `skins:updateSkin`, `skins:removeSkin`, `skins:showAddSkinWindow`. الشراء يعطي item 16 (بعد التأكد من وجود مساحة) ثم يخصم المال، ولبس السكن يمر بنفس مسار المتجر (`setElementModel` + `clothing:id` + شيدر الصورة)، لذلك ما يحتاج نظام تنزيل/فك تشفير خاص. يُفتح بالتحدث (Talk) مع أي بيد نوعه `ped:interact = "skins"`، ولأصحاب المتجر خيار "Add new skin" إضافي. |
| `mtaserver.conf` (Fix #65) | تشغيل المورد الجديد `skin-system`، وتشغيل `mabako-clothingstore` (كان معطلاً!) لأنه **المورد الوحيد الذي يرسم `clothing:id` على البيد** (تنزيل الصورة من الرابط + شيدر `tex.fx`)، فبدونه لا يظهر أي سكن/ملابس مشتراة في اللعبة. |
| `pdz_missing_tables.sql` (Fix #65) | إضافة عمودي `clothing.private` (0/1) و `clothing.owner` (رقم الشخصية) لسكنات اللاعبين. **يجب إعادة استيراد الملف مرة واحدة**: `mysql -u root pdz < pdz_missing_tables.sql`. لو الأعمدة ناقصة، `skin-system` يشتغل لكن يحفظ كل السكنات كعامة (ويطبع تحذيرًا في اللوق). |
| `mabako-clothingstore/g_util.lua` + `s_shop.lua` (Fix #65) | احترام خصوصية السكنات: `canBuySkin` يرفض سكن `private = 1` لغير صاحبه، وقائمة `clothing:list` ما ترسل السكنات الخاصة لغير مالكها (كانت تظهر للجميع في متجر الملابس). |
| `vehicle-tuning/c_vehtuning.lua` + `g_vehtuning.lua` (Fix #63 متابعة) | تصحيح إضاءة النيون: `createLight` كانت تُستدعى بوسائط ناقصة ونطاق 0 (لا تُرى)، صارت `createLight(0, x, y, z, 1.8, r, g, b)` وموضعها يُحدَّث كل فريم من مصفوفة السيارة بنفس إزاحات الكلاينت القديم (نوران متماثلان = يضيّئان الأرض، حسب سلوك MTA الرسمي). `TUNING.neonUseObjects = false` صريحة: فعّلها لو رجع باك الدفات/التكسترات للأجسام 1940. |
| باقي ناقص من الكلاينت القديم | مورد `clothes` (متجر الملابس بالأجزاء: قمصان/بناطيل/أحذية/نظارات... بقوائم `clothes_types` و `clothes_list` و نافذة "Clothes Shop" ثنائية اللغة) موجود في الباك أب ولم يُسترجَع بعد. `barber` (الحلاق) كذلك. |
| `resources/interior-system/c_interior_ui.lua` (Fix #66 - ملف جديد) | **لوحات البيوت**: استرجاع كامل من كلاينت Owl القديم (`backupm/[rp]/interior-system/int_c_decompiled.lua`) بنفس أرقام UIKit حرفياً: "Purchase Property" / "Rent Property" (439x187: ليبل المعلومات + زر Purchase/Rent + Preview Interior + Cancel)، "Property Panel" (439x237: خانة المعلومات الكاملة + Sell property + Cancel)، و"Check Interior" (400x350: آخر دخول/خروج/قفل/فتح + Close). مع أحداث الكلاينت القديم: `interior:openPanel` / `interior:openPurchaseWindow` / `interior:openRentWindow` / `interiors:checkint` / `interior:onClientMarkerHit` / `interior:onClientMarkerLeave` / `interior:playSound`، ورسم اسم العقار في أسفل الشاشة، و لافتة F/H (اللافتة الكاملة للكلاينت القديم موجودة خلف `SHOW_DIRECTIVE` لأن `c_pickups.lua` يرسم HUD سفلي أصلاً)، ومفتاح H لفتح لوحة العقار. |
| `resources/interior-system/s_interior_ui.lua` (Fix #66 - ملف جديد) | **النصف الناقص من أنظمة البيوت**: يستقبل طلب البيد من الكلاينت ويتحقق منه (نفس باب العقار / نفس الديمنشن)، يبني بيانات لوحة العقار (السعر الأصلي، سعر الشراء، تاريخ الشراء، المالك السابق، المالك/المستأجر، العنوان بنفس صيغة الكلاينت: مسافة عن مركز الخريطة + اسم المنطقة)، `interior:buyInterior`/`interior:rentInterior` (جيب اللاعب ثم البنك — ولو كان قائد فاكشن يفتح نافذة الدفع القديمة حتى لا تُفقد ميزة شراء الفاكشن)، `interior:sellInterior` (نفس منطق `/sellproperty` ونفس استرجاع 2/3)، `interior:previewInterior` (نفس معاينة الـ60 ثانية)، وأمر `/checkint [id]` الذي يفتح لوحة "Check Interior" بآخر ENTER/EXIT/LOCK/UNLOCK، وكتابة هذه الحركات في `interior_logs` (كانت ناقصة). |
| `interior-system/c_interior_system.lua` + `blips` (Fix #66) | زر F عند عقار للبيع صار يفتح نوافذ الكلاينت القديم (`interior:openPurchaseWindow` أو `interior:openRentWindow`) بدل نافذة `openPropertyGUI` القديمة (تبقى متاحة لقادة الفاكشنات لأختيار الدفع). |
| `interior-manager/s_interior_manager.lua` (Fix #66) | `/checkint` صار يفتح لوحة "Check Interior" الجديدة (مثل الكلاينت القديم)، ونافذة الإدارة القديمة الكاملة باقية على `/checkinterior` وعلى حدث `interiorManager:checkint` (بدون حذف أي وظيفة). |
| `interior-system/meta.xml` (Fix #66) | تسجيل `s_interior_ui.lua` (بعد s_interior_system) و `c_interior_ui.lua` (قبل c_pickups.lua لأن الأخير يعمل cancelEvent للكول‌شيب). |
| `pdz_missing_tables.sql` (Fix #66) | إضافة `interiors.purchaseprice` / `interiors.purchasedate` / `interiors.originalowner` (تظهر في لوحة العقار). **أعد استيراد الملف**: `mysql -u root pdz < pdz_missing_tables.sql` — لو ما استوردتها يشتغل النظام لكن اللوحة تعرض سعر القائمة بدل سعر الشراء. |
| `radar/c_radar.lua` (Fix #62) | استرجاع 7 تفاصيل بصرية من كلاينت Owl القديم (باك أب backupm): hover البليب 1.3x على الميني ماب، ليبل dispatch الأسود بجانب أيقونة الديسباتش، سمك خط GPS في الميني ماب 8px، خط المسار في F11 يتكبر مع الزوم، سهم اللاعب في F11 أبيض (بدل الوردي)، لوجو السيرفر خلف أيقونة البليب المُمرّر في السايذبار، حد الزوم الأدنى 0.9. |

### موارد stock تم نقلها خارج شجرة `resources`

في نسخ MTA الحديثة أصبح تحميل الموارد من ملفات zip مدعومًا، وكان المجلد يحتوي نسخ stock مضغوطة تتعارض مع مواردك (Duplicate paths):

```
mods/deathmatch/disabled_stock_zip_resources/   <-- نُقلت إلى هنا
    [admin] [editor] [gamemodes] [gameplay] [managers] [web]
```

هذا أصلح أخطاء: `scoreboard`, `freecam`, `parachute`, `superman`, `ipb`, `briefcase` (مواردك الأصلية في `resources/` تعمل الآن). إن احتجت أي منها لاحقًا انقلها للخلف.


كل الموارد الأخرى تتعامل مع قاعدة البيانات عن طريق `exports.mysql:*`، لذا هذه القيم تكفي.
`resources/mysql/s_mysql.lua` و `mods/deathmatch/settings.xml` محدّثة أيضًا لتطابق نفس القيم.
