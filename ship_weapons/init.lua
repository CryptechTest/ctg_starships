local S = minetest.get_translator(minetest.get_current_modname())

ship_weapons = {}

-- load files
local default_path = minetest.get_modpath("ship_weapons")

dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "beam_tower.lua")
dofile(default_path .. DIR_DELIM .. "crafts.lua")
dofile(default_path .. DIR_DELIM .. "compat.lua")
