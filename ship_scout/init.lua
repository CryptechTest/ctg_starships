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
-- legacy scout
ship_def.name = "Scout"
ship_def.size = {
    w = 18,
    h = 13,
    l = 26
}
ship_def.hp = 4000
ship_def.shield = 4000
ship_def.jump_dist = 2500

-- load files
local default_path = minetest.get_modpath("ship_scout")

dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "scout.lua")

ship_scout.register_scout({
    typename = "ship_scout",
    modname = "ship_scout",
    machine_name = "scout",
    jump_dist = ship_def.proto_jump_dist,
    size = ship_def.proto_size,
    hp = ship_def.proto_hp,
    shield = ship_def.proto_shield,
    machine_desc = ship_def.proto_name
});

ship_scout.register_scout({
    typename = "ship_scout",
    modname = "ship_scout",
    machine_name = "legacy",
    jump_dist = ship_def.jump_dist,
    size = ship_def.size,
    hp = ship_def.hp,
    shield = ship_def.shield,
    machine_desc = ship_def.name
});

if minetest.get_modpath("ship_machine") then
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

    ship_machine.register_jumpship({
        modname = "ship_scout",
        machine_name = "jump_drive_legacy",
        machine_desc = "Jump Drive Allocator - Scout",
        typename = "jump_drive",
        do_protect = true,
        ship_name = ship_def.name,
        shield_name = "shield_protect_legacy",
        size = ship_def.size,
        hp = ship_def.hp,
        shield = ship_def.shield
    })
end
