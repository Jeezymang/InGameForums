local baseWidth, baseHeight = 640, 512
local widthMulti, heightMulti = 0.15, 0.15
local categoryBaseHeight = 72
local categoryHeightMulti = 0.025
local threadBaseHeight = 72
local threadHeightMulti = 0.025
local postBaseHeight = 84
local postHeightMulti = 0.025
local categoryTextBaseSize = 12
local messageHintTextBaseSize = 16
local textEntryTextBaseSize = 14

local blurMaterial = Material( "pp/blurscreen" )
local lockMaterial = Material( "vgui/ingame_forums/icons/locked.png", "noclamp smooth" )
local unlockMaterial = Material( "vgui/ingame_forums/icons/unlocked.png", "noclamp smooth" )
local backMaterial = Material( "vgui/ingame_forums/icons/undo-48.png", "noclamp smooth" )
local createCategoryMaterial = Material( "vgui/ingame_forums/icons/add_folder-48.png", "noclamp smooth" )
local cancelMaterial = Material( "vgui/ingame_forums/icons/cancel-48.png", "noclamp smooth" )
local acceptMaterial = Material( "vgui/ingame_forums/icons/checkmark-48.png", "noclamp smooth" )
local postMaterial = Material( "vgui/ingame_forums/icons/new_post-48.png", "noclamp smooth" )
local replyMaterial = Material( "vgui/ingame_forums/icons/create_new_child_post-48.png", "noclamp smooth" )
local userMaterial = Material( "vgui/ingame_forums/icons/user-48.png", "noclamp smooth" )
local rankMaterial = Material( "vgui/ingame_forums/icons/user_shield-48.png", "noclamp smooth" )
local deletePostsMaterial = Material( "vgui/ingame_forums/icons/empty_trash-48.png", "noclamp smooth" )
local banUserMaterial = Material( "vgui/ingame_forums/icons/remove_user-48.png", "noclamp smooth" )
local unBanUserMaterial = Material( "vgui/ingame_forums/icons/add_user-48.png", "noclamp smooth" )
local refreshMaterial = Material( "vgui/ingame_forums/icons/refresh-48.png", "noclamp smooth" )
local stickyMaterial = Material( "vgui/ingame_forums/icons/pin-48.png", "noclamp smooth" )
local unstickyMaterial = Material( "vgui/ingame_forums/icons/low_priority-48.png", "noclamp smooth" )
local logsMaterial = Material( "vgui/ingame_forums/icons/files.png", "noclamp smooth" )
local scrW, scrH = ScrW( ), ScrH( )
local plyMeta = FindMetaTable( "Player" )

local function CreateFonts( )
	surface.CreateFont( "IGForums_CategoryTitle", {
		font = "Segoe UI", 
		size = categoryTextBaseSize + ScreenScale( 7 ), 
		weight = 600
	} )
	surface.CreateFont( "IGForums_CategoryDesc", {
		font = "Segoe UI", 
		size = categoryTextBaseSize + ScreenScale( 3 ), 
		weight = 500
	} )
	surface.CreateFont( "IGForums_NameLabel", {
		font = "Segoe UI", 
		size = categoryTextBaseSize + ScreenScale( 6 ), 
		weight = 750
	} )
	surface.CreateFont( "IGForums_MessageHint", {
		font = "Lobster", 
		size = messageHintTextBaseSize + ScreenScale( 2 ), 
		weight = 750
	} )
	surface.CreateFont( "IGForums_TextEntryFont", {
		font = "Lobster", 
		size = textEntryTextBaseSize + ScreenScale( 2 ), 
		weight = 750
	} )
	surface.CreateFont( "IGForums_TextEntrySmall", {
		font = "Segio UI Semibold", 
		size = textEntryTextBaseSize + ScreenScale( 2 ), 
		weight = 750
	} )
end

// Credits to Willox for the resolution changed hook.
hook.Add( "Initialize", "IGForums_ResolutionInitialize", function( )
	vgui.CreateFromTable {
		Base =  "Panel",
		PerformLayout = function( )
			hook.Run( "ResolutionChanged", ScrW( ), ScrH( ) )
		end
	} : ParentToHUD( )
end )

CreateFonts( )
hook.Add( "ResolutionChanged", "IGForums_ResolutionChanged", function( w, h )
	scrW = w
	scrH = h
	if ( IsValid( LocalPlayer( ).IGForums_Viewer ) ) then
		CreateFonts( )
	end
end )

function plyMeta:HasForumPermissions( enum )
	local userRank = self:GetForumsRank( )
	local canAccess = false
	if ( ForumsConfig.RankPermissions[ enum ] ) then
		canAccess = ( ForumsConfig.RankPermissions[ enum ][userRank] )
	end
	return canAccess
end

function plyMeta:GetForumsRank( )
	local userRank = "user"
	if ( LocalPlayer( ).IGForums.Users[ LocalPlayer( ).forumsID ] ) then
		userRank = LocalPlayer( ).IGForums.Users[ LocalPlayer( ).forumsID ].rank
	end
	return userRank
end

local function GetRankByID( userID )
	local userRank = "user"
	if ( LocalPlayer( ).IGForums.Users[ userID ] ) then
		userRank = LocalPlayer( ).IGForums.Users[ userID ].rank
	end
	return userRank
end

PANEL = {}

function PANEL:Init( )
	local addWidth, addHeight = scrW * widthMulti, scrH * heightMulti
	self:SetSize( baseWidth + addWidth, baseHeight + addHeight )
	self:Center( )
	self:SetTitle( "" )
	self:ShowCloseButton( false )
	self:MakePopup( )
	self.currentCategory = nil
	self.currentThread = nil
	self.isNotViewing = false

	self.dContentFrame = vgui.Create( "DFrame", self )
	self.dContentFrame:SetSize( self:GetWide( ) * 0.8, self:GetTall( ) * 0.8 )
	self.dContentFrame:ShowCloseButton( false )
	self.dContentFrame:SetDraggable( false )
	self.dContentFrame:SetTitle( "" )
	local cFrameWide, cFrameTall = self.dContentFrame:GetSize( )
	local middlePosX, middlePosY = self:GetSize( )
	middlePosX, middlePosY = middlePosX * 0.5, middlePosY * 0.5
	self.dContentFrame:SetPos( middlePosX - ( cFrameWide * 0.5 ), middlePosY - ( cFrameTall * 0.5 ) )
	self.dContentFrame.contentChildren = self.dContentFrame.contentChildren or { }
	self.dContentFrame:NoClipping( true )
	self.dContentFrame.Paint = function( pnl, w, h )
		draw.RoundedBox( 8, -( w * 0.1 ), -( h *0.08 ), w * 1.2, h * 1.15, Color( 0, 0, 0, 200 ) )
	end
	local dCloseButtonLabel, dCloseButton = self:CreateButton( "CLOSE", "IGForums_CategoryDesc", cancelMaterial, function( pnl )
		gui.EnableScreenClicker( false )
		self:Remove( )
	end, self:GetWide( ) * 0.075, self.dContentFrame:GetTall( ) * 1.075, self )
	dCloseButton.Think = function( pnl )
		pnl:MoveToFront( )
	end
	dCloseButton:NoClipping( true )
	self.dCloseButton = dCloseButton
	local closeButtonX, closeButtonY = dCloseButtonLabel:GetPos( )
	self.dCloseButton.offsetPos = function( btn, x, y )
		local lblW, lblH = dCloseButtonLabel:GetSize( )
		dCloseButtonLabel:SetPos( closeButtonX + x , closeButtonY + y )
		local lblX, lblY = dCloseButtonLabel:GetPos( )
		local buttonXPos = lblX + ( lblW * 0.5 ) - 24
		btn:SetPos( buttonXPos, lblY - 48 )
	end
	dCloseButtonLabel.Think = function( pnl )
		pnl:MoveToFront( )
	end
	local dRefreshButtonLabel, dRefreshButton = self:CreateButton( "REFRESH", "IGForums_CategoryDesc", refreshMaterial, function( pnl )
		self:RefreshView( )
	end, self:GetWide( ) * 0.925, self.dContentFrame:GetTall( ) * 1.075, self )
	dRefreshButtonLabel.Think = function( pnl )
		pnl:MoveToFront( )
	end
	dRefreshButton.Think = function( pnl )
		pnl:MoveToFront( )
	end
	dRefreshButton:NoClipping( true )
	self.dRefreshButton = dRefreshButton
	local refreshButtonX, refreshButtonY = dRefreshButtonLabel:GetPos( )
	self.dRefreshButton.offsetPos = function( btn, x, y )
		local lblW, lblH = dRefreshButtonLabel:GetSize( )
		dRefreshButtonLabel:SetPos( refreshButtonX + x , refreshButtonY + y )
		local lblX, lblY = dRefreshButtonLabel:GetPos( )
		local buttonXPos = lblX + ( lblW * 0.5 ) - 24
		btn:SetPos( buttonXPos, lblY - 48 )
	end
	self.dMessageBoxPanel = vgui.Create( "DPanel", self )
	self.dMessageBoxPanel:SetSize( self:GetWide( ) * 0.8, self:GetTall( ) * 0.06 )
	self.dMessageBoxPanel:AlignTop( self:GetTall( ) * 0.05 )
	self.dMessageBoxPanel:CenterHorizontal( )
	self.dMessageBoxPanel.currentMessage = nil
	self.dMessageBoxPanel.messageLength = 0
	self.dMessageBoxPanel.messageEndTime = 0
	self.dMessageBoxPanel.Paint = function( pnl, w, h )
		if ( self.dMessageBoxPanel.currentMessage and self.dMessageBoxPanel.messageEndTime > CurTime( ) ) then
			local alphaModifier = ( self.dMessageBoxPanel.messageEndTime - CurTime( ) ) / self.dMessageBoxPanel.messageLength
			draw.SimpleText( self.dMessageBoxPanel.currentMessage, "IGForums_MessageHint", w * 0.5, h * 0.5, Color( 255, 255, 255, 255 * alphaModifier ), TEXT_ALIGN_CENTER )
		end
	end
	self.dMessageBoxPanel.Think = function( )
		self.dMessageBoxPanel:MoveToFront( )
	end
	self:GenerateCategories( )
end

