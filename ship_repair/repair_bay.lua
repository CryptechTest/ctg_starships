local S = minetest.get_translator(minetest.get_current_modname())

local time_scl = 20

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

-- Fill a list with data for content IDs, after all nodes are registered
local cid_data = {}
minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_nodes) do
		cid_data[minetest.get_content_id(name)] = {
			name = name,
			drops = def.drops,
		}
	end
end)

----------------------------------------------------
----------------------------------------------------
----------------------------------------------------

local function update_formspec(pos, data)
    local meta = minetest.get_meta(pos)
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

        local percent = 0
        if meta:get_int("src_time") then
            percent = (meta:get_int("src_time") / round(time_scl * 10)) * 100
        end
        local progress_time = "image[5.45,4.5;2.9,1;ctg_gui_progress_bar_bg2.png^[lowpart:" .. tostring(percent) .. ":ctg_gui_progress_bar_fg2.png^[transformR270]]"

        local regen_tick_max = 0
        if ltier == "lv" then
            regen_tick_max = 400
        elseif ltier == "mv" then
            regen_tick_max = 300
        elseif  ltier == "hv" then
            regen_tick_max = 240
        end
        local percent2 = 0
        if meta:get_int("regen_tick") then
            percent2 = ((regen_tick_max - meta:get_int("regen_tick")) / regen_tick_max) * 100
        end
        local progress_tick = "image[5.45,4.8;2.9,1;ctg_gui_progress_bar_bg.png^[lowpart:" .. tostring(percent2) .. ":ctg_gui_progress_bar_fg.png^[transformR270]]"

        local label = "label[0,3.0;Materials Required]"

        formspec = "size[8,10;]" ..
                    "list[".."current_name"..";src;0,1;8,2;]" .. "list[current_player;main;0,6;8,4;]" ..
                    "list[current_name;ship_repair_inv;0,3.5;5,2;]" .. "label[0,0;" .. machine_desc:format(tier) .. "]" ..
                    "listring[".."current_name"..";src]" .. "listring[current_player;main]" ..
                    "button[5.5,3.5;2.5,1;toggle;" .. btnName .. "]" .. label .. progress_time .. progress_tick
    end
    return formspec
end

----------------------------------------------------

local function spawn_particle_repair(pos, tier)
    local def = {
        amount = 13,
        time = 0.4,
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        vertical = false,

        texture = {
            name = "ctg_" .. tier .. "_repair_effect.png",
            alpha_tween = {1, 0.2},
            scale_tween = {{
                x = 4,
                y = 4
            }, {
                x = 0,
                y = 0
            }},
            blend = "alpha"
        },
        glow = 12,

        minpos = {
            x = pos.x + -0.6,
            y = pos.y + -0.6,
            z = pos.z + -0.6
        },
        maxpos = {
            x = pos.x + 0.6,
            y = pos.y + 0.6,
            z = pos.z + 0.6
        },
        minvel = {
            x = -0.1,
            y = -0.15,
            z = -0.1
        },
        maxvel = {
            x = 0.1,
            y = 0.15,
            z = 0.1
        },
        minacc = {
            x = -0.75,
            y = -0.5,
            z = -0.75
        },
        maxacc = {
            x = 0.75,
            y = 0.5,
            z = 0.75
        },
        minexptime = 1.0,
        maxexptime = 1.7,
        minsize = 0.8,
        maxsize = 1.2
    }

    minetest.add_particlespawner(def);
end

----------------------------------------------------
----------------------------------------------------

local function is_atmos_node(name)
    if name == "air" then
        return true
    elseif name == "vacuum:vacuum" then
        return true
    elseif name == "vacuum:atmos_thin" then
        return true
    elseif name == "vacuum:atmos_thick" then
        return true
    elseif name == "asteroid:atmos" then
        return true
    end
    return false
end

