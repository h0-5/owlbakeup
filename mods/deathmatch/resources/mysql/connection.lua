--[[
	mysql resource - connection layer
	------------------------------------------------------------
	Rewritten to use MTA's built-in dbConnect / dbQuery API.
	The old version relied on the external "dbconmy"/"mta_mysql"
	module which does not initialize on modern server builds.

	Every exported function keeps the SAME NAME and the SAME
	arguments/return values as the old module, so all other
	resources (exports.mysql:query, fetch_assoc, ...) keep
	working without any change.
--]]

-- connection settings
local hostname = "127.0.0.1"
local username = "root"
local password = ""
local database = "pdz"
local port = 3306
local sqlCharset = "utf8mb4"

-- optional second connection (phpbb / IPB forum database).
-- Leave forumDatabase = nil when the forum DB is not imported: the
-- forum_* helper functions then quietly return false/nil instead of
-- spamming SQL errors.
local forumDatabase = nil
local forumHostname = "127.0.0.1"
local forumUsername = "root"
local forumPassword = ""

-- shared settings (also used by the legacy getters in s_mysql.lua)
MYSQL_SETTINGS = {
	hostname = hostname,
	username = username,
	password = password,
	database = database,
	port = port,
}

-- global things
local MySQLConnection = nil
local ForumConnection = nil
local resultPool = { }
local freeResultIds = { }
local nextResultId = 0
local sqllog = false
local countqueries = 0
local debugModeEnabled = false

-- mysql_null - legacy helper of the old dbconmy module.
-- dbPoll returns SQL NULL values as nil, so returning nil keeps every
-- old comparison such as (row.field ~= mysql_null()) working as before.
function mysql_null()
	return nil
end

-- MTA gives every resource its own global environment and blocks
-- getfenv/setfenv, so a Lua global defined in this resource cannot be
-- shared with the others (the old C module could). Because of that the
-- legacy mysql_null() calls inside the other resources are replaced by
-- "nil" (dbPoll already returns nil for SQL NULL, so the behaviour is
-- identical).

local function logMessageToLogsResource(message)
	local logsResource = getResourceFromName("logs")
	if (logsResource and getResourceState(logsResource) == "running") then
		exports["logs"]:logMessage(message, 24)
	else
		outputDebugString(message)
	end
end

-- connectToDatabase - Internal function, spawn a DB connection
function connectToDatabase()
	if (MySQLConnection and isElement(MySQLConnection)) then
		return true
	end

	local connectionString = "dbname=" .. database ..
		";host=" .. hostname ..
		";port=" .. port ..
		";charset=" .. sqlCharset

	MySQLConnection = dbConnect("mysql", connectionString, username, password)

	if (not MySQLConnection) then
		outputServerLog("[MYSQL] Failed to connect to database '" .. database .. "' at " .. hostname .. ":" .. port .. " (user: " .. username .. ")")
		return false
	end

	outputServerLog("[MYSQL] Connected to database '" .. database .. "' at " .. hostname .. ":" .. port)
	return true
end

addEventHandler("onResourceStart", getResourceRootElement(getThisResource()),
	function()
		connectToDatabase()
	end, false)

-- destroyDatabaseConnection - Internal function, kill the connection if theres one.
function destroyDatabaseConnection()
	if (MySQLConnection and isElement(MySQLConnection)) then
		destroyElement(MySQLConnection)
	end
	MySQLConnection = nil

	if (ForumConnection and isElement(ForumConnection)) then
		destroyElement(ForumConnection)
	end
	ForumConnection = nil
end
addEventHandler("onResourceStop", getResourceRootElement(getThisResource()), destroyDatabaseConnection, false)

function logSQLError(str, errorCode, errorMessage)
	local message = str or "N/A"
	if (errorCode or errorMessage) then
		message = message .. " [ERROR] " .. tostring(errorCode) .. ": " .. tostring(errorMessage)
	end
	if (debugModeEnabled) then
		outputDebugString("MYSQL ERROR: " .. message)
	end
	logMessageToLogsResource("MYSQL ERROR :O! [QUERY] " .. message)
end

local function acquireResultID()
	local id = table.remove(freeResultIds)
	if (id) then
		return id
	end
	nextResultId = nextResultId + 1
	return nextResultId
end

local function releaseResultID(resultid)
	resultPool[resultid] = nil
	table.insert(freeResultIds, resultid)
end

-- ping - makes sure we have a live connection (reconnects when needed)
function ping()
	if (MySQLConnection and isElement(MySQLConnection)) then
		return true
	end
	return connectToDatabase()
end

function escape_string(str)
	if (str == nil) then
		return ""
	end
	str = tostring(str)

	local escaped = str:gsub("\\", "\\\\")
	escaped = escaped:gsub("'", "\\'")
	escaped = escaped:gsub('"', '\\"')
	escaped = escaped:gsub("\n", "\\n")
	escaped = escaped:gsub("\r", "\\r")
	escaped = escaped:gsub("\t", "\\t")
	escaped = escaped:gsub("%z", "\\0")

	return escaped
