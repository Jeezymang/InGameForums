local meta = FindMetaTable( "Player" )

///////////////////////////////////////////////////////////////
/// Opens the forum viewer.
function meta:OpenForumViewer( )
	net.Start( "IGForums_ForumsNET" )
		net.WriteUInt( IGFORUMS_OPENFORUMS, 16 )
	net.Send( self )
	self:NetworkCategories( )
end

///////////////////////////////////////////////////////////////
/// Sends a hint to the client's forum viewer which displays
/// at the top. 
function meta:SendForumHint( message, length )
	net.Start( "IGForums_ForumsNET" )
		net.WriteUInt( IGFORUMS_SENDMESSAGE, 16 )
		net.WriteString( message )
		net.WriteUInt( length, 16 )
	net.Send( self )
end

///////////////////////////////////////////////////////////////
/// Forces the client to refresh/request the category or
/// thread that they're in.
function meta:RefreshForumViewer( )
	net.Start( "IGForums_ForumsNET" )
		net.WriteUInt( IGFORUMS_REFRESHVIEWER, 16 )
	net.Send( self )
end

///////////////////////////////////////////////////////////////
/// Checks if a player meets the rank requirement, this can be
/// configured inside the config file.
function meta:HasForumPermissions( enum, sendError )
	local userRank = self:GetForumsRank( )
	local canAccess = false
	if ( ForumsConfig.RankPermissions[ enum ] ) then
		canAccess = ( ForumsConfig.RankPermissions[ enum ][userRank] )
	end
	if ( canAccess ) then
		return true
	else
		if ( sendError ) then
			self:SendForumHint( "You lack the permissions for that action.", 3 )
		end
		return false
	end
end

///////////////////////////////////////////////////////////////
/// Sets the player's rank.
function meta:SetForumsRank( rank )
	local foundRank = false
	for rankIndex, tbl in pairs ( ForumsConfig.Ranks ) do
		if ( string.lower( rank ) == string.lower( rankIndex ) ) then
			foundRank = true
		end
	end
	if not ( foundRank ) then return end
	local setRankQuery = [[
	UPDATE forum_users
	SET rank = %s
	WHERE user_id = %d;
	]]
	sql.Query( string.format( setRankQuery, SQLStr( rank ), self:GetForumsID( ) ) )
	self:BroadcastRankUpdate( self:GetForumsID( ), rank )
end

///////////////////////////////////////////////////////////////
/// Gets the player's rank.
function meta:GetForumsRank( )
	local userRank = "user"
	local userRankQuery = [[
	SELECT rank 
	FROM forum_users
	WHERE user_id = %d;
	]]
	local resultSet = sql.Query( string.format( userRankQuery, self:GetForumsID( ) ) )
	if ( resultSet ) then userRank = resultSet[1].rank end
	return userRank
end

///////////////////////////////////////////////////////////////
/// Gets the player's UserID, if it fails it returns -1.
function meta:GetForumsID( )
	local idQuery = [[
	SELECT user_id 
	FROM forum_users
	WHERE steam64 = %s;
	]]
	local id = self.forumsID
	if ( !id or id == -1 ) then
		local resultSet = sql.Query( string.format( idQuery, self:SteamID64( ) ) )
		id = resultSet and resultSet[1].user_id
		if not ( id ) then id = -1 end
		self.forumsID = id
	end
	return id
end

///////////////////////////////////////////////////////////////
/// Updates specific elements of the users, used to avoid
/// networking all of the user's data over when not necessary
function meta:UpdatePlayerInfo( id, enum, value )
	if ( enum == IGFORUMS_UPDATEPOSTCOUNT ) then
		net.Start( "IGForums_UserNET" )
			net.WriteUInt( enum, 16 )
			net.WriteUInt( id, 32 )
			net.WriteUInt( value, 32 )
		net.Send( self )
	elseif ( enum == IGFORUMS_UPDATENAME ) then
		net.Start( "IGForums_UserNET" )
			net.WriteUInt( enum, 16 )
			net.WriteUInt( id, 32 )
			net.WriteString( value )
		net.Send( self )
	elseif ( enum == IGFORUMS_UPDATERANK ) then
		net.Start( "IGForums_UserNET" )
			net.WriteUInt( enum, 16 )
			net.WriteUInt( id, 32 )
			net.WriteString( value )
		net.Send( self )
	elseif ( enum == IGFORUMS_UPDATEBAN ) then
		net.Start( "IGForums_UserNET" )
			net.WriteUInt( enum, 16 )
			net.WriteUInt( id, 32 )
			net.WriteBit( value )
		net.Send( self )
	end
