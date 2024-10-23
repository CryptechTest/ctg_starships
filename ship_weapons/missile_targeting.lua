local S = minetest.get_translator(minetest.get_current_modname())

local function isNumber(str)
    return tonumber(str) ~= nil
end

function ship_weapons.register_targeting_computer(custom_data)

    local data = custom_data or {}

    data.tier = (custom_data and custom_data.tier) or "LV"
    data.typename = (custom_data and custom_data.typename) or "target_computer"
    data.modname = (custom_data and custom_data.modname) or "ship_weapons"
    data.machine_name = (custom_data and custom_data.machine_name) or "target_computer"
    data.machine_desc = (custom_data and custom_data.machine_desc) or "Targeting Computer"

    local modname = data.modname
    local machine_name = data.machine_name
    local machine_desc = data.machine_desc
    local lmachine_name = string.lower(machine_name)

    local active_groups = {
        cracky = 2,
        -- technic_machine = 1,
        -- ["technic_" .. ltier] = 1,
        -- ctg_machine = 1,
        metal = 1,
        level = 1,
        ship_machine = 1
        -- ship_weapon = 1,
        -- not_in_creative_inventory = 1
    }

    local on_receive_fields = function(pos, formname, fields, sender)
        if fields.quit then
            return
        end
        local node = minetest.get_node(pos)
        local meta = minetest.get_meta(pos)

        local enabled = false
        if fields.toggle then
            if meta:get_int("enabled") == 1 then
                meta:set_int("enabled", 0)
            else
                meta:set_int("enabled", 1)
                enabled = true
            end
        end

        local locked = meta:get_int("target_locked")
        local power = meta:get_float("target_power") -- distance to travel
        local pitch = meta:get_float("target_pitch") -- location up/down
        local yaw = meta:get_float("target_yaw") -- direction/rotation
        local sel = meta:get_int("selected_dir")
        if fields.btn1 then
            sel = 1
            pitch = 90
            yaw = -90
            locked = 0
        elseif fields.btn2 then
            sel = 2
            pitch = 45
            yaw = -90
            locked = 0
        elseif fields.btn3 then
            sel = 3
            pitch = 0
            yaw = -90
            locked = 0
        elseif fields.btn4 then
            sel = 4
            pitch = -45
            yaw = -90
            locked = 0
        elseif fields.btn5 then
            sel = 5
            pitch = -90
            yaw = -90
            locked = 0
        elseif fields.btn6 then
            sel = 6
            pitch = 90
            yaw = -45
            locked = 0
        elseif fields.btn7 then
            sel = 7
            pitch = 45
            yaw = -45
            locked = 0
        elseif fields.btn8 then
            sel = 8
            pitch = 0
            yaw = -45
            locked = 0
        elseif fields.btn9 then
            sel = 9
            pitch = -45
            yaw = -45
            locked = 0
        elseif fields.btn10 then
            sel = 10
            pitch = -90
            yaw = -45
            locked = 0
        elseif fields.btn11 then
            sel = 11
            pitch = 90
            yaw = 0
            locked = 0
        elseif fields.btn12 then
            sel = 12
            pitch = 45
            yaw = 0
            locked = 0
        elseif fields.btn13 then
            sel = 13
            pitch = 0
            yaw = 0
            locked = 0
        elseif fields.btn14 then
            sel = 14
            pitch = -45
            yaw = 0
            locked = 0
        elseif fields.btn15 then
            sel = 15
            pitch = -90
            yaw = 0
            locked = 0
        elseif fields.btn16 then
            sel = 16
            pitch = 90
            yaw = 45
            locked = 0
        elseif fields.btn17 then
            sel = 17
            pitch = 45
            yaw = 45
            locked = 0
        elseif fields.btn18 then
            sel = 18
            pitch = 0
            yaw = 45
            locked = 0
        elseif fields.btn19 then
            sel = 19
            pitch = -45
            yaw = 45
            locked = 0
        elseif fields.btn20 then
            sel = 20
            pitch = -90
            yaw = 45
            locked = 0
        elseif fields.btn21 then
            sel = 21
            pitch = 90
            yaw = 90
            locked = 0
        elseif fields.btn22 then
            sel = 22
            pitch = 45
            yaw = 90
            locked = 0
        elseif fields.btn23 then
            sel = 23
            pitch = 0
            yaw = 90
            locked = 0
        elseif fields.btn24 then
            sel = 24
            pitch = -45
            yaw = 90
            locked = 0
        elseif fields.btn25 then
            sel = 25
            pitch = -90
            yaw = 90
            locked = 0
        end
        meta:set_int("target_locked", locked)
        meta:set_int("selected_dir", sel)
        meta:set_float("target_pitch", pitch)
        meta:set_float("target_yaw", yaw)

        local isNumError = false
        if fields.inp_power then
            if isNumber(fields.inp_power) then
                power = tonumber(fields.inp_power, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_pitch then
            if isNumber(fields.inp_pitch) then
                pitch = tonumber(fields.inp_pitch, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_yaw then
            if isNumber(fields.inp_yaw) then
                yaw = tonumber(fields.inp_yaw, 10)
            else
                isNumError = true
            end
        end

        if power < 10 then
            power = 10
        end
        if pitch > 100 then
            pitch = 100
        elseif pitch < -100 then
            pitch = -100
        end
        if yaw > 100 then
            yaw = 100
        elseif yaw < -100 then
            yaw = -100
        end

        if fields.submit_target then
            meta:set_int("target_locked", 1)
            meta:set_float("target_power", power)
            meta:set_float("target_pitch", pitch)
            meta:set_float("target_yaw", yaw)
            digilines.receptor_send(pos, digilines.rules.default, "missile_tower", {
                command = "targeting_entry",
                target_entry = {
                    power = power,
                    pitch = pitch,
                    yaw = yaw
                }
            })
        end
        
        local delay = meta:get_int("target_delay")
        if fields.inp_delay then
            if isNumber(fields.inp_delay) then
                delay = tonumber(fields.inp_delay, 10)
            else
                isNumError = true
            end
        end
        if delay > 300 then
            delay = 300
        elseif delay < 0 then
            delay = 0
        end
        meta:set_int("target_delay", delay)
        
        local count = meta:get_int("target_count")
        if fields.inp_count then
            if isNumber(fields.inp_count) then
                count = tonumber(fields.inp_count, 10)
            else
                isNumError = true
            end
        end
        if count > 16 then
            count = 16
        elseif count < 1 then
            count = 1
        end
        meta:set_int("target_count", count)

        if fields.submit_launch then
            digilines.receptor_send(pos, digilines.rules.default, "missile_tower", {
                command = "targeting_launch",
                launch_entry = {
                    count = count,
                    delay = delay,
                }
            })
        end

        local formspec = ship_weapons.update_formspec(data, meta)
        meta:set_string("formspec", formspec)
        
    end

    minetest.register_node(modname .. ":" .. lmachine_name .. "", {
        description = machine_desc,
        tiles = {lmachine_name .. "_top.png", lmachine_name .. "_side.png", lmachine_name .. "_side.png",
                 lmachine_name .. "_side.png", lmachine_name .. "_side.png", lmachine_name .. "_side.png"},
        param = "light",
        paramtype2 = "facedir",
        light_source = 3,
        drop = modname .. ":" .. lmachine_name,
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
            meta:set_string("infotext", "Weapons Control " .. "-" .. " " .. machine_desc)
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            -- local inv = meta:get_inventory()
            meta:set_int("enabled", 1)
            meta:set_int("selected_dir", 13)
            meta:set_string("formspec", ship_weapons.update_formspec(data, meta))
            meta:set_string("pos_target", minetest.serialize({}))
            meta:set_int("target_locked", 0)
            meta:set_int("target_delay", 3)
            meta:set_int("target_count", 1)
            meta:set_float("target_power", 25.0)
            meta:set_float("target_pitch", 0.0)
            meta:set_float("target_yaw", 0.0)
        end,

        on_punch = function(pos, node, puncher)
        end,

        on_receive_fields = on_receive_fields,

        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                action = function()
                end
            }
        }
    })

end

ship_weapons.register_targeting_computer();
