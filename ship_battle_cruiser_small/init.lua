local S = minetest.get_translator(minetest.get_current_modname())

ship_battle_cruiser_small = {}

local ship_def = {}
ship_def.name = "Battle Cruiser Small"
ship_def.size = {
    w = 30,
    h = 10,
    l = 18
}
ship_def.hp = 5000
ship_def.shield = 2000

-- load files
local default_path = minetest.get_modpath("ship_battle_cruiser_small")
dofile(default_path .. "/digilines.lua")

-- register control console
ship_machine.register_control_console({
    typename = "ship_battle_cruiser_small",
    modname = "ship_battle_cruiser_small",
    machine_name = "cruiser",
    jump_dist = 5000,
    min_dist = 32,
    tier = "MV",
    size = ship_def.size,
    hp = ship_def.hp,
    shield = ship_def.shield,
    machine_desc = ship_def.name,
    digiline_effector = ship_battle_cruiser_small.digiline_effector,
    do_docking = true,
    groups = {
        ship_battle_cruiser_small = 1,
        ship_jumps = 3,
    }
});

-- register jumpship
ship_machine.register_jumpship({
    modname = "ship_battle_cruiser_small",
    machine_name = "jump_drive_cruiser",
    machine_desc = "Jump Drive Allocator",
    typename = "jump_drive",
    do_protect = true,
    ship_name = ship_def.name,
    size = ship_def.size,
    hp = ship_def.hp,
    shield = ship_def.shield,
})
