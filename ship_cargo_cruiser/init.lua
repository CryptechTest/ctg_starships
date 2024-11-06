local S = minetest.get_translator(minetest.get_current_modname())

ship_cargo = {}

local ship_def = {}
ship_def.name = "Cargo Cruiser"
ship_def.size = {
    w = 58,
    h = 22,
    l = 25
}
ship_def.hp = 25000
ship_def.shield = 5000

-- load files
local default_path = minetest.get_modpath("ship_cargo")

dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "cargo_cruiser.lua")

ship_cargo.register_cruiser({
    typename = "ship_cargo",
    modname = "ship_cargo",
    machine_name = "cruiser",
    jump_dist = 8000,
    size = ship_def.size,
    hp = ship_def.hp,
    shield = ship_def.shield,
});

if minetest.get_modpath("ship_machine") then
    ship_machine.register_jumpship({
        modname = "ship_cargo",
        machine_name = "jump_drive_cargo_cruiser",
        machine_desc = "Jump Drive Allocator",
        typename = "jump_drive",
        do_protect = true,
        ship_name = ship_def.name,
        size = ship_def.size,
        hp = ship_def.hp,
        shield = ship_def.shield,
    })
end
