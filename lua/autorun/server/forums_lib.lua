IGForums = IGForums or { }

///////////////////////////////////////////////////////////////
/// Checks if a category exists, used before creating a thread.
function IGForums:CategoryExists( id )
	local categoryQuery = [[
	SELECT id 
	FROM forum_categories
	WHERE id = %d;
	]]
	local resultSet = sql.Query( string.format( categoryQuery, id ) )
	local doesExist = ( resultSet and tonumber( resultSet[1].id ) )
	return ( tobool( doesExist ) )
end

///////////////////////////////////////////////////////////////
/// Checks if a thread exists, used before creating a post.
function IGForums:ThreadExists( id )
	local threadQuery = [[
	SELECT id 
	FROM forum_threads
	WHERE id = %d;
	]]
	local resultSet = sql.Query( string.format( threadQuery, id ) )
	local doesExist = ( resultSet and tonumber( resultSet[1].id ) )
	return ( tobool( doesExist ) )
end

////////////////////////////////////////////////////////////////
/// Gets the ID for the specified icon, returns false 
/// if no icon is found.
function IGForums:GetIconID( iconPath )
	local iconQuery = [[
	SELECT id 
	FROM forum_icons
	WHERE path = %s;
	]]
	local resultSet = sql.Query( string.format( iconQuery, SQLStr( iconPath ) ) )
	if ( resultSet ) then
		return ( tonumber( resultSet[1].id ) )
	else
		return false
	end
end

///////////////////////////////////////////////////////////////
/// Makes all players who currently have the forum viewer open
/// request/refresh the category or thread they're in.
function IGForums:UpdateAllForumViewers( )
	for index, ply in ipairs ( player.GetAll( ) ) do
		ply:RefreshForumViewer( )
	end
end

///////////////////////////////////////////////////////////////
/// Used to broadcast the changing of a user's values to the
/// whole server.
function IGForums:BroadcastUserUpdate( id, enum, value )
	for index, ply in ipairs ( player.GetAll( ) ) do
		ply:UpdatePlayerInfo( id, enum, value )
	end
end

///////////////////////////////////////////////////////////////
/// Checks if a specific userID is banned.
function IGForums:IsIDBanned( userID )
	local userQuery = [[
	SELECT banned 
	FROM forum_users
	WHERE user_id = %d;
	]]
	local resultSet = sql.Query( string.format( userQuery, userID ) )
	if not ( resultSet ) then return true end
	return ( tobool( resultSet[1].banned ) )
end

///////////////////////////////////////////////////////////////
/// Bans a user by their ID.
function IGForums:BanUserByID( userID, activator )
	local userQuery = [[
	UPDATE forum_users
	SET banned = 1
	WHERE user_id = %d;
	]]
	sql.Query( string.format( userQuery, userID ) )
	self:BroadcastUserUpdate( IGFORUMS_UPDATEBAN, userID, true )
	if ( IsValid( activator ) ) then
		activator:SendForumHint( "You've banned UserID[ " .. userID .. " ] from the Forums.", 3 )
		self:Log( activator:GetNiceInfo( ) .. " has banned UserID[ " .. userID .. " ]." )
	end
end

///////////////////////////////////////////////////////////////
/// Unbans a user by their ID
function IGForums:UnBanUserByID( userID, activator )
	local userQuery = [[
	UPDATE forum_users
	SET banned = 0
	WHERE user_id = %d;
	]]
	sql.Query( string.format( userQuery, userID ) )
	self:BroadcastUserUpdate( IGFORUMS_UPDATEBAN, userID, false )
	if ( IsValid( activator ) ) then
		activator:SendForumHint( "You've unbanned UserID[ " .. userID .. " ] from the Forums.", 3 )
		self:Log( activator:GetNiceInfo( ) .. " has unbanned UserID[ " .. userID .. " ]." )
	end
end