local function is_atmos(cid)
    if cid == minetest.CONTENT_AIR then
        return true
    elseif cid == minetest.get_content_id("vacuum:vacuum") then
        return true
    elseif cid == minetest.get_content_id("vacuum:atmos_thin") then
        return true   
    elseif cid == minetest.get_content_id("vacuum:atmos_thick") then
        return true     
    elseif cid == minetest.get_content_id("asteroid:atmos") then
        return true
    end
    return false
end

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

local function update_get_ship_protect(pos) 
    local meta = minetest.get_meta(pos)
    local tick = meta:get_int("ship_pos_tick") or 0
    if tick <= 0 then
        tick = 30
    else
        tick = tick - 1
    end
    meta:set_int("ship_pos_tick", tick)
    local ship = nil
    if tick <= 0 then
        ship = find_ship_protect(pos)
        meta:set_string("ship_pos", minetest.serialize(ship))
    else
        ship = minetest.deserialize(meta:get_string("ship_pos"))
    end
    return ship
end

local function detect_resources_repair(pos)
    local meta = minetest.get_meta(pos)
    if meta:get_string("node_damage_list") == nil then
        minetest.log("node_damage_list is null!")
        return
    end
    local count = 0
    local materials = {}
    local node_damage_list = minetest.deserialize(meta:get_string("node_damage_list"))
    if node_damage_list and #node_damage_list > 0 then
        for _, node in ipairs(node_damage_list) do
            local name = node.name
            if node.drop and node.drop ~= '' then
                name = node.drop
            end
            if name then
                if not materials[name] then
                    materials[name] = 0
                end
                materials[name] = (materials[name] or 0) + 1
                count = count + 1
                if #materials >= 10 then
                    break;
                end
            end
        end
    end
    return materials
end

local function detect_resources(pos)
    --[[local shipp = find_ship_protect(pos)
    if shipp ~= nil then
        return nil
    end]]
    local ship_meta = minetest.get_meta(pos)
    local size = {
        w = ship_meta:get_int("p_width") or 10, 
        l = ship_meta:get_int("p_length") or 10, 
        h = ship_meta:get_int("p_height") or 10,
    }

	local vm1 = VoxelManip()
	local p1 = vector.subtract(pos, { x = size.w, y = size.h, z = size.l })
	local p2 = vector.add(pos, { x = size.w, y = size.h, z = size.l })
	local minp, maxp = vm1:read_from_map(p1, p2)
	local a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm1:get_data()
	local count = 0

    local materials = {}

	for z = pos.z - size.l, pos.z + size.l do
        for x = pos.x - size.w, pos.x + size.w do
		    for y = pos.y - size.h, pos.y + size.h do
                local vi = a:index(x, y, z)
				local cid = data[vi]
                count = count + 1
				if not is_atmos(cid) then
                    local def = cid_data[cid]
                    --table.insert(materials, {material = def.name, count = 1})
                    materials[def.name] = (materials[def.name] and materials[def.name] + 1) or 1
				end
			end
		end
	end

	--vm1:set_data(data)
	--vm1:write_to_map()

    local cnt = 0
    local mat_list = {}
    local top_materials = {}

    for m, c in pairs(materials) do table.insert(mat_list, {material = m, count = c}) end

    local function compare(a,b)
        return a.count > b.count
    end
    table.sort(mat_list, compare)
    
    for _, matc in pairs(mat_list) do
        top_materials[matc.material] = matc.count
        cnt = cnt + 1
        if cnt >= 10 then
            break;
        end
    end

    --minetest.log(dump(top_materials))
    return top_materials
end

