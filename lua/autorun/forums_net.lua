///////////////////////////////////////////////////////////////
/// Receives net messages for manipulating users.
net.Receive( "IGForums_UserNET", function( len, ply )
	local mesType = net.ReadUInt( 16 )
	if ( mesType == IGFORUMS_SETRANK ) then
		local userID = net.ReadUInt( 32 )
		local rank = net.ReadString( )
		local plyRank = ply:GetForumsRank( )
		if not ( ply:HasForumPermissions( IGFORUMS_ADMINPERMISSIONS, true ) ) then return end
		IGForums:SetRankByID( userID, rank, ply )
	elseif ( mesType == IGFORUMS_BANUSER ) then
		local userID = net.ReadUInt( 32 )
		local plyRank = ply:GetForumsRank( )
		if not ( ply:HasForumPermissions( IGFORUMS_MODERATORPERMISSIONS, true ) ) then return end
		IGForums:BanUserByID( userID, ply )
	elseif ( mesType == IGFORUMS_UNBANUSER ) then
		local userID = net.ReadUInt( 32 )
		local plyRank = ply:GetForumsRank( )
		if not ( ply:HasForumPermissions( IGFORUMS_MODERATORPERMISSIONS, true ) ) then return end
		IGForums:UnBanUserByID( userID, ply )
	end
end )

///////////////////////////////////////////////////////////////
/// Receives general net messages related to the addon.
net.Receive( "IGForums_ForumsNET", function( len, ply )
	local mesType = net.ReadUInt( 16 )
	if ( mesType == IGFORUMS_REQUESTICONS ) then
		if not ( ply.requestedForumIcons ) then
			ply:NetworkIcons( )
			ply.requestedForumIcons = true
		end
	elseif ( mesType == IGFORUMS_REQUESTUSERS ) then
		if not ( ply.requestedForumUsers ) then
			ply:NetworkUsers( true )
			ply.requestedForumUsers = true
		end
	end
end )

///////////////////////////////////////////////////////////////
/// Receives net messages for manipulatiing categories.
net.Receive( "IGForums_CategoryNET", function( len, ply )
	local mesType = net.ReadUInt( 16 )
	if ( mesType == IGFORUMS_CREATECATEGORY ) then
		local userQuery = [[
		SELECT rank FROM forum_users
		WHERE user_id = %d;
		]]
		local resultSet = sql.Query( string.format( userQuery, ply:GetForumsID( ) ) )
		if not ( resultSet ) then return end
		if not ( ply:HasForumPermissions( IGFORUMS_ADMINPERMISSIONS, true ) ) then return end
		local title = net.ReadString( )
		local desc = net.ReadString( )
		local icon = net.ReadString( )
		IGForums:CreateCategory( icon, title, desc, 0, ply )
		IGForums:UpdateAllForumViewers( )
	elseif ( mesType == IGFORUMS_REQUESTCATEGORY ) then
		local categoryID = net.ReadUInt( 32 )
		local pageNumber = net.ReadUInt( 16 )
		ply:NetworkThreads( categoryID, pageNumber )
	elseif ( mesType == IGFORUMS_REQUESTCATEGORIES ) then
		ply:NetworkCategories( )
	elseif ( mesType == IGFORUMS_DELETECATEGORY ) then
		local categoryID = net.ReadUInt( 32 )
		if not ( ply:HasForumPermissions( IGFORUMS_ADMINPERMISSIONS, true ) ) then return end
		IGForums:DeleteCategory( categoryID, ply )
		IGForums:UpdateAllForumViewers( )
	elseif ( mesType == IGFORUMS_CATEGORYMOVEUP ) then
		local categoryID = net.ReadUInt( 32 )
		if not ( ply:HasForumPermissions( IGFORUMS_ADMINPERMISSIONS, true ) ) then return end
		IGForums:MoveCategory( categoryID, mesType )
		IGForums:UpdateAllForumViewers( )
	elseif ( mesType == IGFORUMS_CATEGORYMOVEDOWN ) then
		local categoryID = net.ReadUInt( 32 )
		if not ( ply:HasForumPermissions( IGFORUMS_ADMINPERMISSIONS, true ) ) then return end
		IGForums:MoveCategory( categoryID, mesType )
		IGForums:UpdateAllForumViewers( )
	end
end )

