
minetest.register_node("buckshot_test:sink_bathroom", {
	description = S("Bathroom Sink"),
    -- up, down, right, left, back, front
	tiles = {
		"bst_sink_top_hd.png",
		"bst_cab_bottom.png",
		"bst_sink_side.png",
		"bst_sink_side.png",
		"bst_sink_side.png",
		"bst_sink_front_hd.png"
	},
	drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 2,
		level = 1,
    },
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.375, 0.5, 0.25, 0.5}, -- cab
			{-0.5, 0.25, -0.5, 0.5, 0.3125, 0.5}, -- top
			{-0.5, 0.3125, 0.3125, 0.5, 0.5, 0.5}, -- back
			{-0.5, 0.3125, -0.5, 0.5, 0.5, -0.3125}, -- front
			{0.3125, 0.3125, -0.3125, 0.5, 0.5, 0.3125}, -- right
			{-0.5, 0.3125, -0.3125, -0.3125, 0.5, 0.3125}, -- left
			{-0.4375, 0.5, 0.3125, 0.4375, 0.5625, 0.4375}, -- sink_back
			{-0.4375, 0.5, -0.4375, 0.4375, 0.5625, -0.3125}, -- sink_front
			{0.3125, 0.5, -0.3125, 0.4375, 0.5625, 0.3125}, -- sink_right
			{-0.4375, 0.5, -0.3125, -0.3125, 0.5625, 0.3125}, -- sink_left
			{-0.125, 0.5, 0.3125, 0.125, 0.75, 0.46875}, -- spigot_back
			{-0.0625, 0.6875, 0.0625, 0.0625, 0.75, 0.3125}, -- spigot
			{-0.40625, 0.5625, 0.34375, 0.40625, 0.578125, 0.40625}, -- sink_back_t
			{-0.40625, 0.5625, -0.40625, 0.40625, 0.578125, -0.34375}, -- sink_front_t
			{0.34375, 0.5625, -0.40625, 0.40625, 0.578125, 0.40625}, -- sink_right_t
			{-0.40625, 0.5625, -0.40625, -0.34375, 0.578125, 0.40625}, -- sink_left_t
			{-0.03125, 0.65625, 0.0625, 0.03125, 0.6875, 0.125}, -- spigot_mouth
		}
	},
    selection_box = {
        type = "fixed",
		fixed = {
            {-0.5, -0.5, -0.375, 0.5, 0.25, 0.5}, -- cab_sel
			{-0.5, 0.1875, -0.5, 0.5, 0.5, 0.5}, -- cab_top
        }
    }
})

minetest.register_node("buckshot_test:cabinet_bathroom", {
    description = S("Bathroom Cabinet"),
    -- up, down, right, left, back, front
	tiles = {
		"bst_cab_top.png",
		"bst_cab_bottom.png",
		"bst_cab_front.png",
		"bst_cab_front.png",
		"bst_cab_front.png",
		"bst_cab_front.png"
	},
	drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 2,
        level = 1,
    },
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.375, 0.5, 0.25, 0.5}, -- cab
			{-0.5, 0.1875, -0.5, 0.5, 0.5, 0.5}, -- cab_top
		}
	},
    selection_box = {
        type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.375, 0.5, 0.25, 0.5}, -- cab
			{-0.5, 0.1875, -0.5, 0.5, 0.5, 0.5}, -- cab_top
        }
    }
})
