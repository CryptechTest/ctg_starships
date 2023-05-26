local S = minetest.get_translator(minetest.get_current_modname())

local time_tick = 40
local time_scl = 40

ship_engine.mese_image_mask = "default_mese_crystal.png^[colorize:#75757555"

local function round(v)
    return math.floor(v + 0.5)
end

local function out_result(pos, ninput, machine_node, machine_desc_tier, tier)
    local output = {}
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    if ninput and ninput.new_input then
        inv:set_list("src", {ninput.new_input})
        meta:set_int("last_input_type", ninput.input_type)
        return true
    end
    return false
end

local function out_results(pos, machine_node, machine_desc_tier, tier, do_use)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local ninput = ship_engine.get_mese(inv:get_list("src"), do_use)
    local result = -1
    if (do_use) then
        if out_result(pos, ninput, machine_node, machine_desc_tier, tier) then
            result = 0
        end
    end
    if ninput and ninput.input_type then
        return ninput.input_type
    end
    return result
end

function ship_engine.register_engine(data)
    local tier = data.tier
    local ltier = string.lower(tier)
    local machine_name = data.machine_name
    local machine_desc = data.machine_desc
    local tmachine_name = string.lower(machine_name):gsub("_r", ""):gsub("_l", "")

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
    data.tube = tube
    if data.can_insert then
        tube.can_insert = data.can_insert
    end
    if data.insert_object then
        tube.insert_object = data.insert_object
    end

    local groups = {
        cracky = 2,
        technic_machine = 1,
        ["technic_" .. ltier] = 1,
        ctg_machine = 1,
        metal = 1,
        level = 2,
        ship_engine = 1
    }

    if data.tube then
        groups.tubedevice = 1
        groups.tubedevice_receiver = 1
    end

    local active_groups = {
        not_in_creative_inventory = 1
    }
    for k, v in pairs(groups) do
        active_groups[k] = v
    end

    local run = function(pos, node)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local eu_input = meta:get_int(tier .. "_EU_input")
        local eu_supply = meta:get_int(tier .. "_EU_supply")

        if not eu_supply then
            meta:set_int(tier .. "_EU_supply", data.supply)
        end

        local machine_desc_tier = machine_desc:format(tier)
        local machine_node = data.modname .. ":" .. ltier .. "_" .. machine_name
        local machine_demand = data.demand

        local charge_max = meta:get_int("charge_max")
        local charge = meta:get_int("charge")

        -- Setup meta data if it does not exist.
        if not eu_input then
            meta:set_int(tier .. "_EU_demand", machine_demand[1])
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

        local powered = eu_input >= machine_demand[EU_upgrade + 1]
        if powered then
            meta:set_int("src_time", meta:get_int("src_time") + round(data.speed * 10))
        end
        if meta:get_int('last_input_type') > 0 then
            meta:set_int("src_time", meta:get_int("src_time") + round(data.speed * 10))
        end
        while true do
            local enabled = meta:get_int("enabled") == 1
            local has_mese = ship_engine.get_mese(inv:get_list("src"), false) ~= nil
            local chrg = meta:get_int('last_input_type')

            if (not enabled) then
                technic.swap_node(pos, machine_node)
                meta:set_string("infotext", S("%s Disabled"):format(machine_desc_tier))
                meta:set_int(tier .. "_EU_demand", 0)
                meta:set_int(tier .. "_EU_supply", 0)
                -- meta:set_int("src_time", 0)
                local formspec = ship_engine.update_formspec(data, false, enabled, has_mese, 0, charge, charge_max,
                    eu_input, eu_supply)
                meta:set_string("formspec", formspec)
                return
            end

            if not has_mese then
                digilines.receptor_send(pos, digilines.rules.default, "ship_engine", "request_mese")
            end

            if meta:get_int("src_time") <= round(data.speed * 10.0 * 1.5) then
                time_scl = time_tick * 1
                local out_res = out_results(pos, machine_node, machine_desc_tier, ltier, has_mese)
                if not has_mese then
                    technic.swap_node(pos, machine_node)
                    meta:set_string("infotext", S("%s Idle - Missing Input"):format(machine_desc_tier))
                    meta:set_int(tier .. "_EU_supply", 0)
                    meta:set_int("src_time", round(data.speed * 10))
                    local formspec = ship_engine.update_formspec(data, chrg > 0, enabled, has_mese, 0, charge,
                        charge_max, eu_input, eu_supply)
                    meta:set_string("formspec", formspec)
                elseif out_res then
                    technic.swap_node(pos, machine_node)
                    meta:set_string("infotext", S("%s Energizing - Active Pending"):format(machine_desc_tier))
                    meta:set_int("src_time", round(data.speed * 10))
                    meta:set_int(tier .. "_EU_supply", data.supply)
                    time_scl = time_tick * (out_res * 0.1)
                end
                -- return
            end

            local item_percent = (math.floor(meta:get_int("src_time") / round(time_scl * 10) * 100))
            local formspec = ship_engine.update_formspec(data, chrg > 0, enabled, has_mese, item_percent, charge,
                charge_max, eu_input, eu_supply)
            meta:set_string("formspec", formspec)

            technic.swap_node(pos, machine_node .. "_active")
            if meta:get_int('last_input_type') > 0 then
                meta:set_int(tier .. "_EU_supply", data.supply)
            elseif not has_mese then
                meta:set_int(tier .. "_EU_supply", 0)
            end

            if not ship_engine.needs_charge(pos) then
                meta:set_int(tier .. "_EU_demand", 0)
                if meta:get_int("src_time") < round(data.speed * 10.0 * 2) then
                    technic.swap_node(pos, machine_node .. "_active")
                    meta:set_string("infotext", S("%s Charged & Active"):format(machine_desc_tier))
                    -- meta:set_int(tier .. "_EU_supply", data.supply)
                    meta:set_int("src_time", round(data.speed * 10))
                    local formspec = ship_engine.update_formspec(data, chrg > 0, enabled, has_mese, 0, charge,
                        charge_max, eu_input, eu_supply)
                    meta:set_string("formspec", formspec)
                    -- return
                elseif meta:get_int("src_time") >= round((time_scl * 10) - (data.speed * 10.0)) then
                    meta:set_int("last_input_type", 0)
                    meta:set_int("src_time", 0)
                end
                return
            end

            meta:set_int(tier .. "_EU_demand", machine_demand[EU_upgrade + 1])
            meta:set_string("infotext", S("%s Active - Charging"):format(machine_desc_tier))

            if not powered then
                meta:set_string("infotext", S("%s Not Powered"):format(machine_desc_tier))
                return
            end

            if meta:get_int("src_time") < round(time_scl * 10) then
                if not powered then
                    technic.swap_node(pos, machine_node)
                    meta:set_int(tier .. "_EU_supply", 0)
                    meta:set_string("infotext", S("%s Unpowered"):format(machine_desc_tier))
                    return
                end
                return
            end

            --[[
            local command = ""
            if machine_name == "lv_engine_r" then
                command = "pos_eng1"
            elseif machine_name == "lv_engine_l" then
                command = "pos_eng2"
            end
            digilines.receptor_send(pos, digilines.rules.default, "ship_scout", {
                command = command,
                pos_nav = {pos.x, pos.y, pos.z}
            })--]]

            if powered and chrg > 0 then
                out_results(pos, machine_node, machine_desc_tier, ltier, false)
                meta:set_int("charge", charge + chrg + math.random(0, 1))
            elseif powered then
                meta:set_int("charge", charge + math.random(1, 2))
            end

            -- if meta:get_int("charge") > meta:get_int("charge_max") then
            --    meta:set_int("charge", meta:get_int("charge_max") )
            -- end

            -- reset timer tick
            meta:set_int("last_input_type", 0)
            meta:set_int("src_time", 0)
            return
        end
    end

    local node_name = data.modname .. ":" .. ltier .. "_" .. machine_name
    minetest.register_node(node_name .. "", {
        description = machine_desc,
        tiles = {ltier .. "_" .. tmachine_name .. "_top.png", ltier .. "_" .. tmachine_name .. "_bottom.png",
                 ltier .. "_" .. tmachine_name .. "_side.png", ltier .. "_" .. tmachine_name .. "_side.png",
                 ltier .. "_" .. tmachine_name .. "_back.png", ltier .. "_" .. tmachine_name .. "_front.png"},
        paramtype2 = "facedir",
        drop = data.modname .. ":" .. ltier .. "_" .. machine_name,
        groups = groups,
        tube = data.tube and tube or nil,
        legacy_facedir_simple = true,
        sounds = default.node_sound_glass_defaults(),
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
            local charge_max = meta:get_int("charge_max")
            local charge = meta:get_int("charge")
            local eu_input = meta:get_int(tier .. "_EU_input")
            local eu_supply = meta:get_int(tier .. "_EU_supply")
            local formspec = ship_engine.update_formspec(data, false, true, false, 0, charge, charge_max, eu_input,
                eu_supply)
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
            local charge_max = meta:get_int("charge_max")
            local charge = meta:get_int("charge")
            local eu_input = meta:get_int(tier .. "_EU_input")
            local eu_supply = meta:get_int(tier .. "_EU_supply")
            local enabled = false
            if fields.toggle then
                if meta:get_int("enabled") == 1 then
                    meta:set_int("enabled", 0)
                else
                    meta:set_int("enabled", 1)
                    enabled = true
                end
            end
            local formspec = ship_engine.update_formspec(data, false, enabled, false, 0, charge, charge_max, eu_input,
                eu_supply)
            meta:set_string("formspec", formspec)
        end,

        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                action = data.engine_digiline_effector
            }
        }
    })

    minetest.register_node(node_name .. "_active", {
        description = machine_desc,
        tiles = {ltier .. "_" .. tmachine_name .. "_top.png", ltier .. "_" .. tmachine_name .. "_bottom.png",
                 ltier .. "_" .. tmachine_name .. "_side.png", ltier .. "_" .. tmachine_name .. "_side.png",
                 ltier .. "_" .. tmachine_name .. "_back_active.png",
                 ltier .. "_" .. tmachine_name .. "_front_active.png"},
        param = "light",
        paramtype2 = "facedir",
        light_source = 10,
        drop = data.modname .. ":" .. ltier .. "_" .. machine_name,
        groups = active_groups,
        tube = data.tube and tube or nil,
        legacy_facedir_simple = true,
        sounds = default.node_sound_glass_defaults(),
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
            local charge_max = meta:get_int("charge_max")
            local charge = meta:get_int("charge")
            local eu_input = meta:get_int(tier .. "_EU_input")
            local eu_supply = meta:get_int(tier .. "_EU_supply")
            local formspec = ship_engine.update_formspec(data, false, true, false, 0, charge, charge_max, eu_input,
                eu_supply)
            meta:set_string("formspec", formspec)
        end,

        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
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
            local charge_max = meta:get_int("charge_max")
            local charge = meta:get_int("charge")
            local eu_input = meta:get_int(tier .. "_EU_input")
            local eu_supply = meta:get_int(tier .. "_EU_supply")
            local enabled = false
            if fields.toggle then
                if meta:get_int("enabled") == 1 then
                    meta:set_int("enabled", 0)
                else
                    meta:set_int("enabled", 1)
                    enabled = true
                end
            end
            local formspec = ship_engine.update_formspec(data, false, enabled, false, 0, charge, charge_max, eu_input,
                eu_supply)
            meta:set_string("formspec", formspec)
        end,

        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                action = data.engine_digiline_effector
            }
        }
    })

    technic.register_machine(tier, node_name, technic.producer_receiver)
    technic.register_machine(tier, node_name .. "_active", technic.producer_receiver)