end

///////////////////////////////////////////////////////////////
/// Networks all categories to the client
function meta:NetworkCategories( )
	local categoriesQuery = [[
	SELECT * 
	FROM forum_categories;
	]]
	local resultSet = sql.Query( categoriesQuery )
	if not ( resultSet ) then return end
	for index, data in ipairs ( resultSet ) do
		self:NetworkCategory( data )
	end
end

///////////////////////////////////////////////////////////////
/// Used by PLAYER:NetworkCategories
function meta:NetworkCategory( categoryTbl )
	net.Start( "IGForums_CategoryNET" )
		net.WriteUInt( IGFORUMS_SENDCATEGORY, 16 )
		net.WriteUInt( categoryTbl.id, 32 )
		net.WriteUInt( categoryTbl.icon_id, 32 )
		net.WriteString( categoryTbl.name )
		net.WriteString( categoryTbl.desc )
		net.WriteUInt( categoryTbl.priority, 32 )
	net.Send( self )
end

///////////////////////////////////////////////////////////////
/// Networks all the threads within a specific category 
/// to the client.
function meta:NetworkThreads( categoryID, page )
	local threadCountQuery = [[
	SELECT COUNT( id ) AS amount 
	FROM forum_threads
	WHERE category_id = %d;
	]]
	local threadCountResultSet = sql.Query( string.format( threadCountQuery, tonumber( categoryID ) ) )
	if not ( threadCountResultSet ) then return end
	local threadCount = tonumber( threadCountResultSet[1].amount )
	local pageAmount = math.ceil( threadCount / ForumsConfig.ThreadsPerPage )
	net.Start( "IGForums_CategoryNET" )
		net.WriteUInt( IGFORUMS_SENDPAGEAMOUNT, 16 )
		net.WriteUInt( categoryID, 32 )
		net.WriteUInt( pageAmount, 16 )
	net.Send( self )
	local categoryQuery
	if ( pageAmount > 1 ) then
		local pageOffset = ( page - 1 ) * ForumsConfig.ThreadsPerPage
		categoryQuery = [[
		SELECT id, user_id, icon_id, time, name, text, locked, sticky 
		FROM forum_threads
		WHERE category_id = %d
		ORDER BY time DESC
		LIMIT ]] .. pageOffset .. ", " .. ForumsConfig.ThreadsPerPage .. ";"
	else
		categoryQuery = [[
		SELECT id, user_id, icon_id, time, name, text, locked, sticky 
		FROM forum_threads
		WHERE category_id = %d; 
		]]
	end
	local resultSet = sql.Query( string.format( categoryQuery, categoryID ) )
	if not ( resultSet ) then return end
	local postQuery = [[
	SELECT COUNT( id ) AS amount 
	FROM forum_posts
	WHERE thread_id = %d;
	]]
	local lastPostQuery = [[
	SELECT MAX( time ) AS lastPost 
	FROM forum_posts
	WHERE thread_id = %d;
	]]
	for index, data in ipairs ( resultSet ) do
		local lastPost = data.time
		local postCount = 0
		local countResultSet = sql.Query( string.format( postQuery, tonumber( data.id ) ) )
		if ( countResultSet ) then postCount = tonumber( countResultSet[1].amount ) end
		local lastPostResultSet = sql.Query( string.format( lastPostQuery, tonumber( data.id ) ) )
		if ( lastPostResultSet ) then lastPost = ( tonumber( lastPostResultSet[1].lastPost ) or data.time ) end
		net.Start( "IGForums_CategoryNET" )
			net.WriteUInt( IGFORUMS_SENDTHREAD, 16 )
			net.WriteUInt( categoryID, 32 )
			net.WriteUInt( data.id, 32 )
			net.WriteUInt( data.user_id, 32 )
			net.WriteUInt( data.icon_id, 32 )
			net.WriteUInt( data.time, 32 )
			net.WriteUInt( lastPost, 32 )
			net.WriteUInt( postCount, 32 )
			net.WriteString( data.name )
			net.WriteString( data.text )
			net.WriteBit( tobool( data.locked ) )
			net.WriteBit( tobool( data.sticky ) )
		net.Send( self )
	end
