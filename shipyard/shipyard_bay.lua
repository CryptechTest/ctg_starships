local S = minetest.get_translator(minetest.get_current_modname())

local function machine_can_dig(pos, player)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    if not inv:is_empty("ship1") then
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

local function load_schematic_ship_shell(pos, filename)
    local default_path = minetest.get_modpath("shipyard")
    -- load the schematic from file..
    local lmeta = schemlib.load_emitted_file({
        filename = filename,
        origin = {
            x = pos.x,
            y = pos.y,
            z = pos.z
        },
        moveObj = false,
        filepath = default_path .. "/schematics/"
    })
end

local function register_assembler_bay(data)

    local machine_name = string.lower(data.name)
    local machine_desc = data.name

    local update_formspec = function(pos, data)
        --local formspec = nil

        local btnName = "Launch"

        local bg = "image[0,0;10,6.0;starfield_2.png]"

        local formspec = {
            "formspec_version[6]",
            "size[10,11.15]", bg,
            "image[0,0;5,0.5;console_bg.png]",
            "label[0.2,0.3;Shipyard Assembly Bay: Proto Class]",

            -- player inv
            "list[current_player;main;0.15,6.25;8,4;]",
            "listring[current_player;main]",

            -- topbar
            --"button[6,0;3,0.5;begin;Begin]",
            "button_exit[9,0;1,0.5;exit;Exit]",

            -- input
            "label[2.6,0.8;Key]",
            "list[current_name;ship1;2.5,1;1,2;0]",
            "listring[current_name;ship1]",
            
            "button[2.6,3.0;3.5,0.6;begin_prefab;Begin Prefab]",
            "button[2.6,3.6;3.5,0.6;begin_custom;Begin Framed]",
            "button[2.6,4.2;3.5,0.6;begin_empty;Begin Empty]"

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

        if fields.begin_prefab then
            local inv = meta:get_inventory()
            local rdy = get_count(inv, "ship1", "ship_parts:proto_ship_key") > 0
            if sender and not rdy then
                minetest.chat_send_player(sender:get_player_name(),
                    S("Assembly is blocked. You require a key to use this..."))
            elseif sender then
                local offset = {x = 0, y = 2, z = 1 + 2 + 14}
                local core_pos = vector.add(pos, offset)

                if minetest.get_node(core_pos).name == "ship_machine:jump_drive" then
                    minetest.chat_send_player(sender:get_player_name(),
                    S("This shipyard bay is occupied..."))
                    return
                end

                local items = inv:get_list("ship1")
                items[1] = nil
                inv:set_list("ship1", items)

                local op =  sender:get_player_name();
                meta:set_string("operator", op)

                shipyard.do_particle_effects(core_pos, 70);

                minetest.chat_send_player(sender:get_player_name(),
                    S("Assembling Jumpship..."))
                load_schematic_ship_shell(core_pos, "proto_scout1b");

                minetest.after(7, function()   
                    minetest.set_node(core_pos, {
                        name = "ship_machine:jump_drive"
                    })
                    local core_meta = minetest.get_meta(core_pos);
                    core_meta:set_string("owner", op)
                    core_meta:set_int("locked", 1)
                    
                    local prot_pos = vector.add(core_pos, {x = 0, y = 2, z = 0})
                    minetest.set_node(prot_pos, {
                        name = "ship_scout:protect2"
                    })
                    local prot_meta = minetest.get_meta(prot_pos);
                    prot_meta:set_string("owner", op)
                    prot_meta:set_string("members", "")
                    prot_meta:set_string("infotext", S("Protection (owned by @1)", op))
                    prot_meta:set_int("p_width", 12);
                    prot_meta:set_int("p_length", 15);
                    prot_meta:set_int("p_height", 12);
                    minetest.chat_send_player(sender:get_player_name(),
                        S("Jumpship Assembly Ready!"))
                end)
            end
        elseif fields.begin_custom or fields.begin_empty then
            local inv = meta:get_inventory()
            local rdy = get_count(inv, "ship1", "ship_parts:proto_ship_key") > 0
            if sender and not rdy then
                minetest.chat_send_player(sender:get_player_name(),
                    S("Assembly is blocked. You require a key to use this..."))
            elseif sender then
                local offset = {x = 0, y = 2, z = 1 + 2 + 14}
                local core_pos = vector.add(pos, offset)

                if minetest.get_node(core_pos).name == "ship_machine:jump_drive" then
                    minetest.chat_send_player(sender:get_player_name(),
                    S("This shipyard bay is occupied..."))
                    return
                end

                local items = inv:get_list("ship1")
                items[1] = nil
                inv:set_list("ship1", items)

                local op =  sender:get_player_name();
                meta:set_string("operator", op)

                shipyard.do_particle_effects(core_pos, 70);

                if fields.begin_custom then
                    minetest.chat_send_player(sender:get_player_name(),
                        S("Assembling Jumpship Frame..."))
                    load_schematic_ship_shell(core_pos, "ship_frame1");
                else
                    minetest.chat_send_player(sender:get_player_name(),
                        S("Assembling Jumpship Skeleton..."))
                    load_schematic_ship_shell(core_pos, "ship_frame0");
                end

                minetest.after(5, function()   
                    minetest.set_node(core_pos, {
                        name = "ship_machine:jump_drive"
                    })
                    local core_meta = minetest.get_meta(core_pos);
                    core_meta:set_string("owner", op)
                    core_meta:set_int("locked", 1)
                    
                    local prot_pos = vector.add(core_pos, {x = 0, y = 2, z = 0})
                    minetest.set_node(prot_pos, {
                        name = "ship_scout:protect2"
                    })
                    local prot_meta = minetest.get_meta(prot_pos);
                    prot_meta:set_string("owner", op)
                    prot_meta:set_string("members", "")
                    prot_meta:set_string("infotext", S("Protection (owned by @1)", op))
                    prot_meta:set_int("p_width", 12);
                    prot_meta:set_int("p_length", 15);
                    prot_meta:set_int("p_height", 12);
                    minetest.chat_send_player(sender:get_player_name(),
                        S("Jumpship Framing Ready!"))
                end)
            end
        end

        local formspec = update_formspec(pos, data)
        meta:set_string("formspec", formspec)
    end

    minetest.register_node("shipyard:assembler_bay", {
        description = S("Jumpship Assembler Bay"),
        tiles = {{
            name = "ship_deployer.png"
            -- backface_culling = false
        }},
        groups = {
            cracky = 1,
            metal = 1,
            level = 1,
            not_in_creative_inventory = 1
        },
        sounds = default.node_sound_metal_defaults(),
        -- drawtype = "glasslike_framed",
        -- climbable = true,
        -- sunlight_propagates = true,
        paramtype = "light",

        on_receive_fields = on_receive_fields,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Jumpship Assembler " .. "-" .. " " .. machine_desc)
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
            inv:set_size("ship1", 1)
            meta:set_int("enabled", 1)
            meta:set_string("operator", "")            
            meta:set_string("formspec", update_formspec(pos, data))
        end,
    })

end

register_assembler_bay({
    name = "Shipyard Bay"
});