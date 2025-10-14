local S = minetest.get_translator(minetest.get_current_modname())

spatial_tubes = {}

-- load files
local default_path = minetest.get_modpath("spatial_tubes")

local time_scl = 5

local function isInteger(str)
    return tonumber(str) ~= nil
end

local function round(v)
    return math.floor(v + 0.5)
end

local function particle_effect(pos, type)
    local time = 2
    local minpos = {
        x = pos.x - 0.9,
        y = pos.y - 0.3,
        z = pos.z - 0.9
    }
    local maxpos = {
        x = pos.x + 0.9,
        y = pos.y + 0.1,
        z = pos.z + 0.9
    }

    if type == 1 then
        time = 1.5
        minpos = {
            x = pos.x - 0.4,
            y = pos.y - 0.3,
            z = pos.z - 0.4
        }
        maxpos = {
            x = pos.x + 0.4,
            y = pos.y + 0.1,
            z = pos.z + 0.4
        }
    end
    -- spawn particle
    minetest.add_particlespawner({
        amount = 50, -- amount
        time = time, -- time
        minpos = minpos, -- minpos
        maxpos = maxpos, -- maxpos
        minvel = {
            x = 0,
            y = 0,
            z = 0
        }, -- minvel
        maxvel = {
            x = 0,
            y = 0.05,
            z = 0
        }, -- maxvel
        minacc = {
            x = -0,
            y = 1,
            z = -0
        }, -- minacc
        maxacc = {
            x = 0,
            y = 2,
            z = 0
        }, -- maxacc
        minexptime = 0.45, -- minexptime
        maxexptime = time - 0.5, -- maxexptime
        minsize = 0.5, -- minsize
        maxsize = 2.5, -- maxsize
        collisiondetection = false, -- collisiondetection
        collision_removal = false, -- collision_removal
        object_collision = false,
        vertical = true,
        texture = {
            name = "scifi_nodes_tp_part.png",
            fade = "out"
        }, -- texture
        glow = 11 -- glow
    })
end

local function particle_effect_teleport(pos, amount)
    local texture = {
        name = "local_tele_effect_anim.png",
        fade = "out"
    }
    local animation = {
        type = "vertical_frames",
        aspect_w = 64,
        aspect_h = 64,
        length = 0.22
    }
    --[[local r = math.random(0, 4)
    if r == 1 then
        texture = "local_tele_effect_anim.png^[transformR90"
    elseif r == 2 then
        texture = "local_tele_effect_anim.png^[transformR180"
    elseif r == 3 then
        texture = "local_tele_effect_anim.png^[transformR270"
    elseif r == 4 then
        texture = "local_tele_effect_anim.png^[transformFX"
    end--]]
    -- local opac = math.random(4, 10) * 0.1
    -- texture = texture .. "^[opacity:" .. opac

    -- spawn particle
    minetest.add_particlespawner({
        amount = amount,
        time = math.random(0.5, 0.7),
        minpos = {
            x = pos.x - 0.02,
            y = pos.y - 0.15,
            z = pos.z - 0.02
        },
        maxpos = {
            x = pos.x + 0.02,
            y = pos.y + 0.42,
            z = pos.z + 0.02
        },
        minvel = {
            x = 0,
            y = 0,
            z = 0
        },
        maxvel = {
            x = 0,
            y = 0.15,
            z = 0
        },
        minacc = {
            x = -0,
            y = -0.1,
            z = -0
        },
        maxacc = {
            x = 0,
            y = 0.25,
            z = 0
        },
        minexptime = 0.28,
        maxexptime = 0.46,
        minsize = 16,
        maxsize = 25,
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        animation = animation,
        texture = texture,
        glow = 15
    })
end

local function play_sound(pos, sound, distance, excluded_name)
    if sound then
        -- higher pitch for a child
        local pitch = 0.6

        -- a little random pitch to be different
        pitch = pitch + math.random(-10, 10) * 0.005

        minetest.sound_play(sound, {
            pos = pos,
            gain = 1.0,
            max_hear_distance = distance,
            pitch = pitch,
            exclude_player = excluded_name
        }, true)
    end
end

local function needs_charge(pos)
    local meta = minetest.get_meta(pos)
    local charge = meta:get_int("charge")
    local charge_max = meta:get_int("charge_max")
    return charge < charge_max
end

