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

    -- minetest.log(dump(msg))
    if msg.command == 'jump' then
        if (not msg.offset) then
            return
        end
        --minetest.log(dump(msg.offset))
        local node = core.get_node(pos)
        local meta = core.get_meta(pos)
        local owner = meta:get_string("owner")
        local enabled = meta:get_int("enable") == 1
        local w = core.get_item_group(node.name, 'ship_size_w')
        local h = core.get_item_group(node.name, 'ship_size_h')
        local l = core.get_item_group(node.name, 'ship_size_l')
        local size = {
            w = w,
            h = h,
            l = l
        }
        if enabled then
            local function jump_callback(j)
                local success = false
                local message = ""
                if j == 1 then
                    success = true
                    message = "Performing Jump!"
                elseif j == 0 then
                    message = "FTL Engines require more charge..."
                elseif j == -1 then
                    message = "Travel obstructed at destination."
                elseif j == -3 then
                    message = "FTL Jump Drive not found..."
                else
                    message = "FTL Engines Failed to Start?"
                end
                local msg = {
                    success,
                    message
                }
                digilines.receptor_send(pos, digilines.rules.default, 'jumpdrive', msg)
            end
            -- async jump with callback
            ship_machine.engine_do_jump(pos, size, jump_callback, msg.offset)
        else
            local msg = {
                success = false,
                message = "FTL Drive not enabled."
            }
            digilines.receptor_send(pos, digilines.rules.default, 'jumpdrive', msg)
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

    if msg.command == "pos" then
        digilines.receptor_send(pos, digilines.rules.default, 'jumpdrive', {
            pos = minetest.serialize(pos)
        })
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
