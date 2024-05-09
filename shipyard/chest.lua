local S = minetest.get_translator(minetest.get_current_modname())

shipyard.can_access_crate = function(clicker, pos)

    if not clicker or not pos then
        return false
    end

    -- protector_bypass privileged users can override protection
    if minetest.check_player_privs(clicker, {
        protection_bypass = true
    }) then
        return true
    end

    local s = shipyard.size;
    -- find the protector nodes
    local prots = minetest.find_nodes_in_area({
        x = pos.x - s.w,
        y = pos.y - s.h,
        z = pos.z - s.l
    }, {
        x = pos.x + s.w,
        y = pos.y + s.h,
        z = pos.z + s.l
    }, {"shipyard:protect2", "ship_scout:protect2"}) -- "shipyard:protect2",

    local isValid = false
    for n = 1, #prots do
		if isValid then
			break;
		end
        local node = minetest.get_node(prots[n])
        if node.name == "ship_scout:protect2" then
            local meta = minetest.get_meta(prots[n])
            local owner = meta:get_string("owner") or ""

            local sc = {
                w = meta:get_int("p_width") or 0,
                l = meta:get_int("p_length") or 0,
                h = meta:get_int("p_height") or 0
            }
            local childArea = minetest.find_nodes_in_area({
                x = pos.x - sc.w,
                y = pos.y - sc.h,
                z = pos.z - sc.l
            }, {
                x = pos.x + sc.w,
                y = pos.y + sc.h,
                z = pos.z + sc.l
            }, {"ship_scout:protect2"})

            if #childArea > 0 then
                -- node change and clicker is owner
                if owner == clicker then
                    isValid = true;
                    break
                end
                for c = 1, #childArea do
                    local cmeta = minetest.get_meta(childArea[c])
                    local cowner = cmeta:get_string("owner") or ""
                    -- node change and clicker is owner
                    if cowner == clicker then
                        isValid = true;
                        break
                    end
                    -- node change and clicker isn't owner
                    if cowner ~= clicker then
                        if not shipyard.protector.is_member(cmeta, clicker) then
                            isValid = false;
                            local pn = clicker
                            minetest.chat_send_player(pn, S("This ship crate is owned by @1", cowner) .. "!")
                            return false
						elseif shipyard.protector.is_member(cmeta, clicker) then
                            isValid = true;
                            break
                        end
                    end
                end
            end

        end

        -- end loop
    end

    return isValid
end

function shipyard.get_chest_formspec(pos)
    local spos = pos.x .. "," .. pos.y .. "," .. pos.z
    local formspec = "size[8,9]" .. default.gui_bg .. default.gui_bg_img .. default.gui_slots .. "list[nodemeta:" ..
                         spos .. ";main;0,0.3;8,4;]" .. "list[current_player;main;0,4.85;8,1;]" ..
                         "list[current_player;main;0,6.08;8,3;8]" .. "listring[nodemeta:" .. spos .. ";main]" ..
                         "listring[current_player;main]" .. default.get_hotbar_bg(0, 4.85)
    return formspec
end

-- Helper functions
local function drop_chest_stuff()
    return function(pos, oldnode, oldmetadata, digger)
        local meta = minetest.get_meta(pos)
        meta:from_table(oldmetadata)
        local inv = meta:get_inventory()
        for i = 1, inv:get_size("main") do
            local stack = inv:get_stack("main", i)
            if not stack:is_empty() then
                local p = {
                    x = pos.x + math.random(0, 5) / 5 - 0.5,
                    y = pos.y,
                    z = pos.z + math.random(0, 5) / 5 - 0.5
                }
                minetest.add_item(p, stack)
            end
        end
    end
end

