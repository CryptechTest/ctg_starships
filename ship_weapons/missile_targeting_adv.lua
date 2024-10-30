local S = minetest.get_translator(minetest.get_current_modname())

local time_scl = 10

local function isNumber(str)
    return tonumber(str) ~= nil
end

local function round(v)
    return math.floor(v + 0.5)
end

local function check_path(origin, pos_target)
    local bClear = 0;
    local ray = minetest.raycast(origin, pos_target, true, false)
    for pointed_thing in ray do
        if pointed_thing.type == "node" then
            local pos = pointed_thing.intersection_point
            if (vector.distance(origin, pos) > 1.25) and (vector.distance(pos_target, pos) > 3) then
                local node = minetest.get_node(pos)
                if node.name ~= "air" and node.name ~= "vacuum:vacuum" and node.name ~= "vacuum:atmos_thin" and
                    node.name ~= ":asteroid:atmos" then
                    bClear = bClear + 1;
                    break
                end
            end
        end
    end
    return bClear
end

local function do_strike_obj(pos, dish_pos, mode, ltier)
    local meta = minetest.get_meta(pos)
    local meta_dish = minetest.get_meta(dish_pos)
    local range = meta_dish:get_int("range")
    -------------------------------------------------------
    -- strike launch to target object
    local proj_def = {
        delay = 7,
        tier = ltier
    }
    local bFoundTarget = false
    local nTargetCount = 0
    local objs = minetest.get_objects_inside_radius(dish_pos, range + 0.251)
    for _, obj in pairs(objs) do
        if nTargetCount >= 1 then
            break
        end
        local obj_pos = obj:get_pos()
        -- check for line of sight...
        if obj_pos and check_path(dish_pos, obj_pos) == 0 then
            -- handle entities
            if obj:get_luaentity() and not obj:is_player() then
                local ent = obj:get_luaentity()
                if ent.type and (ent.type == "npc" or ent.type == "animal" or ent.type == "monster") then
                    -- monsters
                    if ent.type == "monster" and (mode == 5) then
                        bFoundTarget = true;
                        nTargetCount = nTargetCount + 1
                        digilines.receptor_send(pos, technic.digilines.rules_allfaces, "missile_tower", {
                            command = "targeting_set",
                            target_entry = {
                                pos = obj_pos
                            }
                        })
                    end
                end
            elseif obj:is_player() and (mode == 2 or mode == 3) then
                local name = obj:get_player_name()
                -- players
                if name ~= meta:get_string("owner") --[[and not ship_weapons.is_member(meta, name)]] then
                    bFoundTarget = true;
                    nTargetCount = nTargetCount + 1
                    digilines.receptor_send(pos, technic.digilines.rules_allfaces, "missile_tower", {
                        command = "targeting_set",
                        target_entry = {
                            pos = obj_pos
                        }
                    })
                end
            end
        end
    end
    if bFoundTarget then
        meta:set_int("firing", 1)
        digilines.receptor_send(pos, technic.digilines.rules_allfaces, "missile_tower", {
            command = "targeting_launch",
            launch_entry = {
                count = 1,
                delay = 5
            }
        })
    else
        meta:set_int("firing", 0)
    end
    -- end strike
    return nTargetCount
end

local function find_ship(pos, r)
    local nodes = minetest.find_nodes_in_area({
        x = pos.x - r,
        y = (pos.y - r) + 2,
        z = pos.z - r
    }, {
        x = pos.x + r,
        y = (pos.y + r) + 2,
        z = pos.z + r
    }, {"group:jumpdrive"})
    return nodes
end

local function find_ship_protect(pos, r)
    local nodes = minetest.find_nodes_in_area({
        x = pos.x - r,
        y = (pos.y - r) + 2,
        z = pos.z - r
    }, {
        x = pos.x + r,
        y = (pos.y + r) + 2,
        z = pos.z + r
    }, {"group:ship_protector"})
    return nodes
