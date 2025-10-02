ship_shuttle.digiline_effector = function(pos, node, channel, msg)
    local set_channel = "ship_shuttle" -- static channel for now

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
        digilines.receptor_send(pos, digilines.rules.default, channel, {
            command = msg.command .. "_ack",
            ready = meta:get_int("ready")
        })
    end

end
