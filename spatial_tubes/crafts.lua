if true then
    local ms = "ship_parts:metal_support"
    local gw = "basic_materials:gold_wire"
    local sym = "ship_parts:engine_part4"
    local flx = "ship_parts:flux_tube"
    local es = "basic_materials:empty_spool"

    minetest.register_craft({
        output = "spatial_tubes:hv_telepad_machine",
        recipe = {{gw, flx, gw}, {"", sym, ""}, {"", ms, ""}},
        replacements = {{ gw, es .. " 2" }}
    })
end
