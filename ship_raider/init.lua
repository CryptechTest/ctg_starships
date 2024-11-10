local S = minetest.get_translator(minetest.get_current_modname())

ship_raider = {}

local ship_def_raider = {
    size = {
        w = 12,
        h = 12,
        l = 15
    },
    name = "Raider",
    hp = 1000,
    shield = 1000
}

-- load files
local default_path = minetest.get_modpath("ship_raider")

dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "raider.lua")

ship_raider.register_scout({
    typename = "ship_raider",
    modname = "ship_raider",
    machine_name = "raider",
    jump_dist = 2000,
    size = ship_def_raider.size,
    hp = ship_def_raider.hp,
    shield = ship_def_raider.shield,
    machine_desc = ship_def_raider.name
});

if minetest.get_modpath("ship_machine") then
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
    })
end
