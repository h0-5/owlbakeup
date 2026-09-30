--MAXIME
function createForumThread(thePlayer, poster, createInForumID, fTitle, fContent, MsgToPlayer, alertStaff)
	--local posterUsername = string.gsub(getElementData(poster, "account:username"), "_", " ")
	local posterUsername = 'Maxime'--exports.mysql:escape_string(posterUsername)
	local posterID = 1--getElementData(poster, "account:id")
	
	fTitle = mysql:escape_string(fTitle)
	local content = "[header]"..fTitle.."[/header]"..fContent
	content = mysql:escape_string(content)
	
	local firstID = exports.mysql:forum_query_insert_free("INSERT INTO post SET  parentid = '0', username = '"..posterUsername.."', userid = '"..posterID.."', title = '" .. fTitle .. "', dateline = unix_timestamp(), pagetext = '"..content.."', allowsmilie = '0', showsignature = '0', ipaddress = '127.0.0.1', iconid = '0', visible = '1', attach = '0', infraction = '0', reportthreadid = '0'")
	-- [Fix #94] the forum DB is optional on this server: the insert returns
	-- false and the old code concatenated it ("concatenate local 'firstID'
	-- (a boolean)") which also broke every export caller
	if not firstID then
		outputDebugString("[integration] createForumThread: post insert failed (forum DB unavailable) - skipped", 2)
		return false
	end
	
	local seccondID = exports.mysql:forum_query_insert_free("INSERT INTO thread SET `force_read_usergroups`='', `force_read_forums`='', title = '" .. fTitle .. "', firstpostid = '" .. firstID .. "', lastpost = unix_timestamp(), forumid = '"..createInForumID.."', pollid = '0', open = '1', replycount = '0', postercount = '1', hiddencount = '0', deletedcount = '0', postusername = '"..posterUsername.."', postuserid = '"..posterID.."', lastposter = '"..posterUsername.."', lastposterid = '"..posterID.."', dateline = unix_timestamp(), views = '0', iconid = '0', visible = '1', sticky = '0', votenum = '0', votetotal = '0', attach = '0' ")
	-- [Fix #94] same guard for the thread insert (concatenating false would
	-- throw at the UPDATE below)
	if not seccondID then
		outputDebugString("[integration] createForumThread: thread insert failed (forum DB unavailable) - skipped", 2)
		return false
	end
	
	exports.mysql:forum_query_free("UPDATE post SET threadid = '"..seccondID.."' WHERE postid = '"..firstID.."'")
	exports.mysql:forum_query_free("update `user` set posts = posts + 1 where userid = '"..posterID.."' ")
	exports.mysql:forum_query_free("UPDATE forum set replycount = replycount + 1, lastpost = unix_timestamp(), lastposter = '"..posterUsername.."', lastposterid='"..posterID.."', lastpostid='"..firstID.."', lastthread='"..fTitle.."', lastthreadid='"..seccondID.."', threadcount = threadcount + 1 WHERE forumid = '"..createInForumID.."'")
	
	exports.mysql:forum_query_insert_free("INSERT INTO activitystream SET userid = '"..posterID.."', dateline = unix_timestamp(), contentid = '"..seccondID.."', typeid = '6'")
	if MsgToPlayer then
		outputChatBox(MsgToPlayer..". URL: http://forums.owlgaming.net/showthread.php/"..seccondID, thePlayer)
	end
	
	if alertStaff then
		exports.global:sendWrnToStaff(alertStaff..". URL: http://forums.owlgaming.net/showthread.php/"..seccondID, "NPC")
	end
	return "http://forums.owlgaming.net/showthread.php/"..seccondID
end