end

local function do_strike_ship(pos, dish_pos, mode, ltier)
    local meta = minetest.get_meta(pos)
    local meta_dish = minetest.get_meta(dish_pos)
    local range = meta_dish:get_int("range")
    if range > 80 then
        range = 80
    end
    -------------------------------------------------------
    -- strike launch to target object
    local proj_def = {
        delay = 8,
        tier = ltier
    }
    local bFoundTarget = false
    local nTargetCount = 0
    local nodes = find_ship(dish_pos, range)
    local protects = find_ship_protect(dish_pos, 72)
    local our_ship = nil
    for _, node in pairs(protects) do
        local ship_meta = minetest.get_meta(node)
        local name = ship_meta:get_string("owner")
        if name == meta:get_string("owner") then
            our_ship = {
                pos = node,
                meta = ship_meta
            }
        end
    end
    if our_ship == nil then
        return nTargetCount
    end
    for _, node in pairs(nodes) do
        if nTargetCount >= 1 then
            break
        end
        local node_pos = node
        -- check for line of sight...
        local nodes_in_path = check_path(dish_pos, node_pos)
        if node_pos and nodes_in_path < 48 then
            local ship_meta = minetest.get_meta(node_pos)
            local name = ship_meta:get_string("owner")
            local r = (nodes_in_path * 0.8) + 3
            local target_pos = vector.add(node_pos, {
                x = math.random(-r, r),
                y = math.random(-r, r),
                z = math.random(-r, r)
            })
            -- ships
            if name ~= meta:get_string("owner") and not ship_weapons.is_member(our_ship.meta, name) then
                bFoundTarget = true;
                nTargetCount = nTargetCount + 1
                digilines.receptor_send(pos, technic.digilines.rules_allfaces, "missile_tower", {
                    command = "targeting_set",
                    target_entry = {
                        pos = target_pos
                    }
                })
            end
        end
    end
    if bFoundTarget then
        meta:set_int("firing", 1)
        digilines.receptor_send(pos, technic.digilines.rules_allfaces, "missile_tower", {
            command = "targeting_launch",
            launch_entry = {
                count = 1,
                delay = 5
            }
        })
    else
        meta:set_int("firing", 0)
    end
    -- end strike
    return nTargetCount
end