end

------------ QUERY FUNCTIONS (same API as before) ---------------

-- query - runs a query and returns a result id (or false on error)
function query(str)
	if (type(str) ~= "string") then
		return false
	end

	if sqllog then
		outputDebugString("[SQL] " .. str)
	end
	countqueries = countqueries + 1

	if (not ping()) then
		return false
	end

	local queryHandle = dbQuery(MySQLConnection, str)
	if (not queryHandle) then
		logSQLError(str)
		return false
	end

	local rows, errorCode, errorMessage = dbPoll(queryHandle, -1)
	if (rows == false) then
		logSQLError(str, errorCode, errorMessage)
		return false
	end

	local resultid = acquireResultID()
	resultPool[resultid] = { rows = rows, cursor = 0 }
	return resultid
end

-- unbuffered_query - kept for compatibility (dbQuery buffers anyway)
function unbuffered_query(str)
	return query(str)
end

function query_free(str)
	local queryresult = query(str)
	if (queryresult == false) then
		return false
	end
	releaseResultID(queryresult)
	return true
end

function fetch_assoc(resultid)
	local entry = resultPool[resultid]
	if (not entry) then
		return false
	end
	entry.cursor = entry.cursor + 1
	local row = entry.rows[entry.cursor]
	if (not row) then
		return false
	end
	return row
end

function rows_assoc(resultid)
	local entry = resultPool[resultid]
	if (not entry) then
		return false
	end
	return entry.rows
end

function free_result(resultid)
	if (not resultPool[resultid]) then
		return false
	end
	releaseResultID(resultid)
	return nil
end

-- result - legacy access by row/field offset (mysql_result equivalent)
function result(resultid, row_offset, field_offset)
	local entry = resultPool[resultid]
	if (not entry) then
		return false
	end

	local row = entry.rows[row_offset or 1]
	if (not row) then
		return false
	end

	if (field_offset == nil) then
		for _, value in pairs(row) do
			return value
		end
		return false
	elseif (type(field_offset) == "number") then
		local index = 0
		for _, value in pairs(row) do
			index = index + 1
			if (index == field_offset) then
				return value
			end
		end
		return false
	end

	return row[field_offset]
end

function num_rows(resultid)
	local entry = resultPool[resultid]
	if (not entry) then
		return false
	end
	return #entry.rows
end

function insert_id()
	if (not ping()) then
		return false
	end

	local queryHandle = dbQuery(MySQLConnection, "SELECT LAST_INSERT_ID() AS id")
	if (not queryHandle) then
		return false
	end

	local rows = dbPoll(queryHandle, -1)
	if (not rows or not rows[1]) then
		return false
	end
	return rows[1].id
end

function query_fetch_assoc(str)
	local queryresult = query(str)
	if (queryresult == false) then
		return false
	end
	local row = fetch_assoc(queryresult)
	releaseResultID(queryresult)
	return row
end

function query_rows_assoc(str)
	local queryresult = query(str)
	if (queryresult == false) then
		return false
	end
	local rows = rows_assoc(queryresult)
	releaseResultID(queryresult)
	return rows
end

function query_insert_free(str)
	local queryresult = query(str)
	if (queryresult == false) then
		return false
	end
	local id = insert_id()
	releaseResultID(queryresult)
	return id
end

function debugMode()
	sqllog = not sqllog
	debugModeEnabled = sqllog
	return sqllog
end

function returnQueryStats()
	return countqueries
end



------------ QUERY HELPERS (table based, used by several resources) ---------------

-- builds an SQL literal out of a Lua value
local function sqlValue(value)
	if (value == nil) then
		return "NULL"
	end

	local valueType = type(value)
	if (valueType == "number") then
		if (value ~= value or value == math.huge or value == -math.huge) then
			return "NULL"
		end
		return tostring(value)
	elseif (valueType == "boolean") then
		return value and "1" or "0"
	end

	return "'" .. escape_string(tostring(value)) .. "'"
end

