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
        local busy = meta:get_int("busy") or 0 == 1
        local w = core.get_item_group(node.name, 'ship_size_w')
        local h = core.get_item_group(node.name, 'ship_size_h')
        local l = core.get_item_group(node.name, 'ship_size_l')
        local size = {
            w = w,
            h = h,
            l = l
        }
        if busy then
            local msg = {
                success = false,
                message = "FTL Drive is busy!"
            }
            digilines.receptor_send(pos, digilines.rules.default, 'jumpdrive', msg)
        elseif not enabled then
            local msg = {
                success = false,
                message = "FTL Drive not enabled."
            }
            digilines.receptor_send(pos, digilines.rules.default, 'jumpdrive', msg)
        else
            local function jump_callback(j)
                local success = false
                local message = ""
                if j == 1 then
                    success = true
                    message = "Performed Jump!"
                elseif j == 0 then
                    message = "FTL Engines require more charge..."
                elseif j == -1 then
                    message = "Travel obstructed at destination."
                elseif j == -3 then
                    message = "FTL Jump Drive Error..."
                else
                    message = "FTL Engines Failed to Start?"
                end
                local msg = {
                    success,
                    message
                }
                if success then
                    local o_pos = vector.add(pos, msg.offset)
                    local meta = core.get_meta(o_pos)
                    meta:set_int("busy", 0)
                    digilines.receptor_send(o_pos, digilines.rules.default, 'jumpdrive', msg)
                else
                    local meta = core.get_meta(pos)
                    meta:set_int("busy", 0)
                    digilines.receptor_send(pos, digilines.rules.default, 'jumpdrive', msg)
                end
            end
            -- get ship
            local ship, ships_other = ship_machine.get_local_ships(pos, size)
            if ship then
                meta:set_int("busy", 1)
                -- async jump with callback
                ship_machine.engine_do_jump_fleet(ship, ships_other, jump_callback, msg.offset)
            end
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
    local meta = minetest.get_meta(pos)
    local set_channel = "chemical_lab" -- static channel for now

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

    if msg.command == "set_recipe" then
        local recipe = tonumber(msg.recipe)
        if recipe then
            meta:set_int(recipe)
        end
    end

    if msg.command == "recipe" then
        local inv = meta:get_inventory()
        local src1 = inv:get_list("src1")
        local src2 = inv:get_list("src2")
        local src3 = inv:get_list("src3")
        local src4 = inv:get_list("src4")
        local recipe_index = meta:get_int("recipe")
        local recipe_name = ""
        if recipe_index == 1 then
            recipe_name = "Coolant"
        elseif recipe_index == 2 then
            recipe_name = "Seed Oil"
        end
        digilines.receptor_send(pos, digilines.rules.default, set_channel, {
            command = msg.command .. "_ack",            
            pos = minetest.serialize(pos),
            recipe = recipe_index,
            recipe_name = recipe_name,
            inv1 = src1[1]:get_count(),
            inv2 = src2[1]:get_count(),
            inv3 = src3[1]:get_count(),
            inv4 = src4[1]:get_count(),
            has_water = meta:get_int("output_count") > 0,
        })
    end

    if msg.command == "fluid_status" then
        digilines.receptor_send(pos, digilines.rules.default, set_channel, {
            command = msg.command .. "_ack",            
            pos = minetest.serialize(pos),
            has_water = meta:get_int("output_count") > 0,
            water_count = meta:get_int("output_count"),
            water_max = meta:get_int("output_max"),
        })
    end

end
