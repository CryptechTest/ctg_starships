

-- temporary pos store
local player_pos = {}

-- get static spawn position
local statspawn = minetest.string_to_pos(minetest.settings:get("static_spawnpoint")) or {
    x = 0,
    y = 2,
    z = 0
}
-- spawn protection
local protector_spawn = tonumber(minetest.settings:get("protector_spawn")) or 250

local use_jump_display_ent = false

if use_jump_display_ent then
    minetest.register_entity("ship_machine:jump_display", {
        physical = false,
        collisionbox = {0, 0, 0, 0, 0, 0},
        visual = "sprite",
        -- wielditem seems to be scaled to 1.5 times original node size
        visual_size = {
            x = 0.6,
            y = 0.6
        },
        pointable = false,
        textures = {"tele_effect03.png"},
        timer = 0,
        glow = 5,
        nametag = "UNKNOWN",
        infotext = "Jumpship",
        hp_max = 1000,
        hp = 1000,
        type = 0,

        on_step = function(self, dtime)

            self.timer = self.timer + dtime

            local col
            if self.type == 0 then
                col = "#FFFFFF"
            elseif self.type == 1 then
                col = ship_machine.colorize_text_hp(self.hp, self.hp_max)
            elseif self.type == 2 then
                local qua = self.hp_max / 6
                if self.hp <= qua then
                    col = "#FF000F"
                elseif self.hp <= (qua * 2) then
                    col = "#FF7A0F"
                elseif self.hp <= (qua * 3) then
                    col = "#FFB50F"
                elseif self.hp <= (qua * 4) then
                    col = "#FFFF0F"
                elseif self.hp <= (qua * 5) then
                    col = "#B4FF0F"
                elseif self.hp > (qua * 5) then
                    col = "#00FF0F"
                end
            end
            self.object:set_properties({nametag = self.nametag, nametag_color = col, infotext = self.infotext})

            -- remove after set number of seconds
            if self.timer > 10 then
                --self.object:remove()
            end
        end
    })
end

-- check if pos is inside a protected spawn area
local inside_spawn = function(pos, radius)

    if protector_spawn <= 0 then
        return false
    end

    if pos.x < statspawn.x + radius and pos.x > statspawn.x - radius and pos.y < statspawn.y + radius and pos.y >
        statspawn.y - radius and pos.z < statspawn.z + radius and pos.z > statspawn.z - radius then

        return true
    end

    return false
end

