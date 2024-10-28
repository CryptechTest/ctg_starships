local S = minetest.get_translator(minetest.get_current_modname())

local time_scl = 20

local function round(v)
    return math.floor(v + 0.5)
end

local function needs_charge(pos)
    local meta = minetest.get_meta(pos)
    local charge = meta:get_int("charge")
    local charge_max = meta:get_int("charge_max")
    return charge < charge_max
end

function ship_machine.register_engine(data)
    local tier = data.tier
    local ltier = string.lower(tier)
    local machine_name = data.machine_name
    local machine_desc = tier .. " " .. data.machine_desc
    local tmachine_name = string.lower(machine_name)
    local gen_reset_tick = 0

    local groups = {
        cracky = 2,
        technic_machine = 1,
        ["technic_" .. ltier] = 1,
        ctg_machine = 1,
        metal = 1,
        level = 2,
        ship_machine = 1,
        gravity_gen = 1
    }

    if data.machine_name == "gravity_drive_admin" or data.machine_name == "gravity_drive" then
        groups["not_in_creative_inventory"] = 1
    end

    local active_groups = {
        not_in_creative_inventory = 1
    }
    for k, v in pairs(groups) do
        active_groups[k] = v
    end

    local tube = {
        insert_object = function(pos, node, stack, direction)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            local added = inv:add_item("src", stack)
            return added
        end,
        can_insert = function(pos, node, stack, direction)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            return inv:room_for_item("src", stack)
        end,
        connect_sides = {
            front = 1,
            left = 1,
            right = 1,
            -- back = 1,
            top = 1,
            bottom = 1
        }
    }
    -- data.tube = tube

    if data.tube then
        groups.tubedevice = 1
        groups.tubedevice_receiver = 1
    end

    if data.can_insert then
        tube.can_insert = data.can_insert
    end
    if data.insert_object then
        tube.insert_object = data.insert_object
    end

    -------------------------------------------------------

    -- technic run
    local run = function(pos, node)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local eu_input = meta:get_int(tier .. "_EU_input")

        local machine_desc_tier = machine_desc:format(tier)
        local machine_node = data.modname .. ":" .. ltier .. "_" .. machine_name
        local machine_demand_active = data.demand
        local machine_demand_idle = data.demand[1] * 0.6

        local charge_max = meta:get_int("charge_max")
        local charge = meta:get_int("charge")

        -- Setup meta data if it does not exist.
        if not eu_input then
            meta:set_int(tier .. "_EU_demand", machine_demand_active[1])
            meta:set_int(tier .. "_EU_input", 0)
            return
        end

        if not meta:get_int("enabled") then
            meta:set_int("enabled", 0)
            return
        end

        local EU_upgrade, tube_upgrade = 0, 0
        if data.upgrade then
            EU_upgrade, tube_upgrade = technic.handle_machine_upgrades(meta)
        end
        if data.tube then
            technic.handle_machine_pipeworks(pos, tube_upgrade)
        end

        local powered = eu_input >= machine_demand_active[EU_upgrade + 1]
        if powered then
            meta:set_int("src_time", meta:get_int("src_time") + round(data.speed * 10 * 1.0))
        end
        while true do
            local enabled = meta:get_int("enabled") == 1

            if (not enabled) then
                technic.swap_node(pos, machine_node)
                meta:set_string("infotext", machine_desc_tier .. S(" Disabled"))
                meta:set_int(tier .. "_EU_demand", 0)
                meta:set_int("src_time", 0)
                local formspec = ship_machine.update_formspec(data, false, enabled, false, 0, charge, charge_max)
                meta:set_string("formspec", formspec)
                gen_reset_tick = gen_reset_tick + 1
                if gen_reset_tick >= 3 then
                    ship_machine.reset_generator(meta)
                    gen_reset_tick = 0
                end
                return
            end

            local has_mese = true
            technic.swap_node(pos, machine_node .. "_active")
            meta:set_int(tier .. "_EU_demand", machine_demand_active[EU_upgrade + 1])

            if not needs_charge(pos) then
                technic.swap_node(pos, machine_node .. "_active")
                meta:set_string("infotext", machine_desc_tier .. S(" Operational - Charged"))
                meta:set_int(tier .. "_EU_demand", machine_demand_idle)
                meta:set_int("src_time", 0)
                local formspec = ship_machine.update_formspec(data, true, enabled, has_mese, 0, charge, charge_max)
                meta:set_string("formspec", formspec)
                -- apply gravity
                ship_machine.apply_gravity(pos, data.gravity)
                return
            end

            meta:set_string("infotext", machine_desc_tier .. S(" Active - Charging"))
            if meta:get_int("src_time") < round(time_scl * 10) then
                local item_percent = (math.floor(meta:get_int("src_time") / round(time_scl * 10) * 100))
                if not powered then
                    technic.swap_node(pos, machine_node)
                    meta:set_string("infotext", machine_desc_tier .. S(" Unpowered"))
                    local formspec = ship_machine.update_formspec(data, false, enabled, has_mese, item_percent, charge,
                        charge_max)
                    meta:set_string("formspec", formspec)
                    -- ship_machine.reset_generator(meta)
                    return
                end
                local formspec = ship_machine.update_formspec(data, true, enabled, has_mese, item_percent, charge,
                    charge_max)
                meta:set_string("formspec", formspec)
                return
            end

            --[[local command = "pos_grav_gen"
            digilines.receptor_send(pos, digilines.rules.default, "ship_scout", {
                command = command,
                pos_nav = {pos.x, pos.y, pos.z}
            })--]]

            local chrg = 1
            meta:set_int("charge", charge + chrg)

            meta:set_int("src_time", meta:get_int("src_time") - round(time_scl * 10))
            -- return
        end
    end

    -------------------------------------------------------
    -- register machine node

    local node_name = data.modname .. ":" .. ltier .. "_" .. machine_name
    minetest.register_node(node_name .. "", {
        description = machine_desc,
        tiles = {ltier .. "_" .. tmachine_name .. "_top.png", ltier .. "_" .. tmachine_name .. "_bottom.png",
                 ltier .. "_" .. tmachine_name .. ".png", ltier .. "_" .. tmachine_name .. ".png",
                 ltier .. "_" .. tmachine_name .. ".png", ltier .. "_" .. tmachine_name .. ".png"},
        paramtype2 = "facedir",
        drop = data.modname .. ":" .. ltier .. "_" .. machine_name,
        groups = groups,
        tube = data.tube and tube or nil,
        legacy_facedir_simple = true,
        sounds = default.node_sound_metal_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            if data.tube then
                pipeworks.after_place(pos)
            end
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            return technic.machine_after_dig_node
        end,
        on_push_item = function(pos, dir, item)
            local tube_dir = minetest.get_meta(pos):get_int("tube_dir")
            if dir == tubelib2.Turn180Deg[tube_dir] then
                local s = minetest.get_meta(pos):get_string("peer_pos")
                if s and s ~= "" then
                    push_item(minetest.string_to_pos(s))
                    return true
                end
            end
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Starship Engine")
            meta:set_int("tube_time", 0)
            local inv = meta:get_inventory()
            inv:set_size("src", 1)
            inv:set_size("dst", 1)
            inv:set_size("upgrade1", 1)
            inv:set_size("upgrade2", 1)
            meta:set_int("enabled", 1)
            meta:set_int("charge", 0)
            meta:set_int("charge_max", data.charge_max)
            meta:set_int("demand", data.demand[1])
            local formspec = ship_machine.update_formspec(data, false, true)
            meta:set_string("formspec", formspec)
        end,

        allow_metadata_inventory_put = technic.machine_inventory_put,
        allow_metadata_inventory_take = technic.machine_inventory_take,
        allow_metadata_inventory_move = technic.machine_inventory_move,
        technic_run = run,

        on_receive_fields = function(pos, formname, fields, sender)
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
            local formspec = ship_machine.update_formspec(data, false, enabled)
            meta:set_string("formspec", formspec)
        end,

        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                action = data.digiline_effector
            }
        }
    })

    local texture_active_top = {
        image = ltier .. "_" .. machine_name .. "_top_active.png",
        animation = {
            type = "vertical_frames",
            aspect_w = 32,
            aspect_h = 32,
            length = 3
        }
    }
    local texture_active = {
        image = ltier .. "_" .. machine_name .. "_active.png",
        animation = {
            type = "vertical_frames",
            aspect_w = 32,
            aspect_h = 32,
            length = 3
        }
    }

    minetest.register_node(node_name .. "_active", {
        description = machine_desc,
        tiles = {texture_active_top, ltier .. "_" .. tmachine_name .. "_bottom.png", texture_active, texture_active,
                 texture_active, texture_active},
        param = "light",
        -- paramtype2 = "facedir",
        light_source = 8,
        drop = data.modname .. ":" .. ltier .. "_" .. machine_name,
        groups = active_groups,
        tube = data.tube and tube or nil,
        legacy_facedir_simple = true,
        sounds = default.node_sound_metal_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            if data.tube then
                pipeworks.after_place(pos)
            end
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,

        on_push_item = function(pos, dir, item)
            local tube_dir = minetest.get_meta(pos):get_int("tube_dir")
            if dir == tubelib2.Turn180Deg[tube_dir] then
                local s = minetest.get_meta(pos):get_string("peer_pos")
                if s and s ~= "" then
                    push_item(minetest.string_to_pos(s))
                    return true
                end
            end
        end,

        allow_metadata_inventory_put = technic.machine_inventory_put,
        allow_metadata_inventory_take = technic.machine_inventory_take,
        allow_metadata_inventory_move = technic.machine_inventory_move,
        technic_run = run,

        on_receive_fields = function(pos, formname, fields, sender)
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
            local formspec = ship_machine.update_formspec(data, false, enabled)
            meta:set_string("formspec", formspec)
        end,

        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                action = data.digiline_effector
            }
        }
    })

    technic.register_machine(tier, node_name, technic.receiver)
    technic.register_machine(tier, node_name .. "_active", technic.receiver)

end

