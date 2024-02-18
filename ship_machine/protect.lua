-- default support (for use with MineClone2 and other [games]
default = default or {
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

ship_machine.protector = {
    mod = "ship_machine",
    modpath = MP,
    intllib = S
}

local protector_max_share_count = 12
-- get minetest.conf settings
local protector_radius = 14
local protector_flip = minetest.settings:get_bool("ship_machine.protector_flip") or false
local protector_hurt = tonumber(minetest.settings:get("ship_machine.protector_hurt")) or 1
local protector_spawn = tonumber(minetest.settings:get("ship_machine.protector_spawn") or
                                     minetest.settings:get("ship_machine.protector_pvp_spawn")) or 0
local protector_show = tonumber(minetest.settings:get("ship_machine.protector_show_interval")) or 7
local protector_msg = minetest.settings:get_bool("ship_machine.protector_msg") ~= false

-- radius limiter (minetest cannot handle node volume of more than 4096000)
if protector_radius > 22 then
    protector_radius = 22
end

-- get static spawn position
local statspawn = minetest.string_to_pos(minetest.settings:get("static_spawnpoint")) or {
    x = 0,
    y = 2,
    z = 0
}

-- return list of members as a table
local get_member_list = function(meta)

    return meta:get_string("members"):split(" ")
end

-- write member list table in protector meta as string
local set_member_list = function(meta, list)

    meta:set_string("members", table.concat(list, " "))
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
    if is_owner(meta, name) or is_member(meta, name) then
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

-- protector interface
ship_machine.protector_formspec = function(meta)

    local formspec = "size[8,7]" .. default.gui_bg .. default.gui_bg_img .. "label[2.5,0;" ..
                         F(S("Jumpship Protection Interface")) .. "]" .. "label[0,2.5;" ..
                         F(S("PUNCH node to show protected area")) .. "]" .. "label[0,2;" .. F(S("Members:")) .. "]" ..
                         "button_exit[2.5,6.2;3,0.5;close_me;" .. F(S("Close")) .. "]" ..
                         "field_close_on_enter[protector_add_member;false]"

    local members = get_member_list(meta)
    local npp = protector_max_share_count -- max users added to protector list
    local i = 0
    local checkbox_faction = false

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

    for n = 1, #members do

        if i < npp then

            -- show username
            formspec = formspec .. "button[" .. (i % 4 * 2) .. "," .. math.floor(i / 4 + 3) ..
                           ";1.5,.5;protector_member;" .. F(members[n]) .. "]" -- username remove button
            .. "button[" .. (i % 4 * 2 + 1.25) .. "," .. math.floor(i / 4 + 3) .. ";.75,.5;protector_del_member_" ..
                           F(members[n]) .. ";X]"
        end

        i = i + 1
    end

    if i < npp then

        -- user name entry field
        formspec = formspec .. "field[" .. (i % 4 * 2 + 1 / 3) .. "," .. (math.floor(i / 4 + 3) + 1 / 3) ..
                       ";1.433,.5;protector_add_member;;]" -- username add button
        .. "button[" .. (i % 4 * 2 + 1.25) .. "," .. math.floor(i / 4 + 3) .. ";.75,.5;protector_submit;+]"

    end

    return formspec
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

ship_machine.protector.can_dig = function(r, pos, digger, onlyowner, infolevel)

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

        show_msg(digger, S("Spawn @1 has been protected up to a @2 block radius.", minetest.pos_to_string(statspawn),
            protector_spawn))

        return false
    end

    -- find the protector nodes
    local pos = minetest.find_nodes_in_area({
        x = pos.x - r,
        y = pos.y - r,
        z = pos.z - (r + 3)
    }, {
        x = pos.x + r,
        y = pos.y + r,
        z = pos.z + (r + 3)
    }, {"ship_machine:protect2"}) -- "ship_machine:protect2",

    if pos and #pos > 0 and pos[1] ~= nil then
        local jumpdrive_pos = vector.add(pos[1], {
            x = 0,
            y = -2,
            z = 0
        })
        local jumpdrive = minetest.get_node(jumpdrive_pos)
        if jumpdrive.name ~= "ship_machine:jump_drive" then
            return true
        end
    end

    local meta, owner, members

    for n = 1, #pos do

        meta = minetest.get_meta(pos[n])
        owner = meta:get_string("owner") or ""
        members = meta:get_string("members") or ""

        -- node change and digger isn't owner
        if infolevel == 1 and owner ~= digger then

            -- and you aren't on the member list
            if onlyowner or not is_member(meta, digger) then

                show_msg(digger, S("This ship area is owned by @1", owner) .. "!")

                return false
            end
        end

        -- when using protector as tool, show protector information
        if infolevel == 2 then

            minetest.chat_send_player(digger, S("This ship area is owned by @1", owner) .. ".")

            minetest.chat_send_player(digger, S("Protection located at: @1", minetest.pos_to_string(pos[n])))

            if members ~= "" then

                minetest.chat_send_player(digger, S("Members: @1.", members))
            end

            return false
        end

    end

    -- show when you can build on unprotected area
    if infolevel == 2 then

        if #pos < 1 then

            minetest.chat_send_player(digger, S("This ship area is not protected."))
        end

        minetest.chat_send_player(digger, S("You can build here."))
    end

    return true
end

-- add protector hurt and flip to protection violation function
minetest.register_on_protection_violation(function(pos, name)

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
end)

local old_is_protected = minetest.is_protected

-- check for protected area, return true if protected and digger isn't on list
function minetest.is_protected(pos, digger)

    digger = digger or "" -- nil check

    -- is area protected against digger?
    if not ship_machine.protector.can_dig(protector_radius, pos, digger, false, 1) then
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

    -- make sure protector doesn't overlap onto protected spawn area
    if inside_spawn(pos, protector_spawn + protector_radius) then

        minetest.chat_send_player(name, S("Spawn @1 has been protected up to a @2 block radius.",
            minetest.pos_to_string(statspawn), protector_spawn))

        return itemstack
    end

    -- make sure protector doesn't overlap any other player's area
    if not ship_machine.protector.can_dig(protector_radius * 2, pos, name, true, 3) then

        minetest.chat_send_player(name, S("Overlaps into above players protected area"))

        return itemstack
    end

    return minetest.item_place(itemstack, placer, pointed_thing)

end

-- remove protector display entities
local del_display = function(pos)

    local objects = minetest.get_objects_inside_radius(pos, 0.5)

    for _, v in ipairs(objects) do

        if v and v:get_luaentity() and v:get_luaentity().name == "ship_machine:display" then
            v:remove()
        end
    end
end

-- temporary pos store
local player_pos = {}

local texture_active = {
    image = "ship_protector_anim.png",
    animation = {
        type = "vertical_frames",
        aspect_w = 32,
        aspect_h = 32,
        length = 3
    }
}

function ship_machine.rightclick(pos, clicker)
    local meta = minetest.get_meta(pos)
    local name = clicker:get_player_name()

    if meta and ship_machine.protector.can_dig(1, pos, name, true, 1) then
        player_pos[name] = pos
        minetest.show_formspec(name, "ship_machine:node", ship_machine.protector_formspec(meta))
    end
end

function ship_machine.punch(pos, node, puncher)
    if minetest.is_protected(pos, puncher:get_player_name()) then
        return
    end
    minetest.add_entity(pos, "ship_machine:display")
end

-- protection node
minetest.register_node("ship_machine:protect2", {
    description = S("Ship Protection Block"),
    drawtype = "nodebox",
    -- tiles = {"ship_protector_anim.png", "ship_protector_anim.png", "ship_protector2.png"},
    tiles = {"ship_protector.png", "ship_protector.png", texture_active, texture_active, texture_active, texture_active},
    -- use_texture_alpha = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        dig_immediate = 2,
        unbreakable = 1
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
                 {-0.46875, 0.46875, -0.46875, -0.40625, -0.46875, -0.40625}, {-0.25, -0.25, -0.25, 0.25, 0.25, 0.25}}

    },

    on_place = check_overlap,

    after_place_node = function(pos, placer)

        local meta = minetest.get_meta(pos)

        meta:set_string("owner", placer:get_player_name() or "")
        meta:set_string("members", "")
        meta:set_string("infotext", S("Protection (owned by @1)", meta:get_string("owner")))
    end,

    on_use = function(itemstack, user, pointed_thing)

        if pointed_thing.type ~= "node" then
            return
        end

        ship_machine.protector.can_dig(protector_radius, pointed_thing.under, user:get_player_name(), false, 2)
    end,

    on_rightclick = function(pos, node, clicker, itemstack)

        local meta = minetest.get_meta(pos)
        local name = clicker:get_player_name()

        if meta and ship_machine.protector.can_dig(1, pos, name, true, 1) then

            player_pos[name] = pos

            minetest.show_formspec(name, "ship_machine:node", ship_machine.protector_formspec(meta))
        end
    end,

    on_punch = function(pos, node, puncher)

        if minetest.is_protected(pos, puncher:get_player_name()) then
            return
        end

        local pos_offset = vector.add(pos, {
            x = 0,
            y = -2,
            z = 0
        })

        minetest.add_entity(pos_offset, "ship_machine:display")
    end,

    can_dig = function(pos, player)
        -- return player and ship_machine.protector.can_dig(1, pos, player:get_player_name(), true, 1)
        local is_admin = player:get_player_name() == "squidicuzz"
        return player and is_admin
    end,

    on_blast = function()
    end,

    after_destruct = del_display
})

