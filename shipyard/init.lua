local S = minetest.get_translator(minetest.get_current_modname())

shipyard = {}

shipyard.size = {
    l = 30,
    h = 42,
    w = 72
}

-- load files
local default_path = minetest.get_modpath("shipyard")

dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "shipyard_bay.lua")
dofile(default_path .. DIR_DELIM .. "shipyard.lua")
dofile(default_path .. DIR_DELIM .. "protect.lua")
dofile(default_path .. DIR_DELIM .. "chest.lua")


ship_machine.register_jumpship({
    modname = "shipyard",
    machine_name = "jump_drive",
    machine_desc = "Jump Drive - Shipyard Station",
    typename = "jump_drive",
    size = shipyard.size
})
