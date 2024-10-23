ship_weapons.missile_tower_digiline_effector = function(pos, node, channel, msg)
    local set_channel = "missile_tower" -- static channel for now

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
    
    if msg.command == "status" then
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local inv_src = inv:get_list("src")[1]
        local count = 0
        if inv_src then
            count = inv_src:get_count()
        end
        digilines.receptor_send(pos, digilines.rules.default, channel, {
            command = msg.command .. "_ack",
            ready = meta:get_int("ready"),
            missile_count = count
        })
    end
    
    if msg.command == "targeting_entry" then
        local meta = minetest.get_meta(pos)
        local te = msg.target_entry

        -- Get digiline data storage
        local digiline_data = minetest.deserialize(meta:get_string("digiline_data"))
        -- Update values
        digiline_data.power = te.power
        digiline_data.pitch = te.pitch
        digiline_data.yaw = te.yaw
        -- Update digiline data...
        meta:set_string("digiline_data", minetest.serialize(digiline_data))
        
        digilines.receptor_send(pos, digilines.rules.default, channel, {
            command = msg.command .. "_ack",
        })
    end
    
    if msg.command == "targeting_launch" then
        local meta = minetest.get_meta(pos)
        local le = msg.launch_entry

        -- Get digiline data storage
        local digiline_data = minetest.deserialize(meta:get_string("digiline_data"))
        -- Update values
        digiline_data.launch = true
        digiline_data.count = le.count
        digiline_data.delay = le.delay
        -- Update digiline data...
        meta:set_string("digiline_data", minetest.serialize(digiline_data))
        
        digilines.receptor_send(pos, digilines.rules.default, channel, {
            command = msg.command .. "_ack",
        })
    end

end
