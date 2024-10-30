local S = minetest.get_translator(minetest.get_current_modname())

local time_scl = 10

local function isNumber(str)
    return tonumber(str) ~= nil
end

local function round(v)
    return math.floor(v + 0.5)
end

function ship_weapons.register_targeting_dish(custom_data)

    local data = custom_data or {}

    data.speed = 1
    data.range = custom_data.range or 64
    data.demand = custom_data.demand or {200, 180, 150}
    data.tier = (custom_data and custom_data.tier) or "LV"
    data.typename = (custom_data and custom_data.typename) or "target_dish"
    data.modname = (custom_data and custom_data.modname) or "ship_weapons"
    data.machine_name = (custom_data and custom_data.machine_name) or string.lower(data.tier) ..
                            "_targeting_dish_antenna"
    data.machine_desc = (custom_data and custom_data.machine_desc) or "Targeting Antenna Dish"

    local tier = data.tier
    local ltier = string.lower(tier)
    local modname = data.modname
    local machine_name = data.machine_name
    local machine_desc = tier .. " " .. data.machine_desc
    local lmachine_name = string.lower(machine_name)
    local node_name = modname .. ":" .. machine_name

    local active_groups = {
        cracky = 2,
        technic_machine = 1,
        ["technic_" .. ltier] = 1,
        ctg_machine = 1,
        metal = 1,
        level = 1,
        ship_machine = 1
        -- ship_weapon = 1,
        -- not_in_creative_inventory = 1
    }

    local connect_sides = {"back"}

    -------------------------------------------------------
    -------------------------------------------------------
    -- technic run
    local run = function(pos, node)
        local meta = minetest.get_meta(pos)
        local owner = meta:get_string("owner")
        local operator = minetest.get_player_by_name(owner);
        local inv = meta:get_inventory()
        local eu_input = meta:get_int(tier .. "_EU_input")

        local machine_desc_tier = machine_desc:format(tier)
        local machine_node = data.modname .. ":" .. machine_name
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

    minetest.register_node(node_name, {
        description = "Targeting Antenna Dish",
        tiles = {"ctg_" .. ltier .. "_target_dish_side.png^[transformR90",
                 "ctg_" .. ltier .. "_target_dish_side.png^[transformFXR90", "ctg_" .. ltier .. "_target_dish_side.png",
                 "ctg_" .. ltier .. "_target_dish_side.png^[transformFX", "ctg_" .. ltier .. "_target_dish_back.png",
                 "ctg_" .. ltier .. "_target_dish_front.png"},
        param = "light",
        paramtype2 = "facedir",
        light_source = 4,
        drop = node_name,
        groups = active_groups,
        legacy_facedir_simple = true,
        drawtype = "nodebox",
        paramtype = "light",
        node_box = {
            type = "fixed",
            fixed = {{-0.3125, -0.3125, -0.25, 0.3125, 0.3125, -0.1875}, -- dish
            {-0.5, -0.5, -0.375, -0.4375, 0.5, -0.3125}, -- dish_left
            {0.4375, -0.5, -0.375, 0.5, 0.5, -0.3125}, -- dish_right
            {-0.4375, 0.4375, -0.375, 0.4375, 0.5, -0.3125}, -- dish_top
            {-0.4375, -0.5, -0.375, 0.4375, -0.4375, -0.3125}, -- dish_bottom
            {-0.5, 0.25, -0.3125, 0.5, 0.5, -0.25}, -- dish_top_2
            {-0.5, -0.5, -0.3125, 0.5, -0.25, -0.25}, -- dish_bottom_2
            {0.25, -0.25, -0.3125, 0.5, 0.25, -0.25}, -- node_right_2
            {-0.5, -0.25, -0.3125, -0.25, 0.25, -0.25}, -- node_left_2
            {-0.03125, -0.03125, -0.5, 0.03125, 0.03125, -0.25}, -- ant
            {-0.0625, -0.125, -0.1875, 0.0625, 0.125, 0.375}, -- base
            {-0.1875, -0.1875, 0.375, 0.1875, 0.1875, 0.5} -- base2
            }
        },
        collision_box = {
            type = "fixed",
            fixed = {{-0.5, -0.5, -0.375, 0.5, 0.5, -0.1875}, -- col1
            {-0.1875, -0.1875, -0.1875, 0.1875, 0.1875, 0.5}, -- col2
            {-0.03125, -0.03125, -0.5, 0.03125, 0.03125, -0.375} -- col3
            }
        },
        selection_box = {
            type = "fixed",
            fixed = {{-0.5, -0.5, -0.375, 0.5, 0.5, -0.1875}, -- col1
            {-0.1875, -0.1875, -0.1875, 0.1875, 0.1875, 0.5} -- col2
            }
        },
        sounds = default.node_sound_metal_defaults(),
        connect_sides = connect_sides,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Targeting Antenna")
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            return technic.machine_after_dig_node
        end,
        can_dig = technic.machine_can_dig,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            -- local inv = meta:get_inventory()
            meta:set_int("enabled", 0)
            meta:set_int("range", data.range)
        end,

        on_punch = function(pos, node, puncher)
        end,

        technic_run = run,

        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                action = ship_weapons.targeting_dish_digiline_effector
            }
        }
    })

    technic.register_machine(tier, node_name, technic.receiver)
end

ship_weapons.register_targeting_dish({
    tier = "LV",
    demand = {200, 180, 150},
    range = 72
});
ship_weapons.register_targeting_dish({
    tier = "MV",
    demand = {700, 670, 640},
    range = 80 -- max distance is 80  or volume of 4096000 nodes...
});