-- builds " WHERE `a` = 1 AND `b` = 'x'"
local function buildWhere(where)
	if (type(where) ~= "table") then
		return ""
	end

	local parts = { }
	for column, value in pairs(where) do
		parts[#parts + 1] = "`" .. tostring(column) .. "` = " .. sqlValue(value)
	end

	if (#parts == 0) then
		return ""
	end

	return " WHERE " .. table.concat(parts, " AND ")
end

-- INSERT INTO `table` (...) VALUES (...) -> true / false
function insert(tableName, data)
	if (type(tableName) ~= "string" or type(data) ~= "table") then
		return false
	end

	local columns, values = { }, { }
	for column, value in pairs(data) do
		columns[#columns + 1] = "`" .. tostring(column) .. "`"
		values[#values + 1] = sqlValue(value)
	end

	if (#columns == 0) then
		return false
	end

	return query_free("INSERT INTO `" .. tableName .. "` (" ..
		table.concat(columns, ", ") .. ") VALUES (" .. table.concat(values, ", ") .. ")")
end

-- SELECT * FROM `table` [WHERE ...] -> array of rows
function select(tableName, where)
	if (type(tableName) ~= "string") then
		return false
	end

	local resultid = query("SELECT * FROM `" .. tableName .. "`" .. buildWhere(where))
	if (resultid == false) then
		return false
	end

	local rows = rows_assoc(resultid) or { }
	releaseResultID(resultid)
	return rows
end

-- SELECT * FROM `table` [WHERE ...] LIMIT 1 -> single row or nil
function select_one(tableName, where)
	if (type(tableName) ~= "string") then
		return nil
	end

	local resultid = query("SELECT * FROM `" .. tableName .. "`" .. buildWhere(where) .. " LIMIT 1")
	if (resultid == false) then
		return nil
	end

	local row = fetch_assoc(resultid)
	releaseResultID(resultid)
	return row or nil
end

-- UPDATE `table` SET ... [WHERE ...] -> true / false
function update(tableName, data, where)
	if (type(tableName) ~= "string" or type(data) ~= "table") then
		return false
	end

	local sets = { }
	for column, value in pairs(data) do
		sets[#sets + 1] = "`" .. tostring(column) .. "` = " .. sqlValue(value)
	end

	if (#sets == 0) then
		return false
	end

	return query_free("UPDATE `" .. tableName .. "` SET " .. table.concat(sets, ", ") .. buildWhere(where))
end

-- DELETE FROM `table` [WHERE ...] -> true / false
function delete(tableName, where)
	if (type(tableName) ~= "string") then
		return false
	end

	return query_free("DELETE FROM `" .. tableName .. "`" .. buildWhere(where))
end

------------ OPTIONAL FORUM (phpBB / IPB) CONNECTION ---------------

local function connectForumDatabase()
	if (not forumDatabase) then
		return false
	end

	if (ForumConnection and isElement(ForumConnection)) then
		return true
	end

	local connectionString = "dbname=" .. forumDatabase ..
		";host=" .. forumHostname ..
		";charset=" .. sqlCharset

	ForumConnection = dbConnect("mysql", connectionString, forumUsername, forumPassword)

	if (not ForumConnection) then
		outputServerLog("[MYSQL] Forum database '" .. forumDatabase .. "' is not reachable, forum helpers are disabled.")
		return false
	end

	return true
end

local function forumRunQuery(str)
	if (not connectForumDatabase()) then
		return false
	end

	local queryHandle = dbQuery(ForumConnection, str)
	if (not queryHandle) then
		logSQLError(str)
		return false
	end

	local rows, errorCode, errorMessage = dbPoll(queryHandle, -1)
	if (rows == false) then
		logSQLError(str, errorCode, errorMessage)
		return false
	end

	local resultid = acquireResultID()
	resultPool[resultid] = { rows = rows, cursor = 0 }
	return resultid
end

function forum_query_free(str)
	local resultid = forumRunQuery(str)
	if (resultid == false) then
		return false
	end
	releaseResultID(resultid)
	return true
end

function forum_query_insert_free(str)
	local resultid = forumRunQuery(str)
	if (resultid == false) then
		return false
	end

	local insertId = false
	local queryHandle = dbQuery(ForumConnection, "SELECT LAST_INSERT_ID() AS id")
	if (queryHandle) then
		local rows = dbPoll(queryHandle, -1)
		if (rows and rows[1]) then
			insertId = rows[1].id
		end
	end

	releaseResultID(resultid)
	return insertId
end

function forum_query_fetch_assoc(str)
	local resultid = forumRunQuery(str)
	if (resultid == false) then
		return false
	end

	local row = fetch_assoc(resultid)
	releaseResultID(resultid)
	return row
end

------------ LEGACY LAZY QUERY LOGGER ---------------

-- used by the logs resource for its owl_logs inserts.
-- The query is executed on the main connection; when that fails (missing
-- table / broken query) it is appended to maxime.log so nothing is lost.
local function appendQueryToLogFile(message)
	local filename = "maxime.log"
	local file = nil

	if (fileExists(filename)) then
		file = fileOpen(filename, true)
	else
		file = fileCreate(filename)
	end

	if (not file) then
		return false
	end

	fileSetPos(file, fileGetSize(file))
	fileWrite(file, tostring(message) .. "\r\n")
	fileFlush(file)
	fileClose(file)

	return true
end

function lazyQuery(message)
	if (type(message) == "string" and ping()) then
		local queryHandle = dbQuery(MySQLConnection, message)
		if (queryHandle) then
			local rows = dbPoll(queryHandle, -1)
			if (rows ~= false) then
				return true
			end
		end
	end

	return appendQueryToLogFile(message)
end
