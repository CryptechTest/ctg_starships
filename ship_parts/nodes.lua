local S = minetest.get_translator(minetest.get_current_modname())

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
    backface_culling = false,
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
    paramtype = "light"
})

local function machine_can_dig(pos, player)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    if not inv:is_empty("hull1") or not inv:is_empty("hull2")
            or not inv:is_empty("ship1") or not inv:is_empty("ship2")
            or not inv:is_empty("command") or not inv:is_empty("systems")
            or not inv:is_empty("env") or not inv:is_empty("enabled") 
            or not inv:is_empty("eng1") or not inv:is_empty("eng2") then
        if player then
            minetest.chat_send_player(player:get_player_name(),
                S("Assembler cannot be removed because it is not empty"))
        end
        return false
    end

    return true
end

local function get_count(inv, name, itm)
    local balance = 0
    local items = inv:get_list(name)
    if items and #items > 0 then
        for _, item in ipairs(items) do
            if item ~= nil and not item:is_empty() and item:get_name() == itm then
                balance = balance + item:get_count()
            end
        end
    end
    return balance
end

local function assembler_is_full(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    if not inv:is_empty("hull1") and not inv:is_empty("hull2")
            and not inv:is_empty("ship1") and not inv:is_empty("ship2")
            and not inv:is_empty("command") and not inv:is_empty("systems")
            and not inv:is_empty("env") and not inv:is_empty("eng1") and not inv:is_empty("eng2") then
        local chull1 = get_count(inv, "hull1", "ship_parts:hull_plating")
        local chull2 = get_count(inv, "hull2", "ship_parts:hull_plating")
        local cship1 = get_count(inv, "ship1", "scifi_nodes:white2")
        local cship2 = get_count(inv, "ship2", "scifi_nodes:white2")
        local ccommand1 = get_count(inv, "command", "ship_parts:command_capsule")
        local ccommand2 = get_count(inv, "command", 'ship_parts:system_capsule')
        local csystems1 = get_count(inv, "systems", "ship_parts:solar_array")
        local csystems2 = get_count(inv, "systems", "ship_parts:eviromental_sys")
        local cenv = get_count(inv, "env", "ctg_airs:air_duct_S")
        local ceng1 = get_count(inv, "eng1", "ship_parts:mass_aggregator")
        local ceng2 = get_count(inv, "eng2", "ship_parts:mass_aggregator")

        local ready = false
        if chull1 == 100 and chull2 == 100 and cship1 == 198 and cship2 == 198 and
                ccommand1 == 10 and ccommand2 == 20 and csystems1== 40 and csystems2 == 30 and
                cenv == 198 and ceng1 == 3 and ceng2 == 3 then
            ready = true
        end
        return ready
    end

    return false
end

local function clear_assembler(pos) 
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_list("hull1", {})
    inv:set_list("hull2", {})
    inv:set_list("ship1", {})
    inv:set_list("ship2", {})
    inv:set_list("command", {})
    inv:set_list("systems", {})
    inv:set_list("env", {})
    inv:set_list("eng1", {})
    inv:set_list("eng2", {})
    local chull1 = get_count(inv, "hull1", "ship_parts:hull_plating")
    local chull2 = get_count(inv, "hull2", "ship_parts:hull_plating")
    local cship1 = get_count(inv, "ship1", "scifi_nodes:white2")
    local cship2 = get_count(inv, "ship2", "scifi_nodes:white2")
    local ccommand1 = get_count(inv, "command", "ship_parts:command_capsule")
    local ccommand2 = get_count(inv, "command", 'ship_parts:system_capsule')
    local csystems1 = get_count(inv, "systems", "ship_parts:solar_array")
    local csystems2 = get_count(inv, "systems", "ship_parts:eviromental_sys")
    local cenv = get_count(inv, "env", "ctg_airs:air_duct_S")
    local ceng1 = get_count(inv, "eng1", "ship_parts:mass_aggregator")
    local ceng2 = get_count(inv, "eng2", "ship_parts:mass_aggregator")
    return chull1 == 0 and chull2 == 0 and cship1 == 0 and cship2 == 0 and
        ccommand1 == 0 and ccommand2 == 0 and csystems1== 0 and csystems2 == 0 and
        cenv == 0 and ceng1 == 0 and ceng2 == 0
end

local function check_full(sender, stack)
	local one_item_stack = ItemStack(stack)
	one_item_stack:set_count(1)
	if not sender:get_inventory():room_for_item("main", one_item_stack) then
		return true
	end
    return false
end

local function register_assembler(data)

    local machine_name = string.lower(data.name)
    local machine_desc = data.name

    local update_formspec = function(pos, data)
        --local formspec = nil

        local btnName = "Launch"

        local bg = "image[0,0;10,6.0;starfield_2.png]"

        local formspec = {
            "formspec_version[6]",
            "size[10,11.15]", bg,
            "image[0,0;3.5,0.5;console_bg.png]",
            "label[0.2,0.3;Assembler: Scout]",

            -- player inv
            "list[current_player;main;0.15,6.25;8,4;]",
            "listring[current_player;main]",

            -- topbar
            --"button[4,0;2,0.5;crew;Crew]",
            "button[6,0;3,0.5;launch;Launch]",
            "button_exit[9,0;1,0.5;exit;Exit]",

            -- hull 1
            "image[1,1;1,1;ship_hull_plating_sq.png]",
            "image[1,2.25;1,1;ship_hull_plating_sq.png]",
            "image[1,3.5;1,1;ship_hull_plating_sq.png]",
            "image[1,4.75;1,1;ship_hull_plating_sq.png]",
            "list[current_name;hull1;1,1;1,4;0]",
            "listring[current_name;hull1]",
            "label[1.6,1.2;25]",
            "label[1.6,2.4;25]",
            "label[1.6,3.7;25]",
            "label[1.6,4.9;25]",
            -- hull 2
            "image[8,1;1,1;ship_hull_plating_sq.png]",
            "image[8,2.25;1,1;ship_hull_plating_sq.png]",
            "image[8,3.5;1,1;ship_hull_plating_sq.png]",
            "image[8,4.75;1,1;ship_hull_plating_sq.png]",
            "list[current_name;hull2;8,1;1,4;0]",
            "listring[current_name;hull2]",
            "label[8.6,1.2;25]",
            "label[8.6,2.4;25]",
            "label[8.6,3.7;25]",
            "label[8.6,4.9;25]",
            -- command
            "image[3.9,1;1,1;ship_command_module.png]",
            "image[5.15,1;1,1;ship_systems_module.png]",
            "list[current_name;command;3.9,1;2,1;0]",
            "listring[current_name;command]",
            "label[4.5,1.2;10]",
            "label[5.7,1.2;20]",
            -- ship 1
            "image[2.5,1;1,1;ship_parts_plastic_icon.png]",
            "image[2.5,2.25;1,1;ship_parts_plastic_icon.png]",
            "list[current_name;ship1;2.5,1;1,2;0]",
            "listring[current_name;ship1]",
            "label[3.1,1.2;99]",
            "label[3.1,2.4;99]",
            -- ship 2
            "image[6.5,1;1,1;ship_parts_plastic_icon.png]",
            "image[6.5,2.25;1,1;ship_parts_plastic_icon.png]",
            "list[current_name;ship2;6.5,1;1,2;0]",
            "listring[current_name;ship2]",
            "label[7.1,1.2;99]",
            "label[7.1,2.4;99]",
            -- systems
            "image[3.9,3;1,1;ship_solar_array.png]",
            "image[5.15,3;1,1;ship_eviromental_comp.png]",
            "list[current_name;systems;3.9,3;2,1;0]",
            "listring[current_name;systems]",
            "label[4.5,3.2;40]",
            "label[5.7,3.2;30]",
            -- env
            "image[3.9,4.7;1,1;ship_parts_duct_icon.png]",
            "image[5.15,4.7;1,1;ship_parts_duct_icon.png]",
            "list[current_name;env;3.9,4.7;2,1;0]",
            "listring[current_name;env]",
            "label[4.5,4.9;99]",
            "label[5.7,4.9;99]",
            -- eng 1
            "image[2.5,4.7;1,1;ship_mass_aggregator.png]",
            "list[current_name;eng1;2.5,4.7;1,1;0]",
            "listring[current_name;eng1]",
            "label[3,4.9;3]",
            -- eng 2
            "image[6.5,4.7;1,1;ship_mass_aggregator.png]",
            "list[current_name;eng2;6.5,4.7;1,1;0]",
            "listring[current_name;eng2]",
            "label[7,4.9;3]",
            -- labels
            "label[1.2,0.8;Hull]",
            "label[8.2,0.8;Hull]",
            "label[2.6,0.8;Ship]",
            "label[6.7,0.8;Ship]",
            "label[4.2,0.8;Command]",
            "label[2.5,4.5;Engine]",
            "label[6.5,4.5;Engine]",
            "label[3.9,4.5;Environmental]",
            "label[4.3,2.8;Systems]",
            
        }
        
        return table.concat(formspec) 
    end

    local on_receive_fields = function(pos, formname, fields, sender)
        if fields.quit or fields.exit then
            return
        end
        local node = minetest.get_node(pos)
        local meta = minetest.get_meta(pos)
        local enabled = false
        if fields.toggle then
            if meta:get_int("enabled") == 1 then
                meta:set_int("enabled", 0)
            else
                meta:set_int("enabled", 1)
                enabled = true
            end
        end

        if fields.crew then
            if sender then
                minetest.chat_send_player(sender:get_player_name(),
                    S("Crew Control not implemented yet.."))
            end
        end
        if fields.launch then
            local rdy = assembler_is_full(pos)
            if sender and not rdy then
                minetest.chat_send_player(sender:get_player_name(),
                    S("Launch is not yet ready. You require additional materials.."))
            elseif sender then
                minetest.chat_send_player(sender:get_player_name(),
                    S("Launch is ready."))
                if not check_full(sender, "ship_parts:proto_ship_key") then
                    if clear_assembler(pos) then
                        sender:get_inventory():add_item("main", "ship_parts:proto_ship_key")
                        minetest.chat_send_player(sender:get_player_name(),
                            S("Blueprint Key Granted!"))
                    else
                        minetest.chat_send_player(sender:get_player_name(),
                            S("Error on Key Create!"))
                    end
                else
                    minetest.chat_send_player(sender:get_player_name(),
                        S("there is no room in your inventory..."))
                end
            end
        end

        local formspec = update_formspec(pos, data)
        meta:set_string("formspec", formspec)
    end

    minetest.register_node("ship_parts:assembler", {
        description = S("Starship Assembler"),
        tiles = {{
            name = "ship_deployer.png"
            -- backface_culling = false
        }},
        groups = {
            cracky = 1,
            metal = 1,
            level = 1
        },
        sounds = default.node_sound_metal_defaults(),
        -- drawtype = "glasslike_framed",
        -- climbable = true,
        -- sunlight_propagates = true,
        paramtype = "light",

        on_receive_fields = on_receive_fields,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Starship Assembler " .. "-" .. " " .. machine_desc)
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = machine_can_dig,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            inv:set_size("hull1", 4)
            inv:set_size("hull2", 4)
            inv:set_size("ship1", 2)
            inv:set_size("ship2", 2)
            inv:set_size("command", 2)
            inv:set_size("systems", 2)
            inv:set_size("env", 2)
            inv:set_size("eng1", 1)
            inv:set_size("eng2", 1)
            meta:set_int("enabled", 1)
            meta:set_string("formspec", update_formspec(pos, data))
        end,
    })

end

register_assembler({
    name = "Scout"
});


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
