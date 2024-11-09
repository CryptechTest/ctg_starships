local S = minetest.get_translator(minetest.get_current_modname())

ship_battle_cruiser_small = {}

local ship_def = {}
ship_def.name = "Battle Cruiser Small"
ship_def.size = {
    w = 30,
    h = 10,
    l = 18
}
ship_def.hp = 5000
ship_def.shield = 2000

-- load files
local default_path = minetest.get_modpath("ship_battle_cruiser_small")

dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "battle_cruiser_small.lua")

ship_battle_cruiser_small.register_cruiser({
    typename = "ship_battle_cruiser_small",
    modname = "ship_battle_cruiser_small",
    machine_name = "cruiser",
    jump_dist = 5000,
    size = ship_def.size,
    hp = ship_def.hp,
    shield = ship_def.shield,
});

if minetest.get_modpath("ship_machine") then
    ship_machine.register_jumpship({
        modname = "ship_battle_cruiser_small",
        machine_name = "jump_drive_cruiser",
        machine_desc = "Jump Drive Allocator",
        typename = "jump_drive",
        do_protect = true,
        ship_name = ship_def.name,
        size = ship_def.size,
        hp = ship_def.hp,
        shield = ship_def.shield,
    })
end
