minetest.register_craft({
    output = "ship_parts:metal_support 3",
    recipe = {{"technic:stainless_steel_ingot", "", "technic:stainless_steel_ingot"},
              {"", "technic:stainless_steel_ingot", ""},
              {"technic:stainless_steel_ingot", "", "technic:stainless_steel_ingot"}}
})

minetest.register_craft({
    output = "ship_parts:aluminum_support 3",
    recipe = {{"ctg_world:aluminum_ingot", "", "ctg_world:aluminum_ingot"}, {"", "ctg_world:aluminum_ingot", ""},
              {"ctg_world:aluminum_ingot", "", "ctg_world:aluminum_ingot"}}
})

-------------------------------------------------------------------------------

if true then
    local alb = "ctg_world:aluminum_block"
    local nib = "ctg_world:nickel_block"
    local tib = "ctg_world:titanium_block"
    local ctb = "technic:carbon_steel_block"
    local ssb = "technic:stainless_steel_block"
    local chb = "technic:chromium_block"
    local zib = "technic:zinc_block"
    local tnb = "default:tinblock"
    local gdb = "default:goldblock"
    local mes = "default:mese"
    local urb = "lumpblocks:uranium_block"

    local al = "ctg_world:aluminum_ingot"
    local ni = "ctg_world:nickel_ingot"
    local ti = "ctg_world:titanium_ingot"
    local ct = "technic:carbon_steel_ingot"
    local ss = "technic:stainless_steel_ingot"
    local ch = "technic:chromium_ingot"
    local tn = "default:tin_ingot"
    local zi = "technic:zinc_ingot"
    local li = "technic:lead_ingot"
    local cp = "technic:composite_plate"
    local ms = "ship_parts:metal_support"
    local ms = "ship_parts:metal_support"
    local mi = "moreores:mithril_ingot"
    local sul = "technic:sulfur_lump"

    local ic = "basic_materials:ic"
    local cw = "basic_materials:copper_wire"
    local gw = "basic_materials:gold_wire"
    local ew = "basic_materials:stainless_steel_wire"
    local cm = "scifi_nodes:computer"
    local nw = "ctg_world:nickel_wire"
    local ps = "basic_materials:plastic_sheet"
    local sw = "technic:silicon_wafer"
    local dw = "technic:doped_silicon_wafer"
    local fb = "mesecons_materials:fiber"
    local si = "basic_materials:silicon"
    local mc = "default:mese_crystal"
    local me = "default:mese"
    local gl = "mesecons_materials:glue"
    local fb = "mesecons_materials:fiber"
    local so = "mesecons_solarpanel:solar_panel_off"
    local sp = "technic:solar_panel"
    local mo = "basic_materials:motor"
    local cl = "technic:control_logic_unit"
    local gl = "default:glass"
    local bm = "scifi_nodes:black_mesh"
    local fn = "scifi_nodes:fan"
    local mt = "pipeworks:mesecon_and_digiline_conductor_tube_off_1"
    local ab = "basic_materials:aluminum_bar"

    local cs = "ship_parts:circuit_standard"
    local ca = "ship_parts:circuit_advanced"
    local rc = "ship_parts:reactor_cell"
    local sym = "ship_parts:engine_part4"
    local cam = "ship_parts:engine_part5"
    local flx = "ship_parts:flux_tube"
    local auc = "ship_parts:reactor_cell"
    local jtp = "ctg_jetpack:jetpack_titanium"
    local hy = "ctg_jetpack:jetpack_fuel_hydrogen"

    local col = "technic:copper_coil"
    local enc = "technic:green_energy_crystal"
    local pm = "technic:power_monitor"

    local tub = "pipeworks:tube_1"
    local dgt = "pipeworks:digiline_conductor_tube_1"
    local met = "pipeworks:conductor_tube_off_1"
    local lcd = "digilines:lcd"

    minetest.register_craft({
        output = "ship_parts:assembler",
        recipe = {{al, hy, al}, {ni, jtp, ni}, {al, hy, al}}
    })

    minetest.register_craft({
        output = "ship_parts:circuit_standard",
        recipe = {{ic, ps, ""}, {cw, dw, nw}, {cl, ps, fb}}
    })

    minetest.register_craft({
        output = "ship_parts:circuit_advanced",
        recipe = {{ic, ps, gw}, {cw, cs, nw}, {cl, ps, fb}}
    })

    minetest.register_craft({
        output = "ship_parts:solar_array",
        recipe = {{so, nw, so}, {so, sp, so}, {so, ps, so}}
    })

    minetest.register_craft({
        output = "ship_parts:solar_collimator",
        recipe = {{so, gl, so}, {ni, cs, sp}, {"", gw, ""}}
    })
    
    minetest.register_craft({
        output = "ship_parts:hull_plating 2",
        recipe = {{alb, zib, alb}, {nib, cp, nib}, {alb, ms, alb}}
    })
    
    minetest.register_craft({
        output = "ship_parts:eviromental_sys",
        recipe = {{fb, mt, ti}, {cm, mo, gdb}, {fn, bm, fn}}
    })
    
    minetest.register_craft({
        output = "ship_parts:command_capsule",
        recipe = {{ca, ca, ca}, {cm, me, cm}, {"", "", ""}}
    })

    minetest.register_craft({
        output = "ship_parts:system_capsule",
        recipe = {{"", "", ""}, {cs, mc, cs}, {cl, cm, cl}}
    })

    minetest.register_craft({
        output = "ship_parts:telemetry_capsule",
        recipe = {{"", "", ""}, {rc, rc, rc}, {cm, gl, cl}}
    })

    minetest.register_craft({
        output = "ship_parts:mass_aggregator",
        recipe = {{col, sym, col}, {flx, cs, flx}, {gw, enc, gw}}
    })

    minetest.register_craft({
        output = "ship_parts:engine_part4",
        recipe = {{cs, cs, cs}, {mo, cam, mo}, {mes, col, mes}}
    })

    minetest.register_craft({
        output = "ship_parts:flux_tube",
        recipe = {{dgt, auc, met}, {dgt, ca, met}, {dgt, ab, met}}
    })

    minetest.register_craft({
        output = "ship_parts:reactor_cell",
        recipe = {{tub, ic, tub}, {li, urb, li}, {tub, mi, tub}}
    })

    minetest.register_craft({
        output = "ship_parts:engine_part5",
        recipe = {{lcd, ps, lcd}, {ps, dw, ps}, {"", pm, ""}}
    })

end