function ship_weapons.register_targeting_computer_adv(custom_data)

    local data = custom_data or {}

    data.speed = 1
    data.range = 72
    data.demand = {50, 45, 40}
    data.tier = (custom_data and custom_data.tier) or "MV"
    data.typename = (custom_data and custom_data.typename) or "target_computer"
    data.modname = (custom_data and custom_data.modname) or "ship_weapons"
    data.machine_name = (custom_data and custom_data.machine_name) or "target_computer_adv"
    data.machine_desc = (custom_data and custom_data.machine_desc) or "Targeting Computer"

    local tier = data.tier
    local ltier = string.lower(tier)
    local modname = data.modname
    local machine_name = data.machine_name
    local machine_desc = tier .. " " .. data.machine_desc
    local lmachine_name = string.lower(machine_name)
    local node_name = modname .. ":" .. machine_name

    local active_groups = {
        cracky = 2,
        technic_machine = 1,
        ["technic_" .. ltier] = 1,
        ctg_machine = 1,
        metal = 1,
        level = 1,
        ship_machine = 1
        -- ship_weapon = 1,
        -- not_in_creative_inventory = 1
    }

    local connect_sides = {"top", "bottom", "left", "right"}

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

        local attack_mode = meta:get_int("attack_mode")
        local locked = meta:get_int("target_locked")
        local power = meta:get_float("target_power") -- distance to travel
        local pitch = meta:get_float("target_pitch") -- location up/down
        local yaw = meta:get_float("target_yaw") -- direction/rotation
        local sel = meta:get_int("selected_dir")
        if fields.btn1 then
            sel = 1
            pitch = 90
            yaw = -90
            locked = 0
        elseif fields.btn2 then
            sel = 2
            pitch = 45
            yaw = -90
            locked = 0
        elseif fields.btn3 then
            sel = 3
            pitch = 0
            yaw = -90
            locked = 0
        elseif fields.btn4 then
            sel = 4
            pitch = -45
            yaw = -90
            locked = 0
        elseif fields.btn5 then
            sel = 5
            pitch = -90
            yaw = -90
            locked = 0
        elseif fields.btn6 then
            sel = 6
            pitch = 90
            yaw = -45
            locked = 0
        elseif fields.btn7 then
            sel = 7
            pitch = 45
            yaw = -45
            locked = 0
        elseif fields.btn8 then
            sel = 8
            pitch = 0
            yaw = -45
            locked = 0
        elseif fields.btn9 then
            sel = 9
            pitch = -45
            yaw = -45
            locked = 0
        elseif fields.btn10 then
            sel = 10
            pitch = -90
            yaw = -45
            locked = 0
        elseif fields.btn11 then
            sel = 11
            pitch = 90
            yaw = 0
            locked = 0
        elseif fields.btn12 then
            sel = 12
            pitch = 45
            yaw = 0
            locked = 0
        elseif fields.btn13 then
            sel = 13
            pitch = 0
            yaw = 0
            locked = 0
        elseif fields.btn14 then
            sel = 14
            pitch = -45
            yaw = 0
            locked = 0
        elseif fields.btn15 then
            sel = 15
            pitch = -90
            yaw = 0
            locked = 0
        elseif fields.btn16 then
            sel = 16
            pitch = 90
            yaw = 45
            locked = 0
        elseif fields.btn17 then
            sel = 17
            pitch = 45
            yaw = 45
            locked = 0
        elseif fields.btn18 then
            sel = 18
            pitch = 0
            yaw = 45
            locked = 0
        elseif fields.btn19 then
            sel = 19
            pitch = -45
            yaw = 45
            locked = 0
        elseif fields.btn20 then
            sel = 20
            pitch = -90
            yaw = 45
            locked = 0
        elseif fields.btn21 then
            sel = 21
            pitch = 90
            yaw = 90
            locked = 0
        elseif fields.btn22 then
            sel = 22
            pitch = 45
            yaw = 90
            locked = 0
        elseif fields.btn23 then
            sel = 23
            pitch = 0
            yaw = 90
            locked = 0
        elseif fields.btn24 then
            sel = 24
            pitch = -45
            yaw = 90
            locked = 0
        elseif fields.btn25 then
            sel = 25
            pitch = -90
            yaw = 90
            locked = 0
        end

        if attack_mode == 1 then
            meta:set_int("target_locked", locked)
            meta:set_int("selected_dir", sel)
            meta:set_float("target_pitch", pitch)
            meta:set_float("target_yaw", yaw)
        end

        local isNumError = false
        if fields.inp_power then
            if isNumber(fields.inp_power) then
                power = tonumber(fields.inp_power, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_pitch then
            if isNumber(fields.inp_pitch) then
                pitch = tonumber(fields.inp_pitch, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_yaw then
            if isNumber(fields.inp_yaw) then
                yaw = tonumber(fields.inp_yaw, 10)
            else
                isNumError = true
            end
        end

        if power < 10 then
            power = 10
        elseif power > 1000 then
            power = 1000
        end
        if pitch > 110 then
            pitch = 110
        elseif pitch < -110 then
            pitch = -110
        end
        if yaw > 120 then
            yaw = 120
        elseif yaw < -120 then
            yaw = -120
        end

        if fields.attack_mode then
            local attack = fields.attack_mode
            if attack == 'Manual' then
                attack_mode = 1
            elseif attack == 'Automatic' then
                attack_mode = 2
            elseif attack == 'Auto Player' then
                attack_mode = 3
            elseif attack == 'Auto Ship' then
                attack_mode = 4
            elseif attack == 'Auto Any' then
                attack_mode = 5
            end
            meta:set_int("attack_mode", attack_mode)
        end

        if fields.submit_target and not isNumError and attack_mode == 1 then
            meta:set_int("target_locked", 1)
            meta:set_float("target_power", power)
            meta:set_float("target_pitch", pitch)
            meta:set_float("target_yaw", yaw)
            digilines.receptor_send(pos, technic.digilines.rules_allfaces, "missile_tower", {
                command = "targeting_entry",
                target_entry = {
                    power = power,
                    pitch = pitch,
                    yaw = yaw
                }
            })
        end

        local delay = meta:get_int("target_delay")
        if fields.inp_delay then
            if isNumber(fields.inp_delay) then
                delay = tonumber(fields.inp_delay, 10)
            else
                isNumError = true
            end
        end
        if delay > 300 then
            delay = 300
        elseif delay < 0 then
            delay = 0
        end
        if not isNumError then
            meta:set_int("target_delay", delay)
        end

        local count = meta:get_int("target_count")
        if fields.inp_count then
            if isNumber(fields.inp_count) then
                count = tonumber(fields.inp_count, 10)
            else
                isNumError = true
            end
        end
        if count > 16 then
            count = 16
        elseif count < 1 then
            count = 1
        end
        if not isNumError then
            meta:set_int("target_count", count)
        end

        if isNumError then
            meta:set_int("target_error_number", 1)
        else
            meta:set_int("target_error_number", 0)
        end

        if fields.submit_launch and locked and attack_mode == 1 then
            digilines.receptor_send(pos, technic.digilines.rules_allfaces, "missile_tower", {
                command = "targeting_launch",
                launch_entry = {
                    count = count,
                    delay = delay
                }
            })
        end

        local formspec = ship_weapons.update_formspec(data, meta)
        meta:set_string("formspec", formspec)

    end

    -------------------------------------------------------
    -------------------------------------------------------
    -- technic run
    local run = function(pos, node)
        local meta = minetest.get_meta(pos)
        local owner = meta:get_string("owner")
        local operator = minetest.get_player_by_name(owner);
        local inv = meta:get_inventory()
        local eu_input = meta:get_int(tier .. "_EU_input")

        local machine_desc_tier = machine_desc:format(tier)
        local machine_node = data.modname .. ":" .. ltier .. "_" .. machine_name
        local machine_demand_active = data.demand

        local attack_mode = meta:get_int("attack_mode")
        local dish_ping = meta:get_int("dish_ping")
        local dish_pos = minetest.deserialize(meta:get_string("dish_pos")) or nil

        if dish_ping == 0 then
            meta:set_int("dish_ping", 30)
            meta:set_string("dish_pos", nil)
            digilines.receptor_send(pos, technic.digilines.rules_allfaces, "targeting_dish", {
                command = "pos_self"
            })
        end
        if dish_ping > 0 then
            meta:set_int("dish_ping", dish_ping - 1)
        end

        -- Get digiline data storage
        -- local digiline_data = minetest.deserialize(meta:get_string("digiline_data")) or default_digi_data

        -- Setup meta data if it does not exist.
        if not eu_input then
            meta:set_int(tier .. "_EU_demand", machine_demand_active[1])
            meta:set_int(tier .. "_EU_input", 0)
            return
        end

        local powered = eu_input >= machine_demand_active[1]
        if powered then
            meta:set_int("src_time", meta:get_int("src_time") + round(data.speed * 10 * 1.0))
        end
        while true do
            local enabled = meta:get_int("enabled") == 1

            meta:set_int(tier .. "_EU_demand", machine_demand_active[1])

            if not powered then
                meta:set_string("infotext", machine_desc_tier .. S(" - Not Powered"))
                return
            end

            if attack_mode == 1 then
                meta:set_string("infotext", machine_desc_tier .. S(" - Powered"))
            else
                if dish_pos == nil then
                    meta:set_string("infotext", machine_desc_tier .. S(" - Targeting Dish Not Found!"))
                else
                    meta:set_string("infotext", machine_desc_tier .. S(" - Powered"))
                end
            end

            if meta:get_int("last_hit") >= 1 then
                meta:set_int("last_hit", meta:get_int("last_hit") - 1)
            end

            local isFiring = meta:get_int("firing") ~= 0

            if (meta:get_int("src_time") < round(time_scl * 10)) then
                break
            end

            if attack_mode == 1 then

            elseif attack_mode == 2 and dish_pos then
                if do_strike_obj(pos, dish_pos, attack_mode, ltier) == 0 then
                    do_strike_ship(pos, dish_pos, attack_mode, ltier)
                end
            elseif attack_mode == 3 and dish_pos then
                do_strike_obj(pos, dish_pos, attack_mode, ltier)
            elseif attack_mode == 4 and dish_pos then
                do_strike_ship(pos, dish_pos, attack_mode, ltier)
            end

            meta:set_int("src_time", meta:get_int("src_time") - round(time_scl * 10))
        end
    end

    minetest.register_node(node_name, {
        description = machine_desc,
        tiles = {"mv_target_computer_top.png", "mv_target_computer_side.png", "mv_target_computer_side.png",
                 "mv_target_computer_side.png", "mv_target_computer_side.png", "mv_target_computer_side.png"},
        param = "light",
        paramtype2 = "facedir",
        light_source = 4,
        drop = node_name,
        groups = active_groups,
        legacy_facedir_simple = true,
        drawtype = "mesh",
        mesh = "moreblocks_slope_half_raised.obj",
        selection_box = {
            type = "fixed",
            fixed = {{-0.5000, -0.5000, -0.5000, 0.5000, 0.5000, 0.5000}}
        },
        collision_box = {
            type = "fixed",
            fixed = {{-0.5, -0.5, -0.5, 0.5, 0.125, 0.5}, {-0.5, 0.125, -0.25, 0.5, 0.25, 0.5},
                     {-0.5, 0.25, 0, 0.5, 0.375, 0.5}, {-0.5, 0.375, 0.25, 0.5, 0.5, 0.5}}
        },
        sounds = default.node_sound_glass_defaults(),
        connect_sides = connect_sides,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Weapons Control " .. "-" .. " " .. machine_desc)
            if placer:is_player() then
                meta:set_string("owner", placer:get_player_name()) -- TODO: get owner from area...
            end
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            -- local inv = meta:get_inventory()
            meta:set_int("enabled", 1)
            meta:set_int("selected_dir", 13)
            meta:set_int("attack_mode", 1)
            meta:set_string("formspec", ship_weapons.update_formspec(data, meta))
            meta:set_string("pos_target", minetest.serialize({}))
            meta:set_int("target_error_number", 0)
            meta:set_int("target_locked", 0)
            meta:set_int("target_delay", 3)
            meta:set_int("target_count", 1)
            meta:set_float("target_power", 25.0)
            meta:set_float("target_pitch", 0.0)
            meta:set_float("target_yaw", 0.0)
            meta:set_int("dish_ping", 0)
            meta:set_string("dish_pos", nil)
        end,

        on_punch = function(pos, node, puncher)
        end,

        on_receive_fields = on_receive_fields,
        technic_run = run,

        digiline = {
            receptor = {
                rules = technic.digilines.rules_allfaces,
                action = function()
                end
            },
            effector = {
                rules = technic.digilines.rules_allfaces,
                action = ship_weapons.targeting_computer_adv_digiline_effector
            }
        }
    })

    technic.register_machine(tier, node_name, technic.receiver)
end

ship_weapons.register_targeting_computer_adv();