///////////////////////////////////////////////////////////////
/// Toggles whether a thread is a sticky or not.
function IGForums:ToggleThreadSticky( threadID, activator )
	local threadQuery = [[
	SELECT sticky 
	FROM forum_threads
	WHERE id = %d;
	]]
	local resultSet = sql.Query( string.format( threadQuery, threadID ) )
	if not ( resultSet ) then return end
	local newStatus = !tobool( resultSet[1].sticky )
	newStatus = newStatus and 1 or 0
	local updateThreadQuery = [[
	UPDATE forum_threads
	SET sticky = %d
	WHERE id = %d;
	]]
	sql.Query( string.format( updateThreadQuery, newStatus, threadID ) )
	newStatus = tobool( newStatus )
	net.Start( "IGForums_ThreadNET" )
		net.WriteUInt( IGFORUMS_UPDATETHREADSTICKY, 16 )
		net.WriteUInt( threadID, 32 )
		net.WriteBit( newStatus )
	net.Broadcast( )
	if ( IsValid( activator ) ) then
		if ( newStatus ) then
			activator:SendForumHint( "You've stickied ThreadID[ " .. threadID .. " ].", 3 )
			self:Log( activator:GetNiceInfo( ) .. " has stickied ThreadID[ " .. threadID .. " ]." )
		else
			activator:SendForumHint( "You've unstickied ThreadID[ " .. threadID .. " ].", 3 )
			self:Log( activator:GetNiceInfo( ) .. " has stickied ThreadID[ " .. threadID .. " ]." )
		end
	end
end

///////////////////////////////////////////////////////////////
/// Toggles the locked status of a thread.
function IGForums:ToggleThreadLock( threadID, activator )
	local threadQuery = [[
	SELECT locked 
	FROM forum_threads
	WHERE id = %d;
	]]
	local resultSet = sql.Query( string.format( threadQuery, threadID ) )
	if not ( resultSet ) then return end
	local newStatus = !tobool( resultSet[1].locked )
	newStatus = newStatus and 1 or 0
	local updateThreadQuery = [[
	UPDATE forum_threads
	SET locked = %d
	WHERE id = %d;
	]]
	sql.Query( string.format( updateThreadQuery, newStatus, threadID ) )
	newStatus = tobool( newStatus )
	net.Start( "IGForums_ThreadNET" )
		net.WriteUInt( IGFORUMS_UPDATETHREADLOCK, 16 )
		net.WriteUInt( threadID, 32 )
		net.WriteBit( newStatus )
	net.Broadcast( )
	if ( IsValid( activator ) ) then
		if ( newStatus ) then
			activator:SendForumHint( "You've locked ThreadID[ " .. threadID .. " ].", 3 )
			self:Log( activator:GetNiceInfo( ) .. " has locked ThreadID[ " .. threadID .. " ]." )
		else
			activator:SendForumHint( "You've unlocked ThreadID[ " .. threadID .. " ].", 3 )
			self:Log( activator:GetNiceInfo( ) .. " has unlocked ThreadID[ " .. threadID .. " ]." )
		end
	end
end

///////////////////////////////////////////////////////////////
/// TSwitches the priority of a category with the one above
/// it or below it.
function IGForums:MoveCategory( categoryID, enum )
	local categoryCount = [[
	SELECT COUNT( id ) AS amount 
	FROM forum_categories;
	]]
	local countResultSet = sql.Query( categoryCount )
	if ( !countResultSet or tonumber( countResultSet[1].amount ) <= 1 ) then
		return
	end
	local categoryQuery = [[
	SELECT priority 
	FROM forum_categories
	WHERE id = %d;
	]]
	local resultSet = sql.Query( string.format( categoryQuery, categoryID ) )
	local currentPriority = tonumber( resultSet[1].priority )
	local changePriorityQuery = [[
	UPDATE forum_categories
	SET priority = %d
	WHERE id = %d;
	]]
	local switchCategoryQuery = [[
	SELECT id 
	FROM forum_categories
	WHERE priority = %d
	LIMIT 1;
	]]
	if ( enum == IGFORUMS_CATEGORYMOVEUP ) then
		if ( currentPriority == 1 ) then return end
		local switchResultSet = sql.Query( string.format( switchCategoryQuery, currentPriority - 1 ) )
		if not ( switchResultSet ) then return end
		sql.Query( string.format( changePriorityQuery, currentPriority, tonumber( switchResultSet[1].id ) ) )
		sql.Query( string.format( changePriorityQuery, currentPriority - 1, categoryID ) )
	elseif ( enum == IGFORUMS_CATEGORYMOVEDOWN ) then
		local maxPriorityQuery = [[
		SELECT MAX( priority ) AS maxPriority FROM forum_categories;
		]]
		local maxPriority = tonumber( sql.Query( maxPriorityQuery )[1].maxPriority )
		if ( currentPriority == maxPriority ) then return end
		local switchResultSet = sql.Query( string.format( switchCategoryQuery, currentPriority + 1 ) )
		if not ( switchResultSet ) then return end
		sql.Query( string.format( changePriorityQuery, currentPriority, tonumber( switchResultSet[1].id ) ) )
		sql.Query( string.format( changePriorityQuery, currentPriority + 1, categoryID ) )
	end
