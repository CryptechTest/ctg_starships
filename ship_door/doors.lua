
-- This table now uses named parameters and more convenient variables names
local doors = {
    {base_name = "Doom", base_ingredient =  "scifi_nodes:Doom_door_closed", sound = "scifi_nodes_door_normal"},
    {base_name = "black", base_ingredient = "scifi_nodes:black_door_closed", sound = "scifi_nodes_door_normal"},
    {base_name = "white", base_ingredient = "scifi_nodes:white_door_closed", sound = "scifi_nodes_door_normal"},
    {base_name = "green", base_ingredient = "scifi_nodes:green_door_closed", sound = "scifi_nodes_door_normal"},
    {base_name = "blue", base_ingredient = "scifi_nodes:blue_door_closed", sound = "scifi_nodes_door_normal"}
}

-- temporary pos store
local player_pos = {}

local function is_number(v)
	return type(v) == "number"
end

local function get_formspec(pos)
    local meta = core.get_meta(pos)
    local locked = meta:get_int("locked") > 0
    local locked_mese = meta:get_int("locked_mese") > 0
    local close_delay = meta:get_int("close_delay")
    local close_mese = meta:get_int("close_mese") > 0
    local mese_closes = meta:get_int("mese_closes") > 0
    return "size[6,3.0]"..
        --"allow_close[false]"..
        "image[-0.155,-0.1;0.5,0.5;basic_materials_padlock.png;]"..
        "label[0.325,-0.1;Secure Door Controls]"..
        "checkbox[0,0.75;locked;Locked to Public;"..tostring(locked).."]"..
        "checkbox[2.95,0.75;locked_mese;Block Mese Control;"..tostring(locked_mese).."]"..
        "field[0.55,2.29;2.1,1;close_delay;Auto Close Delay;"..tostring(close_delay).."]"..
        "field_close_on_enter[close_delay;false]"..
        "checkbox[2.95,1.5;close_mese;Mese Auto Closes;"..tostring(close_mese).."]"..
        "checkbox[2.95,2.25;mese_closes;Do Mese Close;"..tostring(mese_closes).."]"..
        "button_exit[5.05,-0.2;1.15,0.8;quit;Close]"
end

local function do_lock(pos, locked)
    local meta = core.get_meta(pos)
    if locked then
        meta:set_int("locked", 1)
        meta:set_string("infotext", "Locked Door")
    else
        meta:set_int("locked", 0)
        meta:set_string("infotext", "")
    end    
end

local function do_lock_mese(pos, locked)
    local meta = core.get_meta(pos)
    if locked then
        meta:set_int("locked_mese", 1)
    else
        meta:set_int("locked_mese", 0)
    end    
end

-- check formspec buttons or when name entered
core.register_on_player_receive_fields(function(player, formname, fields)
    -- check if our form
    if formname ~= "ship_door:door_form" then
        return
    end

    local name = player:get_player_name()
    local pos = player_pos[name]
    if not name or not pos then
        if name then
            core.chat_send_player(name, "Access Denied for Snack Machine!")
        end
        return
    end

    local meta = core.get_meta(pos)
    local locked = meta:get_int("locked") > 0
    local locked_mese = meta:get_int("locked_mese") > 0
    local owner = meta:get_string("owner") or ""

    if locked and name ~= owner then
        player_pos[name] = nil
        core.close_formspec(name, "ship_door:door_form")
        core.chat_send_player(name, "No Access for Door Control!")
        return
    elseif (fields.locked or fields.locked_mese) and name ~= owner then
        player_pos[name] = nil
        core.close_formspec(name, "ship_door:door_form")
        core.chat_send_player(name, "Access Denied for Door Control!")
        return
    end

    if fields.locked or fields.locked ~= nil then
        if fields.locked == 'true' then
            locked = 1
        else
            locked = 0
        end
        do_lock(pos, locked == 1)
    end

    if fields.locked_mese or fields.locked_mese ~= nil then
        if fields.locked_mese == 'true' then
            locked_mese = 1
        else
            locked_mese = 0
        end
        do_lock_mese(pos, locked_mese == 1)
    end

    if fields.close_me or fields.quit or fields.key_enter_field or fields.close_delay then
        local delay = tonumber(fields.close_delay)
        if is_number(delay) then
            meta:set_int("close_delay", delay)
        end
    end

    if fields.close_mese or fields.close_mese ~= nil then
        if fields.close_mese == 'true' then
            meta:set_int("close_mese", 1)
        else
            meta:set_int("close_mese", 0)
        end
    end

    if fields.mese_closes or fields.mese_closes ~= nil then
        if fields.mese_closes == 'true' then
            meta:set_int("mese_closes", 1)
        else
            meta:set_int("mese_closes", 0)
        end
    end

    -- reset formspec until close button pressed
    if (fields.close_me or fields.quit) then
        player_pos[name] = nil
        return
    end

    core.show_formspec(name, formname, get_formspec(pos))
end)

