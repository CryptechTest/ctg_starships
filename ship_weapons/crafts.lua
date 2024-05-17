
local orb = "spectrum:spectrum_orb_block"
local glw = "group:crystal"
local ml = "technic:laser_mk1"
local flx = "ship_parts:flux_tube"
local cor = "ctg_world:corestone_glow_octa"
local sc = "technic:supply_converter"
local sw = "technic:doped_silicon_wafer"
local det = "digistuff:detector"

minetest.register_craft({
    output = "ship_weapons:lv_beam_tower",
    recipe = {{glw, ml, glw}, {sw, orb, sw}, {det, cor, sc}}
})