end

local function register_lv_engine(data)
    data.modname = "ship_engine"
    data.charge_max = 160
    data.demand = {5000}
    data.supply = 6600
    data.speed = 3
    data.tier = "LV"
    data.typename = "engine"
    -- data.machine_name = "engine"
    -- data.machine_desc = "Starship Engine"

    ship_engine.register_engine(data)
end

register_lv_engine({
    machine_name = "engine_l",
    machine_desc = "Port Engine",
    engine_digiline_effector = ship_engine.engine_digiline_effector_l
})
register_lv_engine({
    machine_name = "engine_r",
    machine_desc = "Starboard Engine",
    engine_digiline_effector = ship_engine.engine_digiline_effector_r
})

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

function ship_engine.register_engine_core(data)
    data.typename = "engine_core"
    data.modname = "ship_engine"
    data.tier = "LV"
    data.demand = {500}
    data.charge_max = 2000
    data.speed = 25
    data.machine_name = "surveyor"
    data.machine_desc = "Spacial Conjuction Surveyor"

    local tier = data.tier
    local ltier = string.lower(tier)
    local machine_name = data.machine_name
    local machine_desc = data.machine_desc
    local tmachine_name = string.lower(machine_name)

    local groups = {
        cracky = 2,
        technic_machine = 1,
        ["technic_" .. ltier] = 1,
        ctg_machine = 1,
        metal = 1,
        level = 2,
        ship_engine = 2
    }

    local active_groups = {
        not_in_creative_inventory = 1
    }
    for k, v in pairs(groups) do
        active_groups[k] = v
    end

    local run = function(pos, node)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local eu_input = meta:get_int(tier .. "_EU_input")

        local machine_desc_tier = machine_desc:format(tier)
        local machine_node = data.modname .. ":" .. ltier .. "_" .. machine_name
        local machine_demand = data.demand

        local charge_max = meta:get_int("charge_max")
        local charge = meta:get_int("charge")

        -- Setup meta data if it does not exist.
        if not eu_input then
            meta:set_int(tier .. "_EU_demand", machine_demand[1])
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

        local powered = eu_input >= machine_demand[EU_upgrade + 1]
        if powered then
            meta:set_int("src_time", meta:get_int("src_time") + round(data.speed * 10 * 1.0))
        end
        while true do
            local enabled = meta:get_int("enabled") == 1
            local eng_enabled = meta:get_int("engine_en_1") == 1 and meta:get_int("engine_en_2") == 1

            if (not enabled) then
                technic.swap_node(pos, machine_node)
                meta:set_string("infotext", S("%s Disabled"):format(machine_desc_tier))
                meta:set_int(tier .. "_EU_demand", 0)
                meta:set_int("src_time", 0)
                local formspec = ship_engine.update_formspec(data, false, enabled, false, 0, charge, charge_max)
                meta:set_string("formspec", formspec)
                return
            end

            local has_mese = eng_enabled
            if powered and meta:get_int("src_time") <= round(data.speed * 10 * 1.0) then
                if not has_mese then
                    technic.swap_node(pos, machine_node)
                    meta:set_string("infotext", S("%s Idle - Missing Engines"):format(machine_desc_tier))
                    meta:set_int(tier .. "_EU_demand", 0)
                    meta:set_int("src_time", 0)
                    local formspec = ship_engine.update_formspec(data, false, enabled, has_mese, 0, charge, charge_max)
                    meta:set_string("formspec", formspec)
                    return
                end
            end

            if not ship_engine.needs_charge(pos) then
                technic.swap_node(pos, machine_node .. "_active")
                meta:set_string("infotext", S("%s Idle - Charged!"):format(machine_desc_tier))
                meta:set_int(tier .. "_EU_demand", 0)
                meta:set_int("src_time", 0)
                local formspec = ship_engine.update_formspec(data, false, enabled, has_mese, 0, charge, charge_max)
                meta:set_string("formspec", formspec)
                return
            end

            technic.swap_node(pos, machine_node .. "_active")
            meta:set_int(tier .. "_EU_demand", machine_demand[EU_upgrade + 1])
            meta:set_string("infotext", S("%s Active"):format(machine_desc_tier))
            if meta:get_int("src_time") < round(time_scl * 10) then
                local item_percent = (math.floor(meta:get_int("src_time") / round(time_scl * 10) * 100))
                if not powered then
                    technic.swap_node(pos, machine_node)
                    meta:set_string("infotext", S("%s Unpowered"):format(machine_desc_tier))
                    local formspec = ship_engine.update_formspec(data, false, enabled, has_mese, item_percent, charge,
                        charge_max)
                    meta:set_string("formspec", formspec)
                    return
                end
                local formspec = ship_engine.update_formspec(data, true, enabled, has_mese, item_percent, charge,
                    charge_max)
                meta:set_string("formspec", formspec)
                return
            end

            digilines.receptor_send(pos, digilines.rules.default, "ship_scout", {
                command = "pos_nav",
                pos_nav = {pos.x, pos.y, pos.z}
            })

            meta:set_int("charge", charge + 1)

            meta:set_int("src_time", meta:get_int("src_time") - round(time_scl * 10))
            -- return
        end
    end

    local node_name = data.modname .. ":" .. ltier .. "_" .. machine_name
    minetest.register_node(node_name, {
        description = machine_desc,
        tiles = {ltier .. "_" .. tmachine_name .. "_top.png", ltier .. "_" .. tmachine_name .. "_bottom.png",
                 ltier .. "_" .. tmachine_name .. "_side.png", ltier .. "_" .. tmachine_name .. "_side.png",
                 ltier .. "_" .. tmachine_name .. "_side.png", ltier .. "_" .. tmachine_name .. "_front.png"},
        paramtype2 = "facedir",
        drop = data.modname .. ":" .. ltier .. "_" .. machine_name,
        groups = groups,
        tube = data.tube and tube or nil,
        legacy_facedir_simple = true,
        sounds = default.node_sound_glass_defaults(),
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

        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Starship Hyperdrive")
            -- meta:set_int("tube_time", 0)
            local inv = meta:get_inventory()
            -- inv:set_size("src", 1)
            -- inv:set_size("dst", 1)
            inv:set_size("upgrade1", 1)
            inv:set_size("upgrade2", 1)
            meta:set_int("enabled", 0)
            meta:set_int("charge", 0)
            meta:set_int("charge_max", data.charge_max)
            meta:set_int("demand", data.demand[1])
            meta:set_int("jump_ready", 0)
            local formspec = ship_engine.update_formspec(data, false, false)
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
            local formspec = ship_engine.update_formspec(data, false, enabled)
            meta:set_string("formspec", formspec)
        end,

        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                action = ship_engine.engine_digiline_effector
            }
        }
    })

    minetest.register_node(node_name .. "_active", {
        description = machine_desc,
        tiles = {{
            image = ltier .. "_" .. machine_name .. "_top_active.png",
            backface_culling = false,
            animation = {
                type = "vertical_frames",
                aspect_w = 32,
                aspect_h = 32,
                length = 2
            }
        }, ltier .. "_" .. tmachine_name .. "_bottom.png", ltier .. "_" .. tmachine_name .. "_side.png",
                 ltier .. "_" .. tmachine_name .. "_side.png", ltier .. "_" .. tmachine_name .. "_side.png",
                 ltier .. "_" .. tmachine_name .. "_front.png"},
        param = "light",
        paramtype2 = "facedir",
        light_source = 6,
        drop = data.modname .. ":" .. ltier .. "_" .. machine_name,
        groups = groups,
        tube = data.tube and tube or nil,
        legacy_facedir_simple = true,
        sounds = default.node_sound_glass_defaults(),
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
            local formspec = ship_engine.update_formspec(data, false, enabled)
            meta:set_string("formspec", formspec)
        end,

        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                action = ship_engine.engine_digiline_effector
            }
        }
    })

    technic.register_machine(tier, node_name, technic.receiver)
    technic.register_machine(tier, node_name .. "_active", technic.receiver)

end

ship_engine.register_engine_core({})