///////////////////////////////////////////////////////////////
/// Receives net messages for manipulating threads.
net.Receive( "IGForums_ThreadNET", function( len, ply )
	local mesType = net.ReadUInt( 16 )
	if ( mesType == IGFORUMS_CREATETHREAD ) then
		local categoryID = net.ReadUInt( 32 )
		local title = net.ReadString( )
		local content = net.ReadString( )
		local icon = net.ReadString( )
		local isLocked = tobool( net.ReadBit( ) )
		local isStickied = tobool( net.ReadBit( ) )
		if ( isLocked or isStickied ) then
			if not ( ply:HasForumPermissions( IGFORUMS_MODERATORPERMISSIONS, true ) ) then return end
		end
		IGForums:CreateThread( ply, categoryID, icon, title, content, isLocked, isStickied )
		IGForums:UpdateAllForumViewers( )
	elseif ( mesType == IGFORUMS_REQUESTTHREAD ) then
		local threadID = net.ReadUInt( 32 )
		local pageNumber = net.ReadUInt( 16 )
		ply:NetworkPosts( threadID, pageNumber )
	elseif ( mesType == IGFORUMS_CREATEPOST ) then
		local threadID = net.ReadUInt( 32 )
		local postContent = net.ReadString( )
		local pageNumber = net.ReadUInt( 16 )
		IGForums:CreatePost( ply, threadID, postContent )
		IGForums:UpdateAllForumViewers( )
		--ply:NetworkPosts( threadID, pageNumber )
	elseif ( mesType == IGFORUMS_DELETEALLPOSTS ) then
		local userID = net.ReadUInt( 32 )
		if not ( ply:HasForumPermissions( IGFORUMS_MODERATORPERMISSIONS, true ) ) then return end
		IGForums:DeletePostsByID( userID, ply )
	elseif ( mesType == IGFORUMS_DELETEPOST ) then
		local postID = net.ReadUInt( 32 )
		if not ( ply:HasForumPermissions( IGFORUMS_MODERATORPERMISSIONS, true ) ) then return end
		IGForums:DeletePost( postID, ply )
		IGForums:UpdateAllForumViewers( )
	elseif ( mesType == IGFORUMS_DELETETHREAD ) then
		local threadID = net.ReadUInt( 32 )
		if not ( ply:HasForumPermissions( IGFORUMS_MODERATORPERMISSIONS, true ) ) then return end
		IGForums:DeleteThread( threadID, ply )
		IGForums:UpdateAllForumViewers( )
	elseif ( mesType == IGFORUMS_TOGGLETHREADLOCK ) then
		local threadID = net.ReadUInt( 32 )
		if not ( ply:HasForumPermissions( IGFORUMS_MODERATORPERMISSIONS, true ) ) then return end
		IGForums:ToggleThreadLock( threadID, ply )
		IGForums:UpdateAllForumViewers( )
	elseif ( mesType == IGFORUMS_TOGGLETHREADSTICKY ) then
		local threadID = net.ReadUInt( 32 )
		if not ( ply:HasForumPermissions( IGFORUMS_MODERATORPERMISSIONS, true ) ) then return end
		IGForums:ToggleThreadSticky( threadID, ply )
		IGForums:UpdateAllForumViewers( )
	end
end )

if not ( CLIENT ) then return end

///////////////////////////////////////////////////////////////
/// Initialization of the tables, along with requesting the
/// icons and users.
hook.Add( "InitPostEntity", "IGForums_ForumsInitialize", function( )
	LocalPlayer( ).IGForums = LocalPlayer( ).IGForums or { }
	LocalPlayer( ).IGForums.Users = LocalPlayer( ).IGForums.Users or { }
	LocalPlayer( ).IGForums.Categories = LocalPlayer( ).IGForums.Categories or { }
	LocalPlayer( ).IGForums.Icons = LocalPlayer( ).IGForums.Icons or { }
	net.Start( "IGForums_ForumsNET" )
		net.WriteUInt( IGFORUMS_REQUESTICONS, 16 )
	net.SendToServer( )
	net.Start( "IGForums_ForumsNET" )
		net.WriteUInt( IGFORUMS_REQUESTUSERS, 16 )
	net.SendToServer( )
end )

