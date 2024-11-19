local S = minetest.get_translator(minetest.get_current_modname())

ship_raider = {}

local ship_def_raider = {
    size = {
        w = 12,
        h = 5,
        l = 7
    },
    name = "Raider",
    hp = 1000,
    shield = 1000
}

-- load files
local default_path = minetest.get_modpath("ship_raider")
dofile(default_path .. "/digilines.lua")

-- register control console
ship_machine.register_control_console({
    typename = "ship_raider",
    modname = "ship_raider",
    machine_name = "raider",
    jump_dist = 2000,
    min_dist = 15,
    size = ship_def_raider.size,
    hp = ship_def_raider.hp,
    shield = ship_def_raider.shield,
    machine_desc = ship_def_raider.name,
    digiline_effector = ship_raider.digiline_effector,
    do_docking = true,
    groups = {
        ship_raider = 1
    }
});

-- register jumpship
ship_machine.register_jumpship({
    modname = "ship_raider",
    machine_name = "jump_drive_raider",
    machine_desc = "Jump Drive Allocator",
    typename = "jump_drive",
    do_protect = true,
    ship_name = ship_def_raider.name,
    size = ship_def_raider.size,
    hp = ship_def_raider.hp,
    shield = ship_def_raider.shield,
});
