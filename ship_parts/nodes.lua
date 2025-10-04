local S = minetest.get_translator(minetest.get_current_modname())

local box_slope_col = {
	type = "fixed",
	fixed = {
		{-0.5,  -0.5,  -0.5, 0.5, -0.25, 0.5},
		{-0.5, -0.25, -0.25, 0.5,     0, 0.5},
		{-0.5,     0,     0, 0.5,  0.25, 0.5},
		{-0.5,  0.25,  0.25, 0.5,   0.5, 0.5}
	}
}

minetest.register_node("ship_parts:metal_support", {
    description = S("Stainless Steel Support"),
    tiles = {{
        name = "steel_support.png",
        backface_culling = false
    }},
    groups = {
        cracky = 1,
        metal = 1,
        level = 1,
        leaky = 1
    },
    sounds = default.node_sound_metal_defaults(),
    drawtype = "glasslike_framed",
    -- climbable = true,
    sunlight_propagates = true,
	is_ground_content = false,
    paramtype = "light"
})

local metal_tile = {
	name = "aluminum_support.png",
	backface_culling = true
}

minetest.register_node("ship_parts:metal_support_slant", {
    description = S("Stainless Steel Support Slanted"),
    tiles = {{
        name = "steel_support.png",
        backface_culling = false
    }, metal_tile, metal_tile, metal_tile, metal_tile, metal_tile},
	paramtype2 = "facedir",
	use_texture_alpha = "clip",
    groups = {
        cracky = 1,
        metal = 1,
        level = 1,
        leaky = 1
    },
	drawtype = "mesh",
	--drawtype = "glasslike_framed",
	mesh = "moreblocks_slope.obj",
	selection_box = box_slope_col,
	collision_box = box_slope_col,
    sounds = default.node_sound_metal_defaults(),
    -- climbable = true,
    sunlight_propagates = true,
	is_ground_content = false,
    paramtype = "light"
})

minetest.register_node("ship_parts:aluminum_support", {
    description = S("Aluminum Support"),
    tiles = {{
        name = "aluminum_support.png",
        backface_culling = false
    }},
    groups = {
        cracky = 1,
        metal = 1,
        level = 1,
        leaky = 1
    },
    sounds = default.node_sound_metal_defaults(),
    drawtype = "glasslike_framed",
    -- climbable = true,
    sunlight_propagates = true,
	is_ground_content = false,
    paramtype = "light"
})

local alum_tile = {
	name = "aluminum_support.png",
	backface_culling = true
}

minetest.register_node("ship_parts:aluminum_support_slant", {
    description = S("Aluminum Support Slanted"),
    tiles = {{
        name = "aluminum_support.png",
        backface_culling = false
    }, alum_tile, alum_tile, alum_tile, alum_tile, alum_tile},
	paramtype2 = "facedir",
	use_texture_alpha = "clip",
    groups = {
        cracky = 1,
        metal = 1,
        level = 1,
        leaky = 1
    },
	drawtype = "mesh",
	--drawtype = "glasslike_framed",
	mesh = "moreblocks_slope.obj",
	selection_box = box_slope_col,
	collision_box = box_slope_col,
    sounds = default.node_sound_metal_defaults(),
    -- climbable = true,
    sunlight_propagates = true,
	is_ground_content = false,
    paramtype = "light"
})

