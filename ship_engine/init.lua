local S = minetest.get_translator(minetest.get_current_modname())

ship_engine = {}

-- load files
local default_path = minetest.get_modpath("ship_engine")

dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "engine.lua")


local function register_lv_engine(data)
    data.modname = "ship_engine"
    data.charge_max = 160
    data.demand = {6000}
    data.supply = 8000
    data.speed = 1
    data.tier = "LV"
    data.typename = "engine"
    data.machine_name = data.machine_name or "engine"
    data.machine_desc = data.machine_desc or "Jumpship Engine"

    ship_engine.register_engine(data)
end

register_lv_engine({
    machine_name = "engine_l",
    machine_desc = "LV Port Engine",
    engine_digiline_effector = ship_engine.engine_digiline_effector_l
})
register_lv_engine({
    machine_name = "engine_r",
    machine_desc = "LV Starboard Engine",
    engine_digiline_effector = ship_engine.engine_digiline_effector_r
})

-- navigator
ship_engine.register_engine_core({})