local function get_material(items, name, take)
    if not items then
        return nil
    end
    local take_amount = 1;
    local taken = 0;
    local found = 0;
    local new_inputs = {}
    for i, stack in ipairs(items) do
        if stack:get_name() == name and stack:get_count() > 0 then
            local new_input = ItemStack(stack)
            if take and taken < take_amount then
                taken = taken + 1
                if new_input:get_count() == 1 then
                    new_input = nil
                else
                    new_input:take_item(1)
                end
            end
            if new_input then
                table.insert(new_inputs, new_input)
            end
            found = found + 1
        else
            table.insert(new_inputs, stack)
        end
    end
    if (found > 0) then
        return new_inputs
    else
        return nil
    end
end

local function repair_replace_node(pos, def)
    minetest.set_node(pos, {name = def.name, param1 = def.param1, param2 = def.param2})
    if def.meta then
        minetest.get_meta(pos):from_table(def.meta)
    end
    if def.invs then
        local inventory = minetest.get_meta(pos):get_inventory()
        for i, s in pairs(def.invs) do
            inventory:set_size(i, s)
            inventory:set_list(i, {})
        end
    end
    if def.tube then
        minetest.after(0, function()
            pipeworks.after_place(pos)
        end)
    end
end

local function do_repair(src, ship, count, tier)
    local meta = minetest.get_meta(src)
    local meta_ship = minetest.get_meta(ship)
    if meta_ship:get_string("node_damage_list") == nil then
        return
    end
    -- recent shield hit check
    local shield_hit = meta_ship:get_int("shield_hit")
    if shield_hit > 0 then
        return
    end
    local regened = 0
    -- get regen node from damage list
    local node_damage_list = minetest.deserialize(meta_ship:get_string("node_damage_list"))
    if node_damage_list and #node_damage_list > 0 then
        local d_count = #node_damage_list
        local skips = 0
        local inv = meta:get_inventory()
        for i = 0, count do
            -- get a node damage entry
            local node_damage = table.remove(node_damage_list, 1)
            if node_damage and node_damage.name then
                local cid = minetest.get_content_id(node_damage.name)
                local def = cid_data[cid]
                -- get material inputs
                local inputs = nil
                if node_damage.drop then
                    inputs = get_material(inv:get_list("src"), node_damage.drop, true)
                else
                    inputs = get_material(inv:get_list("src"), node_damage.name, true)
                end
                if inputs ~= nil and def then
                    local node_pos = vector.add(ship, node_damage.pos)
                    -- Set the node back to original state
                    repair_replace_node(node_pos, node_damage)
                    -- update the inputs inventory
                    inv:set_list("src", inputs)
                    -- add particle effects
                    spawn_particle_repair(src, tier)
                    spawn_particle_repair(ship, tier)
                    spawn_particle_repair(node_pos, tier)
                    regened = regened + 5
                elseif def then
                    table.insert(node_damage_list, node_damage)
                    i = i - 1
                    skips = skips + 1
                end
                if skips >= d_count then
                    break;
                end
                if #node_damage_list <= 0 then
                    break;
                end
            end
        end
        --meta:set_int("regen_tick", 50)
        meta_ship:set_string("node_damage_list", minetest.serialize(node_damage_list))
    end
    if regened > 0 then
        -- regen hp
        local ship_hp_max = meta_ship:get_int("hp_max") or 1
        local ship_hp = meta_ship:get_int("hp") or 1
        if tier == "lv" then
            ship_hp = ship_hp + regened + 5
        elseif tier == "mv" then
            ship_hp = ship_hp + regened + 6
        elseif  tier == "hv" then
            ship_hp = ship_hp + regened + 7
        end
        if ship_hp > ship_hp_max then
            ship_hp = ship_hp_max
        end
        meta_ship:set_int("hp", ship_hp)
    end
end

