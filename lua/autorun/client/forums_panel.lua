local baseWidth, baseHeight = 640, 512
local widthMulti, heightMulti = 0.15, 0.15
local categoryBaseHeight = 64
local categoryHeightMulti = 0.025
local categoryTextBaseSize = 12
local messageHintTextBaseSize = 16
local textEntryTextBaseSize = 14

local blurMaterial = Material( "pp/blurscreen" )
local lockMaterial = Material( "vgui/ingame_forums/icons/locked61.png" )
local unlockMaterial = Material( "vgui/ingame_forums/icons/unlocked46.png" )
local backMaterial = Material( "vgui/ingame_forums/icons/left arrow.png" )
local createCategoryMaterial = Material( "vgui/ingame_forums/icons/book244.png" )
local cancelMaterial = Material( "vgui/ingame_forums/icons/cancel22.png" )
local acceptMaterial = Material( "vgui/ingame_forums/icons/basic14.png" )
local postMaterial = Material( "vgui/ingame_forums/icons/notes27.png" )
local replyMaterial = Material( "vgui/ingame_forums/icons/outbox4.png" )
local userMaterial = Material( "vgui/ingame_forums/icons/profile29.png" )
local rankMaterial = Material( "vgui/ingame_forums/icons/password19.png" )
local deletePostsMaterial = Material( "vgui/ingame_forums/icons/basket30.png" )
local banUserMaterial = Material( "vgui/ingame_forums/icons/caution7.png" )
local unBanUserMaterial = Material( "vgui/ingame_forums/icons/hand226.png" )
local refreshMaterial = Material( "vgui/ingame_forums/icons/refresh62.png" )
local stickyMaterial = Material( "vgui/ingame_forums/icons/pin61.png" )
local unstickyMaterial = Material( "vgui/ingame_forums/icons/message31.png" )
local scrW, scrH = ScrW( ), ScrH( )
local plyMeta = FindMetaTable( "Player" )

// Credits to Willox for the resolution changed hook.
hook.Add( "Initialize", "IGForums_ResolutionInitialize", function( )
	vgui.CreateFromTable {
		Base =  "Panel",
		PerformLayout = function( )
			hook.Run( "ResolutionChanged", ScrW( ), ScrH( ) )
		end
	} : ParentToHUD( )
end )

