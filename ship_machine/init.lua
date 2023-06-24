local S = minetest.get_translator(minetest.get_current_modname())

ship_machine = {}

-- load files
local default_path = minetest.get_modpath("ship_machine")

dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "gravity_drive.lua")
dofile(default_path .. DIR_DELIM .. "jump_drive.lua")
dofile(default_path .. DIR_DELIM .. "nodes.lua")
dofile(default_path .. DIR_DELIM .. "crafts.lua")