end

///////////////////////////////////////////////////////////////
/// Networks all the posts within a specific thread
/// to the client
function meta:NetworkPosts( threadID, page )
	local postCountQuery = [[
	SELECT COUNT( id ) AS amount 
	FROM forum_posts
	WHERE thread_id = %d;
	]]
	local postCountResultSet = sql.Query( string.format( postCountQuery, tonumber( threadID ) ) )
	if not ( postCountResultSet ) then return end
	local postCount = tonumber( postCountResultSet[1].amount )
	local pageAmount = math.ceil( postCount / ForumsConfig.PostsPerPage )
	local threadQuery
	if ( pageAmount > 1 ) then
		local pageOffset = ( page - 1 ) * ForumsConfig.PostsPerPage
		threadQuery = [[
		SELECT id, user_id, time, text 
		FROM forum_posts
		WHERE thread_id = %d
		ORDER BY time DESC
		LIMIT ]] .. pageOffset .. ", " .. ForumsConfig.PostsPerPage .. ";"
	else
		threadQuery = [[
		SELECT id, user_id, time, text FROM forum_posts
		WHERE thread_id = %d;
		]]
	end
	local categoryQuery = [[
	SELECT category_id 
	FROM forum_threads
	WHERE id = %d;
	]]
	local resultSet = sql.Query( string.format( threadQuery, tonumber( threadID ) ) )
	local countedPosts = { }
	local threadCategory = sql.Query( string.format( categoryQuery, threadID ) )
	if not ( threadCategory ) then return end
	threadCategory = threadCategory[1].category_id
	net.Start( "IGForums_ThreadNET" )
		net.WriteUInt( IGFORUMS_SENDPAGEAMOUNT, 16 )
		net.WriteUInt( threadID, 32 )
		net.WriteUInt( threadCategory, 32 )
		net.WriteUInt( pageAmount, 16 )
	net.Send( self )
	for index, data in ipairs ( resultSet or { } ) do
		net.Start( "IGForums_ThreadNET" )
			net.WriteUInt( IGFORUMS_SENDTHREAD, 16 )
			net.WriteUInt( threadCategory, 32 )
			net.WriteUInt( threadID, 32 )
			net.WriteUInt( data.id, 32 )
			net.WriteUInt( data.user_id, 32 )
			net.WriteUInt( data.time, 32 )
			net.WriteString( data.text )
		net.Send( self )
	end
end

///////////////////////////////////////////////////////////////
/// Networks all the icons to the client.
function meta:NetworkIcons( )
	local iconQuery = [[
	SELECT * 
	FROM forum_icons;
	]]
	local resultSet = sql.Query( iconQuery )
	if not ( resultSet ) then return end
	for index, data in ipairs ( resultSet ) do
		net.Start( "IGForums_IconNET" )
			net.WriteUInt( data.id, 32 )
			net.WriteString( data.path )
		net.Send( self )
	end
end

///////////////////////////////////////////////////////////////
/// Networks all the users to othe client, argument for
/// updating the post count is optional.
function meta:NetworkUsers( updatePostCount )
	local userQuery = [[
	SELECT * 
	FROM forum_users;
	]]
	local resultSet = sql.Query( userQuery )
	if not ( resultSet ) then return end
	for index, data in ipairs( resultSet ) do
		net.Start( "IGForums_UserNET" )
			net.WriteUInt( IGFORUMS_INSERTUSER, 16 )
			net.WriteUInt( data.user_id, 32 )
			net.WriteString( data.steam64 )
			net.WriteString( data.name )
			net.WriteString( data.rank )
			net.WriteBit( tobool( tonumber( data.banned ) ) )
		net.Send( self )
		IGForums:UpdatePostCountByID( data.user_id, self )
	end
end

///////////////////////////////////////////////////////////////
/// Used as a helper function when logging
function meta:GetNiceInfo( )
	local forumsID = self:GetForumsID( )
	local steamID = self:SteamID( )
	local name = self:Nick( )
	return ( "[" .. forumsID .. "]-[" .. steamID .. "]-[" .. name .. "]" )
end