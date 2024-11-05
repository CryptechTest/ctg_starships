local S = minetest.get_translator(minetest.get_current_modname())

ship_cube = {}

ship_cube.size = {
    w = 35,
    h = 35,
    l = 46
}

-- load files
local default_path = minetest.get_modpath("ship_cube")

dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "cube_cruiser.lua")

ship_cube.register_cruiser({
    typename = "ship_cube",
    modname = "ship_cube",
    machine_name = "cruiser",
    jump_dist = 2000,
    size = ship_cube.size,
    hp = 20000,
});

if minetest.get_modpath("ship_machine") then
    ship_machine.register_jumpship({
        modname = "ship_cube",
        machine_name = "jump_drive_cube_cruiser",
        machine_desc = "Jump Drive Allocator",
        typename = "jump_drive",
        do_protect = true,
        size = ship_cube.size,
        hp = 20000,
    })
end
