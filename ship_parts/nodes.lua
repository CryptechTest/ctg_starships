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
    description = S("Aluminum Support"),
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
            "button[4,0;2,0.5;crew;Crew]",
            "button[6,0;3,0.5;launch;Launch]",
            "button[9,0;1,0.5;exit;Exit]",

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
            "image[3.9,3;1,1;ship_solar_charger.png]",
            "image[5.15,3;1,1;ship_eviromental_comp.png]",
            "list[current_name;systems;3.9,3;2,1;0]",
            "listring[current_name;systems]",
            "label[4.5,3.2;50]",
            "label[5.7,3.2;42]",
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
            "label[3,4.9;10]",
            -- eng 2
            "image[6.5,4.7;1,1;ship_mass_aggregator.png]",
            "list[current_name;eng2;6.5,4.7;1,1;0]",
            "listring[current_name;eng2]",
            "label[7,4.9;10]",
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
        if fields.quit then
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

        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Starship Assembler " .. "-" .. " " .. machine_desc)
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
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
        end
    })

end

register_assembler({
    name = "Scout"
});