hook.Add( "ResolutionChanged", "IGForums_ResolutionChanged", function( w, h )
	scrW = w
	scrH = h
	if ( IsValid( LocalPlayer( ).IGForums_Viewer ) ) then
		LocalPlayer( ).IGForums_Viewer:CreateFonts( )
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
	self:CreateFonts( )
	local addWidth, addHeight = scrW * widthMulti, scrH * heightMulti
	self:SetSize( baseWidth + addWidth, baseHeight + addHeight )
	self:Center( )
	self:SetTitle( "" )
	self:ShowCloseButton( false )
	self.currentCategory = nil
	self.currentThread = nil
	self.isNotViewing = false

	local dCloseButton = self:CreateButton( "CLOSE", "IGForums_CategoryDesc", cancelMaterial, function( pnl )
		gui.EnableScreenClicker( false )
		self:Remove( )
	end, self:GetWide( ) * 0.95, self:GetTall( ) * 0.175, self )
	local dRefreshButton = self:CreateButton( "REFRESH", "IGForums_CategoryDesc", refreshMaterial, function( pnl )
		self:RefreshView( )
	end, self:GetWide( ) * 0.95, self:GetTall( ) * 0.28, self )

	self.dMessageBoxPanel = vgui.Create( "DPanel", self )
	self.dMessageBoxPanel:SetSize( self:GetWide( ) * 0.8, self:GetTall( ) * 0.06 )
	self.dMessageBoxPanel:AlignTop( self:GetTall( ) * 0.03 )
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
	self.dContentFrame.Paint = function( pnl, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
	end
	self:GenerateCategories( )
	self:MakePopup( )
end

function PANEL:Paint( w, h )
	// Credits to Chessnut for the screen blur effect.
	local x, y = self:LocalToScreen( 0, 0 )
	surface.SetDrawColor( Color( 255, 255, 255 ) )
	surface.SetMaterial( blurMaterial )
	for i = 1, 3 do
		blurMaterial:SetFloat( "$blur", ( i / 3 ) * 8 )
		blurMaterial:Recompute( )
		render.UpdateScreenEffectTexture( )
		surface.DrawTexturedRect( x * -1, y * -1, ScrW( ), ScrH( ) )
	end
	draw.RoundedBox( 0, 0, 0, w, h, Color( 45, 45, 45, 200 ) )
end

function PANEL:ParseTextLines( text )
	local textTable = string.Explode( " ", text )
	local builtString = ""
	local currentLine = ""
	for index, subString in ipairs( textTable ) do
		if not ( string.len( currentLine ) > 80 ) then
			builtString = builtString .. subString .. " "
			currentLine = currentLine .. subString .. " "
		else
			builtString = builtString .. "\n" .. subString .. " "
			currentLine = ""
		end
	end
	return builtString
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
			self:GeneratePosts( self.currentCategory, self.currentThread )
			if not ( tonumber( self.currentThread ) ) then return end
			net.Start( "IGForums_ThreadNET" )
				net.WriteUInt( IGFORUMS_REQUESTTHREAD, 16 )
				net.WriteUInt( self.currentThread, 32 )
			net.SendToServer( )
		else
			self:GenerateThreads( self.currentCategory )
			if not ( tonumber( self.currentCategory ) ) then return end
			net.Start( "IGForums_CategoryNET" )
				net.WriteUInt( IGFORUMS_REQUESTCATEGORY, 16 )
				net.WriteUInt( self.currentCategory, 32 )
			net.SendToServer( )
		end
	else
		self:GenerateCategories( )
		net.Start( "IGForums_CategoryNET" )
			net.WriteUInt( IGFORUMS_REQUESTCATEGORIES, 16 )
		net.SendToServer( )
	end
end

function PANEL:CreateFonts( )
	surface.CreateFont( "IGForums_CategoryTitle", {
		font = "Segoe UI Semibold", 
		size = categoryTextBaseSize + ScreenScale( 8 ), 
		weight = 500
	} )
	surface.CreateFont( "IGForums_CategoryDesc", {
		font = "Segoe UI", 
		size = categoryTextBaseSize + ScreenScale( 2 ), 
		weight = 500
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

function PANEL:CreateDIconLayout( )
	local dScrollPanel = vgui.Create( "DScrollPanel", self.dContentFrame )
	dScrollPanel:SetSize( self.dContentFrame:GetWide( ) * 0.9, self.dContentFrame:GetTall( ) * 0.7 )
	dScrollPanel:SetPos( self.dContentFrame:GetWide( ) * 0.05, self.dContentFrame:GetTall( ) * 0.1 )
	self.dIconLayout = vgui.Create( "DIconLayout", dScrollPanel )
	self.dIconLayout:SetSize( dScrollPanel:GetWide( ), dScrollPanel:GetTall( ) )
	self.dIconLayout:SetPos( 0, 0 )
	self.dIconLayout:SetSpaceX( 5 )
	self.dIconLayout:SetSpaceY( 5 )
	table.insert( self.dContentFrame.contentChildren, dScrollPanel )
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
		if ( self.dContentFrame and self.dContentFrame.selectedPanel == pnl  ) then
			draw.RoundedBox( 8, 0, 0, w, h, Color( 26, 188, 156, 200 ) )
		else
			draw.RoundedBox( 8, 0, 0, w, h, Color( 236, 240, 241, 255 ) )
		end
		surface.SetDrawColor( Color( 255, 255, 255 ) )
		surface.SetMaterial( buttonMaterial )
		surface.DrawTexturedRect( 0, 0, w, h )
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
		net.Start( "IGForums_UserNET" )
			net.WriteUInt( IGFORUMS_SETRANK, 16 )
			net.WriteUInt( userListTable[ selectedLine ].userID, 32 )
			net.WriteString( selectedRank )
		net.SendToServer( )
	end, self.dContentFrame:GetWide( ) * 0.2, self.dContentFrame:GetTall( ) * 0.65 )
	local setRankButtonX, setRankButtonY = setRankButton:GetPos( )
	local setRankButtonW, setRankButtonH = setRankButton:GetSize( )
	local dRankComboBox = vgui.Create( "DComboBox", self.dContentFrame )
	local dRankComboBoxW, dRankComboBoxH = dRankComboBox:GetSize( )
	dRankComboBox:SetSize( self.dContentFrame:GetWide( ) * 0.1, self.dContentFrame:GetTall( ) * 0.05 )
	dRankComboBox:SetPos( setRankButtonX - ( dRankComboBoxW * 0.1 ), ( setRankButtonY + setRankButtonH ) + dRankComboBoxH * 0.35 )
	dRankComboBox:SetValue( "user" )
	for rankIndex, rankTbl in pairs ( ForumsConfig.Ranks ) do
		dRankComboBox:AddChoice( rankIndex )
	end
	dRankComboBox.OnSelect = function( pnl, index, value, data )
		selectedRank = value
	end
	table.insert( self.dContentFrame.contentChildren, dRankComboBox )
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
	local backButton = self:CreateButton( "GO BACK", "IGForums_CategoryDesc", backMaterial, function( pnl )
		self:GenerateCategories( )
	end, self.dContentFrame:GetWide( ) * 0.5, self.dContentFrame:GetTall( ) * 0.95 )
end

function PANEL:OpenCategoryCreator( )
	self.isNotViewing = true
	self:ClearContentFrame( )
	local titleTextEntry = vgui.Create( "DTextEntry", self.dContentFrame )
	titleTextEntry:SetSize( self.dContentFrame:GetWide( ) * 0.7, self.dContentFrame:GetTall( ) * 0.05 )
	table.insert( self.dContentFrame.contentChildren, titleTextEntry )
	titleTextEntry:AlignTop( self.dContentFrame:GetTall( ) * 0.1 )
	titleTextEntry:CenterHorizontal( )
	titleTextEntry:SetFont( "IGForums_TextEntryFont" )
	local descTextEntry = vgui.Create( "DTextEntry", self.dContentFrame )
	descTextEntry:SetSize( self.dContentFrame:GetWide( ) * 0.7, self.dContentFrame:GetTall( ) * 0.125 )
	descTextEntry:AlignTop( self.dContentFrame:GetTall( ) * 0.22 )
	descTextEntry:CenterHorizontal( )
	descTextEntry:SetMultiline( true )
	descTextEntry:SetFont( "IGForums_TextEntryFont" )
	table.insert( self.dContentFrame.contentChildren, descTextEntry )
	local dScrollPanel = vgui.Create( "DScrollPanel", self.dContentFrame )
	dScrollPanel:SetSize( self.dContentFrame:GetWide( ) * 0.7, self.dContentFrame:GetTall( ) * 0.45 )
	dScrollPanel:SetPos( 0, self.dContentFrame:GetTall( ) * 0.4 )
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
		iconButton:SetSize( 64, 64 )
		iconButton.Paint = function( pnl, w, h )
			if ( dScrollPanel.selectedIcon == iconTbl.path ) then
				draw.RoundedBox( 8, 0, 0, w, h, Color( 26, 188, 156, 200 ) )
			else
				draw.RoundedBox( 8, 0, 0, w, h, Color( 236, 240, 241, 255 ) )
			end
			surface.SetDrawColor( Color( 255, 255, 255 ) )
			surface.SetMaterial( iconTbl.mat )
			surface.DrawTexturedRect( 0, 0, w, h )
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
	dTitleLabel:AlignTop( self.dContentFrame:GetTall( ) * 0.04 )
	table.insert( self.dContentFrame.contentChildren, dTitleLabel )
	local dDescLabel = vgui.Create( "DLabel", self.dContentFrame )
	dDescLabel:SetText( "Category Description" )
	dDescLabel:SetFont( "IGForums_CategoryTitle" )
	dDescLabel:SizeToContents( )
	dDescLabel:CenterHorizontal( )
	dDescLabel:AlignTop( self.dContentFrame:GetTall( ) * 0.165 )
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
	end, self.dContentFrame:GetWide( ) * 0.45, self.dContentFrame:GetTall( ) * 0.95 )
	local dCancelButton = self:CreateButton( "CANCEL", "IGForums_CategoryDesc", cancelMaterial, function( pnl )
		self:GenerateCategories( )
	end, self.dContentFrame:GetWide( ) * 0.55, self.dContentFrame:GetTall( ) * 0.95 )
end

function PANEL:GenerateCategories( )
	self:ClearContentFrame( IGFORUMS_GENERATECATEGORIES )
	self:CreateDIconLayout( )
	self.dIconLayout:Clear( )
	self.currentCategory = nil
	self.currentThread = nil
	self.isNotViewing = false
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
		end, self.dContentFrame:GetWide( ) * 0.4, self.dContentFrame:GetTall( ) * 0.95  )
		self:CreateButton( "USER MANAGEMENT", "IGForums_CategoryDesc", userMaterial, function( pnl ) 
			self:OpenUserManagement( )
		end, self.dContentFrame:GetWide( ) * 0.6, self.dContentFrame:GetTall( ) * 0.95  )
	end
	if ( #categoryTable == 0 ) then
		local dPanel = self.dIconLayout:Add( "DPanel" )
		dPanel:SetSize( self.dIconLayout:GetWide( ), self.dContentFrame:GetTall( ) * 0.3 )
		dPanel.Paint = function( pnl, w, h )
			draw.RoundedBox( 16, ( w * 0.5 ) - 32, ( h * 0.6 ), 64, 64, Color( 175, 45, 45, 50 ) )
			surface.SetDrawColor( Color( 255, 255, 255 ) )
			surface.SetMaterial( cancelMaterial )
			surface.DrawTexturedRect( ( w * 0.5 ) - 32, ( h * 0.6 ), 64, 64 )
			draw.SimpleText( "There are no existing categories.", "IGForums_MessageHint", w * 0.5, h * 0.4, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
		end
		table.insert( self.dContentFrame.contentChildren, dPanel )
	end
end

function PANEL:CreateCategory( dIconLayout, categoryTbl )
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
			draw.RoundedBox( 0, 0, 0, w, h, Color( 236, 240, 241, 255 ) )
		end
	end
	dCategoryPanel.OnMousePressed = function( pnl, btn )
		if ( btn == 107 ) then
			self:GenerateThreads( categoryTbl.categoryID )
			net.Start( "IGForums_CategoryNET" )
				net.WriteUInt( IGFORUMS_REQUESTCATEGORY, 16 )
				net.WriteUInt( categoryTbl.categoryID, 32 )
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
	iconPanel:SetSize( 64, 64 )
	if ( scrW < 1024 and scrH < 768 ) then
		iconPanel:SetSize( 48, 48 )
	end
	local iconX, iconY = iconPanel:GetPos( )
	local iconW, iconH = iconPanel:GetSize( )
	iconPanel:SetPos( 16, ( dCategoryPanel:GetTall( ) * 0.5 ) - iconH * 0.5 )
	iconPanel.Paint = function( pnl, w, h )
		local mat = postMaterial
		if ( LocalPlayer( ).IGForums.Icons[categoryTbl.iconID] ) then
			mat = LocalPlayer( ).IGForums.Icons[categoryTbl.iconID].mat
		end
		draw.RoundedBox( 8, 0, 0, w, h, Color( 189, 195, 199, 100 ) )
		surface.SetMaterial( mat )
	    surface.SetDrawColor( Color( 255, 255, 255 ) )
	    surface.DrawTexturedRect( 0, 0, w, h )
	end
	local dTitleLabel = vgui.Create( "DLabel", dCategoryPanel )
	dTitleLabel:SetText( categoryTbl.name )
	dTitleLabel:SetFont( "IGForums_CategoryTitle" )
	dTitleLabel:SetTextColor( Color( 0, 0, 0 ) )
	dTitleLabel:SizeToContents( )
	dTitleLabel:SetPos( iconX + ( iconW * 1.5 ), dCategoryPanel:GetTall( ) * 0.05 )
	local dDescLabel = vgui.Create( "DLabel", dCategoryPanel )
	dDescLabel:SetText( categoryTbl.desc )
	dDescLabel:SetFont( "IGForums_CategoryDesc" )
	dDescLabel:SetTextColor( Color( 0, 0, 0 ) )
	dDescLabel:SizeToContents( )
	dDescLabel:SetPos( iconX + ( iconW * 1.5 ), dCategoryPanel:GetTall( ) * 0.35 )
end

function PANEL:OpenThreadCreator( categoryID )
	self.isNotViewing = true
	self:ClearContentFrame( )
	local titleTextEntry = vgui.Create( "DTextEntry", self.dContentFrame )
	titleTextEntry:SetSize( self.dContentFrame:GetWide( ) * 0.7, self.dContentFrame:GetTall( ) * 0.05 )
	table.insert( self.dContentFrame.contentChildren, titleTextEntry )
	titleTextEntry:AlignTop( self.dContentFrame:GetTall( ) * 0.1 )
	titleTextEntry:CenterHorizontal( )
	titleTextEntry:SetFont( "IGForums_TextEntryFont" )
	local contentTextEntry = vgui.Create( "DTextEntry", self.dContentFrame )
	contentTextEntry:SetSize( self.dContentFrame:GetWide( ) * 0.7, self.dContentFrame:GetTall( ) * 0.185 )
	contentTextEntry:AlignTop( self.dContentFrame:GetTall( ) * 0.22 )
	contentTextEntry:CenterHorizontal( )
	contentTextEntry:SetMultiline( true )
	contentTextEntry:SetFont( "IGForums_TextEntryFont" )
	table.insert( self.dContentFrame.contentChildren, contentTextEntry )
	local dScrollPanel = vgui.Create( "DScrollPanel", self.dContentFrame )
	dScrollPanel:SetSize( self.dContentFrame:GetWide( ) * 0.7, self.dContentFrame:GetTall( ) * 0.4 )
	dScrollPanel:SetPos( 0, self.dContentFrame:GetTall( ) * 0.435 )
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
		iconButton:SetSize( 64, 64 )
		iconButton.Paint = function( pnl, w, h )
			if ( dScrollPanel.selectedIcon == iconTbl.path ) then
				draw.RoundedBox( 8, 0, 0, w, h, Color( 26, 188, 156, 200 ) )
			else
				draw.RoundedBox( 8, 0, 0, w, h, Color( 236, 240, 241, 255 ) )
			end
			surface.SetDrawColor( Color( 255, 255, 255 ) )
			surface.SetMaterial( iconTbl.mat )
			surface.DrawTexturedRect( 0, 0, w, h )
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
		dLockedCheckBox:SetPos( self.dContentFrame:GetWide( ) * 0.6, self.dContentFrame:GetTall( ) * 0.055 )
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
		dStickyCheckBox:SetPos( self.dContentFrame:GetWide( ) * 0.7, self.dContentFrame:GetTall( ) * 0.055 )
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
	dTitleLabel:AlignTop( self.dContentFrame:GetTall( ) * 0.04 )
	table.insert( self.dContentFrame.contentChildren, dTitleLabel )
	local dDescLabel = vgui.Create( "DLabel", self.dContentFrame )
	dDescLabel:SetText( "Thread Contents" )
	dDescLabel:SetFont( "IGForums_CategoryTitle" )
	dDescLabel:SizeToContents( )
	dDescLabel:CenterHorizontal( )
	dDescLabel:AlignTop( self.dContentFrame:GetTall( ) * 0.165 )
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
			net.WriteString( self:ParseTextLines( contentTextEntry:GetValue( ) ) )
			net.WriteString( dScrollPanel.selectedIcon or "" )
			net.WriteBit( isLocked )
			net.WriteBit( isSticky )
		net.SendToServer( )
		self:GenerateThreads( categoryID )
	end, self.dContentFrame:GetWide( ) * 0.4, self.dContentFrame:GetTall( ) * 0.95 )
	local dCancelButton = self:CreateButton( "CANCEL", "IGForums_CategoryDesc", cancelMaterial, function( pnl )
		self:GenerateThreads( categoryID )
	end, self.dContentFrame:GetWide( ) * 0.6, self.dContentFrame:GetTall( ) * 0.95 )
end

function PANEL:GenerateThreads( categoryID )
	self:ClearContentFrame( IGFORUMS_GENERATETHREADS )
	self:CreateDIconLayout( )
	self.dIconLayout:Clear( )
	self.currentCategory = categoryID
	self.currentThread = nil
	self.isNotViewing = false
	local threadTable = { }
	local stickyThreadTable = { }
	if not ( LocalPlayer( ).IGForums.Categories[ categoryID ] ) then
		self:GenerateCategories( )
		return
	end
	for index, thread in pairs ( LocalPlayer( ).IGForums.Categories[categoryID].Threads or { } ) do
		if ( thread.sticky ) then
			table.insert( stickyThreadTable, { threadID = index, iconID = thread.iconID, name = thread.name, userID = thread.userID, postDate = thread.postDate, text = thread.text, locked = thread.locked, sticky = thread.sticky, postCount = thread.postCount } )
		else
			table.insert( threadTable, { threadID = index, iconID = thread.iconID, name = thread.name, userID = thread.userID, postDate = thread.postDate, text = thread.text, locked = thread.locked, sticky = thread.sticky, postCount = thread.postCount } )
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
		dPanel:SetSize( self.dIconLayout:GetWide( ), self.dContentFrame:GetTall( ) * 0.3 )
		dPanel.Paint = function( pnl, w, h )
			draw.RoundedBox( 16, ( w * 0.5 ) - 32, ( h * 0.6 ), 64, 64, Color( 175, 45, 45, 50 ) )
			surface.SetDrawColor( Color( 255, 255, 255 ) )
			surface.SetMaterial( cancelMaterial )
			surface.DrawTexturedRect( ( w * 0.5 ) - 32, ( h * 0.6 ), 64, 64 )
			draw.SimpleText( "There are no threads in this category.", "IGForums_MessageHint", w * 0.5, h * 0.4, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
		end
		table.insert( self.dContentFrame.contentChildren, dPanel )
	end
	local centerX, centerY = self.dContentFrame:GetWide( ) * 0.5, self.dContentFrame:GetTall( ) * 0.5
	local buttonWidth = self.dContentFrame:GetWide( ) * 0.2
	local dPostThreadButton = self:CreateButton( "POST THREAD", "IGForums_CategoryDesc", postMaterial, function( pnl )
		self:OpenThreadCreator( categoryID )
	end, self.dContentFrame:GetWide( ) * 0.4, self.dContentFrame:GetTall( ) * 0.95 )
	local dBackButton = self:CreateButton( "GO BACK", "IGForums_CategoryDesc", backMaterial, function( pnl )
		self:GenerateCategories( )
	end, self.dContentFrame:GetWide( ) * 0.6, self.dContentFrame:GetTall( ) * 0.95 )
end

function PANEL:CreateThread( dIconLayout, threadTbl, categoryID )
	local addHeight = ScrH( ) * categoryHeightMulti
	local dThreadPanel = dIconLayout:Add( "DPanel" )
	dThreadPanel:SetSize( dIconLayout:GetWide( ), categoryBaseHeight + addHeight )
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
			net.Start( "IGForums_ThreadNET" )
				net.WriteUInt( IGFORUMS_REQUESTTHREAD, 16 )
				net.WriteUInt( threadTbl.threadID, 32 )
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
	iconPanel:SetSize( 64, 64 )
	if ( scrW < 1024 and scrH < 768 ) then
		iconPanel:SetSize( 48, 48 )
	end
	local iconX, iconY = iconPanel:GetPos( )
	local iconW, iconH = iconPanel:GetSize( )
	iconPanel:SetPos( 16, ( dThreadPanel:GetTall( ) * 0.5 ) - iconH * 0.5 )
	iconPanel.Paint = function( pnl, w, h )
		draw.RoundedBox( 8, 0, 0, w, h, Color( 189, 195, 199, 100 ) )
		surface.SetMaterial( LocalPlayer( ).IGForums.Icons[threadTbl.iconID].mat )
	    surface.SetDrawColor( Color( 255, 255, 255 ) )
	    surface.DrawTexturedRect( 0, 0, w, h )
	end
	local dTitleLabel = vgui.Create( "DLabel", dThreadPanel )
	dTitleLabel:SetText( threadTbl.name )
	dTitleLabel:SetFont( "IGForums_CategoryTitle" )
	dTitleLabel:SetTextColor( Color( 0, 0, 0 ) )
	dTitleLabel:SizeToContents( )
	local lblW, lblH = dTitleLabel:GetSize( )
	dTitleLabel:SetPos( iconX + ( iconW * 1.5 ), dThreadPanel:GetTall( ) * 0.05 )
	local dAuthorLabel = vgui.Create( "DLabel", dThreadPanel )
	dAuthorLabel:SetText( "Author: " )
	dAuthorLabel:SetFont( "IGForums_CategoryDesc" )
	dAuthorLabel:SetTextColor( Color( 0, 0, 0 ) )
	dAuthorLabel:SizeToContents( )
	dAuthorLabel:SetPos( iconX + ( iconW * 1.5 ), dThreadPanel:GetTall( ) * 0.35 )
	local userRank = GetRankByID( threadTbl.userID )
	local authorLabelX, authorLabelY = dAuthorLabel:GetPos( )
	local authorLabelW, authorLabelH = dAuthorLabel:GetSize( )
	local dNameLabel = vgui.Create( "DLabel", dThreadPanel )
	dNameLabel:SetText( LocalPlayer( ).IGForums.Users[ threadTbl.userID ].name )
	dNameLabel:SetFont( "IGForums_CategoryDesc" )
	dNameLabel:SetTextColor( ForumsConfig.Ranks[userRank].color )
	dNameLabel:SizeToContents( )
	dNameLabel:SetPos( authorLabelX + authorLabelW, authorLabelY )
	local dDateLabel = vgui.Create( "DLabel", dThreadPanel )
	dDateLabel:SetText( "Post Date: " .. os.date( "%a %b %d %I:%M%p", threadTbl.postDate ) )
	dDateLabel:SetFont( "IGForums_CategoryDesc" )
	dDateLabel:SetTextColor( Color( 0, 0, 0 ) )
	dDateLabel:SizeToContents( )
	dDateLabel:SetPos( iconX + ( iconW * 1.5 ), dThreadPanel:GetTall( ) * 0.5 )
	local dPostCountLabel = vgui.Create( "DLabel", dThreadPanel )
	dPostCountLabel:SetText( "Post Count: " .. ( threadTbl.postCount or 0 ) )
	dPostCountLabel:SetFont( "IGForums_CategoryDesc" )
	dPostCountLabel:SetTextColor( Color( 0, 0, 0 ) )
	dPostCountLabel:SizeToContents( )
	local dPostCountLabelX, dPostCountLabelY = dPostCountLabel:GetPos( )
	local dPostCountLabelW, dPostCountLabelH = dPostCountLabel:GetSize( )
	dPostCountLabel:SetPos( ( dThreadPanel:GetWide( ) * 0.95 ) - dPostCountLabelW, dThreadPanel:GetTall( ) * 0.125 )
	if ( threadTbl.locked ) then
		local lockedPanel = vgui.Create( "DPanel", dThreadPanel )
		lockedPanel:SetSize( 48, 48 )
		lockedPanel:SetPos( 0, dPostCountLabelY + dPostCountLabelH + 12 )
		lockedPanel:AlignRight( 32 )
		lockedPanel.Paint = function( pnl, w, h )
			surface.SetMaterial( lockMaterial )
			surface.SetDrawColor( Color( 255, 255, 255 ) )
			surface.DrawTexturedRect( 0, 0, w, h )
		end
	end
end

function PANEL:OpenPostCreator( categoryID, threadID )
	self.isNotViewing = true
	self:ClearContentFrame( )
	self:CreateAuthorPost( nil, categoryID, threadID, true )
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
			net.WriteString( self:ParseTextLines( dContentTextEntry:GetValue( ) ) )
		net.SendToServer( )
		self:GeneratePosts( categoryID, threadID )
	end, self.dContentFrame:GetWide( ) * 0.4, self.dContentFrame:GetTall( ) * 0.95 )
	local dCancelButton = self:CreateButton( "CANCEL", "IGForums_CategoryDesc", cancelMaterial, function( pnl )
		self:GeneratePosts( categoryID, threadID )
	end, self.dContentFrame:GetWide( ) * 0.6, self.dContentFrame:GetTall( ) * 0.95 )
end

function PANEL:GeneratePosts( categoryID, threadID )
	self:ClearContentFrame( IGFORUMS_GENERATEPOSTS )
	self:CreateDIconLayout( )
	self.dIconLayout:Clear( )
	self.currentCategory = categoryID
	self.currentThread = threadID
	self.isNotViewing = false
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
	local centerX, centerY = self.dContentFrame:GetWide( ) * 0.5, self.dContentFrame:GetTall( ) * 0.5
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
		if ( backButtonPos == self.dContentFrame:GetWide( ) * 0.5 ) then
			lockButtonPos = self.dContentFrame:GetWide( ) * 0.3
			stickyButtonPos = self.dContentFrame:GetWide( ) * 0.7
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
	local dAuthorLabel = vgui.Create( "DLabel", dAuthorPostPanel )
	dAuthorLabel:SetText( "Author: " )
	dAuthorLabel:SetFont( "IGForums_CategoryDesc" )
	dAuthorLabel:SetTextColor( Color( 0, 0, 0, 255 ) )
	dAuthorLabel:SizeToContents( )
	dAuthorLabel:AlignLeft( dAuthorPostPanel:GetWide( ) * 0.05 )
	dAuthorLabel:AlignTop( dAuthorPostPanel:GetTall( ) * 0.22 )
	local userRank = GetRankByID( threadTable.userID )
	local authorLabelX, authorLabelY = dAuthorLabel:GetPos( )
	local authorLabelW, authorLabelH = dAuthorLabel:GetSize( )
	local dNameLabel = vgui.Create( "DLabel", dAuthorPostPanel )
	dNameLabel:SetText( LocalPlayer( ).IGForums.Users[ threadTable.userID ].name )
	dNameLabel:SetFont( "IGForums_CategoryDesc" )
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
	dPostCountLabel:SetPos( ( dAuthorPostPanel:GetWide( ) * 0.95 ) - dPostCountLabelW, dAuthorPostPanel:GetTall( ) * 0.1 )
	local dContentTextEntry = vgui.Create( "DTextEntry", dAuthorPostPanel )
	dContentTextEntry:SetSize( dAuthorPostPanel:GetWide( ) * 0.9, dAuthorPostPanel:GetTall( ) * 0.4 )
	dContentTextEntry:SetMultiline( true )
	dContentTextEntry:SetText( threadTable.text )
	dContentTextEntry:CenterHorizontal( )
	dContentTextEntry:AlignBottom( dAuthorPostPanel:GetTall( ) * 0.15 )
	dContentTextEntry:SetFont( "IGForums_TextEntrySmall" )
	if ( #string.Explode( "\n", threadTable.text ) > 3 ) then
		dContentTextEntry:SetVerticalScrollbarEnabled( true )
	end
	dContentTextEntry.OnTextChanged = function( pnl, str )
		pnl:SetText( threadTable.text )
	end
end

function PANEL:CreatePost( dIconLayout, post, postNumber )
	local addHeight = ScrH( ) * categoryHeightMulti
	local dPostPanel = dIconLayout:Add( "DPanel" )
	dPostPanel:SetSize( dIconLayout:GetWide( ), categoryBaseHeight + addHeight )
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
	dAuthorLabel:SetFont( "IGForums_CategoryDesc" )
	dAuthorLabel:SetTextColor( Color( 0, 0, 0 ) )
	dAuthorLabel:SizeToContents( )
	dAuthorLabel:SetPos( dPostPanel:GetWide( ) * 0.05, dPostPanel:GetTall( ) * 0.07 )
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
	dDateLabel:SetPos( dPostPanel:GetWide( ) * 0.05, dPostPanel:GetTall( ) * 0.2 )
	local dPostNumberLabel = vgui.Create( "DLabel", dPostPanel )
	dPostNumberLabel:SetText( "Post #" .. postNumber )
	dPostNumberLabel:SetFont( "IGForums_CategoryDesc" )
	dPostNumberLabel:SetTextColor( Color( 0, 0, 0 ) )
	dPostNumberLabel:SizeToContents( )
	local postNumberTxtW, postNumberTxtH = dPostNumberLabel:GetSize( )
	dPostNumberLabel:SetPos( ( dPostPanel:GetWide( ) * 0.95 ) - ( postNumberTxtW ), dPostPanel:GetTall( ) * 0.07 )
	local dPostCountLabel = vgui.Create( "DLabel", dPostPanel )
	dPostCountLabel:SetText( "Posts: " .. LocalPlayer( ).IGForums.Users[ post.userID ].postCount or 0 )
	dPostCountLabel:SetFont( "IGForums_CategoryDesc" )
	dPostCountLabel:SetTextColor( Color( 0, 0, 0, 255 ) )
	dPostCountLabel:SizeToContents( )
	local dPostCountLabelW, dPostCountLabelH = dPostCountLabel:GetSize( )
	dPostCountLabel:SetPos( ( dPostPanel:GetWide( ) * 0.95 ) - dPostCountLabelW, dPostPanel:GetTall( ) * 0.2 )
	local dContentTextEntry = vgui.Create( "DTextEntry", dPostPanel )
	dContentTextEntry:SetSize( dPostPanel:GetWide( ) * 0.9, dPostPanel:GetTall( ) * 0.5 )
	dContentTextEntry:SetMultiline( true )
	dContentTextEntry:SetText( post.text )
	dContentTextEntry:CenterHorizontal( )
	dContentTextEntry:AlignBottom( dPostPanel:GetTall( ) * 0.1 )
	dContentTextEntry:SetFont( "IGForums_TextEntrySmall" )
	if ( #string.Explode( "\n", post.text ) > 3 ) then
		dContentTextEntry:SetVerticalScrollbarEnabled( true )
	end
	dContentTextEntry.OnTextChanged = function( pnl, str )
		pnl:SetText( post.text )
	end
end

vgui.Register( "IGForums_Viewer", PANEL, "DFrame" )