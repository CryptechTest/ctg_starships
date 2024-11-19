ship_cargo.digiline_effector = function(pos, node, channel, msg)
    local set_channel = "ship_cargo" -- static channel for now

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

    --[[if msg.command == "dest" then
        local meta = minetest.get_meta(pos)
        local dest_dir = meta:get_int("dest_dir")
        digilines.receptor_send(pos, digilines.rules.default, channel, {
            command = msg.command,
            dest_dir = dest_dir
        })
    end--]]

    if msg.command == "status" then
        local meta = minetest.get_meta(pos)
        digilines.receptor_send(pos, digilines.rules.default, channel, {
            command = msg.command .. "_ack",
            ready = meta:get_int("ready")
        })
    end

    --[[if msg.command == "pos_nav" then
        local meta = minetest.get_meta(pos)
        meta:set_string("pos_nav", dump(msg.pos_nav))
    end
    if msg.command == "pos_eng1" then
        local meta = minetest.get_meta(pos)
        meta:set_string("pos_eng1", dump(msg.pos_eng1))
    end
    if msg.command == "pos_eng2" then
        local meta = minetest.get_meta(pos)
        meta:set_string("pos_eng2", dump(msg.pos_eng2))
    end--]]

end