end

///////////////////////////////////////////////////////////////
/// Creates a new category.
function IGForums:CreateCategory( icon, name, desc, priority, activator )
	local categoryQuery = [[
	INSERT INTO forum_categories
	( icon_id, name, desc, priority )
	VALUES( %d, %s, %s, %d );
	]]
	local priorityQuery = [[
	SELECT MAX( priority ) AS lastPriority 
	FROM forum_categories;
	]]
	local lastPriority = ( tonumber( sql.Query( priorityQuery )[1].lastPriority ) or 1 )
	if not ( self:CheckCategorySyntax( icon, name, desc, activator ) ) then return end
	if not ( self:GetIconID( icon ) ) then
		if ( IsValid( activator ) ) then
			activator:SendForumHint( "You've chosen an invalid icon.", 3 )
		end
		return
	end
	local lineCount = #string.Explode( "\n", desc )
	if ( lineCount > 3 ) then
		if ( IsValid( activator ) ) then
			activator:SendForumHint( "The category description can't be more than three lines.", 3 )
		end
		return 
	end
	local iconID = IGForums:GetIconID( icon )
	sql.Query( string.format( categoryQuery, iconID, SQLStr( name ), SQLStr( desc ), lastPriority + 1 ) )
	if ( IsValid( activator ) ) then
		activator:SendForumHint( "You've created the category [ " .. name .. " ].", 3 )
		self:Log( activator:GetNiceInfo( ) .. " has created the category [ " .. name .. " ]." )
	end
end

///////////////////////////////////////////////////////////////
/// Deletes a category by its ID.
function IGForums:DeleteCategory( categoryID, activator )
	local threadQuery = [[
	SELECT id FROM forum_threads
	WHERE category_id = %d;
	]]
	local resultSet = sql.Query( string.format( threadQuery, categoryID ) )
	if ( resultSet ) then
		for index, data in ipairs ( resultSet ) do
			self:DeleteThread( resultSet[1].id )
		end
	end
	local categoryQuery = [[
	DELETE FROM forum_categories
	WHERE id = %d;
	]]
	sql.Query( string.format( categoryQuery, categoryID ) )
	net.Start( "IGForums_CategoryNET" )
		net.WriteUInt( IGFORUMS_DELETECATEGORY, 16 )
		net.WriteUInt( categoryID, 32 )
	net.Broadcast( )
	if ( IsValid( activator ) ) then
		activator:SendForumHint( "You've deleted CategoryID[ " .. categoryID .. " ].", 3 )
		self:Log( activator:GetNiceInfo( ) .. " has deleted CategoryID[ " .. categoryID .. " ]." )
	end
	self:OrganizeCategories( )
end

