local S = minetest.get_translator(minetest.get_current_modname())

shipyard = {}

local ship_def = {}
ship_def.name = "Shipyard"
ship_def.size = {
    l = 30,
    h = 42,
    w = 72
}
ship_def.hp = 200000
ship_def.shield = 100000

shipyard.ship = ship_def

-- load files
local default_path = minetest.get_modpath("shipyard")

dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "shipyard_bay.lua")
dofile(default_path .. DIR_DELIM .. "shipyard.lua")
dofile(default_path .. DIR_DELIM .. "chest.lua")

shipyard.register_shipyard({
    ship_name = ship_def.name,
    size = ship_def.size,
    hp = ship_def.hp,
    shield = ship_def.shield,
})

ship_machine.register_jumpship({
    modname = "shipyard",
    machine_name = "jump_drive",
    machine_desc = "Jump Drive - Shipyard Station",
    typename = "jump_drive",
    do_protect = true,
    ship_name = ship_def.name,
    size = ship_def.size,
    hp = ship_def.hp,
    shield = ship_def.shield,
})