local function register_chest(name, custom_def)
    assert(custom_def.description)
    assert(custom_def.tiles)

    local def = {
        paramtype2 = "facedir",
        legacy_facedir_simple = true,
        is_ground_content = false,
        sounds = scifi_nodes.node_sound_wood_defaults(),
        after_dig_node = drop_chest_stuff(),
        on_construct = function(pos)
            local meta = minetest.get_meta(pos)
            -- meta:set_string("formspec", chest_formspec)
            meta:set_string("infotext", custom_def.description)
            local inv = meta:get_inventory()
            inv:set_size("main", 8 * 4)
        end,
        on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
            minetest.log("action", player:get_player_name() .. " moves stuff in box at " .. minetest.pos_to_string(pos))
        end,
        on_metadata_inventory_put = function(pos, listname, index, stack, player)
            minetest.log("action", player:get_player_name() .. " moves stuff to box at " .. minetest.pos_to_string(pos))
        end,
        on_metadata_inventory_take = function(pos, listname, index, stack, player)
            minetest.log("action",
                player:get_player_name() .. " takes stuff from box at " .. minetest.pos_to_string(pos))
        end,

        can_dig = function(pos, player)
            local meta = minetest.get_meta(pos);
            local inv = meta:get_inventory()
            return inv:is_empty("main") and default.can_interact_with_node(player, pos)
        end,
        allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
			local clicker = player:get_player_name() or ""
            if not shipyard.can_access_crate(clicker, pos) then
                return 0
            end
            --[[if not default.can_interact_with_node(player, pos) then
                return 0
            end]]--
            return count
        end,
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			local clicker = player:get_player_name() or ""
            if not shipyard.can_access_crate(clicker, pos) then
                return 0
            end
            --[[if not default.can_interact_with_node(player, pos) then
                return 0
            end]]--
            return stack:get_count()
        end,
        allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			local clicker = player:get_player_name() or ""
            if not shipyard.can_access_crate(clicker, pos) then
                return 0
            end
            --[[if not default.can_interact_with_node(player, pos) then
                return 0
            end]]--
            return stack:get_count()
        end,
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            if not shipyard.can_access_crate(clicker:get_player_name() or "", pos) then
                return itemstack
            end
            --[[if not default.can_interact_with_node(clicker, pos) then
                return itemstack
            end]]--

            local cn = clicker:get_player_name()

            if default.chest.open_chests[cn] then
                default.chest.chest_lid_close(cn)
            end

            minetest.sound_play(custom_def.sound_open, {
                gain = 0.3,
                pos = pos,
                max_hear_distance = 10
            }, true)
            if not default.chest.chest_lid_obstructed(pos) then
                --[[minetest.swap_node(pos, {
                    name = name .. "_open",
                    param2 = node.param2
                })]] --
            end
            minetest.after(0.2, minetest.show_formspec, cn, "shipyard:box2", shipyard.get_chest_formspec(pos))
            default.chest.open_chests[cn] = {
                pos = pos,
                sound = custom_def.sound_close,
                swap = name
            }
        end,
        on_blast = function()
        end,
        on_key_use = function(pos, player)
            local secret = minetest.get_meta(pos):get_string("key_lock_secret")
            local itemstack = player:get_wielded_item()
            local key_meta = itemstack:get_meta()

            if itemstack:get_metadata() == "" then
                return
            end

            if key_meta:get_string("secret") == "" then
                key_meta:set_string("secret", minetest.parse_json(itemstack:get_metadata()).secret)
                itemstack:set_metadata("")
            end

            if secret ~= key_meta:get_string("secret") then
                return
            end

            minetest.show_formspec(player:get_player_name(), "shipyard:box2_locked", shipyard.get_chest_formspec(pos))
        end,
        on_skeleton_key_use = function(pos, player, newsecret)
            local meta = minetest.get_meta(pos)
            local owner = meta:get_string("owner")
            local pn = player:get_player_name()

            -- verify placer is owner of lockable chest
            if owner ~= pn then
                minetest.record_protection_violation(pos, pn)
                minetest.chat_send_player(pn, S("You do not own this crate."))
                return nil
            end

            local secret = meta:get_string("key_lock_secret")
            if secret == "" then
                secret = newsecret
                meta:set_string("key_lock_secret", secret)
            end

            return secret, S("a locked crate"), owner
        end
    }

    for k, v in pairs(custom_def) do
        def[k] = v
    end

    minetest.register_node(name, def)
end

register_chest("shipyard:box2", {
    description = "Locked Storage box",
    tiles = {"scifi_nodes_box_top.png", "scifi_nodes_box_top.png", "scifi_nodes_box.png", "scifi_nodes_box.png",
             "scifi_nodes_box.png", "scifi_nodes_box.png"},
    groups = {
        cracky = 1
    },
    sound_open = "default_chest_open",
    sound_close = "default_chest_close",
    protected = 1
})
