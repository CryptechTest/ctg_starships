local orb = "spectrum:spectrum_orb_block"
local glw = "group:crystal"
local mes = "default:mese_crystal"
local dia = "default:diamond"
local ml1 = "technic:laser_mk1"
local ml2 = "technic:laser_mk2"
local ml3 = "technic:laser_mk3"
local flx = "ship_parts:reactor_cell"
local cor = "ctg_world:corestone_glow_octa"
local sc = "technic:supply_converter"
local det = "digistuff:detector"
local cir = "ship_parts:circuit_standard"
local adv = "ship_parts:circuit_advanced"
local lvbt = "ship_weapons:lv_beam_tower"
local mvbt = "ship_weapons:mv_beam_tower"

minetest.register_craft({
    output = "ship_weapons:lv_beam_tower",
    recipe = {{glw, ml1, glw}, {orb, flx, orb}, {det, cor, sc}}
})

minetest.register_craft({
    output = "ship_weapons:mv_beam_tower",
    recipe = {{glw, ml2, glw}, {dia, orb, dia}, {cir, lvbt, cir}}
})

minetest.register_craft({
    output = "ship_weapons:hv_beam_tower",
    recipe = {{glw, ml3, glw}, {mes, orb, mes}, {adv, mvbt, adv}}
})

local pls = "basic_materials:plastic_sheet"
local alm = "ctg_world:aluminum_ingot"
local nck = "ctg_world:nickel_ingot"
local lvd = "ship_weapons:lv_targeting_dish_antenna"

minetest.register_craft({
    output = "ship_weapons:lv_targeting_dish_antenna",
    recipe = {{pls, dia, pls}, {cir, det, cir}, {"", alm, ""}}
})

minetest.register_craft({
    output = "ship_weapons:mv_targeting_dish_antenna",
    recipe = {{pls, mes, pls}, {adv, lvd, adv}, {"", nck, ""}}
})

local hid = "ctg_world:hiduminium_stock"
local tel = "ship_parts:telemetry_capsule"
local com = "ship_parts:command_capsule"
local cul = "ship_parts:engine_part5"
local tgt = "ship_weapons:target_computer"
local mca = "technic:mv_digi_cable"
local tch = "digistuff:touchscreen"
local tch = "digistuff:touchscreen"
local gls = "default:glass"

minetest.register_craft({
    output = "ship_weapons:target_computer",
    recipe = {{gls, cul, nck}, {tch, tel, cir}, {pls, com, alm}}
})

minetest.register_craft({
    output = "ship_weapons:target_computer_adv",
    recipe = {{gls, glw, hid}, {dia, tgt, adv}, {pls, mca, hid}}
})
