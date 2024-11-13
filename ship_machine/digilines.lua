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
            command = msg.command .. "_ack",
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
            command = msg.command .. "_ack",
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

ship_machine.jumpdrive_digiline_effector = function(pos, node, channel, msg)
    local set_channel = "jumpdrive" -- static channel for now

    local msgt = type(msg)

    if msgt ~= "table" then
        return
    end

    if channel ~= set_channel then
        return
    end

    minetest.log(dump(msg))
    if msg.command == 'jump' then
        if (not msg.dest) then
            return
        end
        minetest.log(dump(msg.dest))
        local meta = minetest.get_meta(pos)
        local owner = meta:get_string("owner")
        local size = {
            w = 20,
            h = 18,
            l = 34
        }
        if ship_machine.check_engines_charged(pos) then
            digilines.receptor_send(pos, digilines.rules.default, 'jumpdrive', {
                command = 'jumping'
            })
            ship_machine.engines_charged_spend(pos)
            --ship_machine.transport_jumpship(pos, msg.dest, size, owner)
        end
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

ship_machine.chem_lab_digiline_effector = function(pos, node, channel, msg)
    local set_channel = "chemical_lab" -- static channel for now

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

end