local function do_repair_regen(src, ship, tier)
    local meta = minetest.get_meta(src)
    -- regen tick
    local tick = meta:get_int("regen_tick") or 0
    tick = tick - round(math.random(1,2))
    if tick < 0 then
        if tier == "lv" then
            tick = 400
        elseif tier == "mv" then
            tick = 300
        elseif  tier == "hv" then
            tick = 240
        end
    end
    meta:set_int("regen_tick", tick)
    if tick > 0 then
        return
    end
    local meta_ship = minetest.get_meta(ship)
    if meta_ship:get_string("node_damage_list") == nil then
        return
    end
    -- recent shield hit check
    local shield_hit = meta_ship:get_int("shield_hit")
    if shield_hit > 0 then
        return
    end
    -- regen hp
    local ship_hp_max = meta_ship:get_int("hp_max") or 1000
	local ship_hp = meta_ship:get_int("hp") or 1000
    local count = 1
    if tier == "lv" then
        ship_hp = ship_hp + 40
        count = round(math.random(1,2))
    elseif tier == "mv" then
        ship_hp = ship_hp + 50
        count = 2
    elseif  tier == "hv" then
        ship_hp = ship_hp + 60
        count = 2
    end
    if ship_hp > ship_hp_max then
        ship_hp = ship_hp_max
    end
    meta_ship:set_int("hp", ship_hp)
    -- regen node from damage list
    local node_damage_list = minetest.deserialize(meta_ship:get_string("node_damage_list"))
    if node_damage_list and #node_damage_list > 0 then
        for i = 0, count do
            -- get a node damage entry
            local node_damage = table.remove(node_damage_list, 1)
            if node_damage and node_damage.name then
                local cid = minetest.get_content_id(node_damage.name)
                local def = cid_data[cid]
                local node_pos = vector.add(ship, node_damage.pos)
                if def then
                    -- Set the node back to original state
                    repair_replace_node(node_pos, node_damage)
                    -- add particle effects
                    spawn_particle_repair(src, tier)
                    spawn_particle_repair(ship, tier)
                    spawn_particle_repair(node_pos, tier)
                    if #node_damage_list <= 0 then
                        break;
                    end
                end
            end
        end
        meta_ship:set_string("node_damage_list", minetest.serialize(node_damage_list))
    end
end

local function show_repair(pos, ship)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local materials = detect_resources_repair(ship)
    --local rep = inv:get_list("ship_repair_inv")    
    local mats = {}
    for material, count in pairs(materials) do
        local stack = ItemStack(material)
        stack:set_count(count)
        table.insert(mats, stack)
    end
    inv:set_list("ship_repair_inv", mats)
    local ship_meta = minetest.get_meta(ship)
    local ship_hp_max = ship_meta:get_int("hp_max") or 1000
	local ship_hp = ship_meta:get_int("hp") or 1000
    return #mats > 0 or ship_hp < ship_hp_max
end

----------------------------------------------------
----------------------------------------------------
----------------------------------------------------

