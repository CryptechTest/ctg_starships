local crs = "group:crystal"
local alm = "ctg_world:aluminum_block"
local grv = "ship_machine:lv_gravity_drive_lite"
local tel = "ship_parts:telemetry_capsule"
local hul = "ship_parts:hull_plating"
local slr = "ship_parts:solar_array"

minetest.register_craft({
    output = "ship_dock:docking_port_ref",
    recipe = {{slr, crs, slr}, {alm, tel, alm}, {hul, grv, hul}}
})
