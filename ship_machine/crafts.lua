if true then
    local gw = "basic_materials:gold_wire"
    local sw = "basic_materials:silver_wire"
    local cel = "ship_parts:reactor_cell"
    local cc = "technic:copper_coil"
    local ec = "technic:red_energy_crystal"
    local t = "ctg_world:titanium_ingot"
    local mc = "technic:machine_casing"
    local gdl = "ship_machine:lv_gravity_drive_lite"
    local cam = "ship_parts:engine_part5"
    local hvt = "technic:hv_transformer"

    minetest.register_craft({
        output = "ship_machine:lv_gravity_drive_lite",
        recipe = {{cel, gw, cel}, {cc, ec, cc}, {t, mc, t}}
    })

    minetest.register_craft({
        output = "ship_machine:hv_gravity_generator",
        recipe = {{gw, cam, gw}, {hvt, gdl, hvt}, {gw, sw, gw}}
    })

    minetest.register_craft({
        output = "ship_machine:hv_gravity_generator",
        recipe = {{gw, cam, gw}, {cc, gdl, cc}, {sw, hvt, sw}}
    })
end