function spatial_tubes.register_machine(data)
    local tier = data.tier
    local ltier = string.lower(tier)
    local machine_name = data.machine_name
    local machine_desc = tier .. ' ' .. data.machine_desc
    local node_name = data.modname .. ":" .. ltier .. "_" .. machine_name

    local groups = {
        cracky = 1,
        technic_machine = 1,
        ["technic_" .. ltier] = 1,
        ctg_machine = 1,
        metal = 1,
        level = 1,
        telepad = 1,
        ["telepad_" .. ltier] = 1
    }

    local active_groups = {
        not_in_creative_inventory = 1
    }
    for k, v in pairs(groups) do
        active_groups[k] = v
    end

    local update_formspec = function(pos, data)
        local node = minetest.get_node(pos)
        local meta = minetest.get_meta(pos)
        local exit = nil
        local formspec = nil

        if data.tier == "LV" or data.tier == "MV" then
            if meta:get_string("exit") then
                exit = minetest.deserialize(meta:get_string("exit"))
            end
            if meta:get_string("sta_exit") and meta:get_string("sta_exit") ~= "" then
                exit = meta:get_string("sta_exit");
            end

            if exit == nil then
                local desc = "label[0.15,0.3;" .. machine_desc .. "]"
                local input_pos =
                    "field[1,1.5;2,1;inp_x;Dest X;0]field[3,1.5;2,1;inp_y;Dest Y;0]field[5,1.5;2,1;inp_z;Dest Z;0]"
                local input_name = "field[1,1.5;3,1;inp_name;This Name;]"
                local input_dest = "field[4,1.5;3,1;dst_name;Dest Name;]"
                local input_save = "button[3,2.5;2,1;save;Save]"

                formspec = {"formspec_version[6]", "size[8,4]", desc, input_name, input_dest, input_save}
            else
                formspec = {}
            end
        else
            if meta:get_string("exit") then
                exit = minetest.deserialize(meta:get_string("exit"))
            end

            if exit == nil then
                local desc = "label[0.15,0.3;" .. machine_desc .. "]"
                local input_pos =
                    "field[1,1.5;2,1;inp_x;Dest X;]field[3,1.5;2,1;inp_y;Dest Y;]field[5,1.5;2,1;inp_z;Dest Z;]"
                local input_save = "button[3,2.5;2,1;save;Lock Link]"

                formspec = {"formspec_version[6]", "size[8,4]", desc, input_pos, input_save}
            else
                formspec = {}
            end
        end

        return table.concat(formspec)
    end

    local texture_tier = ''
    if ltier == "mv" then
        texture_tier = '^[colorize:#4bff3b0a'
    elseif ltier == "hv" then
        texture_tier = '^[colorize:#fff5850f'
    end

    -------------------------------------------------------

    -- technic run
    local run = function(pos, node)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local eu_input = meta:get_int(tier .. "_EU_input")
        local charge_max = meta:get_int("charge_max")
        local charge = meta:get_int("charge")

        local machine_desc_tier = machine_desc:format(tier)
        local machine_node = data.modname .. ":" .. ltier .. "_" .. machine_name
        local machine_demand_active = data.demand
        local machine_demand_idle = data.demand[1] * 0.28

        -- Setup meta data if it does not exist.
        if not eu_input then
            meta:set_int(tier .. "_EU_demand", machine_demand_active[1])
            meta:set_int(tier .. "_EU_input", 0)
            return
        end
        if meta:get_int("enabled") == nil then
            meta:set_int("enabled", 0)
            meta:set_int("ready", 0)
            return
        end

        -- upgrades??
        local EU_upgrade, tube_upgrade = 0, 0
        if data.upgrade then
            EU_upgrade, tube_upgrade = technic.handle_machine_upgrades(meta)
        end
        if data.tube then
            technic.handle_machine_pipeworks(pos, tube_upgrade)
        end

        -- check if powered, then tick machine time
        local powered = eu_input >= machine_demand_active[EU_upgrade + 1]
        if powered then
            meta:set_int("src_time", meta:get_int("src_time") + round(data.speed * 10 * 1.0))
        end

        -- run loop
        while true do
            -- check if enabled..
            local enabled = meta:get_int("enabled") == 1
            local isBusy = meta:get_int("busy") == 1
            if (not enabled) then
                technic.swap_node(pos, machine_node)
                meta:set_string("infotext", machine_desc_tier .. S(" Disabled"))
                meta:set_int(tier .. "_EU_demand", 0)
                meta:set_int("src_time", 0)
                meta:set_int("ready", 0)
                return
            end

            if isBusy then
                technic.swap_node(pos, machine_node .. "_busy")
                meta:set_int(tier .. "_EU_demand", machine_demand_active[EU_upgrade + 1])
                return
            end

            -- get destination from metadata
            local exit = nil
            if meta:get_string("exit") ~= nil then
                exit = minetest.deserialize(meta:get_string("exit")) or nil
            end
            if exit == nil and meta:get_string("sta_exit") ~= nil then
                exit = meta:get_string("sta_exit") or nil
            end

            -- check if charged..
            if not needs_charge(pos) then
                meta:set_int(tier .. "_EU_demand", machine_demand_idle)
                meta:set_int("src_time", 0)
                if exit ~= nil then
                    technic.swap_node(pos, machine_node .. "_active")
                    local dest = (meta:get_string("sta_exit") ~= nil and type(exit) ~= "table" and "\n" .. "Transport to: " .. exit) or ""
                    meta:set_string("infotext", machine_desc_tier .. S(" Ready - Charged") .. dest)
                    meta:set_int("ready", 1)
                else
                    technic.swap_node(pos, machine_node .. "_error")
                    meta:set_string("infotext", machine_desc_tier .. S(" Error - No Destination!"))
                    meta:set_int("ready", 0)
                end
                return
            elseif meta:get_int('ready') then
                technic.swap_node(pos, machine_node .. "_wait")
                meta:set_int("ready", 0)
            end

            -- set power used
            meta:set_int(tier .. "_EU_demand", machine_demand_active[EU_upgrade + 1])

            -- calculate charge percent
            local charge_percent = (math.floor(meta:get_int("charge") / meta:get_int("charge_max") * 100))
            local dest = (meta:get_string("sta_exit") ~= nil and type(exit) ~= "table" and "\n" .. "Transport to: " .. exit) or ""
            meta:set_string("infotext", machine_desc_tier .. S(" - Charge: " .. charge_percent .. "%" .. dest))
            -- check if run time is not expired..
            if meta:get_int("src_time") < round(time_scl * 10) then
                local item_percent = (math.floor(meta:get_int("src_time") / round(time_scl * 10) * 100))
                if not powered then
                    -- teleport pad is not powered!
                    technic.swap_node(pos, machine_node)
                    meta:set_string("infotext", machine_desc_tier .. S(" Unpowered"))
                    meta:set_int("ready", 0)
                    return
                end
                if not exit then
                    -- teleport pad has no destination..
                    technic.swap_node(pos, machine_node .. "_error")
                    meta:set_string("infotext", machine_desc_tier .. S(" Error - No Destination!"))
                    meta:set_int("ready", 0)
                end
                return
            end

            local locked = meta:get_int("locked") == 1
            if locked then
                -- increment charge ticker
                local chrg = math.random(1, 3)
                meta:set_int("charge", charge + chrg)
            end

            -- reset run time
            meta:set_int("src_time", 0)
        end
    end

    -------------------------------------------------------

    -- on_receive_fields event
    local on_receive_fields = function(pos, formname, fields, sender)
        if fields.quit or fields.exit then
            return
        end
        local node = minetest.get_node(pos)
        local meta = minetest.get_meta(pos)

        local dest_x = 0
        local dest_y = 0
        local dest_z = 0
        local isNumError = false
        if fields.inp_x then
            if isInteger(fields.inp_x) then
                dest_x = tonumber(fields.inp_x, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_y then
            if isInteger(fields.inp_y) then
                dest_y = tonumber(fields.inp_y, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_z then
            if isInteger(fields.inp_z) then
                dest_z = tonumber(fields.inp_z, 10)
            else
                isNumError = true
            end
        end

        local name = ""
        local dest = ""
        if fields.inp_name then
            name = fields.inp_name;
        end
        if fields.dst_name then
            dest = fields.dst_name;
        end

        if fields.save and not isNumError then
            if ltier == "lv" or ltier == "mv" then
                meta:set_string("sta_name", name)
                meta:set_string("sta_exit", dest)
                meta:set_string("infotext", "Transport to: " .. dest)
                meta:set_int("locked", 1)
                minetest.chat_send_player(sender:get_player_name(), "Setup Complete")
            else
                if (dest_y > -11000 and dest_y < 22000) then
                    local tfound = false
                    local pos1 = {
                        x = pos.x - 1,
                        y = pos.y - 2,
                        z = pos.z - 1
                    }
                    local pos2 = {
                        x = pos.x + 1,
                        y = pos.y + 2,
                        z = pos.z + 1
                    }
                    schem_lib.common.keep_loaded(pos1, pos2)
                    local dest = minetest.find_nodes_in_area(pos1, pos2, {node_name})
                    if #dest > 0 then
                        local dmeta = minetest.get_meta(dest[1])
                        if minetest.is_protected(dest[1], sender:get_player_name()) and
                            not minetest.check_player_privs(sender:get_player_name(), "protection_bypass") then
                            minetest.chat_send_player(sender:get_player_name(),
                                "Destination is within a protected area!")
                            minetest.record_protection_violation(dest[1], sender:get_player_name())
                            tfound = true
                        elseif dmeta:get_int("locked") ~= nil and dmeta:get_int("locked") == 0 then
                            -- save exit destination
                            meta:set_string("exit", minetest.serialize(dest[1]))
                            -- lock receiver
                            dmeta:set_int("locked", 1)
                            minetest.chat_send_player(sender:get_player_name(), "Telepad destination saved and locked!")
                            tfound = true
                        elseif dmeta:get_int("locked") == 1 then
                            minetest.chat_send_player(sender:get_player_name(), "This Telepad already has a receiver!")
                            tfound = true
                        end
                    end
                    if not tfound then
                        minetest.chat_send_player(sender:get_player_name(), "No Telepad found at destination location!")
                    end
                elseif sender:is_player() then
                    minetest.chat_send_player(sender:get_player_name(),
                        "Invalid Location Entered for Telepad!  Destination must be within spatial bounds.")
                end
            end
        end

        local formspec = update_formspec(pos, data)
        meta:set_string("formspec", formspec)
    end

    -------------------------------------------------------

    -- on_rightclick event
    local on_rightclick = function(pos, node, clicker)
        local clicker_name = clicker:get_player_name()
        local meta = minetest.get_meta(pos)
        -- check protection at this location
        if minetest.is_protected(pos, clicker_name) and
            not minetest.check_player_privs(clicker_name, "protection_bypass") then
            technic.swap_node(pos, node_name .. "_error")
            minetest.record_protection_violation(pos, clicker_name)
            return
        end
        local exit = nil
        -- get destination pos
        if meta:get_string("sta_exit") ~= nil then
            local r = (ltier == "mv" and 75) or 50
            local teles = minetest.find_nodes_in_area({
                x = pos.x - r,
                y = pos.y - r,
                z = pos.z - r
            }, {
                x = pos.x + r,
                y = pos.y + r,
                z = pos.z + r
            }, {"group:telepad_" .. ltier})
            for _, obj in pairs(teles) do
                local metaTo = minetest.get_meta(obj);
                if metaTo:get_string("sta_name") == meta:get_string("sta_exit") then
                    exit = obj
                    break
                end
            end
        elseif meta:get_string("exit") ~= nil then
            exit = minetest.deserialize(meta:get_string("exit"))
        else
            minetest.chat_send_player(clicker_name, "Teleporter exit not found or defined!")
            return;
        end
        -- is our exit destination setup?
        if exit ~= nil then
            -- check protection at destination location
            if minetest.is_protected(exit, clicker_name) and
                not minetest.check_player_privs(clicker_name, "protection_bypass") then
                technic.swap_node(pos, node_name .. "_error")
                minetest.chat_send_player(clicker_name, "Destination is within a protected area!")
                minetest.record_protection_violation(exit, clicker_name)
                return
            end
            local dnode = minetest.get_node(exit)
            -- check if destination pad exists..
            if not string.match(dnode.name, node_name) then
                technic.swap_node(pos, node_name .. "_error")
                minetest.chat_send_player(clicker_name, "Destination must be to another Telepad.")
                return
            end
            -- check if this pad is ready
            if not meta:get_int("ready") then
                minetest.chat_send_player(clicker_name, "This Teleport Pad requires more charge.")
                return
            end
            local dmeta = minetest.get_meta(exit)
            if not dmeta:get_int("locked") then
                technic.swap_node(pos, node_name .. "_error")
                minetest.chat_send_player(clicker_name, "Teleport Pad destination must be locked.")
                return
            end
            -- get destination node
            local nname = minetest.get_node({
                x = exit.x,
                y = exit.y - 1,
                z = exit.z
            }).name
            -- check if destination node is active..
            if nname == node_name then
                technic.swap_node(pos, node_name .. "_error")
                minetest.chat_send_player(clicker_name, "Teleport Pad at destination is not powered.")
                return
            elseif nname == node_name .. "_error" then
                technic.swap_node(pos, node_name .. "_error")
                minetest.chat_send_player(clicker_name, "A Teleport Pad was not found at the destination!")
                return
            end
            -- get objects within radius..
            local objs = minetest.get_objects_inside_radius(pos, 1)
            if #objs > 0 then
                local meta = minetest.get_meta({
                    x = pos.x,
                    y = pos.y,
                    z = pos.z
                })
                minetest.after(0, function()
                    -- summon effects
                    particle_effect(pos, 0)
                    particle_effect(exit, 1)
                    if clicker and clicker:is_player() then
                        local name = clicker:get_player_name()
                        minetest.sound_play("local_tele_drone", {
                            to_player = name,
                            gain = 1.0
                        })
                    end
                end)
                -- set busy flag
                technic.swap_node(pos, node_name .. "_busy")
                meta:set_int("busy", 1)
                minetest.after(2.75, function()
                    -- clear busy
                    technic.swap_node(pos, node_name .. "_error")
                    meta:set_int("busy", 0)
                end)
                -- clear charge
                meta:set_int("charge", 0)
                -- delay a little, then teleport
                minetest.after(1, function()
                    local ppos = clicker:get_pos()
                    if minetest.get_node({
                        x = ppos.x,
                        y = ppos.y,
                        z = ppos.z
                    }).name == node_name .. "_active" then
                        clicker:set_pos(exit)
                        local name = clicker:get_player_name()
                        minetest.sound_play("local_tele_zap", {
                            to_player = name,
                            gain = 1.2,
                            pitch = math.random(0.57, 0.64)
                        })
                    end
                    -- get objects within...
                    local objs = minetest.get_objects_inside_radius(pos, 2.25)
                    if #objs > 0 then
                        -- summon effects at dest
                        particle_effect_teleport(exit, 1)
                        local name = clicker:get_player_name()
                        play_sound(exit, "local_tele_zap", 7, name)
                    end
                    -- teleport objects within.. summon effects
                    for _, obj in pairs(objs) do
                        if obj and obj:get_luaentity() and not obj:is_player() then
                            local ent = obj:get_luaentity()
                            if ent.name == "__builtin:item" then
                                local item1 = obj:get_luaentity().itemstring
                                local obj2 = minetest.add_entity(exit, "__builtin:item")
                                obj2:get_luaentity():set_item(item1)
                                obj:remove()
                                particle_effect_teleport(exit, 1)
                            elseif ent.type and (ent.type == "npc" or ent.type == "animal" or ent.type == "monster") then
                                obj:set_pos(exit)
                                particle_effect_teleport(exit, 1)
                            end
                        elseif obj and obj:is_player() then
                            local name = obj:get_player_name()
                            minetest.sound_play("local_tele_zap", {
                                to_player = name,
                                gain = 1.2,
                                pitch = 0.6
                            })
                            obj:set_pos(exit)
                            particle_effect_teleport(exit, 1)
                        end
                    end
                end)
            end
        else
            minetest.chat_send_player(clicker_name, "Telepad exit is not defined!")
        end
    end

    -------------------------------------------------------
    -------------------------------------------------------

    minetest.register_node(node_name, {
        description = machine_desc,
        tiles = {"local_telepad_top_dark.png" .. texture_tier, "local_telepad_bottom.png" .. texture_tier,
                 "local_telepad_side.png" .. texture_tier, "local_telepad_side.png" .. texture_tier,
                 "local_telepad_side.png" .. texture_tier, "local_telepad_side.png" .. texture_tier},
        drawtype = "nodebox",
        paramtype = "light",
        drop = node_name,
        groups = groups,
        light_source = 4,
        node_box = {
            type = "fixed",
            fixed = {{-0.6250, -0.5000, -0.6250, 0.6250, -0.3438, 0.6250},
                     {-0.8125, -0.5000, -0.5625, -0.6250, -0.4375, 0.5625},
                     {0.6250, -0.5000, -0.5625, 0.8125, -0.4375, 0.5625},
                     {-0.5625, -0.5000, -0.8125, 0.5625, -0.4375, -0.6250},
                     {-0.5625, -0.5000, 0.6250, 0.5625, -0.4375, 0.8125}}
        },
        sounds = scifi_nodes.node_sound_metal_defaults(),

        technic_run = run,
        on_receive_fields = on_receive_fields,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local placer_name = placer:get_player_name()
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", machine_desc)
            meta:set_int("enabled", 1)
            meta:set_int("locked", 0)
            meta:set_int("charge", 0)
            meta:set_int("ready", 0)
            meta:set_int("busy", 0)
            meta:set_int("src_time", round(time_scl * 10) - data.speed)
            meta:set_int("charge_max", data.charge_max)
            meta:set_int("demand", data.demand[1])
            local formspec = update_formspec(pos, data)
            meta:set_string("formspec", formspec)
        end,
        on_rightclick = function(pos, node, clicker)
            local clicker_name = clicker:get_player_name()
            local meta = minetest.get_meta(pos)
            local exit = nil
            if meta:get_string("exit") then
                exit = minetest.deserialize(meta:get_string("exit"))
            end
            if meta:get_string("sta_exit") and meta:get_string("sta_exit") ~= "" then
                exit = meta:get_string("sta_exit");
            end
            if not exit then
                minetest.chat_send_player(clicker_name, "Teleporter exit is not defined!")
            end
        end
    })

    minetest.register_node(node_name .. "_wait", {
        description = machine_desc,
        tiles = {"local_telepad_top_wait.png" .. texture_tier, "local_telepad_bottom.png" .. texture_tier,
                 "local_telepad_side.png" .. texture_tier, "local_telepad_side.png" .. texture_tier,
                 "local_telepad_side.png" .. texture_tier, "local_telepad_side.png" .. texture_tier},
        drawtype = "nodebox",
        paramtype = "light",
        drop = node_name,
        groups = active_groups,
        light_source = 6,
        node_box = {
            type = "fixed",
            fixed = {{-0.6250, -0.5000, -0.6250, 0.6250, -0.3438, 0.6250},
                     {-0.8125, -0.5000, -0.5625, -0.6250, -0.4375, 0.5625},
                     {0.6250, -0.5000, -0.5625, 0.8125, -0.4375, 0.5625},
                     {-0.5625, -0.5000, -0.8125, 0.5625, -0.4375, -0.6250},
                     {-0.5625, -0.5000, 0.6250, 0.5625, -0.4375, 0.8125}}
        },
        sounds = scifi_nodes.node_sound_metal_defaults(),

        technic_run = run,
        on_receive_fields = on_receive_fields,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
        on_rightclick = function(pos, node, clicker)
            local clicker_name = clicker:get_player_name()
            local meta = minetest.get_meta(pos)
            local exit = nil
            if meta:get_string("exit") then
                exit = minetest.deserialize(meta:get_string("exit"))
            end
            if meta:get_string("sta_exit") and meta:get_string("sta_exit") ~= "" then
                exit = meta:get_string("sta_exit");
            end
            if exit == nil then
                minetest.chat_send_player(clicker_name, "Teleporter exit is not defined!")
            end
        end
    })

    minetest.register_node(node_name .. "_error", {
        description = machine_desc,
        tiles = {"local_telepad_top_error.png" .. texture_tier, "local_telepad_bottom.png" .. texture_tier,
                 "local_telepad_side.png" .. texture_tier, "local_telepad_side.png" .. texture_tier,
                 "local_telepad_side.png" .. texture_tier, "local_telepad_side.png" .. texture_tier},
        drawtype = "nodebox",
        paramtype = "light",
        drop = node_name,
        groups = active_groups,
        light_source = 6,
        node_box = {
            type = "fixed",
            fixed = {{-0.6250, -0.5000, -0.6250, 0.6250, -0.3438, 0.6250},
                     {-0.8125, -0.5000, -0.5625, -0.6250, -0.4375, 0.5625},
                     {0.6250, -0.5000, -0.5625, 0.8125, -0.4375, 0.5625},
                     {-0.5625, -0.5000, -0.8125, 0.5625, -0.4375, -0.6250},
                     {-0.5625, -0.5000, 0.6250, 0.5625, -0.4375, 0.8125}}
        },
        sounds = scifi_nodes.node_sound_metal_defaults(),

        technic_run = run,
        on_receive_fields = on_receive_fields,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
        on_rightclick = function(pos, node, clicker)
            local clicker_name = clicker:get_player_name()
            local meta = minetest.get_meta(pos)
            local exit = nil
            if meta:get_string("exit") then
                exit = minetest.deserialize(meta:get_string("exit"))
            end
            if meta:get_string("sta_exit") and meta:get_string("sta_exit") ~= "" then
                exit = meta:get_string("sta_exit");
            end
            if exit == nil then
                minetest.chat_send_player(clicker_name, "Teleporter exit is not defined!")
            end
        end
    })

    minetest.register_node(node_name .. "_busy", {
        description = machine_desc,
        tiles = {"local_telepad_top_send.png" .. texture_tier, "local_telepad_bottom.png" .. texture_tier,
                 "local_telepad_side.png" .. texture_tier, "local_telepad_side.png" .. texture_tier,
                 "local_telepad_side.png" .. texture_tier, "local_telepad_side.png" .. texture_tier},
        drawtype = "nodebox",
        paramtype = "light",
        drop = node_name,
        groups = active_groups,
        light_source = 8,
        node_box = {
            type = "fixed",
            fixed = {{-0.6250, -0.5000, -0.6250, 0.6250, -0.3438, 0.6250},
                     {-0.8125, -0.5000, -0.5625, -0.6250, -0.4375, 0.5625},
                     {0.6250, -0.5000, -0.5625, 0.8125, -0.4375, 0.5625},
                     {-0.5625, -0.5000, -0.8125, 0.5625, -0.4375, -0.6250},
                     {-0.5625, -0.5000, 0.6250, 0.5625, -0.4375, 0.8125}}
        },
        sounds = scifi_nodes.node_sound_metal_defaults(),
        technic_run = run,
        on_receive_fields = on_receive_fields,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig
    })

    local texture_active = {
        image = "local_telepad_top" .. "_active.png" .. texture_tier,
        animation = {
            type = "vertical_frames",
            aspect_w = 32,
            aspect_h = 32,
            length = 2
        }
    }

    minetest.register_node(node_name .. "_active", {
        description = machine_desc,
        tiles = {texture_active, "local_telepad_bottom.png" .. texture_tier, "local_telepad_side.png" .. texture_tier,
                 "local_telepad_side.png" .. texture_tier, "local_telepad_side.png" .. texture_tier,
                 "local_telepad_side.png" .. texture_tier},
        drawtype = "nodebox",
        paramtype = "light",
        drop = node_name,
        groups = active_groups,
        light_source = 7,
        node_box = {
            type = "fixed",
            fixed = {{-0.6250, -0.5000, -0.6250, 0.6250, -0.3438, 0.6250},
                     {-0.8125, -0.5000, -0.5625, -0.6250, -0.4375, 0.5625},
                     {0.6250, -0.5000, -0.5625, 0.8125, -0.4375, 0.5625},
                     {-0.5625, -0.5000, -0.8125, 0.5625, -0.4375, -0.6250},
                     {-0.5625, -0.5000, 0.6250, 0.5625, -0.4375, 0.8125}}
        },
        sounds = scifi_nodes.node_sound_metal_defaults(),

        technic_run = run,
        on_receive_fields = on_receive_fields,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
        on_rightclick = on_rightclick
    });

    technic.register_machine(tier, node_name, technic.receiver)
    technic.register_machine(tier, node_name .. "_wait", technic.receiver)
    technic.register_machine(tier, node_name .. "_busy", technic.receiver)
    technic.register_machine(tier, node_name .. "_active", technic.receiver)
    technic.register_machine(tier, node_name .. "_error", technic.receiver)
end

-- register telepad
spatial_tubes.register_machine({
    modname = "spatial_tubes",
    machine_name = "telepad_machine",
    machine_desc = S("Teleport Pad"),
    tier = "LV",
    demand = {2000},
    charge_max = 32,
    speed = 5
})

-- register telepad
spatial_tubes.register_machine({
    modname = "spatial_tubes",
    machine_name = "telepad_machine",
    machine_desc = S("Teleport Pad"),
    tier = "MV",
    demand = {3000},
    charge_max = 32,
    speed = 6
})

-- register telepad
spatial_tubes.register_machine({
    modname = "spatial_tubes",
    machine_name = "telepad_machine",
    machine_desc = S("Teleport Pad"),
    tier = "HV",
    demand = {2800},
    charge_max = 32,
    speed = 5
})

-- register crafting recipes
dofile(default_path .. DIR_DELIM .. "crafts.lua")
