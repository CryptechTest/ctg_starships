if true then
    local ms = "ship_parts:metal_support"
    local gw = "basic_materials:gold_wire"
    local sym = "ship_parts:engine_part4"
    local am = "ship_parts:engine_part5"
    local flx = "ship_parts:flux_tube"
    local es = "basic_materials:empty_spool"
    local ltp = "spatial_tubes:lv_telepad_machine"
    local mtp = "spatial_tubes:mv_telepad_machine"

    minetest.register_craft({
        output = "spatial_tubes:lv_telepad_machine",
        recipe = {{gw, flx, gw}, {"", sym, ""}, {"", ms, ""}},
        replacements = {{ gw, es .. " 2" }}
    })

    minetest.register_craft({
        output = "spatial_tubes:mv_telepad_machine",
        recipe = {{gw, flx, gw}, {"", ltp, ""}, {"", gw, ""}},
        replacements = {{ gw, es .. " 3" }}
    })

    minetest.register_craft({
        output = "spatial_tubes:hv_telepad_machine",
        recipe = {{gw, flx, gw}, {"", mtp, ""}, {"", am, ""}},
        replacements = {{ gw, es .. " 3" }}
    })
end