minetest.register_node("ship_parts:lightbar_white", {
	description = "Node Light White",
	tiles = {
		"ctg_light_white.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	light_source = minetest.LIGHT_MAX - 1,
	node_box = {
		type = "fixed",
		fixed = {
            {-0.3125, -0.5, -0.125, 0.3125, -0.375, 0.125}, -- NodeBox1
			{-0.125, -0.5, -0.3125, 0.125, -0.375, 0.3125}, -- NodeBox2
			{-0.1875, -0.5, -0.1875, 0.1875, -0.3125, 0.1875}, -- NodeBox3
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
            {-0.3125, -0.5, -0.125, 0.3125, -0.375, 0.125}, -- NodeBox1
			{-0.125, -0.5, -0.3125, 0.125, -0.375, 0.3125}, -- NodeBox2
		}
	},
	groups = {cracky=1, dig_generic = 3, leaky = 1},
	is_ground_content = false,
	sounds = scifi_nodes.node_sound_glass_defaults()
})

minetest.register_node("ship_parts:lightbar_blue", {
	description = "Node Light Blue",
	tiles = {
		"ctg_light_blue.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	light_source = minetest.LIGHT_MAX - 1,
	node_box = {
		type = "fixed",
		fixed = {
            {-0.3125, -0.5, -0.125, 0.3125, -0.375, 0.125}, -- NodeBox1
			{-0.125, -0.5, -0.3125, 0.125, -0.375, 0.3125}, -- NodeBox2
			{-0.1875, -0.5, -0.1875, 0.1875, -0.3125, 0.1875}, -- NodeBox3
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
            {-0.3125, -0.5, -0.125, 0.3125, -0.375, 0.125}, -- NodeBox1
			{-0.125, -0.5, -0.3125, 0.125, -0.375, 0.3125}, -- NodeBox2
		}
	},
	groups = {cracky=1, dig_generic = 3, leaky = 1},
	is_ground_content = false,
	sounds = scifi_nodes.node_sound_glass_defaults()
})

minetest.register_node("ship_parts:light_dot_white", {
	description = "Node Light Dot White",
	tiles = {
		"ctg_light_white.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	light_source = minetest.LIGHT_MAX - 2,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.171875, 0.125, -0.34375, 0.171875}, -- base1
			{-0.171875, -0.5, -0.125, 0.171875, -0.34375, 0.125}, -- base2
			{-0.125, -0.34375, -0.125, 0.125, -0.25, 0.125}, -- top1
			{-0.0625, -0.25, -0.0625, 0.0625, -0.21875, 0.0625}, -- top2
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
            {-0.1875, -0.5, -0.1875, 0.1875, -0.1875, 0.1875}, -- sel_box
		}
	},
	groups = {cracky=1, dig_generic = 3, leaky = 1},
	is_ground_content = false,
	sounds = scifi_nodes.node_sound_glass_defaults()
})

minetest.register_node("ship_parts:light_dot_blue", {
	description = "Node Light Dot Blue",
	tiles = {
		"ctg_light2_blue.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	light_source = minetest.LIGHT_MAX - 2,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.171875, 0.125, -0.34375, 0.171875}, -- base1
			{-0.171875, -0.5, -0.125, 0.171875, -0.34375, 0.125}, -- base2
			{-0.125, -0.34375, -0.125, 0.125, -0.25, 0.125}, -- top1
			{-0.0625, -0.25, -0.0625, 0.0625, -0.21875, 0.0625}, -- top2
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
            {-0.1875, -0.5, -0.1875, 0.1875, -0.1875, 0.1875}, -- sel_box
		}
	},
	groups = {cracky=1, dig_generic = 3, leaky = 1},
	is_ground_content = false,
	sounds = scifi_nodes.node_sound_glass_defaults()
})

minetest.register_node("ship_parts:light_dot_red", {
	description = "Node Light Dot Red",
	tiles = {
		"ctg_light2_red.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	light_source = minetest.LIGHT_MAX - 2,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.171875, 0.125, -0.34375, 0.171875}, -- base1
			{-0.171875, -0.5, -0.125, 0.171875, -0.34375, 0.125}, -- base2
			{-0.125, -0.34375, -0.125, 0.125, -0.25, 0.125}, -- top1
			{-0.0625, -0.25, -0.0625, 0.0625, -0.21875, 0.0625}, -- top2
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
            {-0.1875, -0.5, -0.1875, 0.1875, -0.1875, 0.1875}, -- sel_box
		}
	},
	groups = {cracky=1, dig_generic = 3, leaky = 1},
	is_ground_content = false,
	sounds = scifi_nodes.node_sound_glass_defaults()
})

minetest.register_node("ship_parts:light_dot_yellow", {
	description = "Node Light Dot Yellow",
	tiles = {
		"ctg_light2_yellow.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	light_source = minetest.LIGHT_MAX - 2,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.171875, 0.125, -0.34375, 0.171875}, -- base1
			{-0.171875, -0.5, -0.125, 0.171875, -0.34375, 0.125}, -- base2
			{-0.125, -0.34375, -0.125, 0.125, -0.25, 0.125}, -- top1
			{-0.0625, -0.25, -0.0625, 0.0625, -0.21875, 0.0625}, -- top2
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
            {-0.1875, -0.5, -0.1875, 0.1875, -0.1875, 0.1875}, -- sel_box
		}
	},
	groups = {cracky=1, dig_generic = 3, leaky = 1},
	is_ground_content = false,
	sounds = scifi_nodes.node_sound_glass_defaults()
})

