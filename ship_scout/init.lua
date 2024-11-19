local S = minetest.get_translator(minetest.get_current_modname())

ship_scout = {}

local ship_def = {}
-- proto scout
ship_def.proto_name = "Proto-Scout"
ship_def.proto_size = {
    w = 12,
    h = 12,
    l = 15
}
ship_def.proto_hp = 4000
ship_def.proto_shield = 2000
ship_def.proto_jump_dist = 2000

-- load files
local default_path = minetest.get_modpath("ship_scout")
dofile(default_path .. "/digilines.lua")

-- register control console
ship_machine.register_control_console({
    typename = "ship_scout",
    modname = "ship_scout",
    machine_name = "scout",
    jump_dist = ship_def.proto_jump_dist,
    min_dist = 25,
    tier = "LV",
    size = ship_def.proto_size,
    hp = ship_def.proto_hp,
    shield = ship_def.proto_shield,
    machine_desc = ship_def.proto_name,
    digiline_effector = ship_scout.digiline_effector,
    do_docking = true,
    groups = {
        ship_scout = 1,
        ship_proto = 1
    }
});

-- register jumpship
ship_machine.register_jumpship({
    modname = "ship_scout",
    machine_name = "jump_drive_scout",
    machine_desc = "Jump Drive Allocator - Scout",
    typename = "jump_drive",
    do_protect = true,
    ship_name = ship_def.proto_name,
    size = ship_def.proto_size,
    hp = ship_def.proto_hp,
    shield = ship_def.proto_shield
})