-- check formspec buttons or when name entered
minetest.register_on_player_receive_fields(function(player, formname, fields)

    if formname ~= "ship_machine:node" then
        return
    end

    local name = player:get_player_name()
    local pos = player_pos[name]

    if not name or not pos then
        return
    end

    local add_member_input = fields.protector_add_member

    -- reset formspec until close button pressed
    if (fields.close_me or fields.quit) and (not add_member_input or add_member_input == "") then
        player_pos[name] = nil
        return
    end

    -- only owner can add names
    if not ship_machine.protector.can_dig(1, pos, player:get_player_name(), true, 1) then
        return
    end

    -- are we adding member to a protection node ? (csm protection)
    local nod = minetest.get_node(pos).name

    if nod ~= "ship_machine:protect" and nod ~= "ship_machine:protect2" then
        player_pos[name] = nil
        return
    end

    local meta = minetest.get_meta(pos)

    if not meta then
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

    minetest.show_formspec(name, formname, ship_machine.protector_formspec(meta))
end)

-- display entity shown when protector node is punched
minetest.register_entity("ship_machine:display", {
    physical = false,
    collisionbox = {0, 0, 0, 0, 0, 0},
    visual = "wielditem",
    -- wielditem seems to be scaled to 1.5 times original node size
    visual_size = {
        x = 0.67,
        y = 0.67
    },
    textures = {"ship_machine:display_node"},
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

local x = protector_radius
local y = protector_radius
local z = protector_radius + 3
minetest.register_node("ship_machine:display_node", {
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

local function do_particles(pos, amount)
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
        time = prt.time + math.random(5.6, 10.7),
        minpos = {
            x = pos.x - 2.7,
            y = pos.y - 2.1,
            z = pos.z - 2.7
        },
        maxpos = {
            x = pos.x + 2.7,
            y = pos.y + 3.2,
            z = pos.z + 2.7
        },
        minvel = {
            x = rx,
            y = prt.vel * 0.2,
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
            z = 0.2
        },
        minexptime = prt.time * 0.28,
        maxexptime = prt.time * 0.52,
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

minetest.register_abm({
    label = "ship effects - jumpdrive",
    nodenames = {"ship_machine:protect2"},
    interval = 1,
    chance = 3,
    min_y = vacuum.vac_heights.space.start_height,
    action = function(pos)

        do_particles(pos, 5)

    end
})

dofile(MP .. "/hud.lua")

