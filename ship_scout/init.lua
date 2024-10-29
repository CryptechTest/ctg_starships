local S = minetest.get_translator(minetest.get_current_modname())

ship_scout = {}

ship_scout.proto_size = {
    w = 12,
    h = 12,
    l = 15
}
ship_scout.size = {
    w = 15,
    h = 15,
    l = 32
}

-- load files
local default_path = minetest.get_modpath("ship_scout")

dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "scout.lua")
dofile(default_path .. DIR_DELIM .. "protect.lua")

ship_scout.register_scout({
    typename = "ship_scout",
    modname = "ship_scout",
    machine_name = "scout",
    jump_dist = 2000,
    size = ship_scout.proto_size
});

if minetest.get_modpath("ship_machine") then
    --[[ship_machine.register_jumpship({
        modname = "ship_scout",
        machine_name = "jump_drive",
        machine_desc = "Jump Drive Allocator",
        typename = "jump_drive",
        size = {
            w = 12,
            h = 12,
            l = 15
        }
    })]] --

    ship_machine.register_jumpship({
        modname = "ship_scout",
        machine_name = "jump_drive_scout",
        machine_desc = "Jump Drive Allocator",
        typename = "jump_drive",
        size = ship_scout.proto_size
    })
end
