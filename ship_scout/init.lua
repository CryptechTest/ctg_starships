local S = minetest.get_translator(minetest.get_current_modname())

ship_scout = {}

-- load files
local default_path = minetest.get_modpath("ship_scout")

dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "scout.lua")
