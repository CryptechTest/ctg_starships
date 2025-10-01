local S = minetest.get_translator(minetest.get_current_modname())

ship_door = {}

-- load files
local default_path = minetest.get_modpath(minetest.get_current_modname())
dofile(default_path .. "/doors.lua")
