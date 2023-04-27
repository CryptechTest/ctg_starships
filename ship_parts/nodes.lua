local S = minetest.get_translator(minetest.get_current_modname())

minetest.register_node("ship_parts:metal_support", {
    description = streets.S("Stainless Steel Support"),
    tiles = {{
        name = "steel_support.png",
        backface_culling = false
    }},
    groups = {
        cracky = 1,
        metal = 1,
        level = 1
    },
    sounds = default.node_sound_metal_defaults(),
    drawtype = "glasslike_framed",
    -- climbable = true,
    sunlight_propagates = true,
    backface_culling = false,
    paramtype = "light"
})

minetest.register_node("ship_parts:aluminum_support", {
    description = streets.S("Aluminum Support"),
    tiles = {{
        name = "aluminum_support.png",
        backface_culling = false
    }},
    groups = {
        cracky = 1,
        metal = 1,
        level = 1
    },
    sounds = default.node_sound_metal_defaults(),
    drawtype = "glasslike_framed",
    -- climbable = true,
    sunlight_propagates = true,
    paramtype = "light"
})
