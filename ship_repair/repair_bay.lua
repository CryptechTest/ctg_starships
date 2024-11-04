local S = minetest.get_translator(minetest.get_current_modname())

local time_scl = 10

local has_pipeworks = minetest.get_modpath("pipeworks")

local tube_entry_metal = ""

if has_pipeworks then
    tube_entry_metal = "^pipeworks_tube_connection_metallic.png"
end

local connect_default = {"bottom", "back"}

local function isNumber(str)
    return tonumber(str) ~= nil
end

local function round(v)
    return math.floor(v + 0.5)
end

----------------------------------------------------
----------------------------------------------------
----------------------------------------------------


local function update_formspec(meta, data)
    local machine_desc = data.tier .. " " .. data.machine_desc
    local typename = data.typename
    local tier = data.tier
    local ltier = string.lower(tier)
    local formspec = nil
    if typename == 'repair_box' then
        local enabled = ctg_machines.machine_enabled(meta)
        local btnName = "Status: "
        if enabled then
            btnName = btnName .. "Enabled"
        else
            btnName = btnName .. "Disabled"
        end

        formspec = "size[8,9;]" .. 
                    "list[current_name;src;1,1;6,2;]" ..
                    "list[current_player;main;0,5;8,4;]" .. "label[0,0;" .. machine_desc:format(tier) .. "]" .. 
                    "listring[current_player;main]" .. "listring[current_player;main]" .. 
                     "button[4.5,3.5;2.5,1;toggle;" .. btnName .. "]"
    end

    if data.upgrade then
        formspec = formspec .. "list[current_name;upgrade1;1,3;1,1;]" .. "list[current_name;upgrade2;2,3;1,1;]" ..
                       "label[1,4;" .. S("Upgrade Slots") .. "]" .. "listring[current_name;upgrade1]" ..
                       "listring[current_player;main]" .. "listring[current_name;upgrade2]" ..
                       "listring[current_player;main]"
    end
    return formspec
end

----------------------------------------------------
----------------------------------------------------

local function find_ship_protect(pos)
	local s = {
		w = 50,
		h = 50,
		l = 50
	}
    -- find the protector nodes
    local prots = minetest.find_nodes_in_area({
        x = pos.x - s.w,
        y = pos.y - s.h,
        z = pos.z - s.l
    }, {
        x = pos.x + s.w,
        y = pos.y + s.h,
        z = pos.z + s.l
    }, {"group:ship_protector"})

	local prot = nil
	for _, p in pairs(prots) do
		local ship_meta = minetest.get_meta(p)
		local size = {
			w = ship_meta:get_int("p_width") or 10, 
			l = ship_meta:get_int("p_length") or 10, 
			h = ship_meta:get_int("p_height") or 10,
		}
		if pos.x <= p.x + size.w and pos.x >= p.x - size.w then
			if pos.z <= p.z + size.l and pos.z >= p.z - size.l then
				if pos.y <= p.y + size.h and pos.y >= p.y - size.h then
					prot = p
				end
			end
		end
		if prot ~= nil then
			break
		end
	end

	return prot
end

local function do_repair(pos)
    local meta = minetest.get_meta(pos)
    if meta:get_string("node_damage_list") == nil then
        minetest.log("node_damage_list is null!")
        return
    end
    local node_damage_list = minetest.deserialize(meta:get_string("node_damage_list"))
    if node_damage_list and #node_damage_list > 0 then
        local node_damage = table.remove(node_damage_list)
		local node_pos = vector.add(pos, node_damage.pos)

        minetest.set_node(node_pos, {name = node_damage.name})
    
	    meta:set_string("node_damage_list", minetest.serialize(node_damage_list))
    end
end

----------------------------------------------------

