local S = minetest.get_translator(minetest.get_current_modname())

ship_battle_cruiser_small = {}

ship_battle_cruiser_small.size = {
    w = 28,
    h = 16,
    l = 18
}

-- load files
local default_path = minetest.get_modpath("ship_battle_cruiser_small")

dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "battle_cruiser_small.lua")
dofile(default_path .. DIR_DELIM .. "protect.lua")

ship_battle_cruiser_small.register_cruiser({
    typename = "ship_battle_cruiser_small",
    modname = "ship_battle_cruiser_small",
    machine_name = "cruiser",
    jump_dist = 5000,
    size = ship_battle_cruiser_small.size
});

if minetest.get_modpath("ship_machine") then
    ship_machine.register_jumpship({
        modname = "ship_battle_cruiser_small",
        machine_name = "jump_drive_cruiser",
        machine_desc = "Jump Drive Allocator",
        typename = "jump_drive",
        size = ship_battle_cruiser_small.size
    })
end
