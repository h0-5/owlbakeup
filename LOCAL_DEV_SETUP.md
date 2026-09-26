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

### موارد stock تم نقلها خارج شجرة `resources`

في نسخ MTA الحديثة أصبح تحميل الموارد من ملفات zip مدعومًا، وكان المجلد يحتوي نسخ stock مضغوطة تتعارض مع مواردك (Duplicate paths):

```
mods/deathmatch/disabled_stock_zip_resources/   <-- نُقلت إلى هنا
    [admin] [editor] [gamemodes] [gameplay] [managers] [web]
```

هذا أصلح أخطاء: `scoreboard`, `freecam`, `parachute`, `superman`, `ipb`, `briefcase` (مواردك الأصلية في `resources/` تعمل الآن). إن احتجت أي منها لاحقًا انقلها للخلف.


كل الموارد الأخرى تتعامل مع قاعدة البيانات عن طريق `exports.mysql:*`، لذا هذه القيم تكفي.
`resources/mysql/s_mysql.lua` و `mods/deathmatch/settings.xml` محدّثة أيضًا لتطابق نفس القيم.