local function show_door_form(pos, player)
    local name = player:get_player_name()
    player_pos[name] = pos
    core.show_formspec(name, "ship_door:door_form", get_formspec(pos))
    return nil
end

local function is_protected(pos, placer)
    local meta = core.get_meta(pos)
    local owner = meta:get_string("owner") or ""
    local player_name = placer and placer:get_player_name() or ""
    local protect_bypass = core.check_player_privs(player_name, "protection_bypass")
    local is_owner = owner == player_name
    local is_protected = core.is_protected(pos, player_name)
    if is_protected and not protect_bypass and not is_owner then
        --core.record_protection_violation(pos, player_name)
        return true
    end
    return false
end

-- register doors
for _, current_door in ipairs(doors) do

    local closed = "ship_door:"..current_door.base_name.."_lock".."_door_closed"
    local closed_top = "ship_door:"..current_door.base_name.."_lock".."_door_closed_top"
    local opened = "ship_door:"..current_door.base_name.."_lock".."_door_opened"
    local opened_top = "ship_door:"..current_door.base_name.."_lock".."_door_opened_top"
    local base_name = current_door.base_name
    local base_ingredient = current_door.base_ingredient
    local sound = current_door.sound

    core.register_craft({
        type = "shapeless",
        output = closed .. " 1",
        recipe = { "basic_materials:padlock", base_ingredient, "basic_materials:ic" }
    })

    local function onplace(itemstack, placer, pointed_thing)
        -- Is there room enough ?
        local pos1 = pointed_thing.above
        local pos2 = {x=pos1.x, y=pos1.y, z=pos1.z}
              pos2.y = pos2.y+1 -- 2 nodes above

        if
        not core.registered_nodes[core.get_node(pos1).name].buildable_to or
        not core.registered_nodes[core.get_node(pos2).name].buildable_to or
        not placer or
        not placer:is_player() or
        core.is_protected(pos1, placer:get_player_name()) or
        core.is_protected(pos2, placer:get_player_name()) then
            return
        end

        local pt = pointed_thing.above
        local pt2 = {x=pt.x, y=pt.y, z=pt.z}
        pt2.y = pt2.y+1
        -- Player look dir is converted to node rotation ?
        local p2 = core.dir_to_facedir(placer:get_look_dir())
        -- Where to look for another door ?
        local pt3 = {x=pt.x, y=pt.y, z=pt.z}

        -- Door param2 depends of placer's look dir
        local p4 = 0
        if p2 == 0 then
            pt3.x = pt3.x-1
            p4 = 2
        elseif p2 == 1 then
            pt3.z = pt3.z+1
            p4 = 3
        elseif p2 == 2 then
            pt3.x = pt3.x+1
            p4 = 0
        elseif p2 == 3 then
            pt3.z = pt3.z-1
            p4 = 1
        end

        -- First door of a pair is already there
        if core.get_node(pt3).name == closed then
            core.set_node(pt, {name=closed, param2=p4,})
            core.set_node(pt2, {name=closed_top, param2=p4})
        --    Placed door is the first of a pair
        else
            core.set_node(pt, {name=closed, param2=p2,})
            core.set_node(pt2, {name=closed_top, param2=p2})
        end

        local player_name = placer and placer:get_player_name() or ""
        local meta = core.get_meta(pt)
        meta:set_string("owner", player_name)
        meta:set_int("locked", 0)
        meta:set_int("locked_mese", 0)
        meta:set_int("close_delay", 3)
        meta:set_int("close_mese", 0)
        meta:set_int("mese_closes", 1)

        itemstack:take_item(1)
        return itemstack;
    end

    local function afterdestruct(pos, oldnode)
        core.set_node({x=pos.x,y=pos.y+1,z=pos.z},{name="air"})
    end

    local function change_adjacent(target, pos, node)
        local target_opposite, target_top
        if target == opened then
            target_top = opened_top
            target_opposite = closed
        else
            target_top = closed_top
            target_opposite = opened
        end

        for offset = -1,1,2 do
            local x = pos.x
            local y = pos.y
            local z = pos.z

            -- match param2=0 or param2=2
            if node.param2 % 2 == 0 then
                x = x + offset
            else
                z = z + offset
            end

            local adjacent = core.get_node({x=x, y=y, z=z})
            if adjacent.name == target_opposite then
                core.swap_node({x=x, y=y, z=z}, {name=target, param2 = adjacent.param2})
                core.swap_node({x=x, y=y+1, z=z}, {name=target_top, param2 = adjacent.param2})
            end
        end

    end

    local function open_door(pos, node)
        local node = core.get_node(pos)
        if node.name == opened then
            return false
        end
        -- play sound
        core.sound_play(sound,{
            max_hear_distance = 16,
            pos = pos,
            gain = 1.0,
            --pitch = math.random(0.925, 1.025)
        })

        core.swap_node(pos, {name=opened, param2=node.param2})
        core.swap_node({x=pos.x,y=pos.y+1,z=pos.z}, {name=opened_top, param2=node.param2})

        change_adjacent(opened, pos, node)
        return true  
    end

    local function open_door_mese(pos, node)
        local meta = core.get_meta(pos)
        local locked_mese = meta:get_int("locked_mese") > 0
        local close_mese = meta:get_int("close_mese") > 0
        local close_delay = meta:get_int("close_delay")
        local timer = core.get_node_timer(pos)
        local res = fasle
        if not locked_mese then
            res = open_door(pos, node)
        end
        if res and close_mese then
            timer:start(close_delay or 1)
        end
        return res
    end

    local function close_door(pos, node)
        local node = core.get_node(pos)
        if node.name == closed then
            return false
        end
        -- play sound
        core.sound_play(sound,{
            max_hear_distance = 16,
            pos = pos,
            gain = 0.88,
            --pitch = math.random(0.905, 1.05),
        })

        core.swap_node(pos, {name=closed, param2=node.param2})
        core.swap_node({x=pos.x,y=pos.y+1,z=pos.z}, {name=closed_top, param2=node.param2})

        change_adjacent(closed, pos, node)
        return true
    end

    local function close_door_mese(pos, node)
        local meta = core.get_meta(pos)
        local locked_mese = meta:get_int("locked_mese") > 0
        local close_mese = meta:get_int("close_mese") > 0
        local mese_closes = meta:get_int("mese_closes") > 0
        if not locked_mese and (mese_closes or not close_mese) then
            return close_door(pos, node)
        end
        return false
    end

    local function open_door_close(pos, node, clicker)
        local meta = core.get_meta(pos)
        if clicker and clicker:is_player() then
            local locked = meta:get_int("locked") > 0
            if locked and is_protected(pos, clicker) then
                core.chat_send_player(clicker:get_player_name(), "Access Denied!")
                clicker:set_hp(clicker:get_hp() - 1)
                return false
            end
        end
        local close_delay = meta:get_int("close_delay")
        local timer = core.get_node_timer(pos)
        local res = open_door(pos, node)
        timer:start(close_delay or 3)
        return res
    end

    local function afterplace(pos, placer, itemstack, pointed_thing)
        local node = core.get_node(pos)
        core.set_node({x=pos.x,y=pos.y+1,z=pos.z},{name=opened_top,param2=node.param2})
    end

    local function ontimer(pos, elapsed)
        local node = core.get_node(pos)
        close_door(pos, node)
    end

    local mesecons_doors_rules = {
        -- get signal from pressure plate
        {x=-1, y=0, z=0},
        {x=0,  y=0, z=1},
        {x=0,  y=0, z=-1},
        {x=1,  y=0, z=0},
        -- get signal from wall mounted button
        {x=-1, y=1, z=-1},
        {x=-1, y=1, z=1},
        {x=0, y=1, z=-1},
        {x=0, y=1, z=1},
        {x=1, y=1, z=-1},
        {x=1, y=1, z=1},
        {x=-1, y=1, z=0},
        {x=1, y=1, z=0},
    }

    local mesecons_doors_def = {
        effector = {
            action_on = open_door_mese,
            action_off = close_door_mese,
            rules = mesecons_doors_rules
        },
    }

    local function nodig(pos, digger)
        return false
    end

    local function can_dig(pos, digger)
        local prot = is_protected(pos, digger)
        if prot then
            local player_name = digger and digger:get_player_name() or ""
            core.record_protection_violation(pos, player_name)
        end
        return not prot
    end

    core.register_node(closed, {
        description = "Locking " .. current_door.base_name.." sliding door",
        inventory_image = "ctg_door_"..base_name.."_inv.png",
        wield_image = "ctg_door_"..base_name.."_inv.png",
        tiles = {
            "scifi_nodes_door_"..base_name.."_edge.png",
            "scifi_nodes_door_"..base_name.."_edge.png",
            "scifi_nodes_door_"..base_name.."_edge.png",
            "scifi_nodes_door_"..base_name.."_edge.png",
            "scifi_nodes_door_"..base_name.."_rbottom.png",
            "scifi_nodes_door_"..base_name.."_bottom.png"
        },
        drawtype = "nodebox",
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {
            cracky = 3,
            level = 1,
            oddly_breakable_by_hand = 1,
            ctg_door = 1,
            door = 1
        },
        is_ground_content = false,
        node_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.0625, 0.5, 0.5, 0.0625}
            }
        },
        selection_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.0625, 0.5, 1.5, 0.0625}
            }
        },
        _open = open_door_close,
        mesecons = mesecons_doors_def,
        on_place = onplace,
        on_punch = function(pos, node, puncher, pointed_thing)
            if (puncher and puncher:is_player() and puncher:get_player_control().sneak) then
                if not is_protected(pos, puncher) then
                    show_door_form(pos, puncher)
                    return
                end
            end
        end,
        after_destruct = afterdestruct,
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            if clicker and clicker:is_player() and itemstack:get_name() == "basic_materials:padlock" then
                if not is_protected(pos, clicker) then
                    show_door_form(pos, clicker)
                    return itemstack
                else
                    local player_name = clicker:get_player_name()
                    core.chat_send_player(player_name, "Access Denied! Owner Required.")
                    return itemstack
                end
            end
            open_door_close(pos, node, clicker)
            return itemstack
        end,
        can_dig = can_dig,
        sounds = scifi_nodes.node_sound_metal_defaults(),
        on_rotate = screwdriver.disallow,
    })

    core.register_node(closed_top, {
        tiles = {
            "scifi_nodes_door_"..base_name.."_edge.png",
            "scifi_nodes_door_"..base_name.."_edge.png",
            "scifi_nodes_door_"..base_name.."_edge.png",
            "scifi_nodes_door_"..base_name.."_edge.png",
            "scifi_nodes_door_"..base_name.."_rtop.png^(ctg_door_"..base_name.."_top.png^[transformFX)",
            "scifi_nodes_door_"..base_name.."_top.png^ctg_door_"..base_name.."_top.png"
        },
        drawtype = "nodebox",
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {cracky = 1, dig_generic = 3, door = 1},
        is_ground_content = false,
        node_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.0625, 0.5, 0.5, 0.0625}
            }
        },
        selection_box = {
            type = "fixed",
            fixed = {
                {0, 0, 0, 0, 0, 0},
            }
        },
        can_dig = nodig,
        sounds = scifi_nodes.node_sound_metal_defaults(),
        on_rotate = screwdriver.disallow,
    })

    core.register_node(opened, {
        tiles = {
            "scifi_nodes_door_"..base_name.."_edge.png",
            "scifi_nodes_door_"..base_name.."_edge.png",
            "scifi_nodes_door_"..base_name.."_edge.png",
            "scifi_nodes_door_"..base_name.."_edge.png",
            "scifi_nodes_door_"..base_name.."_rbottom0.png",
            "scifi_nodes_door_"..base_name.."_bottom0.png"
        },
        drawtype = "nodebox",
        paramtype = "light",
        paramtype2 = "facedir",
        drop = closed,
        groups = {cracky = 1, dig_generic = 3, door = 2},
        is_ground_content = false,
        node_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.0625, -0.25, 0.5, 0.0625},
            }
        },
        selection_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.0625, -0.25, 1.5, 0.0625},
            }
        },
        after_place_node = afterplace,
        after_destruct = afterdestruct,
        on_timer = ontimer,
        can_dig = can_dig,
        sounds = scifi_nodes.node_sound_metal_defaults(),
        mesecons = mesecons_doors_def,
        on_rotate = screwdriver.disallow,
    })

    core.register_node(opened_top, {
        tiles = {
            "scifi_nodes_door_"..base_name.."_edge.png",
            "scifi_nodes_door_"..base_name.."_edge.png",
            "scifi_nodes_door_"..base_name.."_edge.png",
            "scifi_nodes_door_"..base_name.."_edge.png",
            "ctg_door_"..base_name.."_topo.png^[transformFX",
            "ctg_door_"..base_name.."_topo.png"
        },
        drawtype = "nodebox",
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {cracky = 1, dig_generic = 3, door = 2},
        is_ground_content = false,
        node_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.0625, -0.25, 0.5, 0.0625},
            }
        },
        selection_box = {
            type = "fixed",
            fixed = {
                {0, 0, 0, 0, 0, 0},
            }
        },
        can_dig = nodig,
        sounds = scifi_nodes.node_sound_metal_defaults(),
        on_rotate = screwdriver.disallow,
    })
end     -- end of doors table browsing

-- opens the ship door at the given position
function ship_door.open_door(pos)
    local node = core.get_node_or_nil(pos)
    if not node then
        -- area not loaded
        return false
    end

    local def = core.registered_nodes[node.name]
    if type(def._open) ~= "function" then
        -- open function not found
        return false
    end

    if not def.groups or not def.groups.ctg_door then
        -- not a scifi_nodes door
        return false
    end

    -- call open function
    def._open(pos, node)
    return true
end