function PANEL:Paint( w, h )
	// Credits to Chessnut for the screen blur effect.
	local x, y = self:LocalToScreen( 0, 0 )
	surface.SetDrawColor( 45, 45, 45 )
	surface.SetMaterial( blurMaterial )
	for i = 1, 5 do
		blurMaterial:SetFloat( "$blur", ( i / 9 ) * 8 )
		blurMaterial:Recompute( )
		render.UpdateScreenEffectTexture( )
		surface.DrawTexturedRect( x * -1, y * -1, ScrW( ), ScrH( ) )
	end
	surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
	draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 150 ) )
end

function PANEL:ParseTextLines( text )
	local textTable = string.Explode( " ", text )
	local builtString = ""
	local currentLine = ""
	local lineAmt = 1
	for index, subString in ipairs( textTable ) do
		if not ( string.len( currentLine ) > 80 ) then
			builtString = builtString .. " " .. subString .. " "
			currentLine = currentLine .. " " .. subString .. " "
		else
			builtString = builtString .. "\n" .. subString .. " "
			currentLine = ""
			lineAmt = lineAmt + 1
		end
	end
	return builtString, lineAmt
end

function PANEL:ActivateMessageBox( message, length )
	self.dMessageBoxPanel.currentMessage = message
	self.dMessageBoxPanel.messageEndTime = CurTime( ) + length
	self.dMessageBoxPanel.messageLength = length
end

function PANEL:RefreshView( )
	if ( self.isNotViewing ) then return end
	if ( tonumber( self.currentCategory ) ) then
		if ( tonumber( self.currentThread ) ) then
			if not ( LocalPlayer( ).IGForums.Categories[self.currentCategory] ) then self:GenerateCategories( ) end
			if not ( LocalPlayer( ).IGForums.Categories[self.currentCategory].Threads[self.currentThread] ) then self:GenerateThreads( self.currentCategory ) end
			if ( ( LocalPlayer( ).IGForums.Categories[self.currentCategory].Threads[self.currentThread] ) ) then
				LocalPlayer( ).IGForums.Categories[self.currentCategory].Threads[self.currentThread].Posts = { }
			end
			self:GeneratePosts( self.currentCategory, self.currentThread )
			if not ( tonumber( self.currentThread ) ) then return end
			net.Start( "IGForums_ThreadNET" )
				net.WriteUInt( IGFORUMS_REQUESTTHREAD, 16 )
				net.WriteUInt( self.currentThread, 32 )
				net.WriteUInt( self.dContentFrame.lastPostPage or 1, 16 )
			net.SendToServer( )
		else
			if not ( LocalPlayer( ).IGForums.Categories[self.currentCategory] ) then self:GenerateCategories( ) return end
			if ( ( LocalPlayer( ).IGForums.Categories[self.currentCategory] ) ) then
				LocalPlayer( ).IGForums.Categories[self.currentCategory].Threads = { }
			end
			self:GenerateThreads( self.currentCategory )
			if not ( tonumber( self.currentCategory ) ) then return end
			local lastPage = self.dContentFrame.lastPage or 1
			net.Start( "IGForums_CategoryNET" )
				net.WriteUInt( IGFORUMS_REQUESTCATEGORY, 16 )
				net.WriteUInt( self.currentCategory, 32 )
				net.WriteUInt( lastPage, 16 )
			net.SendToServer( )
		end
	else
		self:GenerateCategories( )
		net.Start( "IGForums_CategoryNET" )
			net.WriteUInt( IGFORUMS_REQUESTCATEGORIES, 16 )
		net.SendToServer( )
	end
end

function PANEL:CreateDIconLayout( isLocal, widthMulti, heightMulti, xMulti, yMulti, spaceX, spaceY )
	local widthMulti = widthMulti or 0.9
	local heightMulti = heightMulti or 0.7
	local xMulti = xMulti or 0.05
	local yMulti = yMulti or 0.1
	local spaceX = spaceX or 5
	local spaceY = spaceY or 5
	local dScrollPanel = vgui.Create( "DScrollPanel", self.dContentFrame )
	dScrollPanel:SetSize( self.dContentFrame:GetWide( ) * widthMulti, self.dContentFrame:GetTall( ) * heightMulti )
	dScrollPanel:SetPos( self.dContentFrame:GetWide( ) * xMulti, self.dContentFrame:GetTall( ) * yMulti )
	local dIconLayout = vgui.Create( "DIconLayout", dScrollPanel )
	dIconLayout:SetSize( dScrollPanel:GetWide( ), dScrollPanel:GetTall( ) )
	dIconLayout:SetPos( 0, 0 )
	dIconLayout:SetSpaceX( spaceX )
	dIconLayout:SetSpaceY( spaceY )
	if not ( isLocal ) then
		self.dIconLayout = dIconLayout
	end
	table.insert( self.dContentFrame.contentChildren, dScrollPanel )
	return dIconLayout
end

function PANEL:ClearContentFrame( enum )
	if ( IsValid( self.dContentFrame ) ) then
		for index, child in pairs( self.dContentFrame.contentChildren or { } ) do
			if not ( IsValid( child ) ) then continue end
			if ( enum and enum == IGFORUMS_GENERATECATEGORIES ) then
				if ( child.dontRemoveOnCategoryGeneration ) then
					continue
				end
			end
			self.dContentFrame.contentChildren[index] = nil
			child:Remove( )
		end
	end
end

function PANEL:CreateButton( labelText, labelFont, buttonMaterial, onClick, x, y, parentOverride )
	local buttonLabel
	if ( IsValid( parentOverride ) ) then
		buttonLabel = vgui.Create( "DLabel", parentOverride )
	else
		buttonLabel = vgui.Create( "DLabel", self.dContentFrame )
		table.insert( self.dContentFrame.contentChildren, buttonLabel )
	end
	buttonLabel:SetText( labelText )
	buttonLabel:SetFont( labelFont )
	buttonLabel:SetTextColor( Color( 255, 255, 255 ) )
	buttonLabel:SizeToContents( )
	buttonLabel:SetPos( x, y )
	local buttonLabelX, buttonLabelY = buttonLabel:GetPos( )
	local buttonLabelW, buttonLabelH = buttonLabel:GetSize( )
	buttonLabel:SetPos( buttonLabelX - ( buttonLabelW * 0.5 ), buttonLabelY )
	buttonLabelX, buttonLabelY = buttonLabel:GetPos( )
	local dButton
	if ( IsValid( parentOverride ) ) then
		dButton = vgui.Create( "DPanel", parentOverride )
	else
		dButton = vgui.Create( "DPanel", self.dContentFrame )
		table.insert( self.dContentFrame.contentChildren, dButton )
	end
	dButton:SetSize( 48, 48 )
	local buttonXPos = buttonLabelX + ( buttonLabelW * 0.5 ) - 24
	dButton:SetPos( buttonXPos, buttonLabelY - 48 )
	dButton.Paint = function( pnl, w, h )
		local drawColor = Color( 255, 255, 255, 255 )
		if ( self.dContentFrame and self.dContentFrame.selectedPanel == pnl  ) then
			drawColor = Color( 26, 188, 156, 150 )
		end
		surface.SetDrawColor( drawColor )
		surface.SetMaterial( buttonMaterial )
		surface.DrawTexturedRect( 0, 0, w, h )
		surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
	end
	dButton.OnMousePressed = function( pnl, btn )
		surface.PlaySound( "ui/buttonclick.wav" )
		onClick( pnl )
	end
	dButton.OnCursorEntered = function( pnl )
		if ( self.dContentFrame.selectedPanel ~= pnl ) then
			surface.PlaySound( "ui/buttonrollover.wav" )
		end
		self.dContentFrame.selectedPanel = pnl
	end
	dButton.OnCursorExited = function( pnl )
		self.dContentFrame.selectedPanel = nil
	end
	return buttonLabel, dButton
end

local function AttemptPlayerRankSet( rank, userID )
	net.Start( "IGForums_UserNET" )
		net.WriteUInt( IGFORUMS_SETRANK, 16 )
		net.WriteUInt( userID, 32 )
		net.WriteString( rank )
	net.SendToServer( )
end