///////////////////////////////////////////////////////////////
/// Creates a new post
function IGForums:CreatePost( ply, threadID, text )
	if not ( self:ThreadExists( threadID ) ) then ply:SendForumHint( "That thread does not exist.", 3 ) return end
	if ( self:IsIDBanned( ply:GetForumsID( ) ) ) then ply:SendForumHint( "You are currently banned from the Forums.", 3 ) return end
	ply.nextForumPost = ply.nextForumPost or 0
	if not ( ply.nextForumPost < CurTime( ) ) then
		local timeLeft = string.NiceTime( ply.nextForumPost - CurTime( ) )
		ply:SendForumHint( "You cannot post again for another " .. timeLeft .. ".", 3 )
		return
	end
	ply.nextForumPost = CurTime( ) + ForumsConfig.PostCooldown
	if not ( self:CheckPostSyntax( text, ply ) ) then return end
	local threadQuery = [[
	SELECT locked 
	FROM forum_threads
	WHERE id = %d;
	]]
	local threadResultSet = sql.Query( string.format( threadQuery, tonumber( threadID ) ) )
	local isLocked = tobool( tonumber( threadResultSet and threadResultSet[1].locked ) )
	if ( threadResultSet and !isLocked ) then
		local postQuery = [[
		INSERT INTO forum_posts
		( thread_id, user_id, time, text )
		VALUES( %d, %d, %d, %s );
		]]
		sql.Query( string.format( postQuery, threadID, ply:GetForumsID( ), os.time( ), SQLStr( text ) ) )
		self:UpdatePostCountByID( ply:GetForumsID( ), player.GetAll( ) )
		ply:SendForumHint( "You've made a post within ThreadID[ " .. threadID .. " ].", 3 )
	else
		ply:SendForumHint( "You cannot post in locked threads.", 3 )
	end
end

///////////////////////////////////////////////////////////////
/// Deletes a post by its ID
function IGForums:DeletePost( postID, activator )
	local postQuery = [[
	SELECT user_id 
	FROM forum_posts
	WHERE id = %d;
	]]
	local resultSet = sql.Query( string.format( postQuery, postID ) )
	if not ( resultSet ) then return end
	local postDeleteQuery = [[
	DELETE FROM forum_posts
	WHERE id = %d;
	]]
	sql.Query( string.format( postDeleteQuery, postID ) )
	net.Start( "IGForums_ThreadNET" )
		net.WriteUInt( IGFORUMS_DELETEPOSTBYID, 16 )
		net.WriteUInt( postID, 32 )
	net.Broadcast( )
	self:UpdatePostCountByID( resultSet[1].user_id, player.GetAll( ) )
	if ( IsValid( activator ) ) then
		activator:SendForumHint( "You've deleted PostID[ " .. postID .. " ].", 3 )
		self:Log( activator:GetNiceInfo( ) .. " has deleted PostID[ " .. postID .. " ]." )
	end
end

///////////////////////////////////////////////////////////////
/// Deletes multiple posts that match the userID
function IGForums:DeletePostsByID( id, activator )
	local postQuery = [[
	DELETE FROM forum_posts
	WHERE user_id = %d;
	]]
	sql.Query( string.format( postQuery, id ) )
	net.Start( "IGForums_ThreadNET" )
		net.WriteUInt( IGFORUMS_DELETEPOSTSBYID, 16 )
		net.WriteUInt( id, 32 )
	net.Broadcast( )
	if ( IsValid( activator ) ) then
		activator:SendForumHint( "You've deleted all of UserID[ " .. id .. " ]'s posts.", 3 )
		self:Log( activator:GetNiceInfo( ) .. " has deleted all of UserID[ " .. id .. " ]'s posts." )
	end
	self:UpdatePostCountByID( id, player.GetAll( ) )
	local threadQuery = [[
	SELECT id 
	FROM forum_threads
	WHERE user_id = %d;
	]]
	local resultSet = sql.Query( string.format( threadQuery, id ) )
	if not ( resultSet ) then return end
	local postQueryTwo = [[
	DELETE FROM forum_posts
	WHERE thread_id = %d;
	]]
	for index, data in ipairs ( resultSet ) do
		sql.Query( string.format( postQueryTwo, tonumber( data.id ) ) )
		net.Start( "IGForums_ThreadNET" )
			net.WriteUInt( IGFORUMS_DELETETHREADSBYID, 16 )
			net.WriteUInt( data.id, 32 )
		net.Broadcast( )
	end
	local threadQueryTwo = [[
	DELETE FROM forum_threads
	WHERE user_id = %d;
	]]
	sql.Query( string.format( threadQueryTwo, id ) )
end