minetest.register_node("ship_parts:light_dot_green", {
	description = "Node Light Dot Green",
	tiles = {
		"ctg_light2_green.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	light_source = minetest.LIGHT_MAX - 2,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.171875, 0.125, -0.34375, 0.171875}, -- base1
			{-0.171875, -0.5, -0.125, 0.171875, -0.34375, 0.125}, -- base2
			{-0.125, -0.34375, -0.125, 0.125, -0.25, 0.125}, -- top1
			{-0.0625, -0.25, -0.0625, 0.0625, -0.21875, 0.0625}, -- top2
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
            {-0.1875, -0.5, -0.1875, 0.1875, -0.1875, 0.1875}, -- sel_box
		}
	},
	groups = {cracky=1, dig_generic = 3, leaky = 1},
	is_ground_content = false,
	sounds = scifi_nodes.node_sound_glass_defaults()
})

minetest.register_node("ship_parts:light_dot_orange", {
	description = "Node Light Dot Orange",
	tiles = {
		"ctg_light2_orange.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	light_source = minetest.LIGHT_MAX - 2,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.171875, 0.125, -0.34375, 0.171875}, -- base1
			{-0.171875, -0.5, -0.125, 0.171875, -0.34375, 0.125}, -- base2
			{-0.125, -0.34375, -0.125, 0.125, -0.25, 0.125}, -- top1
			{-0.0625, -0.25, -0.0625, 0.0625, -0.21875, 0.0625}, -- top2
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
            {-0.1875, -0.5, -0.1875, 0.1875, -0.1875, 0.1875}, -- sel_box
		}
	},
	groups = {cracky=1, dig_generic = 3, leaky = 1},
	is_ground_content = false,
	sounds = scifi_nodes.node_sound_glass_defaults()
})

minetest.register_node("ship_parts:light_dot_purple", {
	description = "Node Light Dot Purple",
	tiles = {
		"ctg_light2_purple.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	light_source = minetest.LIGHT_MAX - 2,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.171875, 0.125, -0.34375, 0.171875}, -- base1
			{-0.171875, -0.5, -0.125, 0.171875, -0.34375, 0.125}, -- base2
			{-0.125, -0.34375, -0.125, 0.125, -0.25, 0.125}, -- top1
			{-0.0625, -0.25, -0.0625, 0.0625, -0.21875, 0.0625}, -- top2
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
            {-0.1875, -0.5, -0.1875, 0.1875, -0.1875, 0.1875}, -- sel_box
		}
	},
	groups = {cracky=1, dig_generic = 3, leaky = 1},
	is_ground_content = false,
	sounds = scifi_nodes.node_sound_glass_defaults()
})

minetest.register_node("ship_parts:light_dot_magenta", {
	description = "Node Light Dot Magenta",
	tiles = {
		"ctg_light2_magenta.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	light_source = minetest.LIGHT_MAX - 2,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.171875, 0.125, -0.34375, 0.171875}, -- base1
			{-0.171875, -0.5, -0.125, 0.171875, -0.34375, 0.125}, -- base2
			{-0.125, -0.34375, -0.125, 0.125, -0.25, 0.125}, -- top1
			{-0.0625, -0.25, -0.0625, 0.0625, -0.21875, 0.0625}, -- top2
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
            {-0.1875, -0.5, -0.1875, 0.1875, -0.1875, 0.1875}, -- sel_box
		}
	},
	groups = {cracky=1, dig_generic = 3, leaky = 1},
	is_ground_content = false,
	sounds = scifi_nodes.node_sound_glass_defaults()
})

minetest.register_node("ship_parts:light_dot_navy", {
	description = "Node Light Dot Dark Blue",
	tiles = {
		"ctg_light2_navy.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	light_source = minetest.LIGHT_MAX - 2,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.171875, 0.125, -0.34375, 0.171875}, -- base1
			{-0.171875, -0.5, -0.125, 0.171875, -0.34375, 0.125}, -- base2
			{-0.125, -0.34375, -0.125, 0.125, -0.25, 0.125}, -- top1
			{-0.0625, -0.25, -0.0625, 0.0625, -0.21875, 0.0625}, -- top2
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
            {-0.1875, -0.5, -0.1875, 0.1875, -0.1875, 0.1875}, -- sel_box
		}
	},
	groups = {cracky=1, dig_generic = 3, leaky = 1},
	is_ground_content = false,
	sounds = scifi_nodes.node_sound_glass_defaults()
})
