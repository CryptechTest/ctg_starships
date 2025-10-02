ship_weapons.static_turret_digiline_effector = function(pos, node, channel, msg)
    local meta = minetest.get_meta(pos)
    local digiline_channel = meta:get_string("digiline_channel")
    local set_channel = digiline_channel or "static_turret"
    local msgt = type(msg)
    if msgt ~= "table" then
        return
    end
    if channel ~= set_channel then
        return
    end

    if msg.command == "enable" then
        meta:set_int("enabled", 1)
    end

    if msg.command == "disable" then
        meta:set_int("enabled", 0)
    end

    if msg.command == "status" then
        local inv = meta:get_inventory()
        local inv_src = inv:get_list("src")[1]
        local count = 0
        if inv_src then
            count = inv_src:get_count()
        end
        digilines.receptor_send(pos, technic.digilines.rules_allfaces, channel, {
            command = msg.command .. "_ack",
            ready = meta:get_int("ready"),
            missile_count = count
        })
    end

    if msg.command == "targeting_entry" then
        local te = msg.target_entry

        -- Get digiline data storage
        local digiline_data = minetest.deserialize(meta:get_string("digiline_data"))
        -- Update values
        digiline_data.target_pos = nil
        digiline_data.power = te.power
        digiline_data.pitch = te.pitch
        digiline_data.yaw = te.yaw
        -- Update digiline data...
        meta:set_string("digiline_data", minetest.serialize(digiline_data))

        digilines.receptor_send(pos, technic.digilines.rules_allfaces, channel, {
            command = msg.command .. "_ack"
        })
    end

    if msg.command == "targeting_launch" then
        local le = msg.launch_entry

        -- Get digiline data storage
        local digiline_data = minetest.deserialize(meta:get_string("digiline_data"))
        -- Update values
        digiline_data.launch = true
        digiline_data.count = le.count
        digiline_data.delay = le.delay
        -- Update digiline data...
        meta:set_string("digiline_data", minetest.serialize(digiline_data))

        digilines.receptor_send(pos, technic.digilines.rules_allfaces, channel, {
            command = msg.command .. "_ack"
        })
    end

    if msg.command == "targeting_set" then
        local te = msg.target_entry

        -- Get digiline data storage
        local digiline_data = minetest.deserialize(meta:get_string("digiline_data"))
        -- Update values
        digiline_data.target_pos = te.pos
        -- Update digiline data...
        meta:set_string("digiline_data", minetest.serialize(digiline_data))

        digilines.receptor_send(pos, technic.digilines.rules_allfaces, channel, {
            command = msg.command .. "_ack"
        })
    end

end

ship_weapons.targeting_computer_adv_digiline_effector = function(pos, node, channel, msg)
    local meta = minetest.get_meta(pos)
    local digiline_channel = meta:get_string("digiline_channel")
    local set_channel = digiline_channel or "targeting_computer_adv"
    local msgt = type(msg)
    if msgt ~= "table" then
        return
    end
    if channel ~= set_channel then
        return
    end

    if msg.command == "enable" then
        local meta = minetest.get_meta(pos)
        meta:set_int("enabled", 1)
    end

    if msg.command == "disable" then
        local meta = minetest.get_meta(pos)
        meta:set_int("enabled", 0)
    end

    if msg.command == "attack_mode_set" then
        local meta = minetest.get_meta(pos)
        meta:set_int("attack_mode", msg.mode)
    end

    if msg.command == "attack_mode_get" then
        local meta = minetest.get_meta(pos)
        digilines.receptor_send(pos, technic.digilines.rules_allfaces, set_channel .. "_reply", {
            command = "attack_mode_get",
            mode = meta:get_int("attack_mode")
        })
    end

    if msg.command == "dish_pos" then
        local meta = minetest.get_meta(pos)
        meta:set_string("dish_pos", msg.dish_pos)
    end

end

ship_weapons.targeting_dish_digiline_effector = function(pos, node, channel, msg)
    local meta = minetest.get_meta(pos)
    local digiline_channel = meta:get_string("digiline_channel")
    local set_channel = digiline_channel or "targeting_dish"
    local msgt = type(msg)
    if msgt ~= "table" then
        return
    end
    if channel ~= set_channel then
        return
    end

    if msg.command == "pos_self" then
        local meta = minetest.get_meta(pos)
        if (meta:get_int("enabled") == 1) then
            local node = digilines.get_node_force(pos)
            local spec = digilines.getspec(node)
            if spec and spec.effector and spec.effector.action then
                meta:set_int("pinged", 1)
                digilines.receptor_send(pos, technic.digilines.rules_allfaces, "targeting_computer_adv", {
                    command = "dish_pos",
                    dish_pos = minetest.serialize(pos)
                })
            end
            local dir = ship_weapons.get_port_direction(pos);
            meta:set_string("dish_dir", minetest.serialize(dir))
        end
    end

end