///////////////////////////////////////////////////////////////
/// Receives net messages from the server to manipulate the
/// user's data.
net.Receive( "IGForums_UserNET", function( len )
	local mesType = net.ReadUInt( 16 )
	if ( mesType == IGFORUMS_UPDATEPOSTCOUNT ) then
		local plyID = net.ReadUInt( 32 )
		local val = net.ReadUInt( 32 )
		if ( LocalPlayer( ).IGForums.Users[plyID] ) then
			LocalPlayer( ).IGForums.Users[plyID].postCount = val
		else
			LocalPlayer( ).IGForums.Users[plyID] = { }
			LocalPlayer( ).IGForums.Users[plyID].name = "Unknown"
			LocalPlayer( ).IGForums.Users[plyID].postCount = val
			LocalPlayer( ).IGForums.Users[plyID].rank = "user"
			LocalPlayer( ).IGForums.Users[plyID].banned = false
		end
	elseif ( mesType == IGFORUMS_UPDATENAME ) then
		local plyID = net.ReadUInt( 32 )
		local name = net.ReadString( )
		if ( LocalPlayer( ).IGForums.Users[plyID] ) then
			LocalPlayer( ).IGForums.Users[plyID].name = name
		else
			LocalPlayer( ).IGForums.Users[plyID] = { }
			LocalPlayer( ).IGForums.Users[plyID].name = name
			LocalPlayer( ).IGForums.Users[plyID].postCount = 0
			LocalPlayer( ).IGForums.Users[plyID].rank = "user"
			LocalPlayer( ).IGForums.Users[plyID].banned = false
		end
	elseif ( mesType == IGFORUMS_UPDATERANK ) then
		local plyID = net.ReadUInt( 32 )
		local rank = net.ReadString( )
		if ( LocalPlayer( ).IGForums.Users[plyID] ) then
			LocalPlayer( ).IGForums.Users[plyID].rank = rank
		else
			LocalPlayer( ).IGForums.Users[plyID] = { }
			LocalPlayer( ).IGForums.Users[plyID].name = "Unknown"
			LocalPlayer( ).IGForums.Users[plyID].postCount = 0
			LocalPlayer( ).IGForums.Users[plyID].rank = rank
			LocalPlayer( ).IGForums.Users[plyID].banned = false
		end
	elseif ( mesType == IGFORUMS_INSERTUSER ) then
		local plyID = net.ReadUInt( 32 )
		local steam64 = net.ReadString( )
		local name = net.ReadString( )
		local rank = net.ReadString( )
		local banned = tobool( net.ReadBit( ) )
		LocalPlayer( ).IGForums.Users[plyID] = { name = name, rank = rank, banned = banned }
		if ( LocalPlayer( ):SteamID64( ) == steam64 ) then
			LocalPlayer( ).forumsID = plyID
		end
	elseif ( mesType == IGFORUMS_UPDATEBAN ) then
		local plyID = net.ReadUInt( 32 )
		local banStatus = tobool( net.ReadBit( ) )
		if ( LocalPlayer( ).IGForums.Users[plyID] ) then
			LocalPlayer( ).IGForums.Users[plyID].banned = banStatus
		else
			LocalPlayer( ).IGForums.Users[plyID] = { }
			LocalPlayer( ).IGForums.Users[plyID].name = "Unknown"
			LocalPlayer( ).IGForums.Users[plyID].postCount = 0
			LocalPlayer( ).IGForums.Users[plyID].rank = "user"
			LocalPlayer( ).IGForums.Users[plyID].banned = false
		end
	end
end )