function PANEL:OpenLogViewer( dontRequestLogs )
	self.isNotViewing = true
	self:ClearContentFrame( )
	if not ( dontRequestLogs ) then
		LocalPlayer( ).IGForums = LocalPlayer( ).IGForums or { }
		LocalPlayer( ).IGForums.Logs = { }
		net.Start( "IGForums_ForumsNET" )
			net.WriteUInt( IGFORUMS_REQUESTLOGFILES, 16 )
		net.SendToServer( )
	end
	LocalPlayer( ).IGForums = LocalPlayer( ).IGForums or { }
	LocalPlayer( ).IGForums.Logs = LocalPlayer( ).IGForums.Logs or { }
	local backButton = self:CreateButton( "GO BACK", "IGForums_CategoryDesc", backMaterial, function( pnl )
		self:OpenUserManagement( )
	end, self.dContentFrame:GetWide( ) * 0.5, self.dContentFrame:GetTall( ) * 0.95 )
	if ( table.Count( LocalPlayer( ).IGForums.Logs ) == 0 ) then
		local dLabel = vgui.Create( "DLabel", self.dContentFrame )
		dLabel:SetText( "No Log Files Could Be Found" )
		dLabel:SetFont( "IGForums_CategoryTitle" )
		dLabel:SizeToContents( )
		dLabel:CenterHorizontal( )
		dLabel:AlignTop( self.dContentFrame:GetTall( ) * 0.3 )
		table.insert( self.dContentFrame.contentChildren, dLabel )
		local dImagePanel = vgui.Create( "DPanel", self.dContentFrame )
		dImagePanel:SetSize( 48, 48 )
		dImagePanel:CenterHorizontal( )
		dImagePanel:AlignTop( self.dContentFrame:GetTall( ) * 0.4 )
		dImagePanel.Paint = function( pnl, w, h )
			surface.SetDrawColor( Color( 175, 75, 75 ) )
			surface.SetMaterial( cancelMaterial )
			surface.DrawTexturedRect( 0, 0, 48, 48 )
			surface.SetDrawColor( Color( 255, 255, 255 ) )
		end
		table.insert( self.dContentFrame.contentChildren, dImagePanel )
		return
	end
	local daysListLabel = vgui.Create( "DLabel", self.dContentFrame )
	daysListLabel:SetText( "Log Files" )
	daysListLabel:SetFont( "IGForums_CategoryTitle" )
	daysListLabel:SizeToContents( )
	daysListLabel:CenterHorizontal( )
	daysListLabel:AlignTop( self.dContentFrame:GetTall( ) * 0.01 )
	daysListLabel:SetTextColor( Color( 255, 255, 255 ) )
	table.insert( self.dContentFrame.contentChildren, daysListLabel )
	local daysList = self:CreateDIconLayout( true, 0.8, 0.4, 0.1, 0.065 )
	for fileName, fileData in pairs ( LocalPlayer( ).IGForums.Logs ) do
		local filePanel = daysList:Add( "DPanel" )
		filePanel:SetSize( daysList:GetWide( ), 40 )
		filePanel.Paint = function( pnl, w, h )
			local drawColor = Color( 255, 255, 255 )
			if ( daysList.selectedPanel == pnl ) then drawColor = Color( 26, 188, 156 ) end
			draw.RoundedBox( 0, 0, 0, w, h, drawColor )
			draw.SimpleText( fileName, "IGForums_CategoryTitle", w * 0.5, h * 0.2, Color( 0, 0, 0 ), TEXT_ALIGN_CENTER )
		end
		filePanel.OnMousePressed = function( pnl, btn )
			LocalPlayer( ).IGForums.Logs[fileName] = nil
			self.lastLogFileViewed = fileName
			net.Start( "IGForums_ForumsNET" )
				net.WriteUInt( IGFORUMS_REQUESTLOGFILE, 16 )
				net.WriteString( fileName )
			net.SendToServer( )
		end
		filePanel.OnCursorEntered = function( pnl )
			daysList.selectedPanel = pnl
		end
		filePanel.OnCursorExited = function( pnl )
			daysList.selectedPanel = nil
		end
	end
	local logList = self:CreateDIconLayout( true, 0.8, 0.3, 0.1, 0.46 )
	if ( LocalPlayer( ).IGForums.Logs[self.lastLogFileViewed] ) then
		local logListLabel = vgui.Create( "DLabel", self.dContentFrame )
		logListLabel:SetText( "Log Entries" )
		logListLabel:SetFont( "IGForums_CategoryTitle" )
		logListLabel:SizeToContents( )
		logListLabel:CenterHorizontal( )
		logListLabel:AlignTop( self.dContentFrame:GetTall( ) * 0.4 )
		logListLabel:SetTextColor( Color( 255, 255, 255 ) )
		table.insert( self.dContentFrame.contentChildren, logListLabel )
		for index, lineData in ipairs ( LocalPlayer( ).IGForums.Logs[self.lastLogFileViewed] ) do
			local fileLinePanel = logList:Add( "DPanel" )
			fileLinePanel:SetSize( logList:GetWide( ), 40 )
			local lineTextEntry = vgui.Create( "DTextEntry", fileLinePanel )
			lineTextEntry:SetSize( fileLinePanel:GetWide( ) * 0.95, fileLinePanel:GetTall( ) )
			lineTextEntry:Center( )
			lineTextEntry:SetMultiline( true )
			lineTextEntry:SetText( lineData )
			lineTextEntry.OnTextChanged = function( pnl, txt )
				pnl:SetText( lineData )
			end
			lineTextEntry:SetVerticalScrollbarEnabled( true )
		end
	end
end

function PANEL:OpenUserManagement( )
	self.isNotViewing = true
	self:ClearContentFrame( )
	local selectedRank = "user"
	local userListView = vgui.Create( "DListView", self.dContentFrame )
	userListView:SetSize( self.dContentFrame:GetWide( ) * 0.8, self.dContentFrame:GetTall( ) * 0.4 )
	userListView:AlignTop( self.dContentFrame:GetTall( ) * 0.075 )
	userListView:CenterHorizontal( )
	userListView:AddColumn( "UserID" )
	userListView:AddColumn( "Name" )
	userListView:AddColumn( "Posts" )
	userListView:AddColumn( "Rank" )
	userListView:AddColumn( "Banned" )
	userListView:SetMultiSelect( false )
	self.dCloseButton:offsetPos( self:GetWide( ) * 0.175, 0 )
	self.dRefreshButton:offsetPos( -( self:GetWide( ) * 0.175 ), 0 )
	local userListTable = { }
	for index, userTbl in pairs ( LocalPlayer( ).IGForums.Users ) do
		local postCount = userTbl.postCount or 0
		userListView:AddLine( index, userTbl.name, postCount, userTbl.rank, tostring( userTbl.banned ) )
		table.insert( userListTable, { userID = index, name = userTbl.name, postCount = postCount, rank = userTbl.rank, banned = userTbl.banned } )
	end
	table.insert( self.dContentFrame.contentChildren, userListView )
	local setRankButton = self:CreateButton( "SET RANK", "IGForums_CategoryDesc", rankMaterial, function( pnl )
		local selectedLine = userListView:GetSelectedLine( )
		if not ( userListTable[ selectedLine ] ) then 
			self:ActivateMessageBox( "You must select a user before performing an action.", 3 )
			return 
		end
		local popupMenu = DermaMenu( )
		for rankIndex, rankTbl in pairs ( ForumsConfig.Ranks ) do
			popupMenu:AddOption( rankIndex, function( ) 
				AttemptPlayerRankSet( rankIndex, userListTable[ selectedLine ].userID )
			end )
		end
		popupMenu:AddOption( "Cancel" )
		popupMenu:Open( )
	end, self.dContentFrame:GetWide( ) * 0.2, self.dContentFrame:GetTall( ) * 0.65 )
	local deletePostsButton = self:CreateButton( "DELETE POSTS", "IGForums_CategoryDesc", deletePostsMaterial, function( pnl )
		local selectedLine = userListView:GetSelectedLine( )
		if not ( userListTable[ selectedLine ] ) then 
			self:ActivateMessageBox( "You must select a user before performing an action.", 3 )
			return 
		end
		net.Start( "IGForums_ThreadNET" )
			net.WriteUInt( IGFORUMS_DELETEALLPOSTS, 16 )
			net.WriteUInt( userListTable[ selectedLine ].userID, 32 )
		net.SendToServer( )
	end, self.dContentFrame:GetWide( ) * 0.4, self.dContentFrame:GetTall( ) * 0.65 )
	local banUserButton = self:CreateButton( "BAN USER", "IGForums_CategoryDesc", banUserMaterial, function( pnl )
		local selectedLine = userListView:GetSelectedLine( )
		if not ( userListTable[ selectedLine ] ) then 
			self:ActivateMessageBox( "You must select a user before performing an action.", 3 )
			return 
		end
		net.Start( "IGForums_UserNET" )
			net.WriteUInt( IGFORUMS_BANUSER, 16 )
			net.WriteUInt( userListTable[ selectedLine ].userID, 32 )
		net.SendToServer( )
	end, self.dContentFrame:GetWide( ) * 0.6, self.dContentFrame:GetTall( ) * 0.65 )
	local unBanUserButton = self:CreateButton( "UNBAN USER", "IGForums_CategoryDesc", unBanUserMaterial, function( pnl )
		local selectedLine = userListView:GetSelectedLine( )
		if not ( userListTable[ selectedLine ] ) then 
			self:ActivateMessageBox( "You must select a user before performing an action.", 3 )
			return 
		end
		net.Start( "IGForums_UserNET" )
			net.WriteUInt( IGFORUMS_UNBANUSER, 16 )
			net.WriteUInt( userListTable[ selectedLine ].userID, 32 )
		net.SendToServer( )
	end, self.dContentFrame:GetWide( ) * 0.8, self.dContentFrame:GetTall( ) * 0.65 )
	local logsButton = self:CreateButton( "VIEW LOGS", "IGForums_CategoryDesc", logsMaterial, function( pnl )
		self:OpenLogViewer( )
	end, self.dContentFrame:GetWide( ) * 0.4, self.dContentFrame:GetTall( ) * 0.95 )
	local backButton = self:CreateButton( "GO BACK", "IGForums_CategoryDesc", backMaterial, function( pnl )
		self:GenerateCategories( )
	end, self.dContentFrame:GetWide( ) * 0.6, self.dContentFrame:GetTall( ) * 0.95 )
end

