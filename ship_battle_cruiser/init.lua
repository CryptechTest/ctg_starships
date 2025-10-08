local S = minetest.get_translator(minetest.get_current_modname())

ship_battle_cruiser = {}

local ship_def = {}
ship_def.name = "Deucalion"
ship_def.size = {
    w = 64,
    h = 22,
    l = 36
}
ship_def.hp = 25000
ship_def.shield = 10000

-- load files
local default_path = minetest.get_modpath("ship_battle_cruiser")
dofile(default_path .. "/digilines.lua")

-- register control console
ship_machine.register_control_console({
    typename = "battleship",
    modname = "ship_battle_cruiser",
    machine_name = "battleship",
    jump_dist = 9000,
    min_dist = 140,
    tier = "HV",
    size = ship_def.size,
    hp = ship_def.hp,
    shield = ship_def.shield,
    machine_desc = ship_def.name,
    digiline_effector = ship_battle_cruiser.digiline_effector,
    do_docking = true,
    groups = {
        ship_battle_cruiser_small = 1,
        ship_jumps = 3,
    }
});

-- register jumpship
ship_machine.register_jumpship({
    modname = "ship_battle_cruiser",
    machine_name = "jump_drive_battle_cruiser",
    machine_desc = "Jump Drive Allocator",
    typename = "jump_drive",
    do_protect = true,
    ship_name = ship_def.name,
    size = ship_def.size,
    hp = ship_def.hp,
    shield = ship_def.shield,
})