///////////////////////////////////////////////////////////////
/// Receives net messages from the server to manipulate the
/// threads.
net.Receive( "IGForums_ThreadNET", function( len ) 
	local mesType = net.ReadUInt( 16 )
	if ( mesType == IGFORUMS_SENDTHREAD ) then
		local threadCategory = net.ReadUInt( 32 )
		local threadID = net.ReadUInt( 32 )
		local postID = net.ReadUInt( 32 )
		local userID = net.ReadUInt( 32 )
		local postDate = net.ReadUInt( 32 )
		local postText = net.ReadString( )
		LocalPlayer( ).IGForums.Categories[threadCategory] = LocalPlayer( ).IGForums.Categories[threadCategory] or { }
		LocalPlayer( ).IGForums.Categories[threadCategory].Threads = LocalPlayer( ).IGForums.Categories[threadCategory].Threads or { }
		LocalPlayer( ).IGForums.Categories[threadCategory].Threads[threadID] = LocalPlayer( ).IGForums.Categories[threadCategory].Threads[threadID] or { }
		LocalPlayer( ).IGForums.Categories[threadCategory].Threads[threadID].Posts = LocalPlayer( ).IGForums.Categories[threadCategory].Threads[threadID].Posts or { }
		LocalPlayer( ).IGForums.Categories[threadCategory].Threads[threadID].Posts[postID] = { userID = userID, postDate = postDate, text = postText }
		if ( IsValid( LocalPlayer( ).IGForums_Viewer ) ) then
			LocalPlayer( ).IGForums_Viewer:GeneratePosts( threadCategory, threadID )
		end
	elseif ( mesType == IGFORUMS_DELETEPOSTSBYID ) then
		local userID = net.ReadUInt( 32 )
		for categoryID, category in pairs ( LocalPlayer( ).IGForums.Categories or { } ) do
			for threadID, thread in pairs ( LocalPlayer( ).IGForums.Categories[categoryID].Threads or { } ) do
				for postID, post in pairs ( LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].Posts or { } ) do
					if ( post.userID == userID ) then
						LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].Posts[postID] = nil
					end
				end
			end
		end
	elseif ( mesType == IGFORUMS_DELETETHREADSBYID ) then
		local userID = net.ReadUInt( 32 )
		for categoryID, category in pairs ( LocalPlayer( ).IGForums.Categories or { } ) do
			for threadID, thread in pairs ( LocalPlayer( ).IGForums.Categories[categoryID].Threads or { } ) do
				LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID] = nil
			end
		end
	elseif ( mesType == IGFORUMS_DELETEPOSTBYID ) then
		local postID = net.ReadUInt( 32 )
		for categoryID, category in pairs ( LocalPlayer( ).IGForums.Categories or { } ) do
			for threadID, thread in pairs ( LocalPlayer( ).IGForums.Categories[categoryID].Threads or { } ) do
				LocalPlayer( ).IGForums.Categories[categoryID].Threads = LocalPlayer( ).IGForums.Categories[categoryID].Threads or { }
				LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].Posts = LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].Posts or { }
				if ( LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].Posts[postID] ) then
					LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].Posts[postID] = nil
					break
				end
			end
		end
	elseif ( mesType == IGFORUMS_DELETETHREADBYID ) then
		local threadID = net.ReadUInt( 32 )
		for categoryID, category in pairs ( LocalPlayer( ).IGForums.Categories or { } ) do
			LocalPlayer( ).IGForums.Categories[categoryID].Threads = LocalPlayer( ).IGForums.Categories[categoryID].Threads or { }
			if ( LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID] ) then
				LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID] = nil
				break
			end
		end
	elseif ( mesType == IGFORUMS_UPDATETHREADLOCK ) then
		local threadID = net.ReadUInt( 32 )
		local lockedStatus = tobool( net.ReadBit( ) )
		for categoryID, category in pairs ( LocalPlayer( ).IGForums.Categories or { } ) do
			LocalPlayer( ).IGForums.Categories[categoryID].Threads = LocalPlayer( ).IGForums.Categories[categoryID].Threads or { }
			if ( LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID] ) then
				LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].locked = lockedStatus
				break
			end
		end
	elseif ( mesType == IGFORUMS_UPDATETHREADSTICKY ) then
		local threadID = net.ReadUInt( 32 )
		local stickyStatus = tobool( net.ReadBit( ) )
		for categoryID, category in pairs ( LocalPlayer( ).IGForums.Categories or { } ) do
			LocalPlayer( ).IGForums.Categories[categoryID].Threads = LocalPlayer( ).IGForums.Categories[categoryID].Threads or { }
			if ( LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID] ) then
				LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].sticky = stickyStatus
				break
			end
		end
	elseif ( mesType == IGFORUMS_SENDPAGEAMOUNT ) then
		local threadID = net.ReadUInt( 32 )
		local categoryID = net.ReadUInt( 32 )
		local pageAmount = net.ReadUInt( 16 )
		LocalPlayer( ).IGForums.Categories[categoryID] = LocalPlayer( ).IGForums.Categories[categoryID] or { }
		LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID] = LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID] or { }
		LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].pageAmount = pageAmount
		if ( IsValid( LocalPlayer( ).IGForums_Viewer ) ) then
			local lastPage = LocalPlayer( ).IGForums_Viewer.dContentFrame.lastPostPage or 1
			if ( lastPage > ( pageAmount or 1 ) ) then
				LocalPlayer( ).IGForums_Viewer.dContentFrame.lastPostPage = ( pageAmount or 1 )
				LocalPlayer( ).IGForums_Viewer:RefreshView( )
			end
		end
	end
end )

