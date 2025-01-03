local S = minetest.get_translator(minetest.get_current_modname())

local function isInteger(str)
    return tonumber(str) ~= nil
end

function shipyard.register_shipyard(custom_data)

    local data = custom_data or {}

    data.typename = "shipyard"
    data.modname = "shipyard"
    data.tier = "LV"
    data.machine_name = "shipyard"
    data.machine_desc = "Shipyard"
    data.jump_dist = 15000

    local modname = "shipyard"
    local ltier = string.lower(data.tier)
    local machine_name = data.machine_name
    local machine_desc = data.machine_desc or "Shipyard"
    local lmachine_name = string.lower(machine_name)

    local active_groups = {
        cracky = 2,
        -- technic_machine = 1,
        -- ["technic_" .. ltier] = 1,
        -- ctg_machine = 1,
        metal = 1,
        level = 1,
        starship = 1,
        jumpship = 1,
        shipyard = 1,
        ship_jumps = 1,
        not_in_creative_inventory = 1
    }

    local on_receive_fields = function(pos, formname, fields, sender)
        if fields.quit then
            return
        end
        local node = minetest.get_node(pos)
        local meta = minetest.get_meta(pos)

        if fields.submit_migr then
            local shipp = shipyard.get_protector(pos, data.size)
            if shipp then
                meta:set_int("combat_ready", 2)
                local ship_meta = minetest.get_meta(shipp)
                ship_meta:set_int("combat_ready", 2)
                ship_meta:set_int("hp_max", data.hp)
                ship_meta:set_int("hp", data.hp)
                ship_meta:set_int("shield_max", data.shield)
                ship_meta:set_int("shield", data.shield)
            end
            local ready = meta:get_int("travel_ready")
            local message = "Combat Ready!"
            local formspec = shipyard.update_formspec(pos, data, 0, ready, message)
            meta:set_string("formspec", formspec)
            return
        end

        if fields.refresh then
            local ready = meta:get_int("travel_ready")
            local formspec = shipyard.update_formspec(pos, data, 0, ready, '')
            meta:set_string("formspec", formspec)
            return
        end

        local enabled = false
        if fields.toggle then
            if meta:get_int("enabled") == 1 then
                meta:set_int("enabled", 0)
            else
                meta:set_int("enabled", 1)
                enabled = true
            end
        end

        if fields.protector then
            local prot_loc = shipyard.get_protector(pos, data.size)
            if prot_loc then
                minetest.registered_nodes[minetest.get_node(prot_loc).name].on_rightclick(prot_loc, node, sender, nil)
            end
            return
        end

        if fields.holo then
            local drive_loc = ship_machine.get_jumpdrive(pos, data.size)
            local holo_pos = vector.add(pos, vector.new(0,1,0))
            local ofs = vector.subtract(holo_pos, drive_loc)
            local node = core.get_node(holo_pos)
            if node.name ~= "ship_holodisplay:display" then
                core.set_node(holo_pos, {name = "ship_holodisplay:display"})
                local meta = core.get_meta(holo_pos)
                meta:set_int("X", -(128 + ofs.x))
                meta:set_int("Y", -(129 + ofs.y))
                meta:set_int("Z", -(128 + ofs.z))
                core.get_node_timer(holo_pos):start(1)
            else
                core.set_node(holo_pos, {name = "ship_holodisplay:display_off"})
            end
            return
        end

        local jump_dis = meta:get_int("jump_dist")
        local is_deepspace = pos.y > 22000;

        -- local pos_nav = meta:get_string("pos_nav")
        -- local nav = minetest.get_meta(pos_nav)
        -- local nav_ready = nav:get_string("jump_ready")
        local nav_ready = 1

        local changed = false
        local loc = tostring(meta:get_int("dest_dir"))
        if fields.btn_hole_1 then
            loc = "1"
            changed = true
        elseif fields.btn_hole_2 then
            loc = "2"
            changed = true
        elseif fields.btn_hole_3 then
            loc = "3"
            changed = true
        elseif fields.btn_hole_4 then
            loc = "4"
            changed = true
        end
        meta:set_int("dest_dir", tonumber(loc, 10))

        local locked = meta:get_int("travel_ready") == 1
        if locked then
            local formspec = shipyard.update_formspec(pos, data, loc, false, "Interface lockout! Allocator is busy...")
            meta:set_string("formspec", formspec)
            return
        end

        local move_x = 0
        local move_y = 0
        local move_z = 0
        local isNumError = false
        if fields.inp_x then
            if isInteger(fields.inp_x) then
                move_x = tonumber(fields.inp_x, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_y then
            if isInteger(fields.inp_y) then
                move_y = tonumber(fields.inp_y, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_z then
            if isInteger(fields.inp_z) then
                move_z = tonumber(fields.inp_z, 10)
            else
                isNumError = true
            end
        end

        local message = ""
        local offset = {
            x = move_x,
            y = move_y,
            z = move_z
        }
        local ncount, dest = ship_machine.get_jump_dest(pos, offset, data.size)
        local panel_dest = vector.add(pos, offset)

        if ncount == 0 and dest == nil then
            meta:set_int("travel_ready", 0)
            message = "FTL Engines not found..."
        elseif ncount > 1 then
            meta:set_int("travel_ready", 0)
            message = "FTL Engine Mismatch! Actuality Conflict..."
        elseif isNumError then
            meta:set_int("travel_ready", 0)
            message = "Must input a valid number..."
        elseif fields.submit_nav and not is_deepspace and vector.distance(pos, dest) < 99 then
            meta:set_int("travel_ready", 0)
            message = "Jump distance below engine range..."
        elseif fields.submit_nav and not is_deepspace and vector.distance(pos, dest) > jump_dis + 1 then
            meta:set_int("travel_ready", 0)
            message = "Jump distance beyond engine range..."
        elseif fields.submit_nav and not is_deepspace and dest.y > 22000 then
            meta:set_int("travel_ready", 0)
            message = "Jump destination beyond engine abilities..."
        elseif fields.submit_nav and not is_deepspace and dest.y < 4000 then
            meta:set_int("travel_ready", 0)
            message = "Jump destination beyond engine abilities..."
        elseif fields.submit_nav and ((is_deepspace and loc ~= "0") or (not is_deepspace)) then
            message = "Routing Jump Actuality..."
            local formspec = shipyard.update_formspec(pos, data, loc, 0, message)
            meta:set_string("formspec", formspec)

            local function jump_callback(j)
                if formspec == nil then
                    return
                end
                if j == 1 then
                    meta:set_int("travel_ready", 1)
                    meta:set_string("formspec", nil)
                    minetest.after(0.5, function()
                        local metad = minetest.get_meta(panel_dest)
                        metad:set_int("travel_ready", 1)
                        local formspec_new = shipyard.update_formspec(panel_dest, data, loc, 0, "Folding Jump Space...")
                        metad:set_string("formspec", formspec_new)
                    end)
                    minetest.after(3.5, function()
                        local metad = minetest.get_meta(panel_dest)
                        local formspec_new = shipyard.update_formspec(panel_dest, data, loc, 0, "Jump Complete!")
                        metad:set_string("formspec", formspec_new)
                        metad:set_int("travel_ready", 0)
                        minetest.after(7, function()
                            if metad then
                                local formspec_rdy = shipyard.update_formspec(panel_dest, data, loc, 0, "Ready...")
                                metad:set_string("formspec", formspec_rdy)
                            end
                        end)
                    end)
                    return
                elseif j == 0 then
                    meta:set_int("travel_ready", 0)
                    message = "FTL Engines require more charge..."
                elseif j == -1 then
                    meta:set_int("travel_ready", 0)
                    message = "Travel obstructed at " .. "(" .. dest.x .. "," .. dest.y .. "," .. dest.z .. ")"
                elseif j == -3 then
                    meta:set_int("travel_ready", 0)
                    message = "FTL Jump Drive not found..."
                else
                    meta:set_int("travel_ready", 0)
                    message = "FTL Engines Failed to Start?"
                end

                local ready = meta:get_int("travel_ready")
                local formspec = shipyard.update_formspec(pos, data, loc, ready, message)
                meta:set_string("formspec", formspec)
            end

            -- async jump with callback
            ship_machine.engine_do_jump(pos, data.size, jump_callback, offset)

            return
        elseif fields.submit_nav and not changed then
            message = "FTL Engines require more charge..."
            meta:set_int("travel_ready", 0)
        elseif fields.submit_nav and nav_ready ~= 1 and not changed then
            message = "Survey Navigator requires more charge..."
            meta:set_int("travel_ready", 0)
        end

        local ready = meta:get_int("travel_ready")
        local formspec = shipyard.update_formspec(pos, data, loc, ready, message)
        meta:set_string("formspec", formspec)
    end

    minetest.register_node(modname .. ":" .. ltier .. "_" .. lmachine_name .. "", {
        description = machine_desc,
        tiles = {ltier .. "_" .. lmachine_name .. "_top.png", ltier .. "_" .. lmachine_name .. "_bottom.png",
                 ltier .. "_" .. lmachine_name .. "_side.png", ltier .. "_" .. lmachine_name .. "_side.png",
                 ltier .. "_" .. lmachine_name .. "_side.png", ltier .. "_" .. lmachine_name .. "_front.png"},
        param = "light",
        paramtype2 = "facedir",
        light_source = 3,
        drop = modname .. ":" .. ltier .. "_" .. lmachine_name,
        groups = active_groups,
        legacy_facedir_simple = true,
        drawtype = "mesh",
        mesh = "moreblocks_slope_half_raised.obj",
        selection_box = {
            type = "fixed",
            fixed = {{-0.5000, -0.5000, -0.5000, 0.5000, 0.5000, 0.5000}}
        },
        collision_box = {
            type = "fixed",
            fixed = {{-0.5, -0.5, -0.5, 0.5, 0.125, 0.5}, {-0.5, 0.125, -0.25, 0.5, 0.25, 0.5},
                     {-0.5, 0.25, 0, 0.5, 0.375, 0.5}, {-0.5, 0.375, 0.25, 0.5, 0.5, 0.5}}
        },
        sounds = default.node_sound_glass_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Starship Control " .. "-" .. " " .. machine_desc)
            local holo_pos = vector.add(pos, vector.new(0,1,0))
            core.set_node(holo_pos, {name = "ship_holodisplay:display_off"})
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            local holo_pos = vector.add(pos, vector.new(0,1,0))
            local node = core.get_node(holo_pos)
            if node.name == "ship_holodisplay:display" or node.name == "ship_holodisplay:display_off" then
                core.set_node(holo_pos, {name = "air"})
            end
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            meta:set_int("enabled", 1)
            meta:set_int("dest_dir", 0)
            meta:set_int("jump_dist", data.jump_dist)
            meta:set_int("travel_ready", 0)
            meta:set_string("formspec", shipyard.update_formspec(pos, data, "0", false, ''))
            local pos_drive = ship_machine.get_jumpdrive(pos, data.size)
            if pos_drive then
                local drive_offset = vector.subtract(pos, pos_drive)
                meta:set_string("drive_offset", minetest.serialize(drive_offset))
            end
        end,

        on_punch = function(pos, node, puncher)
            local drive_loc = ship_machine.get_protector(pos, data.size)
            if drive_loc then
                minetest.registered_nodes[minetest.get_node(drive_loc).name].on_punch(drive_loc, node, puncher)
            end
        end,

        on_receive_fields = on_receive_fields,
        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                action = shipyard.digiline_effector
            }
        }
    })

end