function ship_repair.register_repair_box(custom_data)

    local data = custom_data or {}

    data.tube = 1
    data.count = custom_data.count or 1
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
        source_inventory = 'src',
        input_inventory = 'src',
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
        local machine_demand_active = data.demand[1]
        local machine_demand_idle = data.demand[1] * 0.08

        -- Setup meta data if it does not exist.
        if not eu_input then
            meta:set_int(tier .. "_EU_demand", machine_demand_idle)
            meta:set_int(tier .. "_EU_input", 0)
            return
        end

        local powered = eu_input >= machine_demand_active or eu_input >= machine_demand_idle
        if powered then
            if meta:get_int("src_time") < round(time_scl * 10) then
                meta:set_int("src_time", meta:get_int("src_time") + round(data.speed * 10))
            end
        end
        while true do
            local enabled = meta:get_int("enabled") == 1

            meta:set_int(tier .. "_EU_demand", machine_demand_idle)

            if not powered then
                meta:set_string("infotext", machine_desc_tier .. S(" - Not Powered"))
                technic.swap_node(pos, machine_node)
                break
            end

            if not enabled then
                meta:set_string("infotext", machine_desc_tier .. S(" - Offline"))
                meta:set_int(tier .. "_EU_demand", 0)
                technic.swap_node(pos, machine_node)
                break
            end

            meta:set_string("infotext", machine_desc_tier .. S(" - Online"))

            local ship = update_get_ship_protect(pos)
            if ship then
                if not show_repair(pos, ship) then
                    meta:set_int("src_time", 0)
                    technic.swap_node(pos, machine_node)
                    break
                end
            end
            
            powered = eu_input >= machine_demand_active
            meta:set_int(tier .. "_EU_demand", machine_demand_active)
            if powered then
                meta:set_string("infotext", machine_desc_tier .. S(" - Active"))
                technic.swap_node(pos, machine_node .. "_active")
            end

            if ship and powered then
                do_repair_regen(pos, ship, ltier)
            end

            if meta:get_int("src_time") % 40 == 0 then
                local formspec = update_formspec(pos, data)
                meta:set_string("formspec", formspec)
            end

            if (meta:get_int("src_time") < round(time_scl * 10)) then
                break
            end

            if ship and powered then
                do_repair(pos, ship, data.count, ltier)
            end
            
            local formspec = update_formspec(pos, data)
            meta:set_string("formspec", formspec)

            meta:set_int("src_time", 0)
            break;
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
        local formspec = update_formspec(pos, data)
        meta:set_string("formspec", formspec)
    end
    
    local function inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
        if from_list == "ship_repair_inv" then
            return 0
        end
        if to_list == "ship_repair_inv" then
            return 0
        end
        return technic.machine_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
    end

    local function inventory_put(pos, listname, index, stack, player)
        if listname == "ship_repair_inv" then
            return 0
        end
        return technic.machine_inventory_put(pos, listname, index, stack, player)
    end

    local function inventory_take(pos, listname, index, stack, player)
        if listname == "ship_repair_inv" then
            return 0
        end
        return technic.machine_inventory_take(pos, listname, index, stack, player)
    end

    minetest.register_node(node_name, {
        description = machine_desc,
        tiles = {
            "ctg_"..ltier.."_repair_bay_top.png" .. tube_entry_metal,
            "ctg_repair_bay_bottom.png",
            "ctg_"..ltier.."_repair_bay_side.png",
            "ctg_"..ltier.."_repair_bay_side.png",
            "ctg_"..ltier.."_repair_bay_side.png",
            "ctg_"..ltier.."_repair_bay_side.png"
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
        allow_metadata_inventory_put = inventory_put,
        allow_metadata_inventory_take = inventory_take,
        allow_metadata_inventory_move = inventory_move,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            meta:set_string("ship_pos", minetest.serialize({}))
            meta:set_int("enabled", 1)
            meta:set_int("tube_time", 0)
            meta:set_int("regen_tick", 50)
            local inv = meta:get_inventory()
            inv:set_size("src", 16)
            inv:set_size("ship_repair_inv", 10)
            local formspec = update_formspec(pos, data)
            meta:set_string("formspec", formspec)
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
            "ctg_"..ltier.."_repair_bay_top.png" .. tube_entry_metal,
            "ctg_repair_bay_bottom.png",
            "ctg_"..ltier.."_repair_bay_side_active.png",
            "ctg_"..ltier.."_repair_bay_side_active.png",
            "ctg_"..ltier.."_repair_bay_side_active.png",
            "ctg_"..ltier.."_repair_bay_side_active.png"
        },
        param = "light",
        paramtype2 = "facedir",
        light_source = 6,
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
        allow_metadata_inventory_put = inventory_put,
        allow_metadata_inventory_take = inventory_take,
        allow_metadata_inventory_move = inventory_move,
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
    speed = 2,
    count = 3,
});
ship_repair.register_repair_box({
    tier = "MV",
    demand = {8000, 7800, 7500},
    speed = 3,
    count = 7,
});
ship_repair.register_repair_box({
    tier = "HV",
    demand = {10000, 9800, 9500},
    speed = 5,
    count = 10,
});