///////////////////////////////////////////////////////////////
/// Updates the player's post count for the client.
function IGForums:UpdatePostCountByID( id, ply )
	local postCount = 0
	local postQuery = [[
	SELECT COUNT( id ) AS amount 
	FROM forum_posts
	WHERE user_id = %d;
	]]
	local resultSet = sql.Query( string.format( postQuery, id ) )
	if ( resultSet ) then postCount = tonumber( resultSet[1].amount ) end
	net.Start( "IGForums_UserNET" )
		net.WriteUInt( IGFORUMS_UPDATEPOSTCOUNT, 16 )
		net.WriteUInt( id, 32 )
		net.WriteUInt( postCount, 32 )
	net.Send( ply )
end

///////////////////////////////////////////////////////////////
/// Creates a new thread.
function IGForums:CreateThread( ply, categoryID, icon, name, text, locked, sticky )
	if not ( self:CategoryExists( categoryID ) ) then ply:SendForumHint( "That category does not exist.", 3 ) return end
	if ( self:IsIDBanned( ply:GetForumsID( ) ) ) then ply:SendForumHint( "You are currently banned from the Forums.", 3 ) return end
	ply.nextForumPost = ply.nextForumPost or 0
	if not ( ply.nextForumPost < CurTime( ) ) then
		local timeLeft = string.NiceTime( ply.nextForumPost - CurTime( ) )
		ply:SendForumHint( "You cannot post again for another " .. timeLeft .. ".", 3 )
		return
	end
	ply.nextForumPost = CurTime( ) + ForumsConfig.PostCooldown
	if not ( self:CheckThreadSyntax( icon, name, text, ply ) ) then return end
	if not ( self:GetIconID( icon ) ) then
		if ( IsValid( activator ) ) then
			activator:SendForumHint( "You've chosen an invalid icon.", 3 )
		end
		return
	end
	local threadQuery = [[
	INSERT INTO forum_threads
	( category_id, user_id, icon_id, time, name, text, locked, sticky )
	VALUES( %d, %d, %d, %d, %s, %s, %d, %d );
	]]
	local iconID = IGForums:GetIconID( icon )
	local isLocked = locked and 1 or 0
	local isStickied = sticky and 1 or 0
	local forumID = ply:GetForumsID( )
	if ( forumID == -1 ) then 
		ply:SendForumHint( "Internal error occured, could not obtain UserID, contact a developer.", 3 )
		return 
	end
	ply:SendForumHint( "You've created a thread inside CategoryID[ " .. categoryID .. " ].", 3 )
	sql.Query( string.format( threadQuery, categoryID, forumID, iconID, os.time( ), SQLStr( name ), SQLStr( text ), isLocked, isStickied ) )
end

///////////////////////////////////////////////////////////////
/// Deletes a thread by its ID.
function IGForums:DeleteThread( threadID, activator )
	local threadQuery = [[
	SELECT user_id 
	FROM forum_threads
	WHERE id = %d;
	]]
	local resultSet = sql.Query( string.format( threadQuery, threadID ) )
	if not ( resultSet ) then return end
	local postQuery = [[
	SELECT id 
	FROM forum_posts
	WHERE thread_id = %d;
	]]
	local postResultSet = sql.Query( string.format( postQuery, threadID ) )
	if ( postResultSet ) then
		for index, data in ipairs ( postResultSet ) do
			self:DeletePost( data.id )
		end
	end
	local threadDeleteQuery = [[
	DELETE FROM forum_threads
	WHERE id = %d;
	]]
	sql.Query( string.format( threadDeleteQuery, threadID ) )
	net.Start( "IGForums_ThreadNET" )
		net.WriteUInt( IGFORUMS_DELETETHREADBYID, 16 )
		net.WriteUInt( threadID, 32 )
	net.Broadcast( )
	if ( IsValid( activator ) ) then
		activator:SendForumHint( "You've deleted ThreadID[ " .. threadID .. " ].", 3 )
		self:Log( activator:GetNiceInfo( ) .. " has deleted ThreadID[ " .. threadID .. " ]" )
	end
end