function PANEL:OpenCategoryCreator( )
	self.isNotViewing = true
	self:ClearContentFrame( )
	self.dCloseButton:offsetPos( self:GetWide( ) * 0.125, 0 )
	self.dRefreshButton:offsetPos( -( self:GetWide( ) * 0.125 ), 0 )
	local titleTextEntry = vgui.Create( "DTextEntry", self.dContentFrame )
	titleTextEntry:SetSize( self.dContentFrame:GetWide( ) * 0.7, self.dContentFrame:GetTall( ) * 0.05 )
	table.insert( self.dContentFrame.contentChildren, titleTextEntry )
	titleTextEntry:AlignTop( self.dContentFrame:GetTall( ) * 0.07 )
	titleTextEntry:CenterHorizontal( )
	titleTextEntry:SetFont( "IGForums_TextEntryFont" )
	local descTextEntry = vgui.Create( "DTextEntry", self.dContentFrame )
	descTextEntry:SetSize( self.dContentFrame:GetWide( ) * 0.7, self.dContentFrame:GetTall( ) * 0.125 )
	descTextEntry:AlignTop( self.dContentFrame:GetTall( ) * 0.19 )
	descTextEntry:CenterHorizontal( )
	descTextEntry:SetMultiline( true )
	descTextEntry:SetFont( "IGForums_TextEntryFont" )
	table.insert( self.dContentFrame.contentChildren, descTextEntry )
	local dScrollPanel = vgui.Create( "DScrollPanel", self.dContentFrame )
	dScrollPanel:SetSize( self.dContentFrame:GetWide( ) * 0.7, self.dContentFrame:GetTall( ) * 0.45 )
	dScrollPanel:SetPos( 0, self.dContentFrame:GetTall( ) * 0.37 )
	dScrollPanel:CenterHorizontal( )
	local dIconLayout = vgui.Create( "DIconLayout", dScrollPanel )
	dIconLayout:SetSize( dScrollPanel:GetWide( ), dScrollPanel:GetTall( ) )
	dIconLayout:SetPos( 0, 0 )
	dIconLayout:SetSpaceX( 5 )
	dIconLayout:SetSpaceY( 5 )
	table.insert( self.dContentFrame.contentChildren, dScrollPanel )
	for index, iconTbl in pairs ( LocalPlayer( ).IGForums.Icons ) do
		local iconButton = dIconLayout:Add( "DPanel" )
		iconButton.iconPath = iconTbl.path
		iconButton:SetSize( 48, 48 )
		iconButton.Paint = function( pnl, w, h )
			local drawColor = Color( 255, 255, 255, 255 )
			if ( dScrollPanel.selectedIcon == iconTbl.path ) then
				drawColor = Color( 26, 188, 156, 255 )
			--	draw.RoundedBox( 8, 0, 0, w, h, Color( 26, 188, 156, 200 ) )
			--else
			--	draw.RoundedBox( 8, 0, 0, w, h, Color( 236, 240, 241, 255 ) )
			end
			surface.SetDrawColor( drawColor )
			surface.SetMaterial( iconTbl.mat )
			surface.DrawTexturedRect( 0, 0, w, h )
			surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
		end
		iconButton.OnMousePressed = function( pnl, btn )
			dScrollPanel.selectedIcon = iconTbl.path
		end
	end
	table.insert( self.dContentFrame.contentChildren, dIconLayout )
	local centerX, centerY = self.dContentFrame:GetWide( ) * 0.5, self.dContentFrame:GetTall( ) * 0.5
	local buttonWidth = self.dContentFrame:GetWide( ) * 0.2
	local dTitleLabel = vgui.Create( "DLabel", self.dContentFrame )
	dTitleLabel:SetText( "Category Title" )
	dTitleLabel:SetFont( "IGForums_CategoryTitle" )
	dTitleLabel:SizeToContents( )
	dTitleLabel:CenterHorizontal( )
	dTitleLabel:AlignTop( self.dContentFrame:GetTall( ) * 0.01 )
	dTitleLabel:SetTextColor( Color( 255, 255, 255 ) )
	table.insert( self.dContentFrame.contentChildren, dTitleLabel )
	local dDescLabel = vgui.Create( "DLabel", self.dContentFrame )
	dDescLabel:SetText( "Category Description" )
	dDescLabel:SetFont( "IGForums_CategoryTitle" )
	dDescLabel:SizeToContents( )
	dDescLabel:CenterHorizontal( )
	dDescLabel:AlignTop( self.dContentFrame:GetTall( ) * 0.135 )
	dDescLabel:SetTextColor( Color( 255, 255, 255 ) )
	table.insert( self.dContentFrame.contentChildren, dDescLabel )
	local dCreateButton = self:CreateButton( "CREATE", "IGForums_CategoryDesc", acceptMaterial, function( pnl )
		if not ( IGForums:CheckCategorySyntax( dScrollPanel.selectedIcon, titleTextEntry:GetValue( ), descTextEntry:GetValue( ) ) ) then return end
		net.Start( "IGForums_CategoryNET" )
			net.WriteUInt( IGFORUMS_CREATECATEGORY, 16 )
			net.WriteString( titleTextEntry:GetValue( ) )
			net.WriteString( self:ParseTextLines( descTextEntry:GetValue( ) ) )
			net.WriteString( dScrollPanel.selectedIcon or "" )
		net.SendToServer( )
		self:GenerateCategories( )
	end, self.dContentFrame:GetWide( ) * 0.35, self.dContentFrame:GetTall( ) * 0.95 )
	local dBackButton = self:CreateButton( "GO BACK", "IGForums_CategoryDesc", backMaterial, function( pnl )
		self:GenerateCategories( )
	end, self.dContentFrame:GetWide( ) * 0.65, self.dContentFrame:GetTall( ) * 0.95 )
end

