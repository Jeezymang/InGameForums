IGForumsVersion = 0.3

util.AddNetworkString( "IGForums_ForumsNET" )
util.AddNetworkString( "IGForums_ThreadNET" )
util.AddNetworkString( "IGForums_CategoryNET" )
util.AddNetworkString( "IGForums_UserNET" )
util.AddNetworkString( "IGForums_IconNET" )

///////////////////////////////////////////////////////////////
/// Initialization of the addon, creates the tables, and adds
/// all icons inside of materials/vgui/ingame_forums_icons/
hook.Add( "Initialize", "IGForums_Initialize", function( )
	local usersTableQuery = [[
	CREATE TABLE IF NOT EXISTS forum_users (
	`user_id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	`steam64` UNSIGNED BIG INT NOT NULL,
	`name` VARCHAR(255),
	`rank` VARCHAR(32),
	`banned` BOOL,
	UNIQUE(`user_id`,`steam64`) );
	]]
	local categoriesTableQuery = [[
	CREATE TABLE IF NOT EXISTS forum_categories (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	`icon_id` INT,
	`name` VARCHAR(255),
	`desc` VARCHAR(255),
	`priority` INT );
	]]
	local threadsTableQuery = [[
	CREATE TABLE IF NOT EXISTS forum_threads (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	`category_id` INTEGER NOT NULL,
	`user_id` INTEGER NOT NULL,
	`icon_id` INT,
	`time` BIGINT,
	`name` VARCHAR(255),
	`text` TEXT,
	`locked` BOOL,
	`sticky` BOOL );
	]]
	local postsTableQuery = [[
	CREATE TABLE IF NOT EXISTS forum_posts (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	`thread_id` INTEGER NOT NULL,
	`user_id` INTEGER NOT NULL,
	`time` BIGINT,
	`text` TEXT );
	]]
	local iconsTableQuery = [[
	CREATE TABLE IF NOT EXISTS forum_icons (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	`path` VARCHAR(255) );
	]]
	sql.Query( usersTableQuery )
	sql.Query( categoriesTableQuery )
	sql.Query( threadsTableQuery )
	sql.Query( postsTableQuery )
	sql.Query( iconsTableQuery )
	local iconPath = "vgui/ingame_forums/icons/"
	local icons, _ = file.Find( "materials/" .. iconPath .. "*", "GAME" )
	for index, icon in ipairs( icons ) do
		if not ( IGForums:GetIconID( iconPath .. icon ) ) then
			local iconQuery = [[
			INSERT INTO forum_icons
			( path )
			VALUES( %s );
			]]
			sql.Query( string.format( iconQuery, SQLStr( iconPath .. icon ) ) )
		end
	end
	IGForums:CheckVersion( )
	IGForums:OrganizeCategories( )
end )

///////////////////////////////////////////////////////////////
/// Player authentication, if they're not in the database it 
/// adds them, and then networks it to all online players.
hook.Add( "PlayerAuthed", "IGForums_PlayerAuth", function( ply, steamID, uniqueid )
	local playerQuery = [[
	INSERT INTO forum_users
	( steam64, name, rank, banned )
	VALUES( %s, %s, %s, %d );
	]]
	local playerExistsQuery = [[
	SELECT * 
	FROM forum_users
	WHERE steam64 = %s;
	]]
	local rank = "user"
	if ( ply:IsAdmin( ) ) then rank = "admin" end
	local resultSet = sql.Query( string.format( playerExistsQuery, util.SteamIDTo64( steamID ) ) )
	if ( resultSet ) then
		local updateQuery = [[
		UPDATE forum_users
		SET name = %s
		WHERE user_id = %d;
		]]
		if ( resultSet[1].name ~= ply:Nick( ) ) then
			sql.Query( string.format( updateQuery, SQLStr( string.Replace( ply:Nick( ), [[\n]], "" ) ), tonumber( resultSet[1].user_id ) ) )
		end
	else
		sql.Query( string.format( playerQuery, util.SteamIDTo64( steamID ), SQLStr( ply:Nick( ) ), SQLStr( rank ), 0 ) )
	end
	for index, plr in ipairs ( player.GetAll( ) ) do
		plr:NetworkUsers( )
	end
end )

///////////////////////////////////////////////////////////////
/// Chat command to bring up the forums viewer.
hook.Add( "PlayerSay", "IGForums_PlayerSay", function( ply, text, team )
	local chatCommand = ForumsConfig.ChatCommand or "!forums"
	local cmdLength = string.len( chatCommand )
	if ( string.lower( string.sub( text, 1, cmdLength ) ) == string.lower( chatCommand ) ) then
		ply:OpenForumViewer( )
	end
end )

///////////////////////////////////////////////////////////////
/// Icon Resources for FastDL, should be disabled if using 
/// workshop version.
local iconPath = "materials/vgui/ingame_forums/icons/"
local icons, _ = file.Find( iconPath .. "*", "GAME" )
for index, icon in ipairs( icons ) do
	resource.AddFile( iconPath .. icon )
end