local S = minetest.get_translator(minetest.get_current_modname())

ship_repair = {}

-- load files
local default_path = minetest.get_modpath("ship_repair")

dofile(default_path .. DIR_DELIM .. "repair_bay.lua")
