local S = minetest.get_translator(minetest.get_current_modname())

ship_cargo = {}

ship_cargo.size = {
    w = 58,
    h = 22,
    l = 25
}

-- load files
local default_path = minetest.get_modpath("ship_cargo")

dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "cargo_cruiser.lua")
dofile(default_path .. DIR_DELIM .. "protect.lua")

ship_cargo.register_cruiser({
    typename = "ship_cargo",
    modname = "ship_cargo",
    machine_name = "cruiser",
    jump_dist = 8000,
    size = ship_cargo.size
});

if minetest.get_modpath("ship_machine") then
    ship_machine.register_jumpship({
        modname = "ship_cargo",
        machine_name = "jump_drive_cargo_cruiser",
        machine_desc = "Jump Drive Allocator",
        typename = "jump_drive",
        size = ship_cargo.size
    })
end