local function register_ship_protect(def)

    -- default support (for use with MineClone2 and other [games]
    local default = default or {
        node_sound_stone_defaults = function(table)
        end,
        node_sound_wood_defaults = function(table)
        end,
        gui_bg = "",
        gui_bg_img = "",
        gui_slots = ""
    }

    -- Load support for intllib.
    local MP = minetest.get_modpath(minetest.get_current_modname())
    local F = minetest.formspec_escape
    local S = minetest.get_translator and minetest.get_translator("protector")

    -- Load support for factions
    local factions_available = minetest.global_exists("factions")

    def.protector = {
        mod = def.modname or "ship_machine",
        modpath = MP,
        intllib = S,
        -- size of protected region
        size = def.size
    }

    local hit_points = def.hp or 1000
    local modname = def.modname or "ship_machine"
    local machine_name = def.machine_name or "shield_protect"
    local nodename = modname .. ":" .. machine_name
    local ship_name = def.ship_name or "Jumpship"

    local protector_max_share_count = 12
    -- get minetest.conf settings
    local protector_flip = minetest.settings:get_bool("ship_machine.protector_flip") or false
    local protector_hurt = tonumber(minetest.settings:get("ship_machine.protector_hurt")) or 0.5
    local protector_show = tonumber(minetest.settings:get("ship_machine.protector_show_interval")) or 10
    local protector_msg = minetest.settings:get_bool("ship_machine.protector_msg") ~= false

    -- return list of members as a table
    local get_member_list = function(meta)
        return meta:get_string("members"):split(" ")
    end

    -- write member list table in protector meta as string
    local set_member_list = function(meta, list)
        meta:set_string("members", table.concat(list, " "))
    end

    -- return list of allies as a table
    local get_ally_list = function(meta)
        return meta:get_string("allies"):split(" ")
    end

    -- write ally list table in protector meta as string
    local set_ally_list = function(meta, list)
        meta:set_string("allies", table.concat(list, " "))
    end

    -- check for owner name
    local is_owner = function(meta, name)
        return name == meta:get_string("owner")
    end

    -- check for member name
    local is_member = function(meta, name)

        if factions_available and meta:get_int("faction_members") == 1 then
            if factions.version == nil then
                -- backward compatibility
                if factions.get_player_faction(name) ~= nil and factions.get_player_faction(meta:get_string("owner")) ==
                    factions.get_player_faction(name) then
                    return true
                end
            else
                -- is member if player and owner share at least one faction
                local owner_factions = factions.get_player_factions(name)
                local owner = meta:get_string("owner")

                if owner_factions ~= nil and owner_factions ~= false then
                    for _, f in ipairs(owner_factions) do
                        if factions.player_is_in_faction(f, owner) then
                            return true
                        end
                    end
                end
            end
        end

        for _, n in pairs(get_member_list(meta)) do
            if n == name then
                return true
            end
        end

        return false
    end

    -- check for ally name
    local is_ally = function(meta, name)
        for _, n in pairs(get_ally_list(meta)) do
            if n == name then
                return true
            end
        end
        return false
    end

    -- add player name to table as member
    local add_member = function(meta, name)
        -- Validate player name for MT compliance
        if name ~= string.match(name, "[%w_-]+") then
            return
        end
        -- Constant (20) defined by player.h
        if name:len() > 25 then
            return
        end
        -- does name already exist?
        if is_owner(meta, name) or is_member(meta, name) or is_ally(meta, name) then
            return
        end
        local list = get_member_list(meta)
        if #list >= protector_max_share_count then
            return
        end
        table.insert(list, name)
        set_member_list(meta, list)
    end

    -- remove player name from table
    local del_member = function(meta, name)
        local list = get_member_list(meta)
        for i, n in pairs(list) do
            if n == name then
                table.remove(list, i)
                break
            end
        end
        set_member_list(meta, list)
    end

    -- add player name to table as ally
    local add_ally = function(meta, name)
        -- Validate player name for MT compliance
        if name ~= string.match(name, "[%w_-]+") then
            return
        end
        -- Constant (20) defined by player.h
        if name:len() > 25 then
            return
        end
        -- does name already exist?
        if is_owner(meta, name) or is_member(meta, name) or is_ally(meta, name) then
            return
        end
        local list = get_ally_list(meta)
        if #list >= protector_max_share_count then
            return
        end
        table.insert(list, name)
        set_ally_list(meta, list)
    end

    -- remove player name from table
    local del_ally = function(meta, name)
        local list = get_ally_list(meta)
        for i, n in pairs(list) do
            if n == name then
                table.remove(list, i)
                break
            end
        end
        set_ally_list(meta, list)
    end

    -- protector interface
    def.protector_formspec = function(meta)

        local formspec = "size[8,9]" .. default.gui_bg .. default.gui_bg_img .. "label[2.5,0;" ..
                             F(S("Jumpship Protection Interface")) .. "]" .. 
                             "button_exit[2.5,8.4;3,0.5;close_me;" .. F(S("Close")) .. "]"

        local menu_level = meta:get_int("menu_level") or 1
        local members = get_member_list(meta)
        local allies = get_ally_list(meta)
        local npp = protector_max_share_count -- max users added to protector list
        local i = 0
        local j = 0
        local checkbox_faction = false

        if menu_level == 1 then
            formspec = formspec .. "button[6,-0.2;2,1;toggle_menu_1;Toggle View]"
            formspec = formspec .. "field_close_on_enter[protector_add_member;false]"
            formspec = formspec .. "label[0,0.4;" .. F(S("Crew Members:")) .. "]"
            formspec = formspec .. "label[0.3,7.6;" .. F(S("Crew members may access ship, perform actions and are safe.")) .. "]"
        elseif menu_level == 2 then
            formspec = formspec .. "button[6,-0.2;2,1;toggle_menu_2;Toggle View]"
            formspec = formspec .. "field_close_on_enter[protector_add_ally;false]"
            formspec = formspec .. "label[0,0.4;" .. F(S("Ally Members:")) .. "]"
            formspec = formspec .. "label[0.3,7.6;" .. F(S("Ally members may not access ship, but are safe from defenses.")) .. "]"
        end

        -- Display the checkbox only if the owner is member of at least 1 faction
        if factions_available then
            if factions.version == nil then
                -- backward compatibility
                if factions.get_player_faction(meta:get_string("owner")) then
                    checkbox_faction = true
                end
            else
                local player_factions = factions.get_player_factions(meta:get_string("owner"))
                if player_factions ~= nil and #player_factions >= 1 then
                    checkbox_faction = true
                end
            end
        end
        if checkbox_faction then
            formspec = formspec .. "checkbox[0,5;faction_members;" .. F(S("Allow faction access")) .. ";" ..
                           (meta:get_int("faction_members") == 1 and "true" or "false") .. "]"
            if npp > 8 then
                npp = 8
            end
        end

        if menu_level == 1 then
            for n = 1, #members do
                if i < npp then
                    -- show username
                    formspec = formspec .. "button[" .. (i % 4 * 2) .. "," .. math.floor(i / 4 + 1) ..
                                ";1.5,.5;protector_member;" .. F(members[n]) .. "]" -- username remove button
                    .. "button[" .. (i % 4 * 2 + 1.275) .. "," .. math.floor(i / 4 + 1) .. ";.75,.5;protector_del_member_" ..
                                F(members[n]) .. ";X]"
                end
                i = i + 1
            end
            if i < npp then
                -- user name entry field
                formspec = formspec .. "field[" .. (i % 4 * 2 + 1 / 3) .. "," .. (math.floor(i / 4 + 1) + 1 / 3) ..
                            ";1.433,.5;protector_add_member;;]" -- username add button
                .. "button[" .. (i % 4 * 2 + 1.275) .. "," .. math.floor(i / 4 + 1) .. ";.75,.5;protector_submit;+]"
            end
        elseif menu_level == 2 then
            for n = 1, #allies do
                if j < npp then
                    -- show username
                    formspec = formspec .. "button[" .. (j % 4 * 2) .. "," .. math.floor(j / 4 + 1) ..
                                ";1.5,.5;protector_ally;" .. F(allies[n]) .. "]" -- username remove button
                    .. "button[" .. (j % 4 * 2 + 1.275) .. "," .. math.floor(j / 4 + 1) .. ";.75,.5;protector_del_ally_" ..
                                F(allies[n]) .. ";X]"
                end
                j = j + 1
            end
            if j < npp then
                -- user name entry field
                formspec = formspec .. "field[" .. (j % 4 * 2 + 1 / 3) .. "," .. (math.floor(j / 4 + 1) + 1 / 3) ..
                            ";1.433,.5;protector_add_ally;;]" -- username add button
                .. "button[" .. (j % 4 * 2 + 1.275) .. "," .. math.floor(j / 4 + 1) .. ";.75,.5;protector_submit;+]"
            end
        end

        return formspec
    end

    -- show protection message if enabled
    local show_msg = function(player, msg)

        -- if messages disabled or no player name provided
        if protector_msg == false or not player or player == "" then
            return
        end

        minetest.chat_send_player(player, msg)
    end

    -- Infolevel:
    -- 0 for no info
    -- 1 for "This area is owned by <owner> !" if you can't dig
    -- 2 for "This area is owned by <owner>.
    -- 3 for checking protector overlaps

    def.protector.can_dig = function(s, pos, digger, onlyowner, infolevel)

        if not digger or not pos then
            return false
        end

        -- protector_bypass privileged users can override protection
        if infolevel == 1 and minetest.check_player_privs(digger, {
            protection_bypass = true
        }) then
            return true
        end

        -- infolevel 3 is only used to bypass priv check, change to 1 now
        if infolevel == 3 then
            infolevel = 1
        end
        
        -- is spawn area protected ?
        if inside_spawn(pos, protector_spawn) then
            show_msg(digger, S("Spawn @1 has been protected up to a @2 block radius.", minetest.pos_to_string(statspawn), protector_spawn))
            return false
        end

        -- find the protector nodes
        local nodes = minetest.find_nodes_in_area({
            x = pos.x - s.w,
            y = (pos.y - s.h) + 2,
            z = pos.z - s.l
        }, {
            x = pos.x + s.w,
            y = (pos.y + s.h) + 2,
            z = pos.z + s.l
        }, {nodename, "group:protector"})

        local meta, owner, members

        for n = 1, #nodes do

            local p = nodes[n]
            local n = minetest.get_node(p)
            local g = minetest.get_item_group(n.name, "protector");
            if g == 2 then
                
                meta = minetest.get_meta(p)
                owner = meta:get_string("owner") or ""
                members = meta:get_string("members") or ""
                local _size = {
                    w = meta:get_int("p_width") or 0,
                    l = meta:get_int("p_length") or 0,
                    h = meta:get_int("p_height") or 0
                }

                local in_bound = false
                if pos.x <= p.x + _size.w and pos.x >= p.x - _size.w then
                    if pos.z <= p.z + _size.l and pos.z >= p.z - _size.l then
                        if pos.y <= (p.y - 2) + _size.h and pos.y >= (p.y - 2) - _size.h then
                            in_bound = true
                        end
                    end
                end

                if in_bound and owner == "*nobody" then
                    return true
                end
                
                -- node change and digger isn't owner
                if infolevel == 1 and owner ~= digger and in_bound then
                    -- and you aren't on the member list
                    if onlyowner or not is_member(meta, digger) then
                        show_msg(digger, S("This ship area is owned by @1", owner) .. "!")
                        return false
                    end
                end

                -- when using protector as tool, show protector information
                if infolevel == 2 and in_bound then
                    minetest.chat_send_player(digger, S("This ship area is owned by @1", owner) .. ".")
                    minetest.chat_send_player(digger, S("Protection located at: @1", minetest.pos_to_string(nodes[n])))
                    if members ~= "" then
                        minetest.chat_send_player(digger, S("Members: @1.", members))
                    end
                    return false
                end
            end

        end

        -- show when you can build on unprotected area
        if infolevel == 2 then
            if #nodes < 1 then
                minetest.chat_send_player(digger, S("This ship area is not protected."))
            end
            minetest.chat_send_player(digger, S("You can build here."))
        end

        return true
    end

    -- add protector hurt and flip to protection violation function
    --[[minetest.register_on_protection_violation(function(pos, name)

        local player = minetest.get_player_by_name(name)

        if player and player:is_player() then

            -- hurt player if protection violated
            if protector_hurt > 0 and player:get_hp() > 0 then

                -- This delay fixes item duplication bug (thanks luk3yx)
                minetest.after(0.1, function(player)
                    player:set_hp(player:get_hp() - protector_hurt)
                end, player)
            end

            -- flip player when protection violated
            if protector_flip then

                -- yaw + 180°
                local yaw = player:get_look_horizontal() + math.pi

                if yaw > 2 * math.pi then
                    yaw = yaw - 2 * math.pi
                end

                player:set_look_horizontal(yaw)

                -- invert pitch
                player:set_look_vertical(-player:get_look_vertical())

                -- if digging below player, move up to avoid falling through hole
                local pla_pos = player:get_pos()

                if pos.y < pla_pos.y then

                    player:set_pos({
                        x = pla_pos.x,
                        y = pla_pos.y + 0.8,
                        z = pla_pos.z
                    })
                end
            end
        end
    end)]]

    local old_is_protected = minetest.is_protected

    -- check for protected area, return true if protected and digger isn't on list
    function minetest.is_protected(pos, digger)

        digger = digger or "" -- nil check

        -- is area protected against digger?
        if not def.protector.can_dig(def.protector.size, pos, digger, false, 1) then
            return true
        end
        

        -- otherwise can dig or place
        return old_is_protected(pos, digger)
    end

    -- make sure protection block doesn't overlap another protector's area
    local check_overlap = function(itemstack, placer, pointed_thing)

        if pointed_thing.type ~= "node" then
            return itemstack
        end

        local pos = pointed_thing.above
        local name = placer:get_player_name()

        local size = {
            l = def.protector.size.l * 2,
            w = def.protector.size.w * 2,
            h = def.protector.size.h * 2
        }

        -- make sure protector doesn't overlap any other player's area
        if not def.protector.can_dig(size, pos, name, true, 3) then

            minetest.chat_send_player(name, S("Overlaps into above players protected area"))

            return itemstack
        end

        return minetest.item_place(itemstack, placer, pointed_thing)

    end

    -- remove protector display entities
    local del_display = function(pos)
        local objects = minetest.get_objects_inside_radius(pos, 0.5)
        for _, v in ipairs(objects) do
            if v and v:get_luaentity() and v:get_luaentity().name == modname .. ":display" then
                v:remove()
            end
        end
    end

    local texture_active = {
        image = "ship_protector_anim.png",
        animation = {
            type = "vertical_frames",
            aspect_w = 32,
            aspect_h = 32,
            length = 3
        }
    }

    function def.rightclick(pos, node, clicker, itemstack)
        local meta = minetest.get_meta(pos)
        local name = clicker:get_player_name()
        local s = {
            l = 1,
            h = 1,
            w = 1
        }
        if meta and def.protector.can_dig(s, pos, name, true, 1) then
            player_pos[name] = pos
            minetest.show_formspec(name, modname .. ":node", def.protector_formspec(meta))
        end
    end

    function def.punch(pos, node, puncher)
        if minetest.is_protected(pos, puncher:get_player_name()) then
            return
        end
        pos = vector.subtract(pos, vector.new(0,2,0))
        minetest.add_entity(pos, modname .. ":display")
    end

    -- protection node
    minetest.register_node(nodename, {
        description = S("Jumpship Protection Block"),
        drawtype = "nodebox",
        -- tiles = {"ship_protector_anim.png", "ship_protector_anim.png", "ship_protector2.png"},
        tiles = {"ship_protector.png", "ship_protector.png", texture_active, texture_active, texture_active,
                 texture_active},
        -- use_texture_alpha = true,
        sounds = default.node_sound_metal_defaults(),
        groups = {
            dig_immediate = 2,
            unbreakable = 1,
            not_in_creative_inventory = 1,
            ship_protector = 1,
            protector = 2,
        },
        is_ground_content = false,
        paramtype = "light",
        light_source = 7,

        node_box = {
            type = "fixed",
            fixed = {{-0.5625, -0.5625, -0.5625, 0.5625, -0.46875, 0.5625},
                     {-0.5625, 0.5625, -0.5625, 0.5625, 0.46875, 0.5625},
                     {0.46875, 0.46875, 0.46875, 0.40625, -0.46875, 0.40625},
                     {-0.46875, 0.46875, 0.46875, -0.40625, -0.46875, 0.40625},
                     {0.46875, 0.46875, -0.46875, 0.40625, -0.46875, -0.40625},
                     {-0.46875, 0.46875, -0.46875, -0.40625, -0.46875, -0.40625},
                     {-0.25, -0.25, -0.25, 0.25, 0.25, 0.25}}

        },

        on_place = check_overlap,

        after_place_node = function(pos, placer)
            local meta = minetest.get_meta(pos)
            meta:set_string("owner", placer:get_player_name() or "")
            meta:set_string("members", "")
            meta:set_string("allies", "")
            meta:set_string("infotext", S("Protection (owned by @1)", meta:get_string("owner")))
            meta:set_int("menu_level", 1)
            meta:set_int("p_width", def.protector.size.w)
            meta:set_int("p_length", def.protector.size.l)
            meta:set_int("p_height", def.protector.size.h)
            meta:set_int("combat_ready", 1)
            meta:set_int("hp_max", def.hp)
            meta:set_int("hp", def.hp)
            meta:set_int("shield_hit", 0)
            meta:set_int("shield_max", def.shield)
            meta:set_int("shield", def.shield)
        end,

        on_use = function(itemstack, user, pointed_thing)
            if pointed_thing.type ~= "node" then
                return
            end
            def.protector.can_dig(def.protector.size, pointed_thing.under, user:get_player_name(), false, 2)
        end,

        on_rightclick = def.rightclick,
        on_punch = def.punch,

        can_dig = function(pos, player)
            local is_admin = false
            if minetest.check_player_privs(player, "jumpship_admin") then
                return true
            end
            return player and is_admin
        end,

        on_blast = function()
        end,

        after_destruct = del_display
    })
    if machine_name == "shield_protect" then
        minetest.register_alias(modname .. ":protect2", nodename)
    end

    -- check formspec buttons or when name entered
    minetest.register_on_player_receive_fields(function(player, formname, fields)

        if formname ~= modname .. ":node" then
            return
        end

        local name = player:get_player_name()
        local pos = player_pos[name]

        if not name or not pos then
            return
        end

        local toggle_menu = (fields.toggle_menu_1 and 1) or (fields.toggle_menu_2 and 2) or 0
        local add_member_input = fields.protector_add_member
        local add_ally_input = fields.protector_add_ally

        local meta = minetest.get_meta(pos)
        if not meta then
            return
        end

        if toggle_menu > 0 then
            if toggle_menu == 1 then
                meta:set_int("menu_level", 2)
            elseif toggle_menu == 2 then
                meta:set_int("menu_level", 1)
            end
            minetest.show_formspec(name, formname, def.protector_formspec(meta))
            return
        end

        -- reset formspec until close button pressed
        if (fields.close_me or fields.quit) and (not add_member_input or add_member_input == "") then
            player_pos[name] = nil
            return
        end
        local s = {
            l = 1,
            h = 1,
            w = 1
        }
        -- only owner can add names
        if not def.protector.can_dig(s, pos, player:get_player_name(), true, 1) then
            return
        end

        -- are we adding member to a protection node ? (csm protection)
        local nod = minetest.get_node(pos).name

        if nod ~= modname .. ":protect" and nod ~= nodename then
            player_pos[name] = nil
            return
        end


        -- add faction members
        if factions_available and fields.faction_members ~= nil then
            meta:set_int("faction_members", fields.faction_members == "true" and 1 or 0)
        end

        -- add member [+]
        if add_member_input then
            for _, i in pairs(add_member_input:split(" ")) do
                add_member(meta, i)
            end
        end

        -- remove member [x]
        for field, value in pairs(fields) do
            if string.sub(field, 0, string.len("protector_del_member_")) == "protector_del_member_" then
                del_member(meta, string.sub(field, string.len("protector_del_member_") + 1))
            end
        end

        -- add ally [+]
        if add_ally_input then
            for _, i in pairs(add_ally_input:split(" ")) do
                add_ally(meta, i)
            end
        end

        -- remove ally [x]
        for field, value in pairs(fields) do
            if string.sub(field, 0, string.len("protector_del_ally_")) == "protector_del_ally_" then
                del_ally(meta, string.sub(field, string.len("protector_del_ally_") + 1))
            end
        end

        minetest.show_formspec(name, formname, def.protector_formspec(meta))
    end)

    -- display entity shown when protector node is punched
    minetest.register_entity(modname .. ":display", {
        physical = false,
        collisionbox = {0, 0, 0, 0, 0, 0},
        visual = "wielditem",
        -- wielditem seems to be scaled to 1.5 times original node size
        visual_size = {
            x = 0.67,
            y = 0.67
        },
        textures = {modname .. ":display_node"},
        timer = 0,
        glow = 10,

        on_step = function(self, dtime)

            self.timer = self.timer + dtime

            -- remove after set number of seconds
            if self.timer > protector_show then
                self.object:remove()
            end
        end
    })

    -- Display-zone node, Do NOT place the display as a node,
    -- it is made to be used as an entity (see above)

    local x = def.protector.size.w
    local y = def.protector.size.h
    local z = def.protector.size.l
    minetest.register_node(modname .. ":display_node", {
        tiles = {"protector_display.png"},
        use_texture_alpha = "clip",
        walkable = false,
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = { -- sides
            {-(x + .55), -(y + .55), -(z + .55), -(x + .45), (y + .55), (z + .55)},
            {-(x + .55), -(y + .55), (z + .45), (x + .55), (y + .55), (z + .55)},
            {(x + .45), -(y + .55), -(z + .55), (x + .55), (y + .55), (z + .55)},
            {-(x + .55), -(y + .55), -(z + .55), (x + .55), (y + .55), -(z + .45)}, -- top
            {-(x + .55), (y + .45), -(z + .55), (x + .55), (y + .55), (z + .55)}, -- bottom
            {-(x + .55), -(y + .55), -(z + .55), (x + .55), -(y + .45), (z + .55)}, -- middle (surround protector)
            {-.55, -.55, -.55, .55, .55, .55}}
        },
        selection_box = {
            type = "regular"
        },
        paramtype = "light",
        groups = {
            dig_immediate = 3,
            not_in_creative_inventory = 1
        },
        drop = ""
    })

    function def.do_particles(pos, amount)
        local prt = {
            texture = {
                name = "tele_effect03.png",
                alpha = 1.0,
                alpha_tween = {1, 0.0},
                scale_tween = {{
                    x = 0.1,
                    y = 0
                }, {
                    x = 1,
                    y = 1
                }}
            },
            texture_r180 = {
                name = "tele_effect03.png" .. "^[transformR180",
                alpha = 1.0,
                alpha_tween = {1, 0.0},
                scale_tween = {{
                    x = 0.1,
                    y = 0.0
                }, {
                    x = 1,
                    y = 1
                }}
            },
            vel = 3,
            time = 1,
            size = 6,
            glow = 8,
            cols = false
        }
        local exm = pos
        exm.y = exm.y - 2.25
        local rx = math.random(-0.05, 0.05) * 0.2
        local rz = math.random(-0.05, 0.05) * 0.2
        local texture = prt.texture
        if (math.random() >= 0.6) then
            texture = prt.texture_r180
        end

        minetest.add_particlespawner({
            amount = amount,
            time = prt.time + math.random(5.6, 12.8),
            minpos = {
                x = pos.x - 2.7,
                y = pos.y - 2.1,
                z = pos.z - 3.4
            },
            maxpos = {
                x = pos.x + 2.7,
                y = pos.y + 3.2,
                z = pos.z + 3.4
            },
            minvel = {
                x = rx,
                y = prt.vel * 0.25,
                z = rz
            },
            maxvel = {
                x = rx,
                y = prt.vel * 0.7,
                z = rz
            },
            minacc = {
                x = -0.2,
                y = 0.15,
                z = -0.2
            },
            maxacc = {
                x = 0.2,
                y = 0.23,
                z = 0.27
            },
            minexptime = prt.time * 0.28,
            maxexptime = prt.time * 0.56,
            minsize = prt.size * 0.7,
            maxsize = prt.size * 1.2,
            collisiondetection = prt.cols,
            collision_removal = false,
            object_collision = false,
            vertical = true,
            animation = prt.animation,
            texture = texture,
            glow = prt.glow
        })
    end

    if use_jump_display_ent then
        -- name info
        function def.register_check_tag_entity_1(meta, pos)
            local object = nil
            local objects = minetest.get_objects_inside_radius(pos, 0.5) or {}
            for _, obj in pairs(objects) do
                local ent = obj:get_luaentity()
                if ent then
                    if ent.name == "ship_machine:jump_display" then
                        object = obj
                        break;
                    end
                end
            end
            if object == nil then
                object = minetest.add_entity(pos, "ship_machine:jump_display")
            end
            if object then
                --local meta = minetest.get_meta(pos)
                local ship_hp_max = meta:get_int("hp_max") or 1000
                local ship_hp = meta:get_int("hp") or 1000
                local ship_hp_prcnt = (ship_hp / ship_hp_max) * 100
                local ent = object:get_luaentity()
                if ent then
                    ent.type = 0
                    ent.hp_max = ship_hp_max
                    ent.hp = ship_hp
                    ent.nametag = ship_name
                end
            end
        end
        
        -- hull
        function def.register_check_tag_entity_2(meta, pos)
            local object = nil
            local objects = minetest.get_objects_inside_radius(pos, 0.5) or {}
            for _, obj in pairs(objects) do
                local ent = obj:get_luaentity()
                if ent then
                    if ent.name == "ship_machine:jump_display" then
                        object = obj
                        break;
                    end
                end
            end
            if object == nil then
                object = minetest.add_entity(pos, "ship_machine:jump_display")
            end
            if object then
                --local meta = minetest.get_meta(pos)
                local ship_hp_max = meta:get_int("hp_max")
                local ship_hp = meta:get_int("hp")
                local ship_hp_prcnt = (ship_hp / ship_hp_max) * 100
                local ent = object:get_luaentity()
                if ent then
                    ent.type = 1
                    ent.hp_max = ship_hp_max
                    ent.hp = ship_hp
                    ent.nametag = "HULL\n" .. string.format("%.2f", ship_hp_prcnt) .. "%"
                end
            end
        end
        
        -- shield
        function def.register_check_tag_entity_3(meta, pos)
            local object = nil
            local objects = minetest.get_objects_inside_radius(pos, 0.5) or {}
            for _, obj in pairs(objects) do
                local ent = obj:get_luaentity()
                if ent then
                    if ent.name == "ship_machine:jump_display" then
                        object = obj
                        break;
                    end
                end
            end
            if object == nil then
                object = minetest.add_entity(pos, "ship_machine:jump_display")
            end
            if object then
                --local meta = minetest.get_meta(pos)
                local ship_shield_max = meta:get_int("shield_max") 
                local ship_shield = meta:get_int("shield")
                local ship_shield_prcnt = (ship_shield / ship_shield_max) * 100
                local ent = object:get_luaentity()
                if ent then
                    ent.type = 2
                    ent.hp_max = ship_shield_max
                    ent.hp = ship_shield
                    ent.nametag = "SHIELD\n" .. string.format("%.2f", ship_shield_prcnt) .. "%"
                end
            end
        end

        function def.clear_check_tag_entity(pos)
            local objects = minetest.get_objects_inside_radius(pos, 2) or {}
            for _, obj in pairs(objects) do
                local ent = obj:get_luaentity()
                if ent then
                    if ent.name == "ship_machine:jump_display" then
                        obj:remove()
                    end
                end
            end 
        end

        function def.register_check_tag_entity(pos)
            local ship_meta = minetest.get_meta(pos)
            local ship_combat_ready = ship_meta:get_int("combat_ready") > 1
            if not ship_combat_ready then
                return
            end
            def.clear_check_tag_entity(pos)
            local pos1 = vector.add(pos, {x = 0, y = 1.25, z = 0})
            local pos2 = vector.add(pos, {x = 0, y = 0, z = 0})
            local pos3 = vector.add(pos, {x = 0, y = -1.5, z = 0})
            def.register_check_tag_entity_1(ship_meta, pos1)
            def.register_check_tag_entity_2(ship_meta, pos2)
            def.register_check_tag_entity_3(ship_meta, pos3)
        end
    end

    function def.regenerate_shield(pos)
        local ship_meta = minetest.get_meta(pos)
        local ship_combat_ready = ship_meta:get_int("combat_ready") > 1
        if not ship_combat_ready then
            return
        end
        if ship_meta:get_int("shield_max") == nil then
            ship_meta:set_int("shield_max", def.shield)
        end
        if ship_meta:get_int("shield") == nil then
            ship_meta:set_int("shield", def.shield)
        end
        if ship_meta:get_int("shield_hit") == nil then
            ship_meta:set_int("shield_hit", 0)
        end
        -- detect recent shield hit
        local shield_hit = ship_meta:get_int("shield_hit")
        if shield_hit > 0 then
            shield_hit = shield_hit - math.random(1, 2)
            if shield_hit < 0 then
                shield_hit = 0
            end
            ship_meta:set_int("shield_hit", shield_hit)
            return
        end
        -- hull hp
        local ship_hp_max = ship_meta:get_int("hp_max")
        local ship_hp = ship_meta:get_int("hp")
        local ship_hp_prcnt = (ship_hp / ship_hp_max) * 100
        -- shield hp
        local ship_shield_max = ship_meta:get_int("shield_max") 
        local ship_shield = ship_meta:get_int("shield")
        local ship_shield_prcnt = (ship_shield / ship_shield_max) * 100
        -- shields disable below 40% hp
        if ship_hp_prcnt >= 40 then
            if ship_shield < ship_shield_max then
                ship_shield = ship_shield + math.random(1, 5)
                if ship_shield > ship_shield_max then
                    ship_shield = ship_shield_max
                end
                ship_meta:set_int("shield", ship_shield)
            end
        end
    end

    minetest.register_abm({
        label = "ship effects - jumpdrive for " .. modname,
        nodenames = {nodename},
        interval = 1,
        chance = 3,
        min_y = vacuum.vac_heights.space.start_height,
        action = function(pos)

            def.regenerate_shield(pos)

            --def.clear_check_tag_entity(pos)
            --def.register_check_tag_entity(pos)

            def.do_particles(pos, 7)

        end
    })

    ----------------------------------------------------
    ----------------------------------------------------
    ----------------------------------------------------

    -- local hud store
    local hud = {}
    local hud_timer = 0
    local hud_interval = 5

    if hud_interval > 0 then
        minetest.register_globalstep(function(dtime)

            -- every 5 seconds
            hud_timer = hud_timer + dtime
            if hud_timer < hud_interval then
                return
            end
            hud_timer = 0

            for _, player in pairs(minetest.get_connected_players()) do

                local name = player:get_player_name()
                local pos = vector.round(player:get_pos())
                local hud_text = ""

                local protectors = minetest.find_nodes_in_area({
                    x = pos.x - def.protector.size.w,
                    y = (pos.y - def.protector.size.h) + 2,
                    z = pos.z - def.protector.size.l
                }, {
                    x = pos.x + def.protector.size.w,
                    y = (pos.y + def.protector.size.h) + 2,
                    z = pos.z + def.protector.size.l
                }, {nodename})

                if #protectors > 0 then
                    local npos = protectors[1]
                    local meta = minetest.get_meta(npos)
                    local nodeowner = meta:get_string("owner")

                    local hp = ''
                    --if meta:get_int("hp") then
                        --local prcnt = meta:get_int("hp") / meta:get_int("hp_max") * 100
                        --hp = "\nHull: " .. prcnt .. "%"
                    --end

                    hud_text = def.ship_name .. "\n" .. S("Owner: @1", nodeowner) .. hp
                end

                if not hud[name] then

                    hud[name] = {}

                    hud[name].id = player:hud_add({
                        type = "text",
                        name = "Jumpship Area",
                        number = 0xFFFF22,
                        position = {
                            x = 0,
                            y = 0.95
                        },
                        offset = {
                            x = 8,
                            y = -8
                        },
                        text = hud_text,
                        scale = {
                            x = 200,
                            y = 60
                        },
                        alignment = {
                            x = 1,
                            y = -1
                        }
                    })

                    return
                else
                    player:hud_change(hud[name].id, "text", hud_text)
                end
            end
        end)

        minetest.register_on_leaveplayer(function(player)
            hud[player:get_player_name()] = nil
        end)

    end

end

ship_machine.register_jumpship_protect = register_ship_protect
