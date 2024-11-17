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
end
