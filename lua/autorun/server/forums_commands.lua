///////////////////////////////////////////////////////////////
/// Pulls a random icon from the database, this function
/// assumes there are icons in there currently.
/// Might add it to the IGForums table later.
local function GetRandomIcon( )
	local randomIconQuery = [[
	SELECT id
	FROM forum_icons
	ORDER BY RANDOM()
	LIMIT 1;
	]]
	return ( sql.Query( randomIconQuery )[1].id )
end

///////////////////////////////////////////////////////////////
/// Determines whether any icons exist.
local function DoIconsExist( )
	local iconQuery = [[
	SELECT COUNT( id ) AS amount
	FROM forum_icons;
	]]
	local resultSet = sql.Query( iconQuery )
	if ( !resultSet or tonumber( resultSet[1].amount ) == 0 ) then return false, 0 end
	return true, resultSet[1].amount
end

///////////////////////////////////////////////////////////////
/// Used for removing an icon from the database, clients will
/// need to reconnect to get new icons table for now.
/// The icon will be added back unless you remove it from
/// your server directory or disable the code that adds it back.
concommand.Add( "igforums_removeicon", function( ply, cmd, args, fstring )
	if not ( ply:IsSuperAdmin( ) ) then ply:ChatPrint( "Only super admins can run this command." ) return end
	if ( !args or !args[1] ) then ply:ChatPrint( "You must enter a path to the icon." ) return end
	if not ( DoIconsExist( ) ) then ply:ChatPrint( "No icons currently exist in the database." ) return end
	local iconQuery = [[
	SELECT id 
	FROM forum_icons
	WHERE path = %s;
	]]
	local resultSet = sql.Query( string.format( iconQuery, SQLStr( args[1] ) ) )
	if not ( resultSet ) then ply:ChatPrint( "The icon [ " .. args[1] .. " ] does not exist in the database." ) return end
	local iconID = resultSet[1].id
	local removeIconQuery = [[
	DELETE FROM forum_icons
	WHERE id = %d;
	]]
	sql.Query( string.format( removeIconQuery, tonumber( iconID ) ) )
	ply:ChatPrint( "You removed icon ( " .. iconID .. " ) [ " .. args[1] .. " ] from the database." )
end )

///////////////////////////////////////////////////////////////
/// Removes all icons from the database, players will need to
/// reconnect to get the new icons table for now.
/// Warning: Doing this on a live server will result in players
/// not being able to post due to using an invalid icon.
/// The icons will be added back unless you remove them from
/// your server directory.
concommand.Add( "igforums_purgeicons", function( ply, cmd, args, fstring )
	if not ( ply:IsSuperAdmin( ) ) then ply:ChatPrint( "Only super admins can run this command." ) return end
	local iconsExist, iconCount = DoIconsExist( )
	if not ( iconsExist ) then ply:ChatPrint( "There are currently no icons in the database." ) return end
	local deleteIconsQuery = [[
	DELETE FROM forum_icons;
	]]
	sql.Query( deleteIconsQuery )
	ply:ChatPrint( "You have deleted " .. string.Comma( tonumber( iconCount ) ) .. " icons from the database." )
end )

///////////////////////////////////////////////////////////////
/// Finds all invalid category icons and sets them to a random
/// one within the database.
concommand.Add( "igforums_fixcategoryicons", function( ply, cmd, args, fstring )
	if not ( ply:IsSuperAdmin( ) ) then ply:ChatPrint( "Only super admins can run this command." ) return end
	local iconsExist, iconCount = DoIconsExist( )
	if not ( iconsExist ) then ply:ChatPrint( "There are currently no icons in the database." ) return end

	local categoryQuery = [[
	SELECT id, icon_id
	FROM forum_categories;
	]]
	local resultSet = sql.Query( categoryQuery )
	if ( !resultSet ) then ply:ChatPrint( "There currently are no categories." ) return end

	local iconQuery = [[
	SELECT id
	FROM forum_icons
	WHERE id = %d;
	]]
	local updateCategoryQuery = [[
	UPDATE forum_categories
	SET icon_id = %d
	WHERE id = %d;
	]]
	local fixedCategories = 0
	for index, data in ipairs ( resultSet ) do
		local iconResultSet = sql.Query( string.format( iconQuery, tonumber( data.icon_id ) ) )
		if not ( iconResultSet ) then
			local randomIcon = GetRandomIcon( )
			sql.Query( string.format( updateCategoryQuery, tonumber( randomIcon ), tonumber( data.id ) ) )
			fixedCategories = fixedCategories + 1
		end
	end
	ply:ChatPrint( "Fixed the icons for " .. string.Comma( fixedCategories ) .. " categories." )
end )

///////////////////////////////////////////////////////////////
/// Finds all invalid thread icons and sets them to a random
/// one in the database.
concommand.Add( "igforums_fixthreadicons", function( ply, cmd, args, fstring )
	if not ( ply:IsSuperAdmin( ) ) then ply:ChatPrint( "Only super admins can run this command." ) return end
	local iconsExist, iconCount = DoIconsExist( )
	if not ( iconsExist ) then ply:ChatPrint( "There are currently no icons in the database." ) return end

	local threadQuery = [[
	SELECT id, icon_id
	FROM forum_threads;
	]]
	local resultSet = sql.Query( threadQuery )
	if ( !resultSet ) then ply:ChatPrint( "There currently are no threads." ) return end

	local iconQuery = [[
	SELECT id
	FROM forum_icons
	WHERE id = %d;
	]]
	local updateThreadQuery = [[
	UPDATE forum_threads
	SET icon_id = %d
	WHERE id = %d;
	]]
	local fixedThreads = 0
	for index, data in ipairs ( resultSet ) do
		local iconResultSet = sql.Query( string.format( iconQuery, tonumber( data.icon_id ) ) )
		if not ( iconResultSet ) then
			local randomIcon = GetRandomIcon( )
			sql.Query( string.format( updateThreadQuery, tonumber( randomIcon ), tonumber( data.id ) ) )
			fixedThreads = fixedThreads + 1
		end
	end
	ply:ChatPrint( "Fixed the icons for " .. string.Comma( fixedThreads ) .. " threads." )
end )

concommand.Add( "openforums", function( ply, cmd, args, fstring )
	ply:OpenForumViewer( )
end )