function PANEL:GenerateCategories( )
	self:ClearContentFrame( IGFORUMS_GENERATECATEGORIES )
	self:CreateDIconLayout( )
	self.dIconLayout:Clear( )
	self.currentCategory = nil
	self.currentThread = nil
	self.isNotViewing = false
	self.dContentFrame.lastPage = 1
	self.dContentFrame.lastPostPage = 1
	local categoryTable = { }
	for index, category in pairs ( LocalPlayer( ).IGForums.Categories ) do
		table.insert( categoryTable, { categoryID = index, iconID = category.iconID, name = category.name, desc = category.desc, priority = category.priority } )
	end
	table.SortByMember( categoryTable, "priority", true )
	for index, category in ipairs ( categoryTable ) do
		self:CreateCategory( self.dIconLayout, category )
	end
	local userRank = LocalPlayer( ):GetForumsRank( )
	if ( userRank == "admin" ) then
		self:CreateButton( "ADD CATEGORY", "IGForums_CategoryDesc", createCategoryMaterial, function( pnl ) 
			self:OpenCategoryCreator( ) 
		end, self.dContentFrame:GetWide( ) * 0.35, self.dContentFrame:GetTall( ) * 0.95  )
		self:CreateButton( "USER MANAGEMENT", "IGForums_CategoryDesc", userMaterial, function( pnl ) 
			self:OpenUserManagement( )
		end, self.dContentFrame:GetWide( ) * 0.65, self.dContentFrame:GetTall( ) * 0.95  )
	end
	if ( #categoryTable == 0 ) then
		local dPanel = self.dIconLayout:Add( "DPanel" )
		dPanel:SetSize( self.dContentFrame:GetWide( ), self.dContentFrame:GetTall( ) * 0.4 )
		dPanel.Paint = function( pnl, w, h )
			draw.RoundedBox( 16, ( w * 0.5 ) - 32, ( h * 0.6 ), 48, 48, Color( 175, 45, 45, 50 ) )
			surface.SetDrawColor( Color( 175, 75, 75 ) )
			surface.SetMaterial( cancelMaterial )
			surface.DrawTexturedRect( ( w * 0.5 ) - 32, ( h * 0.6 ), 48, 48 )
			draw.SimpleText( "There are no existing categories.", "IGForums_MessageHint", w * 0.5, h * 0.4, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
			surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
		end
		table.insert( self.dContentFrame.contentChildren, dPanel )
	end
end

function PANEL:CreateCategory( dIconLayout, categoryTbl )
	self.dCloseButton:offsetPos( self:GetWide( ) * 0.125, 0 )
	self.dRefreshButton:offsetPos( -( self:GetWide( ) * 0.125 ), 0 )
	local addHeight = ScrH( ) * categoryHeightMulti
	local dCategoryPanel = dIconLayout:Add( "DPanel" )
	dCategoryPanel:SetSize( dIconLayout:GetWide( ), categoryBaseHeight + addHeight )
	dCategoryPanel.OnCursorEntered = function( pnl )
		self.dIconLayout.hoveringPanel = dCategoryPanel
	end
	dCategoryPanel.OnCursorExited = function( pnl )
		self.dIconLayout.hoveringPanel = nil
	end
	dCategoryPanel.Paint = function( pnl, w, h )
		if ( self.dIconLayout.hoveringPanel == pnl ) then
			draw.RoundedBox( 0, 0, 0, w, h, Color( 26, 188, 156, 200 ) )
		else
			draw.RoundedBox( 8, 0, 0, w, h, Color( 255, 255, 255, 200 ) )
		end
	end
	dCategoryPanel.OnMousePressed = function( pnl, btn )
		if ( btn == 107 ) then
			LocalPlayer( ).IGForums.Categories[categoryTbl.categoryID].Threads = { }
			self:GenerateThreads( categoryTbl.categoryID )
			local lastPage = self.dContentFrame.lastPage or 1
			net.Start( "IGForums_CategoryNET" )
				net.WriteUInt( IGFORUMS_REQUESTCATEGORY, 16 )
				net.WriteUInt( categoryTbl.categoryID, 32 )
				net.WriteUInt( lastPage, 16 )
			net.SendToServer( )
		elseif ( btn == 108 and LocalPlayer( ):HasForumPermissions( IGFORUMS_ADMINPERMISSIONS ) ) then
			local popupMenu = DermaMenu( )
			popupMenu:AddOption( "Delete Category", function( )
				net.Start( "IGForums_CategoryNET" )
					net.WriteUInt( IGFORUMS_DELETECATEGORY, 16 )
					net.WriteUInt( categoryTbl.categoryID, 32 )
				net.SendToServer( )
			end )
			popupMenu:AddOption( "Move Up", function( )
				net.Start( "IGForums_CategoryNET" )
					net.WriteUInt( IGFORUMS_CATEGORYMOVEUP, 16 )
					net.WriteUInt( categoryTbl.categoryID, 32 )
				net.SendToServer( )
			end )
			popupMenu:AddOption( "Move Down", function( )
				net.Start( "IGForums_CategoryNET" )
					net.WriteUInt( IGFORUMS_CATEGORYMOVEDOWN, 16 )
					net.WriteUInt( categoryTbl.categoryID, 32 )
				net.SendToServer( )
			end )
			popupMenu:AddOption( "Cancel" )
			popupMenu:Open( )
		end
	end
	local iconPanel = vgui.Create( "DPanel", dCategoryPanel )
	iconPanel:SetSize( 72, 72 )
	local iconW, iconH = iconPanel:GetSize( )
	iconPanel:SetPos( 16, ( dCategoryPanel:GetTall( ) * 0.5 ) - iconH * 0.5 )
	local iconX, iconY = iconPanel:GetPos( )
	iconPanel.Paint = function( pnl, w, h )
		local mat = postMaterial
		if ( LocalPlayer( ).IGForums.Icons[categoryTbl.iconID] ) then
			mat = LocalPlayer( ).IGForums.Icons[categoryTbl.iconID].mat
		end
		draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
		surface.SetMaterial( mat )
	    surface.SetDrawColor( Color( 255, 255, 255 ) )
	    surface.DrawTexturedRect( 12, 12, 48, 48 )
	    surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
	end
	local dTitleLabel = vgui.Create( "DLabel", dCategoryPanel )
	dTitleLabel:SetText( categoryTbl.name )
	dTitleLabel:SetFont( "IGForums_CategoryTitle" )
	dTitleLabel:SetTextColor( Color( 0, 0, 0 ) )
	dTitleLabel:SizeToContents( )
	local dTitleW, dTitleH = dTitleLabel:GetSize( )
	dTitleLabel:SetPos( iconX + ( iconW * 1.1 ), iconY )
	local dTitleX, dTitleY = dTitleLabel:GetPos( )
	local dDescLabel = vgui.Create( "DLabel", dCategoryPanel )
	dDescLabel:SetText( categoryTbl.desc )
	dDescLabel:SetFont( "IGForums_CategoryDesc" )
	dDescLabel:SetTextColor( Color( 0, 0, 0 ) )
	dDescLabel:SizeToContents( )
	local dDescW, dDescH = dDescLabel:GetSize( )
	dDescLabel:SetPos( dTitleX * 0.975, dTitleY + dTitleH )
end

function PANEL:OpenThreadCreator( categoryID )
	self.isNotViewing = true
	self:ClearContentFrame( )
	local titleTextEntry = vgui.Create( "DTextEntry", self.dContentFrame )
	titleTextEntry:SetSize( self.dContentFrame:GetWide( ) * 0.7, self.dContentFrame:GetTall( ) * 0.05 )
	table.insert( self.dContentFrame.contentChildren, titleTextEntry )
	titleTextEntry:AlignTop( self.dContentFrame:GetTall( ) * 0.07 )
	titleTextEntry:CenterHorizontal( )
	titleTextEntry:SetFont( "IGForums_TextEntryFont" )
	local contentTextEntry = vgui.Create( "DTextEntry", self.dContentFrame )
	contentTextEntry:SetSize( self.dContentFrame:GetWide( ) * 0.7, self.dContentFrame:GetTall( ) * 0.185 )
	contentTextEntry:AlignTop( self.dContentFrame:GetTall( ) * 0.19 )
	contentTextEntry:CenterHorizontal( )
	contentTextEntry:SetMultiline( true )
	contentTextEntry:SetFont( "IGForums_TextEntryFont" )
	table.insert( self.dContentFrame.contentChildren, contentTextEntry )
	local dScrollPanel = vgui.Create( "DScrollPanel", self.dContentFrame )
	dScrollPanel:SetSize( self.dContentFrame:GetWide( ) * 0.7, self.dContentFrame:GetTall( ) * 0.4 )
	dScrollPanel:SetPos( 0, self.dContentFrame:GetTall( ) * 0.405 )
	dScrollPanel:CenterHorizontal( )
	local dIconLayout = vgui.Create( "DIconLayout", dScrollPanel )
	dIconLayout:SetSize( dScrollPanel:GetWide( ), dScrollPanel:GetTall( ) )
	dIconLayout:SetPos( 0, 0 )
	dIconLayout:SetSpaceX( 5 )
	dIconLayout:SetSpaceY( 5 )
	table.insert( self.dContentFrame.contentChildren, dScrollPanel )
	for index, iconTbl in pairs ( LocalPlayer( ).IGForums.Icons ) do
		local iconButton = dIconLayout:Add( "DPanel" )
		iconButton.iconPath = iconTbl.path
		iconButton:SetSize( 48, 48 )
		iconButton.Paint = function( pnl, w, h )
			local drawColor = Color( 255, 255, 255 )
			if ( dScrollPanel.selectedIcon == iconTbl.path ) then
				drawColor = Color( 26, 188, 156 )
			end
			surface.SetDrawColor( drawColor )
			surface.SetMaterial( iconTbl.mat )
			surface.DrawTexturedRect( 0, 0, w, h )
			surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
		end
		iconButton.OnMousePressed = function( pnl, btn )
			dScrollPanel.selectedIcon = iconTbl.path
		end
	end
	table.insert( self.dContentFrame.contentChildren, dIconLayout )
	local dLockedCheckBox, dStickyCheckBox
	local userRank = LocalPlayer( ):GetForumsRank( )
	if ( userRank == "admin" ) then
		dLockedCheckBox = vgui.Create( "DCheckBox", self.dContentFrame )
		dLockedCheckBox:SetValue( 0 )
		dLockedCheckBox:SetPos( self.dContentFrame:GetWide( ) * 0.6, self.dContentFrame:GetTall( ) * 0.0325 )
		table.insert( self.dContentFrame.contentChildren, dLockedCheckBox )
		local lockedCBoxX, lockedCBoxY = dLockedCheckBox:GetPos( )
		local dIsLockedLabel = vgui.Create( "DLabel", self.dContentFrame )
		dIsLockedLabel:SetText( "Locked" )
		dIsLockedLabel:SetFont( "IGForums_CategoryDesc" )
		dIsLockedLabel:SetPos( lockedCBoxX + 16, lockedCBoxY )
		dIsLockedLabel:SetTextColor( Color( 255, 255, 255 ) )
		table.insert( self.dContentFrame.contentChildren, dIsLockedLabel )
		dStickyCheckBox = vgui.Create( "DCheckBox", self.dContentFrame )
		dStickyCheckBox:SetValue( 0 )
		dStickyCheckBox:SetPos( self.dContentFrame:GetWide( ) * 0.72, self.dContentFrame:GetTall( ) * 0.0325 )
		table.insert( self.dContentFrame.contentChildren, dStickyCheckBox )
		local stickyCBoxX, stickyCBoxY = dStickyCheckBox:GetPos( )
		local dIsStickyLabel = vgui.Create( "DLabel", self.dContentFrame )
		dIsStickyLabel:SetText( "Stickied" )
		dIsStickyLabel:SetFont( "IGForums_CategoryDesc" )
		dIsStickyLabel:SetPos( stickyCBoxX + 16, stickyCBoxY )
		dIsStickyLabel:SetTextColor( Color( 255, 255, 255 ) )
		table.insert( self.dContentFrame.contentChildren, dIsStickyLabel )
	end
	local centerX, centerY = self.dContentFrame:GetWide( ) * 0.5, self.dContentFrame:GetTall( ) * 0.5
	local buttonWidth = self.dContentFrame:GetWide( ) * 0.2
	local dTitleLabel = vgui.Create( "DLabel", self.dContentFrame )
	dTitleLabel:SetText( "Thread Title" )
	dTitleLabel:SetFont( "IGForums_CategoryTitle" )
	dTitleLabel:SizeToContents( )
	dTitleLabel:CenterHorizontal( )
	dTitleLabel:AlignTop( self.dContentFrame:GetTall( ) * 0.025 )
	dTitleLabel:SetTextColor( Color( 255, 255, 255 ) )
	table.insert( self.dContentFrame.contentChildren, dTitleLabel )
	local dDescLabel = vgui.Create( "DLabel", self.dContentFrame )
	dDescLabel:SetText( "Thread Contents" )
	dDescLabel:SetFont( "IGForums_CategoryTitle" )
	dDescLabel:SizeToContents( )
	dDescLabel:CenterHorizontal( )
	dDescLabel:AlignTop( self.dContentFrame:GetTall( ) * 0.135 )
	dDescLabel:SetTextColor( Color( 255, 255, 255 ) )
	table.insert( self.dContentFrame.contentChildren, dDescLabel )
	local dPostButton = self:CreateButton( "POST", "IGForums_CategoryDesc", acceptMaterial, function( pnl )
		if not ( IGForums:CheckThreadSyntax( dScrollPanel.selectedIcon, titleTextEntry:GetValue( ), contentTextEntry:GetValue( ) ) ) then return end
		local isLocked = false
		local isSticky = false
		if ( IsValid( dLockedCheckBox ) ) then
			isLocked = dLockedCheckBox:GetChecked( )
		end
		if ( IsValid( dStickyCheckBox ) ) then
			isSticky = dStickyCheckBox:GetChecked( )
		end
		net.Start( "IGForums_ThreadNET" )
			net.WriteUInt( IGFORUMS_CREATETHREAD, 16 )
			net.WriteUInt( categoryID, 32 )
			net.WriteString( titleTextEntry:GetValue( ) )
			net.WriteString( contentTextEntry:GetValue( ) )
			net.WriteString( dScrollPanel.selectedIcon or "" )
			net.WriteBit( isLocked )
			net.WriteBit( isSticky )
		net.SendToServer( )
		self:GenerateThreads( categoryID )
	end, self.dContentFrame:GetWide( ) * 0.35, self.dContentFrame:GetTall( ) * 0.95 )
	local dBackButton = self:CreateButton( "GO BACK", "IGForums_CategoryDesc", backMaterial, function( pnl )
		self:GenerateThreads( categoryID )
	end, self.dContentFrame:GetWide( ) * 0.65, self.dContentFrame:GetTall( ) * 0.95 )
end

function PANEL:GenerateThreads( categoryID )
	self:ClearContentFrame( IGFORUMS_GENERATETHREADS )
	self:CreateDIconLayout( )
	self.dIconLayout:Clear( )
	self.currentCategory = categoryID
	self.currentThread = nil
	self.isNotViewing = false
	self.dContentFrame.lastPostPage = 1
	self.dCloseButton:offsetPos( self:GetWide( ) * 0.125, 0 )
	self.dRefreshButton:offsetPos( -( self:GetWide( ) * 0.125 ), 0 )
	local threadTable = { }
	local stickyThreadTable = { }
	if not ( LocalPlayer( ).IGForums.Categories[ categoryID ] ) then
		self:GenerateCategories( )
		return
	end
	for index, thread in pairs ( LocalPlayer( ).IGForums.Categories[categoryID].Threads or { } ) do
		if ( thread.sticky ) then
			table.insert( stickyThreadTable, { threadID = index, iconID = thread.iconID, name = thread.name, userID = thread.userID, postDate = thread.postDate, lastPost = thread.lastPost, text = thread.text, locked = thread.locked, sticky = thread.sticky, postCount = thread.postCount } )
		else
			table.insert( threadTable, { threadID = index, iconID = thread.iconID, name = thread.name, userID = thread.userID, postDate = thread.postDate, lastPost = thread.lastPost, text = thread.text, locked = thread.locked, sticky = thread.sticky, postCount = thread.postCount } )
		end
	end
	table.SortByMember( stickyThreadTable, "postDate", false )
	for index, thread in ipairs ( stickyThreadTable ) do
		self:CreateThread( self.dIconLayout, thread, categoryID )
	end
	table.SortByMember( threadTable, "postDate", false )
	for index, thread in ipairs ( threadTable ) do
		self:CreateThread( self.dIconLayout, thread, categoryID )
	end
	if ( #threadTable == 0 and #stickyThreadTable == 0 ) then
		local dPanel = self.dIconLayout:Add( "DPanel" )
		dPanel:SetSize( self.dIconLayout:GetWide( ), self.dContentFrame:GetTall( ) * 0.4 )
		dPanel.Paint = function( pnl, w, h )
			draw.RoundedBox( 16, ( w * 0.5 ) - 32, ( h * 0.6 ), 48, 48, Color( 175, 45, 45, 50 ) )
			surface.SetDrawColor( Color( 175, 75, 75 ) )
			surface.SetMaterial( cancelMaterial )
			surface.DrawTexturedRect( ( w * 0.5 ) - 32, ( h * 0.6 ), 48, 48 )
			draw.SimpleText( "There are no threads in this category.", "IGForums_MessageHint", w * 0.5, h * 0.4, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
			surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
		end
		table.insert( self.dContentFrame.contentChildren, dPanel )
	end
	if ( #threadTable ~= 0 or #stickyThreadTable ~= 0 ) then
		local pageAmount = LocalPlayer( ).IGForums.Categories[categoryID].pageAmount or 1
		local lastPage = self.dContentFrame.lastPage or 1
		local pageComboBox = vgui.Create( "DComboBox", self.dContentFrame )
		pageComboBox:SetSize( self.dContentFrame:GetWide( ) * 0.1, self.dContentFrame:GetTall( ) * 0.05 )
		pageComboBox:AlignRight( self.dContentFrame:GetWide( ) * 0.05 )
		pageComboBox:AlignTop( self.dContentFrame:GetTall( ) * 0.025 )
		for i=1, pageAmount do
			pageComboBox:AddChoice( i )
		end
		pageComboBox.OnSelect = function( pnl, index, value, data )
			if ( value == lastPage ) then return end
			LocalPlayer( ).IGForums.Categories[categoryID].Threads = { }
			self.dContentFrame.lastPage = value
			net.Start( "IGForums_CategoryNET" )
				net.WriteUInt( IGFORUMS_REQUESTCATEGORY, 16 )
				net.WriteUInt( categoryID, 32 )
				net.WriteUInt( value, 16 )
			net.SendToServer( )
		end
		pageComboBox:SetValue( math.Clamp( lastPage, 1, pageAmount ) )
		table.insert( self.dContentFrame.contentChildren, pageComboBox )
		local pageComboBoxX, pageComboBoxY = pageComboBox:GetPos( )
		local pageComboBoxLabel = vgui.Create( "DLabel", self.dContentFrame )
		pageComboBoxLabel:SetText( "Page: " )
		pageComboBoxLabel:SetFont( "IGForums_CategoryTitle" )
		pageComboBoxLabel:SetTextColor( Color( 255, 255, 255 ) )
		pageComboBoxLabel:SizeToContents( )
		local pageComboBoxLabelW, pageComboBoxLabelH = pageComboBoxLabel:GetSize( )
		pageComboBoxLabel:SetPos( pageComboBoxX - pageComboBoxLabelW, pageComboBoxY * 0.8 )
		table.insert( self.dContentFrame.contentChildren, pageComboBoxLabel )
	end
	local centerX, centerY = self.dContentFrame:GetWide( ) * 0.5, self.dContentFrame:GetTall( ) * 0.5
	local buttonWidth = self.dContentFrame:GetWide( ) * 0.2
	local dPostThreadButton = self:CreateButton( "POST THREAD", "IGForums_CategoryDesc", postMaterial, function( pnl )
		self:OpenThreadCreator( categoryID )
	end, self.dContentFrame:GetWide( ) * 0.35, self.dContentFrame:GetTall( ) * 0.95 )
	local dBackButton = self:CreateButton( "GO BACK", "IGForums_CategoryDesc", backMaterial, function( pnl )
		self:GenerateCategories( )
	end, self.dContentFrame:GetWide( ) * 0.65, self.dContentFrame:GetTall( ) * 0.95 )
end

function PANEL:CreateThread( dIconLayout, threadTbl, categoryID )
	local addHeight = ScrH( ) * threadHeightMulti
	local dThreadPanel = dIconLayout:Add( "DPanel" )
	dThreadPanel:SetSize( dIconLayout:GetWide( ), threadBaseHeight + addHeight )
	dThreadPanel.OnCursorEntered = function( pnl )
		self.dIconLayout.hoveringPanel = dThreadPanel
	end
	dThreadPanel.OnCursorExited = function( pnl )
		self.dIconLayout.hoveringPanel = nil
	end
	dThreadPanel.Paint = function( pnl, w, h )
		if ( self.dIconLayout.hoveringPanel == pnl ) then
			draw.RoundedBox( 0, 0, 0, w, h, Color( 26, 188, 156, 200 ) )
		else
			draw.RoundedBox( 0, 0, 0, w, h, Color( 236, 240, 241, 255 ) )
		end
	end
	dThreadPanel.OnMousePressed = function( pnl, btn )
		if ( btn == 107 ) then
			LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadTbl.threadID].Posts = { }
			net.Start( "IGForums_ThreadNET" )
				net.WriteUInt( IGFORUMS_REQUESTTHREAD, 16 )
				net.WriteUInt( threadTbl.threadID, 32 )
				net.WriteUInt( self.dContentFrame.lastPostPage or 1, 16 )
			net.SendToServer( )
			self:GeneratePosts( categoryID, threadTbl.threadID )
		elseif ( btn == 108 and LocalPlayer( ):GetForumsRank( ) == "admin" ) then
			local popupMenu = DermaMenu( )
			popupMenu:AddOption( "Delete Thread", function( )
				net.Start( "IGForums_ThreadNET" )
					net.WriteUInt( IGFORUMS_DELETETHREAD, 16 )
					net.WriteUInt( threadTbl.threadID, 32 )
				net.SendToServer( )
			end )
			popupMenu:AddOption( "Cancel" )
			popupMenu:Open( )
		end
	end
	local iconPanel = vgui.Create( "DPanel", dThreadPanel )
	iconPanel:SetSize( 72, 72 )
	if ( scrW < 1024 and scrH < 768 ) then
		iconPanel:SetSize( 48, 48 )
	end
	local iconW, iconH = iconPanel:GetSize( )
	iconPanel:SetPos( 16, ( dThreadPanel:GetTall( ) * 0.5 ) - iconH * 0.5 )
	local iconX, iconY = iconPanel:GetPos( )
	iconPanel.Paint = function( pnl, w, h )
		local mat = postMaterial
		if ( LocalPlayer( ).IGForums.Icons[threadTbl.iconID] ) then
			mat = LocalPlayer( ).IGForums.Icons[threadTbl.iconID].mat
		end
		draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 255 ) )
		surface.SetMaterial( mat )
	    surface.SetDrawColor( Color( 255, 255, 255 ) )
	    surface.DrawTexturedRect( 12, 12, 48, 48 )
	    surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
	end
	local dTitleLabel = vgui.Create( "DLabel", dThreadPanel )
	dTitleLabel:SetText( threadTbl.name )
	dTitleLabel:SetFont( "IGForums_CategoryTitle" )
	dTitleLabel:SetTextColor( Color( 0, 0, 0 ) )
	dTitleLabel:SizeToContents( )
	dTitleLabel:SetPos( iconX + ( iconW * 1.1 ), iconY )
	local lblX, lblY = dTitleLabel:GetPos( )
	local dAuthorLabel = vgui.Create( "DLabel", dThreadPanel )
	dAuthorLabel:SetText( "Author: " )
	dAuthorLabel:SetFont( "IGForums_NameLabel" )
	dAuthorLabel:SetTextColor( Color( 0, 0, 0 ) )
	dAuthorLabel:SizeToContents( )
	local lblW, lblH = dAuthorLabel:GetSize( )
	dAuthorLabel:SetPos( lblX, lblY + ( lblH * 1.1 ) )
	local userRank = GetRankByID( threadTbl.userID )
	local authorLabelX, authorLabelY = dAuthorLabel:GetPos( )
	local authorLabelW, authorLabelH = dAuthorLabel:GetSize( )
	local dNameLabel = vgui.Create( "DLabel", dThreadPanel )
	dNameLabel:SetText( LocalPlayer( ).IGForums.Users[ threadTbl.userID ].name )
	dNameLabel:SetFont( "IGForums_NameLabel" )
	dNameLabel:SetTextColor( ForumsConfig.Ranks[userRank].color )
	dNameLabel:SizeToContents( )
	lblW, lblH = dNameLabel:GetSize( )
	dNameLabel:SetPos( authorLabelX + authorLabelW, authorLabelY )
	local dDateLabel = vgui.Create( "DLabel", dThreadPanel )
	dDateLabel:SetText( "Post Date: " .. os.date( "%a %b %d %I:%M%p", threadTbl.postDate ) )
	dDateLabel:SetFont( "IGForums_CategoryDesc" )
	dDateLabel:SetTextColor( Color( 0, 0, 0 ) )
	dDateLabel:SizeToContents( )
	lblW, lblH = dDateLabel:GetSize( )
	dDateLabel:SetPos( authorLabelX, authorLabelY + ( authorLabelH ) )
	local dDateLabelX, dDateLabelY = dDateLabel:GetPos( )
	local dLastPostLabel = vgui.Create( "DLabel", dThreadPanel )
	dLastPostLabel:SetText( "Last Post: " .. os.date( "%a %b %d %I:%M%p", threadTbl.lastPost ) )
	dLastPostLabel:SetFont( "IGForums_CategoryDesc" )
	dLastPostLabel:SetTextColor( Color( 0, 0, 0 ) )
	dLastPostLabel:SizeToContents( )
	local dLastPostLabelW, dLastPostLabelH = dLastPostLabel:GetSize( )
	dLastPostLabel:SetPos( ( dThreadPanel:GetWide( ) * 0.95 ) - dLastPostLabelW, authorLabelY )
	local dLastPostLabelX, dLastPostLabelY = dLastPostLabel:GetPos( )
	local dPostCountLabel = vgui.Create( "DLabel", dThreadPanel )
	dPostCountLabel:SetText( "Post Count: " .. ( threadTbl.postCount or 0 ) )
	dPostCountLabel:SetFont( "IGForums_CategoryDesc" )
	dPostCountLabel:SetTextColor( Color( 0, 0, 0 ) )
	dPostCountLabel:SizeToContents( )
	local dPostCountLabelX, dPostCountLabelY = dPostCountLabel:GetPos( )
	local dPostCountLabelW, dPostCountLabelH = dPostCountLabel:GetSize( )
	dPostCountLabel:SetPos( ( dThreadPanel:GetWide( ) * 0.95 ) - dPostCountLabelW, dDateLabelY )
	if ( threadTbl.locked ) then
		local lockedPanel = vgui.Create( "DPanel", dThreadPanel )
		lockedPanel:SetSize( 32, 32 )
		lockedPanel:SetPos( 0, dPostCountLabelY + dPostCountLabelH + 36 )
		lockedPanel:AlignRight( 32 )
		lockedPanel.Paint = function( pnl, w, h )
			surface.SetMaterial( lockMaterial )
			surface.SetDrawColor( Color( 255, 255, 255 ) )
			surface.DrawTexturedRect( 0, 0, w, h )
			surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
		end
	end
end

function PANEL:OpenPostCreator( categoryID, threadID )
	self.isNotViewing = true
	self:ClearContentFrame( )
	self:CreateAuthorPost( nil, categoryID, threadID, true )
	self.dCloseButton:offsetPos( self:GetWide( ) * 0.125, 0 )
	self.dRefreshButton:offsetPos( -( self:GetWide( ) ) * 0.125, 0 )
	local centerX, centerY = self.dContentFrame:GetWide( ) * 0.5, self.dContentFrame:GetTall( ) * 0.5
	local buttonWidth = self.dContentFrame:GetWide( ) * 0.2
	local dContentTextEntry = vgui.Create( "DTextEntry", self.dContentFrame )
	dContentTextEntry:SetMultiline( true )
	dContentTextEntry:SetSize( self.dContentFrame:GetWide( ) * 0.9, self.dContentFrame:GetTall( ) * 0.3 )
	dContentTextEntry:CenterHorizontal( )
	dContentTextEntry:AlignBottom( self.dContentFrame:GetTall( ) * 0.25 )
	dContentTextEntry:FocusNext( )
	dContentTextEntry:RequestFocus( )
	dContentTextEntry:SetFont( "IGForums_TextEntryFont" )
	table.insert( self.dContentFrame.contentChildren, dContentTextEntry )
	local dReplyButton = self:CreateButton( "POST", "IGForums_CategoryDesc", acceptMaterial, function( pnl )
		if not ( IGForums:CheckPostSyntax( dContentTextEntry:GetValue( ) ) ) then return end
		net.Start( "IGForums_ThreadNET" )
			net.WriteUInt( IGFORUMS_CREATEPOST, 16 )
			net.WriteUInt( threadID, 32 )
			net.WriteString( dContentTextEntry:GetValue( ) )
			net.WriteUInt( self.dContentFrame.lastPostPage or 1, 16 )
		net.SendToServer( )
		self:GeneratePosts( categoryID, threadID )
	end, self.dContentFrame:GetWide( ) * 0.35, self.dContentFrame:GetTall( ) * 0.95 )
	local dBackButton = self:CreateButton( "GO BACK", "IGForums_CategoryDesc", backMaterial, function( pnl )
		self:GeneratePosts( categoryID, threadID )
	end, self.dContentFrame:GetWide( ) * 0.65, self.dContentFrame:GetTall( ) * 0.95 )
end

function PANEL:GeneratePosts( categoryID, threadID )
	self:ClearContentFrame( IGFORUMS_GENERATEPOSTS )
	self:CreateDIconLayout( )
	self.dIconLayout:Clear( )
	self.currentCategory = categoryID
	self.currentThread = threadID
	self.isNotViewing = false
	self.dCloseButton:offsetPos( self:GetWide( ) * 0.25, 0 )
	self.dRefreshButton:offsetPos( -( self:GetWide( ) ) * 0.25, 0 )
	if not ( LocalPlayer( ).IGForums.Categories[ categoryID ] ) then
		self:GenerateCategories( )
		return
	end
	if not ( LocalPlayer( ).IGForums.Categories[ categoryID ].Threads[ threadID ] ) then
		self:GenerateCategories( )
		return
	end
	local postsTable = { }
	for index, post in pairs ( LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].Posts or { } ) do
		table.insert( postsTable, { categoryID = categoryID, threadID = threadID, postID = index, userID = post.userID, postDate = post.postDate, text = post.text } )
	end
	self:CreateAuthorPost( self.dIconLayout, categoryID, threadID )
	table.SortByMember( postsTable, "postDate", true )
	for index, post in ipairs ( postsTable ) do
		self:CreatePost( self.dIconLayout, post, index )
	end
	local pageAmount = LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].pageAmount or 1
	local pageComboBox = vgui.Create( "DComboBox", self.dContentFrame )
	pageComboBox:SetSize( self.dContentFrame:GetWide( ) * 0.1, self.dContentFrame:GetTall( ) * 0.05 )
	pageComboBox:AlignRight( self.dContentFrame:GetWide( ) * 0.05 )
	pageComboBox:AlignTop( self.dContentFrame:GetTall( ) * 0.025 )
	for i=1, pageAmount do
		pageComboBox:AddChoice( i )
	end
	pageComboBox.OnSelect = function( pnl, index, value, data )
		LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].Posts = { }
		self.dContentFrame.lastPostPage = value
		net.Start( "IGForums_ThreadNET" )
			net.WriteUInt( IGFORUMS_REQUESTTHREAD, 16 )
			net.WriteUInt( threadID, 32 )
			net.WriteUInt( value, 16 )
		net.SendToServer( )
	end
	local lastPage = self.dContentFrame.lastPostPage or 1
	pageComboBox:SetValue( math.Clamp( lastPage, 1, pageAmount ) )
	table.insert( self.dContentFrame.contentChildren, pageComboBox )
	local centerX, centerY = self.dContentFrame:GetWide( ) * 0.5, self.dContentFrame:GetTall( ) * 0.5
	local pageComboBoxX, pageComboBoxY = pageComboBox:GetPos( )
	local pageComboBoxLabel = vgui.Create( "DLabel", self.dContentFrame )
	pageComboBoxLabel:SetText( "Page: " )
	pageComboBoxLabel:SetFont( "IGForums_CategoryTitle" )
	pageComboBoxLabel:SetTextColor( Color( 255, 255, 255 ) )
	pageComboBoxLabel:SizeToContents( )
	local pageComboBoxLabelW, pageComboBoxLabelH = pageComboBoxLabel:GetSize( )
	pageComboBoxLabel:SetPos( pageComboBoxX - pageComboBoxLabelW, pageComboBoxY * 0.8 )
	table.insert( self.dContentFrame.contentChildren, pageComboBoxLabel )
	local buttonWidth = self.dContentFrame:GetWide( ) * 0.2
	local isLocked = LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].locked
	local isSticky = LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID].sticky
	local lockButtonText = "UNLOCK"
	local lockButtonMaterial = unlockMaterial
	local stickyButtonText = "UNSTICKY"
	local stickyButtonMaterial = unstickyMaterial
	if not ( isLocked ) then
		lockButtonText = "LOCK"
		lockButtonMaterial = lockMaterial
		local dReplyButton = self:CreateButton( "REPLY", "IGForums_CategoryDesc", replyMaterial, function( pnl )
			self:OpenPostCreator( categoryID, threadID )
		end, self.dContentFrame:GetWide( ) * 0.4, self.dContentFrame:GetTall( ) * 0.95 )
	end
	if not ( isSticky ) then
		stickyButtonText = "STICKY"
		stickyButtonMaterial = stickyMaterial
	end
	local backButtonPos = self.dContentFrame:GetWide( ) * 0.6
	if ( isLocked ) then backButtonPos = self.dContentFrame:GetWide( ) * 0.5 end
	local dBackButton = self:CreateButton( "GO BACK", "IGForums_CategoryDesc", backMaterial, function( pnl )
		self:GenerateThreads( categoryID )
	end, backButtonPos, self.dContentFrame:GetTall( ) * 0.95 )
	if ( LocalPlayer( ):GetForumsRank( ) == "admin" ) then
		local lockButtonPos = self.dContentFrame:GetWide( ) * 0.2
		local stickyButtonPos = self.dContentFrame:GetWide( ) * 0.8
		self.dCloseButton:offsetPos( self:GetWide( ) * 0.05, 0 )
		self.dRefreshButton:offsetPos( -( self:GetWide( ) ) * 0.05, 0 )
		if ( backButtonPos == self.dContentFrame:GetWide( ) * 0.5 ) then
			lockButtonPos = self.dContentFrame:GetWide( ) * 0.3
			stickyButtonPos = self.dContentFrame:GetWide( ) * 0.7
			self.dCloseButton:offsetPos( self:GetWide( ) * 0.135, 0 )
			self.dRefreshButton:offsetPos( -( self:GetWide( ) ) * 0.135, 0 )
		end
		local dLockButton = self:CreateButton( lockButtonText, "IGForums_CategoryDesc", lockButtonMaterial, function( pnl )
			net.Start( "IGForums_ThreadNET" )
				net.WriteUInt( IGFORUMS_TOGGLETHREADLOCK, 16 )
				net.WriteUInt( threadID, 32 )
			net.SendToServer( )
		end, lockButtonPos, self.dContentFrame:GetTall( ) * 0.95 )
		local dStickyButton = self:CreateButton( stickyButtonText, "IGForums_CategoryDesc", stickyButtonMaterial, function( pnl )
			net.Start( "IGForums_ThreadNET" )
				net.WriteUInt( IGFORUMS_TOGGLETHREADSTICKY, 16 )
				net.WriteUInt( threadID, 32 )
			net.SendToServer( )
		end, stickyButtonPos, self.dContentFrame:GetTall( ) * 0.95 )
	end
