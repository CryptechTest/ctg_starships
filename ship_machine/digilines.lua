ship_machine.gravity_drive_digiline_effector = function(pos, node, channel, msg)
    local set_channel = "ship_gravity_drive" -- static channel for now

    local msgt = type(msg)

    if msgt ~= "table" then
        return
    end

    if channel ~= set_channel then
        return
    end

    if msg.command == "status" then
        local meta = minetest.get_meta(pos)
        digilines.receptor_send(pos, digilines.rules.default, channel, {
            command = msg.command,
            charge = meta:get_int("charge"),
            demand = meta:get_int("demand"),
            enable = meta:get_int("enabled"),
            charge_max = meta:get_int("charge_max")
        })
    end

    if msg.command == "ready" then
        local meta = minetest.get_meta(pos)
        local max = meta:get_int("charge_max")
        local chg = meta:get_int("charge")
        local ready = "NOT RDY"
        if chg >= max then
            ready = "READY!"
        end
        digilines.receptor_send(pos, digilines.rules.default, channel, {
            command = msg.command,
            ready = ready
        })
    end

    if msg.command == "enable" then
        local meta = minetest.get_meta(pos)
        meta:set_int("enabled", 1)
    end

    if msg.command == "disable" then
        local meta = minetest.get_meta(pos)
        meta:set_int("enabled", 0)
    end

end

ship_machine.gravity_drive_lite_digiline_effector = function(pos, node, channel, msg)
    local set_channel = "ship_gravity_drive_lite" -- static channel for now

    local msgt = type(msg)

    if msgt ~= "table" then
        return
    end

    if channel ~= set_channel then
        return
    end

    if msg.command == "status" then
        local meta = minetest.get_meta(pos)
        digilines.receptor_send(pos, digilines.rules.default, channel, {
            command = msg.command,
            charge = meta:get_int("charge"),
            demand = meta:get_int("demand"),
            enable = meta:get_int("enabled"),
            charge_max = meta:get_int("charge_max")
        })
    end

    if msg.command == "ready" then
        local meta = minetest.get_meta(pos)
        local max = meta:get_int("charge_max")
        local chg = meta:get_int("charge")
        local ready = "NOT RDY"
        if chg >= max then
            ready = "READY!"
        end
        digilines.receptor_send(pos, digilines.rules.default, channel, {
            command = msg.command,
            ready = ready
        })
    end

    if msg.command == "enable" then
        local meta = minetest.get_meta(pos)
        meta:set_int("enabled", 1)
    end

    if msg.command == "disable" then
        local meta = minetest.get_meta(pos)
        meta:set_int("enabled", 0)
    end

end
