local S = core.get_translator(core.get_current_modname())

ship_machine = {}

ship_machine.locations = {}
ship_machine.jumpships = {}
ship_machine.jumpships.cache = {}

-- load files
local default_path = core.get_modpath("ship_machine")

dofile(default_path .. DIR_DELIM .. "locations.lua")
dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "gravity_drive.lua")
dofile(default_path .. DIR_DELIM .. "gravity.lua")
dofile(default_path .. DIR_DELIM .. "ship_control.lua")
dofile(default_path .. DIR_DELIM .. "ship_protect.lua")
dofile(default_path .. DIR_DELIM .. "jump_drive.lua")
dofile(default_path .. DIR_DELIM .. "nodes.lua")
dofile(default_path .. DIR_DELIM .. "crafts.lua")
dofile(default_path .. DIR_DELIM .. "coolants.lua")
dofile(default_path .. DIR_DELIM .. "chemical_lab.lua")
dofile(default_path .. DIR_DELIM .. "supply_relay.lua")

core.register_privilege("jumpship_admin", {
	description = "Allow player to admin jumpdrives",
	give_to_singleplayer = false,
	give_to_admin = true,
})

core.register_on_joinplayer(function(player, last_login)
    local name = player:get_player_name()
    local pos = player:get_pos()

    local last_pos = ship_machine.locations[name];
    if last_pos then
        local drive = ship_machine.get_jumpdrive(last_pos, {l = 72, h = 70, w = 70})
        if drive and player:get_pos() ~= last_pos then
            player:set_pos(last_pos)
            core.chat_send_player(name, "Offline location updated...")
        end
        --core.log("player location loaded")
    end
end)

core.register_on_leaveplayer(function(player, timed_out)
    local name = player:get_player_name()
    local pos = player:get_pos()

    local drive = ship_machine.get_jumpdrive(pos, {l = 72, h = 70, w = 70})

    if drive ~= nil then

        -- update player last location
        ship_machine.locations[name] = pos
        ship_machine.save_locations();

        -- update node meta
        local dmeta = core.get_meta(drive)
        local stor_str = dmeta:get_string("player_storage")
        local contents = {}
        if stor_str ~= nil and #stor_str > 0 then
            contents = core.deserialize(stor_str)
        end
        if not contents[name] then
            contents[name] = true
        end

        dmeta:set_string("player_storage", core.serialize(contents))
        --core.log("player location saved")
    else
        ship_machine.locations[name] = nil
        ship_machine.save_locations();
        --core.log("drive is nil!")
    end

end)
