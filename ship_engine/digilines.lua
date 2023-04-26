ship_engine.engine_digiline_effector_l = function(pos, node, channel, msg)
    local set_channel = "ship_engine_l" -- static channel for now

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
        local ready = "NOT RDY E2"
        if chg >= max then
            ready = "ENG 2 RDY"
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

ship_engine.engine_digiline_effector_r = function(pos, node, channel, msg)
    local set_channel = "ship_engine_r" -- static channel for now

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
        local ready = "NOT RDY E1"
        if chg >= max then
            ready = "ENG 1 RDY"
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

ship_engine.engine_digiline_effector = function(pos, node, channel, msg)
    local set_channel = "ship_engine_core" -- static channel for now

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

    if msg.command == "status_c" then
        local meta = minetest.get_meta(pos)
        if msg.ready and msg.channel == "ship_engine_r" then
            meta:set_int("engine_ready_1", 1)
        elseif msg.channel == "ship_engine_r" then
            meta:set_int("engine_ready_1", 0)
        end
        if msg.ready and msg.channel == "ship_engine_l" then
            meta:set_int("engine_ready_2", 1)
        elseif msg.channel == "ship_engine_l" then
            meta:set_int("engine_ready_2", 0)
        end
        if msg.enable and msg.channel == "ship_engine_r" then
            meta:set_int("engine_en_1", 1)
        elseif msg.channel == "ship_engine_r" then
            meta:set_int("engine_en_1", 0)
        end
        if msg.enable and msg.channel == "ship_engine_l" then
            meta:set_int("engine_en_2", 1)
        elseif msg.channel == "ship_engine_l" then
            meta:set_int("engine_en_2", 0)
        end
    end

    if msg.command == "ready" then
        local meta = minetest.get_meta(pos)
        local max = meta:get_int("charge_max")
        local chg = meta:get_int("charge")
        if chg >= max then
            meta:set_int("jump_ready", 1)
        end
    end

    if msg.command == "is_ready" then
        local meta = minetest.get_meta(pos)
        local ready = meta:get_int("jump_ready")
        digilines.receptor_send(pos, digilines.rules.default, channel, {
            command = msg.command,
            is_ready = ready
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
