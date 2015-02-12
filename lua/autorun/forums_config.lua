///////////////////////////////////////////////////////////////
/// There are three basic ranks for this addon, moderator,
/// admin, and the user. Using this enumerations one can
/// make more ranks that mimic these positions.
IGFORUMS_MODERATORPERMISSIONS = 1
IGFORUMS_ADMINPERMISSIONS = 2

ForumsConfig = ForumsConfig or { }
ForumsConfig.ChatCommand = "!forums" -- The chat command to open the forusm viewer.
ForumsConfig.PostCooldown = 30 -- The amount of seconds inbetween posting and making threads.

///////////////////////////////////////////////////////////////
/// These are the colors that the user's name will be within
/// the forum viewer depending on their rank.
ForumsConfig.Ranks = {
	["admin"] = { color = Color( 255, 125, 125 ) },
	["moderator"] = { color = Color( 125, 125, 255 ) },
	["user"] = { color = Color( 0, 0, 0 ) }
}

///////////////////////////////////////////////////////////////
/// This can be used to add new ranks that can mimic the
/// moderator and admin positions as mentioned above.
/// Example:
/// ForumsConfig.RankPermissions = {
/// 	[IGFORUMS_MODERATORPERMISSIONS] = {
///			["developer"] = true,
///			["vip"] = true,
/// 		["moderator"] = true,
/// 		["admin"] = true,
///			["owner"] = true
/// 	},
/// 	[IGFORUMS_ADMINPERMISSIONS] = {
/// 		["admin"] = true,
///			["owner"]
/// 	}
/// }
ForumsConfig.RankPermissions = {
	[IGFORUMS_MODERATORPERMISSIONS] = { 
		["moderator"] = true,
		["admin"] = true
	},
	[IGFORUMS_ADMINPERMISSIONS] = {
		["admin"] = true
	}
}

///////////////////////////////////////////////////////////////
/// These variables are pretty much self explanitory.
/// The minimum and maximum amount of characters for titles,
/// descriptions, ect.
ForumsConfig.MinimumCategoryTitleLength = 5
ForumsConfig.MaximumCategoryTitleLength = 80
ForumsConfig.MinimumCategoryDescriptionLength = 10
ForumsConfig.MaximumCategoryDescriptionLength = 200

ForumsConfig.MinimumThreadTitleLength = 5
ForumsConfig.MaximumThreadTitleLength = 80
ForumsConfig.MinimumThreadContentLength = 10
ForumsConfig.MaximumThreadContentLength = 1000

ForumsConfig.MinimumPostLength = 10
ForumsConfig.MaximumPostLength = 1000

ForumsConfig.ThreadsPerPage = 10
ForumsConfig.PostsPerPage = 10