function ship_repair.register_repair_box(custom_data)

    local data = custom_data or {}

    data.tube = 1
    data.speed = custom_data.speed or 1
    data.demand = custom_data.demand or {200, 180, 150}
    data.tier = (custom_data and custom_data.tier) or "LV"
    data.typename = (custom_data and custom_data.typename) or "repair_box"
    data.modname = (custom_data and custom_data.modname) or "ship_repair"
    data.machine_name = (custom_data and custom_data.machine_name) or string.lower(data.tier) ..
                            "_station_base"
    data.machine_desc = (custom_data and custom_data.machine_desc) or "Ship Repair Box"

    local tier = data.tier
    local ltier = string.lower(tier)
    local modname = data.modname
    local machine_name = data.machine_name
    local machine_desc = tier .. " " .. data.machine_desc
    local lmachine_name = string.lower(machine_name)
    local node_name = modname .. ":" .. machine_name

    local groups = {
        cracky = 2,
        technic_machine = 1,
        ["technic_" .. ltier] = 1,
        ctg_machine = 1,
        metal = 1,
        ship_machine = 1,
        ship_repair_box = 1
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

    local tube = {
        input_inventory = 'dst',
        insert_object = function(pos, node, stack, direction)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            local added = nil
            added = inv:add_item("src", stack)
            return added
        end,
        can_insert = function(pos, node, stack, direction)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            return inv:room_for_item("src", stack)
            --return false
        end,
        connect_sides = {
            --left = 1,
            --right = 1,
            --back = 1,
            top = 1,
            bottom = 1,
        }
    }

    if data.can_insert then
        tube.can_insert = data.can_insert
    end
    if data.insert_object then
        tube.insert_object = data.insert_object
    end

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
            if meta:get_int("src_time") < round(time_scl * 10) then
                meta:set_int("src_time", meta:get_int("src_time") + round(data.speed * 10))
            end
        end
        while true do
            local enabled = meta:get_int("enabled") == 1
            if not enabled then
                meta:set_int(tier .. "_EU_demand", 0)
                technic.swap_node(pos, machine_node)
                return
            end

            meta:set_int(tier .. "_EU_demand", machine_demand_active[1])

            if not powered then
                meta:set_string("infotext", machine_desc_tier .. S(" - Not Powered"))
                technic.swap_node(pos, machine_node)
                return
            end

            meta:set_string("infotext", machine_desc_tier .. S(" - Online"))
            technic.swap_node(pos, machine_node .. "_active")

            if (meta:get_int("src_time") < round(time_scl * 10)) then
                break
            end

            local ship = find_ship_protect(pos)
            if ship then
                do_repair(ship)
            end

            meta:set_int("src_time", 0)
            break
        end
    end
    
    local on_receive_fields = function(pos, formname, fields, sender)
        local meta = minetest.get_meta(pos)
        if fields.quit then
            return
        end
        local enabled = meta:get_int("enabled")
        if fields.toggle then
            if enabled >= 1 then
                meta:set_int("enabled", 0)
            else
                meta:set_int("enabled", 1)
            end
        end
        local formspec = update_formspec(meta, data)
        meta:set_string("formspec", formspec)
    end

    minetest.register_node(node_name, {
        description = machine_desc,
        tiles = {
            "ctg_lv_repair_bay_top.png" .. tube_entry_metal,
            "ctg_lv_repair_bay_top.png" .. tube_entry_metal,
            "ctg_lv_repair_bay_side.png",
            "ctg_lv_repair_bay_side.png",
            "ctg_lv_repair_bay_side.png",
            "ctg_lv_repair_bay_side.png"
        },
        param = "light",
        paramtype2 = "facedir",
        light_source = 3,
        drop = node_name,
        groups = groups,
        tube = data.tube and tube or nil,
        connect_sides = data.connect_sides or connect_default,
        legacy_facedir_simple = true,
        drawtype = "nodebox",
        paramtype = "light",

        node_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5}, -- base
                {-0.5, -0.25, -0.5, -0.3125, 0.375, -0.3125}, -- p1
                {-0.5, -0.25, 0.3125, -0.3125, 0.375, 0.5}, -- p2
                {0.3125, -0.25, 0.3125, 0.5, 0.375, 0.5}, -- p3
                {0.3125, -0.25, -0.5, 0.5, 0.375, -0.3125}, -- p4
                {-0.375, -0.25, -0.375, 0.375, 0.375, 0.375}, -- mid_base
                {-0.4375, -0.125, -0.4375, 0.4375, -0.0625, 0.4375}, -- mid1
                {-0.4375, 0.0625, -0.4375, 0.4375, 0.125, 0.4375}, -- mid2
                {-0.4375, 0.25, -0.4375, 0.4375, 0.3125, 0.4375}, -- mid3
                {-0.5, 0.375, -0.5, 0.5, 0.5, 0.5}, -- top
            }
        },
        selection_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, -- col_base
            }
        },

        sounds = default.node_sound_metal_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            if data.tube then
                pipeworks.after_place(pos)
            end
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", machine_desc)
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            if data.tube then
                pipeworks.after_dig(pos)
            end
            return technic.machine_after_dig_node
        end,
        can_dig = technic.machine_can_dig,
        allow_metadata_inventory_put = technic.machine_inventory_put,
        allow_metadata_inventory_take = technic.machine_inventory_take,
        allow_metadata_inventory_move = technic.machine_inventory_move,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            meta:set_int("enabled", 0)            
            meta:set_int("tube_time", 0)
            local inv = meta:get_inventory()
            inv:set_size("src", 12)
            local formspec = update_formspec(meta, data)
            meta:set_string("formspec", formspec)
            meta:set_int("input_valid", 0)
            meta:set_int("output_count", 0)
            meta:set_int("output_max", data.produced or 1)
        end,

        on_punch = function(pos, node, puncher)
        end,

        technic_run = run,
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

    minetest.register_node(node_name .. "_active", {
        description = machine_desc,
        tiles = {
            "ctg_lv_repair_bay_top.png" .. tube_entry_metal,
            "ctg_lv_repair_bay_top.png" .. tube_entry_metal,
            "ctg_lv_repair_bay_side.png",
            "ctg_lv_repair_bay_side.png",
            "ctg_lv_repair_bay_side.png",
            "ctg_lv_repair_bay_side.png"
        },
        param = "light",
        paramtype2 = "facedir",
        light_source = 4,
        drop = node_name,
        groups = active_groups,
        tube = data.tube and tube or nil,
        connect_sides = data.connect_sides or connect_default,
        legacy_facedir_simple = true,
        drawtype = "nodebox",
        paramtype = "light",
        
        node_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5}, -- base
                {-0.5, -0.25, -0.5, -0.3125, 0.375, -0.3125}, -- p1
                {-0.5, -0.25, 0.3125, -0.3125, 0.375, 0.5}, -- p2
                {0.3125, -0.25, 0.3125, 0.5, 0.375, 0.5}, -- p3
                {0.3125, -0.25, -0.5, 0.5, 0.375, -0.3125}, -- p4
                {-0.375, -0.25, -0.375, 0.375, 0.375, 0.375}, -- mid_base
                {-0.4375, -0.125, -0.4375, 0.4375, -0.0625, 0.4375}, -- mid1
                {-0.4375, 0.0625, -0.4375, 0.4375, 0.125, 0.4375}, -- mid2
                {-0.4375, 0.25, -0.4375, 0.4375, 0.3125, 0.4375}, -- mid3
                {-0.5, 0.375, -0.5, 0.5, 0.5, 0.5}, -- top
            }
        },
        selection_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, -- col_base
            }
        },

        sounds = default.node_sound_metal_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            if data.tube then
                pipeworks.after_dig(pos)
            end
            return technic.machine_after_dig_node
        end,
        can_dig = technic.machine_can_dig,
        allow_metadata_inventory_put = technic.machine_inventory_put,
        allow_metadata_inventory_take = technic.machine_inventory_take,
        allow_metadata_inventory_move = technic.machine_inventory_move,
        on_construct = function(pos)
        end,

        on_punch = function(pos, node, puncher)
        end,

        technic_run = run,
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

    technic.register_machine(tier, node_name, technic.receiver)
    technic.register_machine(tier, node_name .. "_active", technic.receiver)
end

ship_repair.register_repair_box({
    tier = "LV",
    demand = {5000, 4800, 4500},
    speed = 1,
});
