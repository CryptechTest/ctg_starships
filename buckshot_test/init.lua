buckshot_test = {}

-- load files
local default_path = minetest.get_modpath("buckshot_test")

-- register nodes
dofile(default_path .. "/" .. "sink.lua")
dofile(default_path .. "/" .. "game_screen.lua")
dofile(default_path .. "/" .. "vending_machine.lua")
