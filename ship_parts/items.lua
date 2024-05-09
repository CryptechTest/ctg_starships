local S = minetest.get_translator(minetest.get_current_modname())

-- Comamnd Capsule
--[[minetest.register_craftitem("ship_parts:command_capsule", {
	description = S("Spacecraft Command Capsule"),
	inventory_image = "ship_command_module.png",
    wield_scale = {x = 1.5, y = 1.4, z = 1.5},
})--]]

-- Comamnd Capsule
minetest.register_node("ship_parts:command_capsule", {
	description = S("Spacecraft Command Capsule"),
    stack_max = 32,
	inventory_image = "ship_command_module.png",
	tiles = {
		"ship_panel_back.png",
		"ship_panel_back.png",
		"ship_panel_back.png",
		"ship_panel_back.png",
		"ship_panel_back.png",
		"ship_panel_front.png"
	},
	--drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky=1, oddly_breakable_by_hand=1},
    sounds = default.node_sound_metal_defaults(),
})

-- System Capsule
minetest.register_craftitem("ship_parts:system_capsule", {
	description = S("Spacecraft Systems Capsule"),
	inventory_image = "ship_systems_module.png",
    stack_max = 64,
    wield_scale = {x = 0.8, y = 0.8, z = 0.8},
})

-- Advanced Circuit
minetest.register_craftitem("ship_parts:circuit_standard", {
	description = S("Standard Circuit Element"),
	inventory_image = "ship_circuit_green.png",
    wield_scale = {x = 0.8, y = 0.8, z = 0.8},
})

-- Advanced Circuit
minetest.register_craftitem("ship_parts:circuit_advanced", {
	description = S("Advanced Circuit Element"),
	inventory_image = "ship_circuit_red.png",
    wield_scale = {x = 0.7, y = 0.7, z = 0.7},
})

-- Telemetry Capsule
minetest.register_craftitem("ship_parts:telemetry_capsule", {
	description = S("Spacecraft Telemetry Capsule"),
	inventory_image = "ship_telemetry_module.png",
    wield_scale = {x = 0.8, y = 0.8, z = 0.8},
})

-- Starship Power Cell
minetest.register_craftitem("ship_parts:power_cell", {
	description = S("Starship Power Cell"),
	inventory_image = "ship_power_cell.png",
    wield_scale = {x = 0.8, y = 0.8, z = 0.8},
    light_source = 3,
})

-- Reactor Cell
minetest.register_craftitem("ship_parts:reactor_cell", {
	description = S("Actuality Reactor Cell"),
	inventory_image = "ship_reactor_cell.png",
    wield_scale = {x = 0.4, y = 0.6, z = 0.4},
    light_source = 4,
})

-- Flux Tube
minetest.register_craftitem("ship_parts:flux_tube", {
	description = S("Spatial Flux Tube"),
	inventory_image = "ship_flux_tube.png",
    wield_scale = {x = 0.8, y = 0.85, z = 0.8},
    light_source = 4,
})

-- Eviromental Component
minetest.register_craftitem("ship_parts:eviromental_sys", {
	description = S("Eviromental Regulator Component"),
	inventory_image = "ship_eviromental_comp.png",
})

-- Starship Hull
--[[minetest.register_craftitem("ship_parts:hull_plating", {
	description = S("Chassis Hull Platings"),
	inventory_image = "ship_hull_plating_sq.png",
    wield_image = "ship_hull_plating.png",
    wield_scale = {x = 2, y = 1.8, z = 2},
	--wield_offset = {x = 0, y = 20, z = 0}, -- does nothing
    --place_offset_y = 2, -- does nothing
})--]]

-- Starship Hull
minetest.register_node("ship_parts:hull_plating", {
	description = S("Chassis Hull Platings"),
    stack_max = 50,
	inventory_image = "ship_hull_plating_sq.png",
    --wield_image = "ship_hull_plating.png",
	tiles = {
		"ship_metal_part_top.png",
		"ship_metal_part_top.png",
		"ship_metal_part_side.png",
		"ship_metal_part_side.png",
		"ship_metal_part_front.png",
		"ship_metal_part_front.png"
	},
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky=1, level=3, metal=1},
    sounds = default.node_sound_metal_defaults(),
})


-- Gravity Drive..
--[[minetest.register_craftitem("ship_parts:mass_aggregator", {
	description = S("Higg Mass Aggregation Apparatus"),
	inventory_image = "ship_mass_aggregator.png",
    light_source = 2,
})--]]

minetest.register_node("ship_parts:mass_aggregator", {
	description = S("Higg Mass Aggregation Apparatus"),
    stack_max = 8,
    inventory_image = "ship_mass_aggregator.png",
    tiles = {"ship_mass_aggregator_top.png", "ship_mass_aggregator_top.png", "ship_mass_aggregator_left.png",
             "ship_mass_aggregator_right.png", "ship_mass_aggregator_back.png", "ship_mass_aggregator_front.png"},
    drawtype = "nodebox",
    paramtype = "light",
    light_source = 3,
    paramtype2 = "facedir",
    groups = {
        cracky = 1,
        oddly_breakable_by_hand = 1,
    },
    sounds = default.node_sound_metal_defaults()
})

-- Spatial Stabilzier
minetest.register_craftitem("ship_parts:spatial_stabilizer", {
	description = S("Noncontiguous Spatial Constraint Stabilizer"),
	inventory_image = "ship_spatial_stabilizer.png",
    light_source = 3,
})

-- Solar Array
minetest.register_craftitem("ship_parts:solar_array", {
	description = S("Spacecraft Solar Array"),
	inventory_image = "ship_solar_array.png",
    wield_scale = {x = 1.25, y = 1.2, z = 1.25},
})

-- Solar Charger
minetest.register_craftitem("ship_parts:solar_collimator", {
	description = S("Photon Actuality Collimator"),
	inventory_image = "ship_solar_charger.png",
})

-- Engine Part..
minetest.register_craftitem("ship_parts:engine_part4", {
	description = S("Dualistic Symmetry Generator"),
	inventory_image = "ship_engine_part4.png",
})

-- Jumpdrive Part..
minetest.register_craftitem("ship_parts:engine_part5", {
	description = S("Cumulative Actuality Monitor"),
	inventory_image = "ship_engine_part5.png",
    wield_scale = {x = 0.6, y = 0.6, z = 0.6},
})

-- Proto-Ship Blue KeyCard
minetest.register_craftitem("ship_parts:proto_ship_key", {
	description = S("Proto-Ship Blue Assembly"),
	inventory_image = "proto_ship_blue_keycard.png",
    wield_scale = {x = 0.9, y = 0.9, z = 0.9},
	stack_max = 1,
})
