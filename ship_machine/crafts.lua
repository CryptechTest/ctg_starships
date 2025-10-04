if true then
    local es = "basic_materials:empty_spool"
    local gw = "basic_materials:gold_wire"
    local sw = "basic_materials:silver_wire"
    local nw = "ctg_world:nickel_wire"
    local aw = "basic_materials:aluminum_wire"
    local ls = "basic_materials:lead_strip"
    local cel = "ship_parts:reactor_cell"
    local cc = "technic:copper_coil"
    local ec = "technic:red_energy_crystal"
    local ss = "technic:switching_station"
    local t = "ctg_world:titanium_ingot"
    local gdl = "ship_machine:lv_gravity_drive_lite"
    local gdmv = "ship_machine:mv_gravity_generator"
    local cam = "ship_parts:engine_part5"
    local mvt = "technic:mv_transformer"
    local hvt = "technic:hv_transformer"

    -- lv
    minetest.register_craft({
        output = "ship_machine:lv_gravity_drive_lite",
        recipe = {{cel, ls, cel}, {cc, ec, cc}, {t, ss, t}}
    })

    -- mv
    minetest.register_craft({
        output = "ship_machine:mv_gravity_generator",
        recipe = {{nw, gw, nw}, {cc, gdl, cc}, {aw, mvt, aw}},
        replacements = {{ nw, es .. " 2" }, {aw, es .. " 2"}}
    })

    -- hv
    minetest.register_craft({
        output = "ship_machine:hv_gravity_generator",
        recipe = {{gw, cam, gw}, {hvt, gdmv, hvt}, {gw, sw, gw}},
        replacements = {{ gw, es .. " 4"}, {sw, es}}
    })

    -- hv
    minetest.register_craft({
        output = "ship_machine:hv_gravity_generator",
        recipe = {{gw, cam, gw}, {cc, gdmv, cc}, {sw, hvt, sw}},
        replacements = {{ gw, es .. " 2" }, {sw, es .. " 2"}}
    })

    local vp = "ctg_machines:lv_vacuum_pump"
    local bo = "ctg_machines:lv_bottler"
    local bt = "vessels:steel_bottle"
    local nst = "livingcaves:bacteriacave_nest"
    local tb = "pipeworks:mese_tube_000000"
    local lg = "technic:control_logic_unit"
    local cr = "technic:green_energy_crystal"
    local gcr = "group:crystal"

    local lcm = "ship_machine:lv_chemical_lab"
    local mcm = "ship_machine:mv_chemical_lab"

    -- lv
    minetest.register_craft({
        output = "ship_machine:lv_chemical_lab",
        recipe = {{bt, lg, tb}, {nst, bo, nst}, {cc, vp, cc}}
    })
    -- mv
    minetest.register_craft({
        output = "ship_machine:mv_chemical_lab",
        recipe = {{bt, bt, bt}, {cr, lcm, cr}, {cc, mvt, cc}}
    })
    -- hv
    minetest.register_craft({
        output = "ship_machine:hv_chemical_lab",
        recipe = {{bt, gcr, bt}, {bt, mcm, bt}, {cc, hvt, cc}}
    })

    --local coolant_image = "ctg_machines_coolant_source_animated.png"
    --ship_machine.coolant_bottle_image = "[combine:16x16:0,0=" .. coolant_image .. "^vessels_glass_bottle_mask.png^[makealpha:0,254,0"

    if minetest.get_modpath("unified_inventory") then
        unified_inventory.register_craft_type("chemicals", {
            description = "Chemical Processing",
            icon = "ctg_hv_chem_lab_front_active.png",
            width = 2,
            height = 2
        })
        unified_inventory.register_craft({
            type = "chemicals",
            output = "ship_machine:bottle_of_coolant",
            items = {"livingcaves:bucket_cavewater", "technic:sulfur_dust", "group:salt", "group:glow_shroom"}
        })
        unified_inventory.register_craft({
            type = "chemicals",
            output = "basic_materials:oil_extract",
            items = {"group:water_bucket", "group:leaves", "group:seed", "group:seed"}
        })
    end

end
