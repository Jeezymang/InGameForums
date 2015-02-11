# InGameForums
A message board like addon for Garry's Mod. Stores the categories, threads, and posts in SQLite.
It still needs a lot of work.

You may configure the addon within the lua/autorun/forums_config.lua file.
You may also easily add new icons by either dropping them in the addon's material folder, or you can create a
seperate folder with the same path and it will find them. The icons are also automatically resource.AddFile'd if you
wish to disable this it's at the bottom of the lua/autorun/forums_init.lua file.

If you don't wish the store extra icons in the addon's folder, you can put them in a directory like this:
myAddonFolder/materials/vgui/ingame_forums/icons/
