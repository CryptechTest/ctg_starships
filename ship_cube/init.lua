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

dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "cube_cruiser.lua")

ship_cube.register_cruiser({
    typename = "ship_cube",
    modname = "ship_cube",
    machine_name = "cruiser",
    jump_dist = 5000,
    size = ship_def.size,
    hp = ship_def.hp,
    shield = ship_def.shield,
});

if minetest.get_modpath("ship_machine") then
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
end