///////////////////////////////////////////////////////////////
/// Set a user's rank by their ID.
function IGForums:SetRankByID( userID, rank, activator )
	local foundRank = false
	for rankIndex, tbl in pairs ( ForumsConfig.Ranks ) do
		if ( string.lower( rank ) == string.lower( rankIndex ) ) then
			foundRank = true
		end
	end
	if not ( foundRank ) then
		if ( IsValid( activator ) ) then
			activator:SendForumHint( "The rank you specified is invalid.", 3 )
		end
		return 
	end
	local setRankQuery = [[
	UPDATE forum_users
	SET rank = %s
	WHERE user_id = %d;
	]]
	sql.Query( string.format( setRankQuery, SQLStr( rank ), userID ) )
	self:BroadcastUserUpdate( IGFORUMS_UPDATERANK, userID, rank )
	if ( IsValid( activator ) ) then
		activator:SendForumHint( "You've set the rank of UserID[ " .. userID .. " ] to " .. rank .. ".", 3 )
		self:Log( activator:GetNiceInfo( ) .. " has set UserID[ " .. userID .. " ]'s rank to " .. rank .. "." )
	end
end

///////////////////////////////////////////////////////////////
/// Loops through the categories updating the priority to
/// start from one and not repeat.
function IGForums:OrganizeCategories( )
	local categoryQuery = [[
	SELECT * 
	FROM forum_categories;
	]]
	local resultSet = sql.Query( categoryQuery )
	if not ( resultSet ) then return end
	table.SortByMember( resultSet, "priority", true )
	local categoryTable = { }
	local updateQuery = [[
	UPDATE forum_categories
	SET priority = %d
	WHERE id = %d;
	]]
	for index, data in ipairs( resultSet ) do
		sql.Query( string.format( updateQuery, index, data.id ) )
	end
end

///////////////////////////////////////////////////////////////
/// Gets a user's rank by their ID.
function IGForums:GetRankByID( userID )
	local userRank = "user"
	local userRankQuery = [[
	SELECT rank 
	FROM forum_users
	WHERE user_id = %d;
	]]
	local resultSet = sql.Query( string.format( userRankQuery, userID ) )
	if ( resultSet ) then userRank = resultSet[1].rank end
	return userRank
end

///////////////////////////////////////////////////////////////
/// Simple version checker
function IGForums:CheckVersion( )
	http.Fetch( "http://www.jeezy.rocks/gmod/igforums_version.php?VersionNumber=" .. IGForumsVersion,
	function( body, len, headers, code )
		if ( string.find( body, "out of date" ) ) then
			MsgC( Color( 175, 45, 45 ), "--------WARNING--------\n")
			MsgC( Color( 175, 45, 45 ), "-----------------------\n")
			MsgC( Color( 150, 160, 255 ), "[In-Game Forums] :: ", Color( 175, 125, 125 ), body, "\n" )
			MsgC( Color( 175, 45, 45 ), "-----------------------\n")
		else
			MsgC( Color( 45, 175, 45 ), "-----------------------\n")
			MsgC( Color( 45, 175, 45 ), "-----------------------\n")
			MsgC( Color( 150, 160, 255 ), "[In-Game Forums] :: ", Color( 125, 175, 125 ), body, "\n" )
			MsgC( Color( 45, 175, 45 ), "-----------------------\n")
		end
	end )
end

///////////////////////////////////////////////////////////////
/// Logging to track the action's of admins and moderators
if not ( file.IsDir( "ingame_forums", "DATA" ) ) then file.CreateDir( "ingame_forums" ) end
if not ( file.IsDir( "ingame_forums/logs", "DATA" ) ) then file.CreateDir( "ingame_forums/logs" ) end
local logDirectory = "ingame_forums/logs/"
function IGForums:Log( message )
	local fileName = os.date( "%b%d_%y.txt" )
	local timeString = os.date( "[%a %b %d %I:%M%p] " )
	if not ( file.Exists( logDirectory .. fileName, "DATA" ) ) then
		file.Write( logDirectory .. fileName, timeString .. message .. "\n" )
	else
		file.Append( logDirectory .. fileName, timeString .. message .. "\n" )
	end
end