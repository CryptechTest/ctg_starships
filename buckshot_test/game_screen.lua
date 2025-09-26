local screen_node_box = {
    type = "fixed",
    fixed = {
		{-0.5, -0.5, 0.375, 0.5, -0.1875, 0.5}, -- base
    	{-0.5, -0.1875, 0.375, 0.5, -0.125, 0.4375}, -- top
    	{-0.5, -0.5, 0.34375, 0.5, -0.46875, 0.375}, -- bottom
    	{-0.5, -0.15625, 0.34375, 0.5, -0.125, 0.375}, -- top_part
    	{0.46875, -0.46875, 0.34375, 0.5, -0.15625, 0.375}, -- right
    	{-0.5, -0.46875, 0.34375, -0.46875, -0.15625, 0.375} -- left
    }
}
local screen_collision_box = {
    type = "fixed",
    fixed = {
		{-0.5, -0.5, 0.312500, 0.5, -0.125000, 0.5} -- Base
    }
}

digiterms.register_monitor('buckshot_test:game_counter', {
    description = "Black cathodic monitor with white screen",
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = false,
    drawtype = "nodebox",
    groups = {
        cracky = 2,
		level = 1,
        --oddly_breakable_by_hand = 3
    },
	light_source = 6,
    is_ground_content = false,
    node_box = screen_node_box,
    collision_box = screen_collision_box,
    selection_box = screen_collision_box,
	sounds = default.node_sound_metal_defaults(),
    display_entities = {
        ["digiterms:screen"] = {
            on_display_update = font_api.on_display_update,
            depth = 12 / 32 - display_api.entity_spacing,
            top = 10 / 32,
            size = {
                x = 28 / 32,
                y = 5 / 16
            },
            columns = 8,
            lines = 2,
            color = "#daf564",
            font_name = digiterms.font,
            halign = "left",
            valing = "top"
        }
    },
    tiles = {"game_screen_side.png", "game_screen_side.png", "game_screen_side.png",
             "game_screen_side.png^[transformFX]", "game_screen_side.png", "game_screen_front.png"}
})
