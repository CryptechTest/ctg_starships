local S = minetest.get_translator(minetest.get_current_modname())

ship_cube = {}

local ship_def = {}
ship_def.name = "Cube Cruiser"
ship_def.size = {
    w = 42,
    h = 42,
    l = 42
}
ship_def.hp = 20000
ship_def.shield = 10000

-- load files
local default_path = minetest.get_modpath("ship_cube")
dofile(default_path .. "/digilines.lua")

-- register control console
ship_machine.register_control_console({
    typename = "ship_cube",
    modname = "ship_cube",
    machine_name = "cruiser",
    jump_dist = 10000,
    min_dist = 90,
    tier = "HV",
    size = ship_def.size,
    hp = ship_def.hp,
    shield = ship_def.shield,
    machine_desc = ship_def.name,
    digiline_effector = ship_cube.digiline_effector,
    do_docking = true,
    groups = {
        ship_cube = 1,
        ship_jumps = 3,
    }
});

-- register jumpship
ship_machine.register_jumpship({
    modname = "ship_cube",
    machine_name = "jump_drive_cube_cruiser",
    machine_desc = "Jump Drive Allocator",
    typename = "jump_drive",
    do_protect = true,
    ship_name = ship_def.name,
    size = ship_def.size,
    hp = ship_def.hp,
    shield = ship_def.shield,
})
