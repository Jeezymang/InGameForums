IGForums = IGForums or { }

///////////////////////////////////////////////////////////////
/// This function is used both serverside and clientside to
/// verify the syntax when creating a category.
function IGForums:CheckCategorySyntax( icon, title, desc, ply )
	local minTitleLength = ForumsConfig.MinimumCategoryTitleLength
	local maxTitleLength = ForumsConfig.MaximumCategoryTitleLength
	local minDescLength = ForumsConfig.MinimumCategoryDescriptionLength
	local maxDescLength = ForumsConfig.MaximumCategoryDescriptionLength
	local messageBoxFunc = nil
	local funcTbl = nil
	if ( SERVER and IsValid( ply ) ) then
		messageBoxFunc = ply.SendForumHint
		funcTbl = ply
	elseif ( CLIENT ) then
		if not ( IsValid( ply ) ) then 
			ply = LocalPlayer( ) 
		end
		if ( IsValid( ply.IGForums_Viewer ) ) then
			messageBoxFunc = ply.IGForums_Viewer.ActivateMessageBox
			funcTbl = ply.IGForums_Viewer
		end
	end
	local messError = ""
	local isCorrect = true
	if ( !icon or icon == "" ) then
		messError = "You must select an icon for the category."
		isCorrect = false
	elseif not ( string.find( title, "%a" ) ) then
		messError = "Your title must contain characters."
		isCorrect = false
	elseif not ( string.find( desc, "%a" ) ) then
		messError = "Your description must contains characters."
		isCorrect = false
	elseif ( string.find( title, [[\n]] ) ) then
		messError = "Your title cannot contain new-line characters."
		isCorrect = false
	elseif ( string.find( desc, [[\n]] ) ) then
		messError = "Your description cannot contain new-line characters."
		isCorrect = false
	elseif ( string.len( title ) < minTitleLength or string.len( title ) > maxTitleLength ) then
		messError = "Your title must be inbetween " .. minTitleLength .. " and " .. maxTitleLength .. " characters."
		isCorrect = false
	elseif ( string.len( desc ) < minDescLength or string.len( desc ) > maxDescLength ) then
		messError = "Your description must be inbetween " .. minDescLength .. " and " .. maxDescLength .. " characters."
		isCorrect = false
	end
	if ( !isCorrect and isfunction( messageBoxFunc ) ) then
		messageBoxFunc( funcTbl, messError, 3 )
	end
	return isCorrect
end

///////////////////////////////////////////////////////////////
/// This function is used both serverside and clientside to
/// verify the syntax when creating a thread.
function IGForums:CheckThreadSyntax( icon, title, content, ply )
	local minTitleLength = ForumsConfig.MinimumThreadTitleLength
	local maxTitleLength = ForumsConfig.MaximumThreadTitleLength
	local minContentLength = ForumsConfig.MinimumThreadContentLength
	local maxContentLength = ForumsConfig.MaximumThreadContentLength
	local messageBoxFunc = nil
	local funcTbl = nil
	if ( SERVER and IsValid( ply ) ) then
		messageBoxFunc = ply.SendForumHint
		funcTbl = ply
	elseif ( CLIENT ) then
		if not ( IsValid( ply ) ) then 
			ply = LocalPlayer( ) 
		end
		if ( IsValid( ply.IGForums_Viewer ) ) then
			messageBoxFunc = ply.IGForums_Viewer.ActivateMessageBox
			funcTbl = ply.IGForums_Viewer
		end
	end
	local messError = ""
	local isCorrect = true
	if ( !icon or icon == "" ) then
		messError = "You must select an icon for the thread."
		isCorrect = false
	elseif not ( string.find( title, "%a" ) ) then
		messError = "Your title must contain characters."
		isCorrect = false
	elseif not ( string.find( content, "%a" ) ) then
		messError = "Your content must contains characters."
		isCorrect = false
	elseif ( string.len( title ) < minTitleLength or string.len( title ) > maxTitleLength ) then
		messError = "Your title must be inbetween " .. minTitleLength .. " and " .. maxTitleLength .. " characters."
		isCorrect = false
	elseif ( string.len( content ) < minContentLength or string.len( content ) > maxContentLength ) then
		messError = "Your content must be inbetween " .. minContentLength .. " and " .. maxContentLength .. " characters."
		isCorrect = false
	end
	if ( !isCorrect and isfunction( messageBoxFunc ) ) then
		messageBoxFunc( funcTbl, messError, 3 )
	end
	return isCorrect
end

///////////////////////////////////////////////////////////////
/// This function is used both serverside and clientside to
/// verify the syntax when creating a post.
function IGForums:CheckPostSyntax( text, ply )
	local minPostLength = ForumsConfig.MinimumPostLength
	local maxPostLength = ForumsConfig.MaximumPostLength
	local messageBoxFunc = nil
	local funcTbl = nil
	if ( SERVER and IsValid( ply ) ) then
		messageBoxFunc = ply.SendForumHint
		funcTbl = ply
	elseif ( CLIENT ) then
		if not ( IsValid( ply ) ) then 
			ply = LocalPlayer( ) 
		end
		if ( IsValid( ply.IGForums_Viewer ) ) then
			messageBoxFunc = ply.IGForums_Viewer.ActivateMessageBox
			funcTbl = ply.IGForums_Viewer
		end
	end
	local messError = ""
	local isCorrect = true
	if not ( string.find( text, "%a" ) ) then
		messError = "Your post must contains characters."
		isCorrect = false
	elseif ( string.len( text ) < minPostLength or string.len( text ) > maxPostLength ) then
		messError = "Your post must be inbetween " .. minPostLength .. " and " .. maxPostLength .. " characters."
		isCorrect = false
	end
	if ( !isCorrect and isfunction( messageBoxFunc ) ) then
		messageBoxFunc( funcTbl, messError, 3 )
	end
	return isCorrect
end