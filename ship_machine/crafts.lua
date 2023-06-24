if true then
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
        recipe = {{nw, gw, nw}, {cc, gdl, cc}, {aw, mvt, aw}}
    })

    -- hv
    minetest.register_craft({
        output = "ship_machine:hv_gravity_generator",
        recipe = {{gw, cam, gw}, {hvt, gdmv, hvt}, {gw, sw, gw}}
    })

    -- hv
    minetest.register_craft({
        output = "ship_machine:hv_gravity_generator",
        recipe = {{gw, cam, gw}, {cc, gdmv, cc}, {sw, hvt, sw}}
    })
end
