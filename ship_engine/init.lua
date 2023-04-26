local S = minetest.get_translator(minetest.get_current_modname())

ship_engine = {}

-- load files
local default_path = minetest.get_modpath("ship_engine")

dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "engine.lua")
