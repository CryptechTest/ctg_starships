local S = minetest.get_translator(minetest.get_current_modname())

ship_parts = {}

-- load files
local default_path = minetest.get_modpath("ship_parts")

dofile(default_path .. DIR_DELIM .. "nodes.lua")
dofile(default_path .. DIR_DELIM .. "items.lua")
dofile(default_path .. DIR_DELIM .. "crafts.lua")