end

function PANEL:CreateAuthorPost( dIconLayout, categoryID, threadID, dontParent )
	local threadTable = LocalPlayer( ).IGForums.Categories[categoryID].Threads[threadID]
	local addHeight = ScrH( ) * categoryHeightMulti
	local dAuthorPostPanel
	if ( dontParent ) then
		dAuthorPostPanel = vgui.Create( "DPanel", self.dContentFrame )
		dAuthorPostPanel:SetSize( self.dContentFrame:GetWide( ) * 0.9, categoryBaseHeight + 96 )
		dAuthorPostPanel:CenterHorizontal( )
		dAuthorPostPanel:AlignTop( self.dContentFrame:GetTall( ) * 0.1 )
		table.insert( self.dContentFrame.contentChildren, dAuthorPostPanel )
	else
		dAuthorPostPanel = dIconLayout:Add( "DPanel" )
		dAuthorPostPanel:SetSize( dIconLayout:GetWide( ), categoryBaseHeight + 96 )
	end
	local dTitleLabel = vgui.Create( "DLabel", dAuthorPostPanel )
	dTitleLabel:SetText( threadTable.name )
	dTitleLabel:SetFont( "IGForums_CategoryTitle" )
	dTitleLabel:SetTextColor( Color( 0, 0, 0, 255 ) )
	dTitleLabel:SizeToContents( )
	dTitleLabel:AlignLeft( dAuthorPostPanel:GetWide( ) * 0.05 )
	dTitleLabel:AlignTop( dAuthorPostPanel:GetTall( ) * 0.05 )
	local lblX, lblY = dTitleLabel:GetPos( )
	local lblW, lblH = dTitleLabel:GetSize( )
	local dAuthorLabel = vgui.Create( "DLabel", dAuthorPostPanel )
	dAuthorLabel:SetText( "Author: " )
	dAuthorLabel:SetFont( "IGForums_NameLabel" )
	dAuthorLabel:SetTextColor( Color( 0, 0, 0, 255 ) )
	dAuthorLabel:SizeToContents( )
	dAuthorLabel:SetPos( 0, lblY + ( lblH * 0.9 ) )
	dAuthorLabel:AlignLeft( dAuthorPostPanel:GetWide( ) * 0.05 )
	local userRank = GetRankByID( threadTable.userID )
	local authorLabelX, authorLabelY = dAuthorLabel:GetPos( )
	local authorLabelW, authorLabelH = dAuthorLabel:GetSize( )
	local dNameLabel = vgui.Create( "DLabel", dAuthorPostPanel )
	dNameLabel:SetText( LocalPlayer( ).IGForums.Users[ threadTable.userID ].name )
	dNameLabel:SetFont( "IGForums_NameLabel" )
	dNameLabel:SetTextColor( ForumsConfig.Ranks[userRank].color )
	dNameLabel:SizeToContents( )
	dNameLabel:SetPos( authorLabelX + authorLabelW, authorLabelY )
	local dPostDateLabel = vgui.Create( "DLabel", dAuthorPostPanel )
	dPostDateLabel:SetText( "Post Date: " .. os.date( "%a %b %d %I:%M%p", threadTable.postDate ) )
	dPostDateLabel:SetFont( "IGForums_CategoryDesc" )
	dPostDateLabel:SetTextColor( Color( 0, 0, 0, 255 ) )
	dPostDateLabel:SizeToContents( )
	dPostDateLabel:AlignLeft( dAuthorPostPanel:GetWide( ) * 0.05 )
	dPostDateLabel:AlignTop( dAuthorPostPanel:GetTall( ) * 0.3 )
	local dPostCountLabel = vgui.Create( "DLabel", dAuthorPostPanel )
	dPostCountLabel:SetText( "Posts: " .. ( LocalPlayer( ).IGForums.Users[ threadTable.userID ].postCount or 0 ) )
	dPostCountLabel:SetFont( "IGForums_CategoryDesc" )
	dPostCountLabel:SetTextColor( Color( 0, 0, 0, 255 ) )
	dPostCountLabel:SizeToContents( )
	local dPostCountLabelW, dPostCountLabelH = dPostCountLabel:GetSize( )
	dPostCountLabel:SetPos( ( dAuthorPostPanel:GetWide( ) * 0.95 ) - dPostCountLabelW, lblY )
	local dContentTextEntry = vgui.Create( "DTextEntry", dAuthorPostPanel )
	dContentTextEntry:SetSize( dAuthorPostPanel:GetWide( ) * 0.9, dAuthorPostPanel:GetTall( ) * 0.4 )
	dContentTextEntry:SetMultiline( true )
	dContentTextEntry:SetText( threadTable.text )
	dContentTextEntry:CenterHorizontal( )
	dContentTextEntry:AlignBottom( dAuthorPostPanel:GetTall( ) * 0.15 )
	dContentTextEntry:SetFont( "IGForums_TextEntrySmall" )
	local parsedLines, lineAmt = self:ParseTextLines( threadTable.text )
	if ( lineAmt > 3 or string.len( threadTable.text ) > 300 or #string.Explode( "\n",threadTable.text ) > 3 ) then
		dContentTextEntry:SetVerticalScrollbarEnabled( true )
	end
	dContentTextEntry.OnTextChanged = function( pnl, str )
		pnl:SetText( threadTable.text )
	end
end

function PANEL:CreatePost( dIconLayout, post, postNumber )
	local addHeight = ScrH( ) * postHeightMulti
	local dPostPanel = dIconLayout:Add( "DPanel" )
	dPostPanel:SetSize( dIconLayout:GetWide( ), postBaseHeight + addHeight )
	dPostPanel.OnMousePressed = function( pnl, btn )
		if ( btn == 108 and LocalPlayer( ):GetForumsRank( ) == "admin" ) then
			local popupMenu = DermaMenu( )
			popupMenu:AddOption( "Delete Post", function( )
				net.Start( "IGForums_ThreadNET" )
					net.WriteUInt( IGFORUMS_DELETEPOST, 16 )
					net.WriteUInt( post.postID, 32 )
				net.SendToServer( )
			end )
			popupMenu:AddOption( "Cancel" )
			popupMenu:Open( )
		end
	end
	local dAuthorLabel = vgui.Create( "DLabel", dPostPanel )
	dAuthorLabel:SetText( "Author: " )
	dAuthorLabel:SetFont( "IGForums_NameLabel" )
	dAuthorLabel:SetTextColor( Color( 0, 0, 0 ) )
	dAuthorLabel:SizeToContents( )
	local lblW, lblH = dAuthorLabel:GetSize( )
	dAuthorLabel:SetPos( dPostPanel:GetWide( ) * 0.05, lblH * 0.15 )
	local userRank = GetRankByID( post.userID )
	local authorLabelX, authorLabelY = dAuthorLabel:GetPos( )
	local authorLabelW, authorLabelH = dAuthorLabel:GetSize( )
	local dNameLabel = vgui.Create( "DLabel", dPostPanel )
	dNameLabel:SetText( LocalPlayer( ).IGForums.Users[ post.userID ].name )
	dNameLabel:SetFont( "IGForums_CategoryDesc" )
	dNameLabel:SetTextColor( ForumsConfig.Ranks[userRank].color )
	dNameLabel:SizeToContents( )
	dNameLabel:SetPos( authorLabelX + authorLabelW, authorLabelY )
	local dDateLabel = vgui.Create( "DLabel", dPostPanel )
	dDateLabel:SetText( "Post Date: " .. os.date( "%a %b %d %I:%M%p", post.postDate ) )
	dDateLabel:SetFont( "IGForums_CategoryDesc" )
	dDateLabel:SetTextColor( Color( 0, 0, 0 ) )
	dDateLabel:SizeToContents( )
	lblW, lblH = dDateLabel:GetSize( )
	dDateLabel:SetPos( dPostPanel:GetWide( ) * 0.05, ( authorLabelY + authorLabelH ) - lblH * 0.2 )
	local lblX, lblY = dDateLabel:GetPos( )
	local dPostNumberLabel = vgui.Create( "DLabel", dPostPanel )
	dPostNumberLabel:SetText( "Post #" .. postNumber )
	dPostNumberLabel:SetFont( "IGForums_CategoryDesc" )
	dPostNumberLabel:SetTextColor( Color( 0, 0, 0 ) )
	dPostNumberLabel:SizeToContents( )
	local postNumberTxtW, postNumberTxtH = dPostNumberLabel:GetSize( )
	dPostNumberLabel:SetPos( ( dPostPanel:GetWide( ) * 0.95 ) - ( postNumberTxtW ), authorLabelY )
	local dPostCountLabel = vgui.Create( "DLabel", dPostPanel )
	dPostCountLabel:SetText( "Posts: " .. LocalPlayer( ).IGForums.Users[ post.userID ].postCount or 0 )
	dPostCountLabel:SetFont( "IGForums_CategoryDesc" )
	dPostCountLabel:SetTextColor( Color( 0, 0, 0, 255 ) )
	dPostCountLabel:SizeToContents( )
	local dPostCountLabelW, dPostCountLabelH = dPostCountLabel:GetSize( )
	dPostCountLabel:SetPos( ( dPostPanel:GetWide( ) * 0.95 ) - dPostCountLabelW, lblY )
	local dContentTextEntry = vgui.Create( "DTextEntry", dPostPanel )
	dContentTextEntry:SetSize( dPostPanel:GetWide( ) * 0.9, dPostPanel:GetTall( ) * 0.5 )
	dContentTextEntry:SetMultiline( true )
	dContentTextEntry:SetText( post.text )
	dContentTextEntry:CenterHorizontal( )
	dContentTextEntry:AlignBottom( dPostPanel:GetTall( ) * 0.1 )
	dContentTextEntry:SetFont( "IGForums_TextEntrySmall" )
	local parsedLines, lineAmt = self:ParseTextLines( post.text )
	if ( lineAmt > 3 or string.len( post.text ) > 300 or #string.Explode( "\n", post.text ) > 3 ) then
		dContentTextEntry:SetVerticalScrollbarEnabled( true )
	end
	dContentTextEntry.OnTextChanged = function( pnl, str )
		pnl:SetText( post.text )
	end
end

vgui.Register( "IGForums_Viewer", PANEL, "DFrame" )