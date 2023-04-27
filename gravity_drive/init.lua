local S = minetest.get_translator(minetest.get_current_modname())

gravity_drive = {}

-- load files
local default_path = minetest.get_modpath("gravity_drive")

dofile(default_path .. DIR_DELIM .. "nodes.lua")
