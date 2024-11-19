local S = minetest.get_translator(minetest.get_current_modname())

ship_dock = {}

-- load files
local default_path = minetest.get_modpath("ship_dock")
dofile(default_path .. "/crafts.lua")

local function register_ship_dock(def)

    local function isInteger(str)
        return tonumber(str) ~= nil
    end

    local function get_facing_vector(pos)
        local node = minetest.get_node(pos)
        local param2 = node.param2
        -- get direction and rotation from param2
        local dir = math.floor(param2 / 4)
        local rot = param2 % 4
        local dir_x = 0
        local dir_z = 0
        local dir_y = 0
        if dir == 0 or dir == 5 then
            if rot == 0 then
                dir_z = 1
            elseif rot == 1 then
                dir_x = 1
            elseif rot == 2 then
                dir_z = -1
            elseif rot == 3 then
                dir_x = -1
            end
        elseif dir == 1 or dir == 3 then
            if rot == 0 then
                dir_y = -1
            elseif rot == 1 then
                dir_y = -1
            elseif rot == 2 then
                dir_y = 1
            elseif rot == 3 then
                dir_y = 1
            end
        elseif dir == 2 or dir == 4 then
            if rot == 0 then
                dir_y = 1
            elseif rot == 1 then
                dir_y = 1
            elseif rot == 2 then
                dir_y = 1
            elseif rot == 3 then
                dir_y = 1
            end
        end
        return {
            x = dir_x,
            y = dir_y,
            z = dir_z
        }
    end

    local function update_formspec(pos, data)
        local meta = core.get_meta(pos)
        local is_deepspace = pos.y > 22000;
        local formspec = {}

        local dir = get_facing_vector(pos)
        local size = core.deserialize(meta:get_string("d_size"))
        local offset = core.deserialize(meta:get_string("d_offset"))
        local inp_x = size.w
        local inp_y = size.h
        local inp_z = size.l
        local off_x = offset.x
        local off_y = offset.y
        local off_z = offset.z

        local s_length = false
        local s_width = false
        local s_height = false
        if dir.x > 0 then
            s_length = true
            s_height = true
        elseif dir.x < 0 then
            s_length = true
            s_height = true
        elseif dir.z > 0 then
            s_width = true
            s_height = true
        elseif dir.z < 0 then
            s_width = true
            s_height = true
        elseif dir.y > 1 then
            s_width = true
            s_length = true
        elseif dir.y < 1 then
            s_width = true
            s_length = true
        end

        local public = meta:get_int("d_public") >= 1
        local name = meta:get_string("d_name") or "Unknown"

        formspec = {"formspec_version[8]", "size[8.5,6]", "label[0.2,0.3;Jumpship Docking Port - Controller Setup]",
                    "button[5.0,4.5;3,1;submit;Setup Dock]",
                    "label[0.5,1.3;" .. core.colorize("#917ff5", "Define Dock Max Size:") .. "]",
                    "field[0.5,2;1.4,1;inp_x;X-Width;" .. inp_x .. "]",
                    "field[1.8,2;1.4,1;inp_z;Z-Length;" .. inp_z .. "]",
                    "field[3.1,2;1.4,1;inp_y;Y-Height;" .. inp_y .. "]",
                    "checkbox[5,1.3;public;Public Access;" .. tostring(public) .. "]",
                    "field[5,2;3,1;name;Port Name;" .. name .. "]",
                    "label[0.5,3.8;" .. core.colorize("#917ff5", "Define Dock Side Offset:") .. "]"}

        if s_width then
            table.insert(formspec, "field[0.5,4.5;1.4,1;off_x;Width;" .. off_x .. "]")
        end
        if s_length then
            table.insert(formspec, "field[1.8,4.5;1.4,1;off_z;Length;" .. off_z .. "]")
        end
        if s_height then
            table.insert(formspec, "field[3.1,4.5;1.4,1;off_y;Height;" .. off_y .. "]")
        end

        return table.concat(formspec, '')
    end

    local on_receive_fields = function(pos, formname, fields, sender)
        if fields.quit then
            return
        end
        local node = minetest.get_node(pos)
        local meta = minetest.get_meta(pos)

        local size = core.deserialize(meta:get_string("d_size"))
        local offset = core.deserialize(meta:get_string("d_offset"))
        local width = size.w
        local height = size.h
        local length = size.l
        local off_x = offset.x
        local off_y = offset.y
        local off_z = offset.z
        local isNumError = false

        if fields.inp_x then
            if isInteger(fields.inp_x) then
                width = tonumber(fields.inp_x, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_y then
            if isInteger(fields.inp_y) then
                height = tonumber(fields.inp_y, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_z then
            if isInteger(fields.inp_z) then
                length = tonumber(fields.inp_z, 10)
            else
                isNumError = true
            end
        end
        if fields.off_x then
            if isInteger(fields.off_x) then
                off_x = tonumber(fields.off_x, 10)
            else
                isNumError = true
            end
        end
        if fields.off_y then
            if isInteger(fields.off_y) then
                off_y = tonumber(fields.off_y, 10)
            else
                isNumError = true
            end
        end
        if fields.off_z then
            if isInteger(fields.off_z) then
                off_z = tonumber(fields.off_z, 10)
            else
                isNumError = true
            end
        end

        local function send_msg(player, msg)
            if player and player:is_player() and msg and msg ~= "" then
                core.chat_send_player(player:get_player_name(), msg)
            end
        end

        if fields.public ~= nil then
            if fields.public == 'true' then
                meta:set_int("d_public", 1)
            else
                meta:set_int("d_public", 0)
            end
        end
        if fields.submit and not isNumError then
            if (width + 1) * (length + 1) * (height + 1) > 4096000 then
                send_msg(sender, "Volume size of bay is too large!")
                return
            end
            if off_x > width then
                send_msg(sender, "offset must be within max size of width!")
                off_x = width
            elseif off_x < -width then
                send_msg(sender, "offset must be within min size of width!")
                off_x = -width
            end
            if off_z > length then
                send_msg(sender, "offset must be within max size of length!")
                off_z = length
            elseif off_z < -length then
                send_msg(sender, "offset must be within min size of length!")
                off_z = -length
            end
            if off_y > height then
                send_msg(sender, "offset must be within max size of height!")
                off_y = height
            elseif off_y < -height then
                send_msg(sender, "offset must be within min size of height!")
                off_y = -height
            end
            local size = {
                w = width,
                l = length,
                h = height
            }
            local offset = {
                x = off_x,
                y = off_y,
                z = off_z
            }
            meta:set_string("d_size", core.serialize(size))
            meta:set_string("d_offset", core.serialize(offset))
            if fields.name then
                meta:set_string("d_name", fields.name)
            end
            local dir = get_facing_vector(pos)
            local center = {
                x = 0,
                y = 0,
                z = 0
            }
            if dir.x > 0 then
                center = vector.add(pos, vector.new(size.w + 1, 0, 0))
            elseif dir.x < 0 then
                center = vector.subtract(pos, vector.new(size.w + 1, 0, 0))
            elseif dir.z > 0 then
                center = vector.add(pos, vector.new(0, 0, size.l + 1))
            elseif dir.z < 0 then
                center = vector.subtract(pos, vector.new(0, 0, size.l + 1))
            elseif dir.y > 0 then
                center = vector.add(pos, vector.new(0, size.h + 1, 0))
            elseif dir.y < 0 then
                center = vector.subtract(pos, vector.new(0, size.h + 1, 0))
            else
                meta:set_string("formspec", update_formspec(pos, def))
                return
            end
            center = vector.add(center, offset)
            meta:set_int("setup", 1)
            meta:set_string("d_center", core.serialize(center))
            meta:set_string("formspec", update_formspec(pos, def))
            send_msg(sender, "Docking area defined and ready!")
            return
        end

    end

    minetest.register_node("ship_dock:docking_port_ref", {
        description = S("Jumpship Docking Port"),
        -- up, down, right, left, back, front
        tiles = {"ctg_docking_port_top.png", "ctg_docking_port.png", "ctg_docking_port.png", "ctg_docking_port.png",
                 "ctg_docking_port.png", "ctg_docking_port.png"},
        paramtype2 = "facedir",
        groups = {
            cracky = 1,
            metal = 1,
            level = 2,
            ship_dock = 1
        },
        sounds = default.node_sound_metal_defaults(),
        -- paramtype = "light",

        on_receive_fields = on_receive_fields,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            meta:set_string("owner", placer:get_player_name())
            meta:set_string("infotext", "Jumpship Docking Port")
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            -- inv:set_size("ship1", 1)
            meta:set_int("enabled", 1)
            meta:set_int("setup", 0)
            meta:set_string("owner", "")
            local size = {
                w = 12,
                l = 15,
                h = 12
            }
            local offset = {
                x = 0,
                y = -2,
                z = 0
            }
            local center = {
                x = 0,
                y = 0,
                z = 0
            }
            meta:set_string("d_size", core.serialize(size))
            meta:set_string("d_offset", core.serialize(offset))
            meta:set_string("d_center", core.serialize(center))
            meta:set_string("d_name", 'Unknown')
            meta:set_int("d_public", 1)
            meta:set_string("formspec", update_formspec(pos, def))
        end,
        on_dock = function()

        end
    })

    function ship_dock.get_dock_pos(pos, ship_size, s_owner, s_name, s_pub)

        local s_owner = s_owner or ""
        local s_name = s_name or ""
        local s_pub = s_pub or false

        local size = {
            w = 72,
            l = 72,
            h = 64
        }
        local pos1 = vector.subtract(pos, {
            x = size.w,
            y = size.h,
            z = size.l
        })
        local pos2 = vector.add(pos, {
            x = size.w,
            y = size.h,
            z = size.l
        })

        local dock = nil
        local nodes = minetest.find_nodes_in_area(pos1, pos2, "group:ship_dock")

        if #nodes > 0 then
            for _, node in ipairs(nodes) do
                local meta = minetest.get_meta(node)
                local size = core.deserialize(meta:get_string("d_size"))
                -- local offset = core.deserialize(meta:get_string("d_offset"))
                local center = core.deserialize(meta:get_string("d_center"))
                local owner = meta:get_string("owner") or ""
                local name = meta:get_string("d_name") or ""
                local public = (meta:get_int("d_public") or 0) > 0
                -- match dock size to ship size
                if size.w - ship_size.w >= 0 and size.l - ship_size.l >= 0 and size.h - ship_size.h >= 0 then
                    if not s_pub then
                        -- only private dock
                        if s_owner and owner == s_owner then
                            -- owner match
                            if s_name == "" then
                                -- search name empty
                                dock = center
                            elseif name == s_name then
                                -- search name match
                                dock = center
                            end
                        end
                        if public then
                            -- allow public dock
                            if s_name == ""  then
                                -- search name empty
                                dock = center
                            elseif name == s_name then
                                -- search name match
                                dock = center
                            end
                        end
                    elseif public then
                        -- allow public dock
                        if s_name == "" then
                            -- search name empty
                            dock = center
                        elseif name == s_name then
                            -- search name match
                            dock = center
                        end
                    end

                end
                if dock then
                    break
                end
            end
        end
        return dock
    end

    function ship_dock.get_docks(pos, ship_size, s_owner, s_name, s_pub)

        local s_owner = s_owner or ""
        local s_name = s_name or ""
        local s_pub = s_pub or false

        local size = {
            w = 72,
            l = 72,
            h = 64
        }
        local pos1 = vector.subtract(pos, {
            x = size.w,
            y = size.h,
            z = size.l
        })
        local pos2 = vector.add(pos, {
            x = size.w,
            y = size.h,
            z = size.l
        })

        local docks = {}
        local nodes = minetest.find_nodes_in_area(pos1, pos2, "group:ship_dock")

        if #nodes > 0 then
            for _, node in ipairs(nodes) do
                local meta = minetest.get_meta(node)
                local size = core.deserialize(meta:get_string("d_size"))
                -- local offset = core.deserialize(meta:get_string("d_offset"))
                local center = core.deserialize(meta:get_string("d_center"))
                local owner = meta:get_string("owner") or ""
                local name = meta:get_string("d_name") or ""
                local public = (meta:get_int("d_public") or 0) > 0
                local setup = (meta:get_int("setup") or 0) > 0
                local dock = nil
                -- match dock size to ship size
                if setup and size.w - ship_size.w >= 0 and size.l - ship_size.l >= 0 and size.h - ship_size.h >= 0 then
                    if not s_pub then
                        -- only private dock
                        if s_owner and owner == s_owner then
                            -- owner match
                            if s_name == "" then
                                -- search name empty
                                dock = center
                            elseif name == s_name then
                                -- search name match
                                dock = center
                            end
                        end
                        if public then
                            -- allow public dock
                            if s_name == ""  then
                                -- search name empty
                                dock = center
                            elseif name == s_name then
                                -- search name match
                                dock = center
                            end
                        end
                    elseif public then
                        -- allow public dock
                        if s_name == "" then
                            -- search name empty
                            dock = center
                        elseif name == s_name then
                            -- search name match
                            dock = center
                        end
                    end

                end
                if dock then
                    table.insert(docks, {name = name, pos = dock})
                end
            end
        end
        return docks
    end

end

register_ship_dock({
    name = "Jumpship Dock"
});
