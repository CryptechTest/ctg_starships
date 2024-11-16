local S = minetest.get_translator(minetest.get_current_modname())

local function round(v)
    return math.floor(v + 0.5)
end

local time_scl = 10

function ship_machine.register_jumpship(data)

    data.tier = data.tier or "LV"
    data.hp = data.hp or 1000
    data.shield = data.shield or 1000
    data.demand = data.demand or {0}
    data.speed = 1

    local tier = data.tier
    local ltier = string.lower(tier)
    local base_texture = data.texture_name or data.machine_name

    local texture_active = {
        image = base_texture .. "_active.png",
        animation = {
            type = "vertical_frames",
            aspect_w = 32,
            aspect_h = 32,
            length = 3
        }
    }

    local connect_sides = {"bottom"}

    -------------------------------------------------------
    -------------------------------------------------------
    -- technic run
    local run = function(pos, node)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local eu_input = meta:get_int(tier .. "_EU_input")

        local machine_desc_tier = data.machine_desc:format(tier)
        local machine_node = data.modname .. ":" .. data.machine_name
        local machine_demand_active = data.demand

        -- Setup meta data if it does not exist.
        if not eu_input then
            meta:set_int(tier .. "_EU_demand", machine_demand_active[1])
            meta:set_int(tier .. "_EU_input", 0)
            return
        end

        local powered = eu_input >= machine_demand_active[1]
        if powered then
            meta:set_int("enabled", 1)
            meta:set_int("src_time", meta:get_int("src_time") + round(data.speed * 10 * 1.0))
        end
        while true do
            local enabled = meta:get_int("enabled") == 1

            meta:set_int(tier .. "_EU_demand", machine_demand_active[1])

            if not powered then
                meta:set_int("enabled", 0)
                meta:set_string("infotext", machine_desc_tier .. S(" - Not Powered"))
                return
            end

            meta:set_string("infotext", machine_desc_tier .. S(" - Online"))

            if (meta:get_int("src_time") < round(time_scl * 10)) then
                break
            end

            meta:set_int("src_time", meta:get_int("src_time") - round(time_scl * 10))
        end
    end

    -------------------------------------------------------

    local nodename = data.modname .. ":" .. data.machine_name
    minetest.register_node(nodename, {
        description = S(data.machine_desc),
        tiles = {texture_active, base_texture .. "_bottom.png", texture_active, texture_active, texture_active,
                 texture_active},

        paramtype = "light",
        paramtype2 = "facedir",
        light_source = 4,
        groups = {
            cracky = 1,
            technic_machine = 1,
            ["technic_" .. ltier] = 1,
            ctg_machine = 1,
            metal = 1,
            level = 2,
            jumpdrive = 1,
            ship_machine = 1,
            not_in_creative_inventory = 1
        },
        sounds = default.node_sound_metal_defaults(),
        drop = nodename,

        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5}, -- base
                {-0.53125, -0.5, -0.53125, -0.4375, 0.50625, -0.4375}, -- p1
                {-0.53125, -0.5, 0.4375, -0.4375, 0.50625, 0.53125}, -- p2
                {0.4375, -0.5, 0.4375, 0.53125, 0.50625, 0.53125}, -- p3
                {0.4375, -0.5, -0.53125, 0.53125, 0.50625, -0.4375}, -- p4
                {-0.4375, -0.4375, -0.4375, 0.4375, 0.4375, 0.4375}, -- mid_base
                {-0.5, 0.4375, 0.40625, 0.5, 0.50625, 0.5}, -- top_b
                {-0.5, 0.4375, -0.5, 0.5, 0.50625, -0.40625}, -- top_f
                {-0.5, 0.4375, -0.40625, -0.40625, 0.50625, 0.40625}, -- top_l
                {0.40625, 0.4375, -0.40625, 0.5, 0.50625, 0.40625}, -- top_r
            }
        },
        selection_box = {
            type = "fixed",
            fixed = {
                {-0.53125, -0.5, -0.53125, 0.53125, 0.50625, 0.53125}, -- col_base
            }
        },

        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            meta:set_string("owner", placer:get_player_name())
            local formspec = ship_machine.update_jumpdrive_formspec(data, meta)
            meta:set_string("formspec", formspec)
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)

            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        connect_sides = connect_sides,
        can_dig = function(pos, player)
            local is_admin = false
            if minetest.check_player_privs(player, "jumpship_admin") then
                return true
            end
            return player and is_admin
        end,
        on_blast = function()
            -- TODO: handle destroy...
        end,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Starship Jump Drive Allocator")
            meta:set_int("enabled", 1)
            meta:set_int("ready", 0)
            meta:set_int("jumps", 0)
            meta:set_int("locked", 0)
            local formspec = ship_machine.update_jumpdrive_formspec(data, meta)
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
            local meta = minetest.get_meta(pos)
            if fields.setup then
                local formspec = ship_machine.update_jumpdrive_formspec(data, meta)
                meta:set_string("formspec", formspec)
            end
            local is_admin = false
            if minetest.check_player_privs(sender, "jumpship_admin") then
                is_admin = true
            end
            if not is_admin then
                -- meta:set_string("formspec", '')
                return
            end
            local node = minetest.get_node(pos)
            local owner_name = ""
            if fields.set_owner and fields.owner_name then
                owner_name = fields.owner_name
                meta:set_string("owner", owner_name)
                local prot = minetest.find_node_near(pos, 3, "group:ship_protector")
                if prot then
                    local meta2 = minetest.get_meta(prot)
                    meta2:set_string("owner", owner_name)
                    meta2:set_string("infotext", S("Protection (owned by @1)", meta2:get_string("owner")))
                    ship_machine.update_ship_owner_all(pos, data.size, owner_name)
                end
            end
            local file_name = ""
            if fields.file_name then
                file_name = fields.file_name
            end
            if fields.save then
                minetest.after(0, function()
                    ship_machine.save_jumpship(pos, data.size, sender, file_name)
                end)
            end
            if fields.load then
                minetest.after(0, function()
                    ship_machine.load_jumpship(pos, sender, file_name)
                end)
            end
            local formspec = ship_machine.update_jumpdrive_formspec(data, meta)
            meta:set_string("formspec", formspec)
        end,

        digiline = {
            receptor = {
                rules = technic.digilines.rules_allfaces,
                action = function()
                end
            },
            effector = {
                action = ship_machine.jumpdrive_digiline_effector
            }
        }
    })

    technic.register_machine(tier, nodename, technic.receiver)

    if data.do_protect then
        ship_machine.register_jumpship_protect({
            modname = data.modname,
            machine_name = data.shield_name,
            ship_name = data.ship_name,
            size = data.size,
            hp = data.hp,
            shield = data.shield
        })
    end
end
