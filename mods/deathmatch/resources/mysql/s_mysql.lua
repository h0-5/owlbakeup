-- legacy getters - values come from the shared MYSQL_SETTINGS table
-- which is filled by connection.lua (single place to configure).
username = "root"
password = ""
db = "pdz"
host = "127.0.0.1"
port = 3306

local function setting(name, fallback)
	if (MYSQL_SETTINGS and MYSQL_SETTINGS[name]) then
		return MYSQL_SETTINGS[name]
	end
	return fallback
end

function getMySQLUsername()
	return setting("username", username)
end

function getMySQLPassword()
	return setting("password", password)
end

function getMySQLDBName()
	return setting("database", db)
end

function getMySQLHost()
	return setting("hostname", host)
end

function getMySQLPort()
	return setting("port", port)
end