///////////////////////////////////////////////////////////////
/// Receives net messages from the server to manipulate the
/// categories.
net.Receive( "IGForums_CategoryNET", function( len )
	local mesType = net.ReadUInt( 16 )
	if ( mesType == IGFORUMS_SENDCATEGORY ) then
		local categoryID = net.ReadUInt( 32 )
		local iconID = net.ReadUInt( 32 )
		local name = net.ReadString( )
		local desc = net.ReadString( )
		local priority = net.ReadUInt( 32 )
		LocalPlayer( ).IGForums.Categories[categoryID] = LocalPlayer( ).IGForums.Categories[categoryID] or { }
		LocalPlayer( ).IGForums.Categories[categoryID].iconID = iconID
		LocalPlayer( ).IGForums.Categories[categoryID].name = name
		LocalPlayer( ).IGForums.Categories[categoryID].desc = desc
		LocalPlayer( ).IGForums.Categories[categoryID].priority = priority
		if ( IsValid( LocalPlayer( ).IGForums_Viewer ) ) then
			LocalPlayer( ).IGForums_Viewer:GenerateCategories( )
		end
	elseif ( mesType == IGFORUMS_SENDTHREAD ) then
		local categoryID = net.ReadUInt( 32 )
		local threadID = net.ReadUInt( 32 )
		local userID = net.ReadUInt( 32 )
		local iconID = net.ReadUInt( 32 )
		local time = net.ReadUInt( 32 )
		local lastPost = net.ReadUInt( 32 )
		local postCount = net.ReadUInt( 32 )
		local name = net.ReadString( )
		local text = net.ReadString( )
		local isLocked = tobool( net.ReadBit( ) )
		local isStickied = tobool( net.ReadBit( ) )
		LocalPlayer( ).IGForums.Categories[categoryID] = LocalPlayer( ).IGForums.Categories[categoryID] or { }
		LocalPlayer( ).IGForums.Categories[categoryID].Threads = LocalPlayer( ).IGForums.Categories[categoryID].Threads or { }
		LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID] = LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID] or { }
		LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].userID = userID
		LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].iconID = iconID
		LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].postDate = time
		LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].lastPost = lastPost
		LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].name = name
		LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].text = text
		LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].locked = isLocked
		LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].sticky = isStickied
		LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].postCount = postCount
		if ( IsValid( LocalPlayer( ).IGForums_Viewer ) ) then
			LocalPlayer( ).IGForums_Viewer:GenerateThreads( categoryID )
		end
	elseif ( mesType == IGFORUMS_DELETECATEGORY ) then
		local categoryID = net.ReadUInt( 32 )
		LocalPlayer( ).IGForums.Categories[categoryID] = nil
		if ( IsValid( LocalPlayer( ).IGForums_Viewer ) ) then
			LocalPlayer( ).IGForums_Viewer:RefreshView( )
		end
	elseif ( mesType == IGFORUMS_SENDPAGEAMOUNT ) then
		local categoryID = net.ReadUInt( 32 )
		local pageAmount = net.ReadUInt( 16 )
		LocalPlayer( ).IGForums.Categories[categoryID] = LocalPlayer( ).IGForums.Categories[categoryID] or { }
		LocalPlayer( ).IGForums.Categories[categoryID].pageAmount = pageAmount
		if ( IsValid( LocalPlayer( ).IGForums_Viewer ) ) then
			local lastPage = LocalPlayer( ).IGForums_Viewer.dContentFrame.lastPage or 1
			if ( lastPage > ( pageAmount or 1 ) ) then
				LocalPlayer( ).IGForums_Viewer.dContentFrame.lastPage = ( pageAmount or 1 )
				LocalPlayer( ).IGForums_Viewer:RefreshView( )
			end
		end
	end
end )

///////////////////////////////////////////////////////////////
/// Receives general net messages from the server such as
/// opening, refreshing, and sending hints to the forum.
net.Receive( "IGForums_ForumsNET", function( len )
	local mesType = net.ReadUInt( 16 )
	if ( mesType == IGFORUMS_OPENFORUMS ) then
		if ( IsValid( LocalPlayer( ).IGForums_Viewer ) ) then
			LocalPlayer( ).IGForums_Viewer:Remove( )
		else
			LocalPlayer( ).IGForums_Viewer = vgui.Create( "IGForums_Viewer" )
		end
	elseif ( mesType == IGFORUMS_REFRESHVIEWER ) then
		if ( IsValid( LocalPlayer( ).IGForums_Viewer ) ) then
			LocalPlayer( ).IGForums_Viewer:RefreshView( )
		end
	elseif ( mesType == IGFORUMS_SENDMESSAGE ) then
		if ( IsValid( LocalPlayer( ).IGForums_Viewer ) ) then
			local message = net.ReadString( )
			local length = net.ReadUInt( 16 )
			LocalPlayer( ).IGForums_Viewer:ActivateMessageBox( message, length )
		end
	end
end )

///////////////////////////////////////////////////////////////
/// Receives the icons from the server.
net.Receive( "IGForums_IconNET", function( len )
	local iconID = net.ReadUInt( 32 )
	local iconPath = net.ReadString( )
	LocalPlayer( ).IGForums.Icons[iconID] = { path = iconPath, mat = Material( iconPath ) }
end )