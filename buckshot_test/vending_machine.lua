
local vendor_capacity = 24

-- temporary pos store
local player_pos = {}

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function get_shelf_formspec(pos)
    local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local inv_size = inv:get_size('main') or 4
    local locked = meta:get_int("locked") > 0
	return "size[8,9.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[0,-0.1;Food Vendor Storage]"..
        "checkbox[6.5,-0.25;locked;Locked;"..tostring(locked).."]"..
		"list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";main;"..((math.abs((inv_size / 4) - 10) / 3)-0.35)..",0.75;"..(inv_size / 4)..",4;]"..
		"list[current_player;main;0,5.25;8,1;]"..
		"list[current_player;main;0,6.5;8,3;8]"..
		"listring[nodemeta:"..pos.x..","..pos.y..","..pos.z..";main]"..
		"listring[current_player;main]"
end

local function rightclick(pos, clicker, n)
	if n == 1 then
		local meta = minetest.get_meta(pos)
		local name = clicker:get_player_name()
        local locked = meta:get_int("locked") == 1
		local is_protected = locked and core.is_protected(pos, name);
		if meta and not is_protected then
			--minetest.show_formspec(name, "buckshot_test:vendor_form", get_shelf_formspec(pos))
		end
	elseif n == 2 then
		pos = vector.subtract(pos, {x=0,y=1,z=0})
		local node = core.get_node(pos)
		--local adef = core.registered_nodes[node.name]
		local meta = minetest.get_meta(pos)
		local name = clicker:get_player_name()
		--adef.on_rightclick(pos, node, clicker, nil, nil)
        local locked = meta:get_int("locked") == 1
        local is_protected = locked and core.is_protected(pos, name);
		if meta and not is_protected then
            player_pos[name] = pos
			minetest.show_formspec(name, "buckshot_test:vendor_form", get_shelf_formspec(pos))
		end
	end
    return nil
end

local function check_for_ceiling(pointed_thing)
	if pointed_thing.above.x == pointed_thing.under.x
	  and pointed_thing.above.z == pointed_thing.under.z
	  and pointed_thing.above.y < pointed_thing.under.y then
		return true
	end
end

local function check_for_floor(pointed_thing)
	if pointed_thing.above.x == pointed_thing.under.x
	  and pointed_thing.above.z == pointed_thing.under.z
	  and pointed_thing.above.y > pointed_thing.under.y then
		return true
	end
end

local function update_shelf(pos, listname, index, stack, player)

	local pos_btm = pos;
	local pos_top = vector.add(pos, {x=0,y=1,z=0})

	local node = core.get_node(pos)
	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	
	local count = 0
	for i = 1, inv:get_size("main") do
		local stk = inv:get_stack("main", i)
		if stk and stk:get_count() > 0 then
			count = count + 1
		end
	end

	if count >= 20 then
		core.swap_node(pos_top, { name = "buckshot_test:vending_machine_top_full", param2 = node.param2 })
		core.swap_node(pos_btm, { name = "buckshot_test:vending_machine_bottom_full", param2 = node.param2 })
	elseif count >= 8 then
		core.swap_node(pos_top, { name = "buckshot_test:vending_machine_top_fullish", param2 = node.param2 })
		core.swap_node(pos_btm, { name = "buckshot_test:vending_machine_bottom_fullish", param2 = node.param2 })
	elseif count > 0 then
		core.swap_node(pos_top, { name = "buckshot_test:vending_machine_top_emptyish", param2 = node.param2 })
		core.swap_node(pos_btm, { name = "buckshot_test:vending_machine_bottom_emptyish", param2 = node.param2 })
	elseif count == 0 then
		core.swap_node(pos_top, { name = "buckshot_test:vending_machine_top_empty", param2 = node.param2 })
		core.swap_node(pos_btm, { name = "buckshot_test:vending_machine_bottom_empty", param2 = node.param2 })
	else
		core.swap_node(pos_top, { name = "buckshot_test:vending_machine_top", param2 = node.param2 })
		core.swap_node(pos_btm, { name = "buckshot_test:vending_machine_bottom", param2 = node.param2 })
	end
end

local function on_construct(pos, player)
	-- Initialize inventory
	local meta = core.get_meta(pos)
    meta:set_string("owner", player)
    meta:set_int("locked", 0)
	local inv = meta:get_inventory()
	inv:set_size("main", vendor_capacity or 6)
	-- Initialize formspec
	meta:set_string("formspec", get_shelf_formspec(pos))
end
    
local function create_vendor(itemstack, placer, pointed_thing, n)
	local mod = "buckshot_test:"
	local name = "vending_machine"

	local above = pointed_thing.above
	local anode = core.get_node(above)
	local adef = core.registered_nodes[anode.name]

	--local under = pointed_thing.under
	--local unode = core.get_node(under)
	--local udef = core.registered_nodes[unode.name]

	local under1 = vector.subtract(pointed_thing.under, {x=0,y=2,z=0})
	local node_1 = core.get_node(under1)
	local udef_1 = core.registered_nodes[node_1.name]

	local pos
	if adef and adef.buildable_to and check_for_floor(pointed_thing) then
		pos = above
	elseif udef_1 and udef_1.buildable_to and check_for_ceiling(pointed_thing) then
		pos = under1
	--elseif udef and udef.buildable_to then -- this doesn't matter since we are two node tall
	--	pos = under
	else
		pos = above
	end

	local player_name = placer and placer:get_player_name() or ""
	local is_protected = core.is_protected(pos, player_name);
	local protect_bypass = core.check_player_privs(player_name, "protection_bypass")

	if is_protected and not protect_bypass then
		core.record_protection_violation(pos, player_name)
		return itemstack
	end

	local node_def = core.registered_nodes[core.get_node(pos).name]
	if not node_def or not node_def.buildable_to then
		return itemstack
	end

	local face_dir = core.dir_to_facedir(placer:get_look_dir()) or 0
	local dir = placer and placer:get_look_dir() and face_dir
	local toppos = vector.add(pos, {x=0,y=1,z=0})
	is_protected = core.is_protected(toppos, player_name);

	if is_protected and not protect_bypass then
		core.record_protection_violation(toppos, player_name)
		return itemstack
	end

	local botdef = core.registered_nodes[core.get_node(toppos).name]
	if not botdef or not botdef.buildable_to then
		return itemstack
	end

	core.set_node(pos, { name = mod .. name .. "_bottom_empty", param2 = dir })
	core.set_node(toppos, { name = mod .. name .. "_top_empty", param2 = dir })

	on_construct(pos, player_name)

	if not core.is_creative_enabled(player_name) then
		itemstack:take_item()
	end
	return itemstack
end

local function destruct_vendor(pos, n)
	local other
	if n == 2 then
		local dir = {x=0,y=1,z=0}
		other = vector.subtract(pos, dir)
	elseif n == 1 then
		local dir = {x=0,y=1,z=0}
		other = vector.add(pos, dir)
	end
	if other then
		core.remove_node(other)
	end
end

-- check formspec buttons or when name entered
minetest.register_on_player_receive_fields(function(player, formname, fields)

    if formname ~= "buckshot_test:vendor_form" then
        return
    end

    local name = player:get_player_name()
    local pos = player_pos[name]

    if not name or not pos then
        return
    end

    -- reset formspec until close button pressed
    if (fields.close_me or fields.quit) then
        return
    end

    local meta = core.get_meta(pos)
    local locked = meta:get_int("locked")
    if fields.locked or fields.locked ~= nil then
        if locked == 1 then
            locked = 0
        else
            locked = 1
        end
        meta:set_int("locked", locked)
    end
    meta:set_string("formspec", get_shelf_formspec(pos, meta))

    minetest.show_formspec(name, formname, get_shelf_formspec(pos))
end)

local vending_def_top = {
	description = S("Snack Machine"),
	tiles = {
		"vending_machine_top.png",
		"vending_machine_top.png^[transformFY",
		"vending_machine_side_2.png^[transformFX",
		"vending_machine_side_2.png",
		"vending_machine_back_2.png",
		"vending_machine_front_2.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
    paramtype2 = "facedir",
    groups = {
        cracky = 3,
        level = 2,
        metal = 1,
		not_in_creative_inventory = 1
	},
	light_source = 3,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.3125, 0.5, 0.203125, 0.5},
		}
	},
    --[[selection_box = {
        type = "fixed",
        fixed = {
            {-0.5, -1.5, -0.3125, 0.5, 0.203125, 0.5},
        }
    },]]
    is_ground_content = false,
    drop = "buckshot_test:vending_machine_bottom",
    sounds = default.node_sound_metal_defaults(),
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		return rightclick(pos, clicker, 2)
	end,
	on_rotate = screwdriver.disallow,
	on_place = function(itemstack, placer, pointed_thing)
		return create_vendor(itemstack, placer, pointed_thing, 2)
	end,
    after_dig_node = function(pos, oldnode, oldmetadata, digger) 
		destruct_vendor(pos, 2)
	end,
	on_dig = function(pos, node, digger)
    	local drop = "buckshot_test:vending_machine_bottom"
		local o_pos = pos
		pos = vector.subtract(pos, {x=0,y=1,z=0})
		if string.find(core.get_node(pos).name, drop) then
			-- Pop-up items
			minetest.add_item(pos, drop)
			local meta = minetest.get_meta(pos)
			local list = meta:get_inventory():get_list("main")
			for _,item in pairs(list) do
				local drop_pos = {
					x=math.random(pos.x - 0.5, pos.x + 0.5),
					y=math.random(pos.y - 0.0, pos.x + 0.5),
					z=math.random(pos.z - 0.5, pos.z + 0.5)}
				minetest.add_item(pos, item:to_string())
			end
			-- Remove node
			minetest.remove_node(o_pos)
			destruct_vendor(o_pos, 2)
		else 
			minetest.remove_node(o_pos)
		end
	end,
	on_blast = function(pos)
		pos = vector.subtract(pos, {x=0,y=1,z=0})
    	local drop = "buckshot_test:vending_machine_bottom"
		minetest.add_item(pos, drop)
		local meta = minetest.get_meta(pos)
		local list = meta:get_inventory():get_list("main")
		if list then
			for _,item in pairs(list) do
				local drop_pos = {x=math.random(pos.x - 0.5, pos.x + 0.5), y=pos.y, z=math.random(pos.z - 0.5, pos.z + 0.5)}
				minetest.add_item(pos, item:to_string())
			end
		end
		minetest.remove_node(pos)
		destruct_vendor(pos, 2)
		return nil
	end,
}

local vending_def_bottom = {
	description = S("Snack Machine"),
	tiles = {
		"vending_machine_top.png",
		"vending_machine_top.png^[transformFY",
		"vending_machine_side_1.png^[transformFX",
		"vending_machine_side_1.png",
		"vending_machine_back_1.png",
		"vending_machine_front_1.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
    paramtype2 = "facedir",
    groups = {
        cracky = 3,
        level = 2,
        metal = 1,
    },
	light_source = 3,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.4375, -0.3125, 0.5, 0.5, 0.5}, -- NodeBox7
			{-0.4375, -0.5, -0.25, 0.4375, -0.4375, 0.5}, -- NodeBox8
		}
	},
    selection_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.3125, 0.5, 1.203125, 0.5},
        }
    },
    is_ground_content = false,
    drop = "buckshot_test:vending_machine_bottom",
	sounds = default.node_sound_metal_defaults(),
	--[[on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		rightclick(pos, clicker, 1)
		return nil
	end,]]
	on_rotate = screwdriver.disallow,
	on_construct = function(pos) 
		return on_construct(pos)
	end,
	on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local def = minetest.registered_nodes[node.name]
		if def and def.on_rightclick and
			not (placer and placer:is_player() and
			placer:get_player_control().sneak) then
			return def.on_rightclick(under, node, placer, itemstack,
				pointed_thing) or itemstack
		end
		return create_vendor(itemstack, placer, pointed_thing, 1)
	end,
    after_dig_node = function(pos, oldnode, oldmetadata, digger) 
		destruct_vendor(pos, 1)
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index,
			to_list, to_index, count, player)
        local meta = core.get_meta(pos)
        local locked = meta:get_int("locked") == 1
		if locked and minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		return count
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        local meta = core.get_meta(pos)
        local locked = meta:get_int("locked") == 1
		if locked and minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		local stackname = stack:get_name()
		local is_comsumable = minetest.get_item_group(stackname, "hunger_amount") or 0
		local is_food = minetest.get_item_group(stackname, "food") or 0
		local is_drink = minetest.get_item_group(stackname, "drink") or 0
		if is_comsumable == 0 and is_food == 0 and is_drink == 0 then
			return 0
		end
		return stack:get_count()
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        local meta = core.get_meta(pos)
        local locked = meta:get_int("locked") == 1
		if locked and minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		return stack:get_count()
	end,
	on_metadata_inventory_put = update_shelf,
	on_metadata_inventory_take = update_shelf,
	on_dig = function(pos, node, digger)
		local drop = "buckshot_test:vending_machine_bottom"
		-- Pop-up items
		minetest.add_item(pos, drop)
		local meta = minetest.get_meta(pos)
		local list = meta:get_inventory():get_list("main")
		if list then
			for _,item in pairs(list) do
				local drop_pos = {
					x=math.random(pos.x - 0.5, pos.x + 0.5),
					y=math.random(pos.y - 0.0, pos.x + 0.5),
					z=math.random(pos.z - 0.5, pos.z + 0.5)}
				minetest.add_item(pos, item:to_string())
			end
		end
		-- Remove node
		minetest.remove_node(pos)
		destruct_vendor(pos, 1)
	end,
	on_blast = function(pos)
    	local drop = "buckshot_test:vending_machine_bottom"
		minetest.add_item(pos, drop)
		local meta = minetest.get_meta(pos)
		local list = meta:get_inventory():get_list("main")
		if list then
			for _,item in pairs(list) do
				local drop_pos = {x=math.random(pos.x - 0.5, pos.x + 0.5), y=pos.y, z=math.random(pos.z - 0.5, pos.z + 0.5)}
				minetest.add_item(pos, item:to_string())
			end
		end
		-- Remove node
		minetest.remove_node(pos)
		destruct_vendor(pos, 1)
		return nil
	end,
    on_receive_fields = function(pos, formname, fields, sender)
        if fields.quit then
            return
        end
        local meta = core.get_meta(pos)
        local locked = meta:get_int("locked")
        if fields.locked or fields.locked ~= nil then
            if locked == 1 then
                locked = 0
            else
                locked = 1
            end
            meta:set_int("locked", locked)
        end
        meta:set_string("formspec", get_shelf_formspec(pos, meta))
    end,
}

local vending_def_top_1 = deepcopy(vending_def_top)
local vending_def_top_2 = deepcopy(vending_def_top)
local vending_def_top_3 = deepcopy(vending_def_top)
local vending_def_top_4 = deepcopy(vending_def_top)

vending_def_top_1.tiles = {
	"vending_machine_top.png",
	"vending_machine_top.png^[transformFY",
	"vending_machine_side_2.png^[transformFX",
	"vending_machine_side_2.png",
	"vending_machine_back_2.png",
	"vending_machine_front_2_full.png"
}
vending_def_top_1.light_source = 3
vending_def_top_2.tiles = {
	"vending_machine_top.png",
	"vending_machine_top.png^[transformFY",
	"vending_machine_side_2.png^[transformFX",
	"vending_machine_side_2.png",
	"vending_machine_back_2.png",
	"vending_machine_front_2_fullish.png"
}
vending_def_top_2.light_source = 2
vending_def_top_3.tiles = {
	"vending_machine_top.png",
	"vending_machine_top.png^[transformFY",
	"vending_machine_side_2.png^[transformFX",
	"vending_machine_side_2.png",
	"vending_machine_back_2.png",
	"vending_machine_front_2_empty.png"
}
vending_def_top_3.light_source = 2
vending_def_top_4.tiles = {
	"vending_machine_top.png",
	"vending_machine_top.png^[transformFY",
	"vending_machine_side_2.png^[transformFX",
	"vending_machine_side_2.png",
	"vending_machine_back_2.png",
	"vending_machine_front_2_emptied.png"
}
vending_def_top_4.light_source = 1

local vending_def_bottom_1 = deepcopy(vending_def_bottom)
local vending_def_bottom_2 = deepcopy(vending_def_bottom)
local vending_def_bottom_3 = deepcopy(vending_def_bottom)
local vending_def_bottom_4 = deepcopy(vending_def_bottom)

vending_def_bottom_1.tiles = {
	"vending_machine_top.png",
	"vending_machine_top.png^[transformFY",
	"vending_machine_side_1.png^[transformFX",
	"vending_machine_side_1.png",
	"vending_machine_back_1.png",
	"vending_machine_front_1_full.png"
}
vending_def_bottom_1.light_source = 3
vending_def_bottom_1.groups.not_in_creative_inventory = 1
vending_def_bottom_2.tiles = {
	"vending_machine_top.png",
	"vending_machine_top.png^[transformFY",
	"vending_machine_side_1.png^[transformFX",
	"vending_machine_side_1.png",
	"vending_machine_back_1.png",
	"vending_machine_front_1_fullish.png"
}
vending_def_bottom_2.light_source = 2
vending_def_bottom_2.groups.not_in_creative_inventory = 1
vending_def_bottom_3.tiles = {
	"vending_machine_top.png",
	"vending_machine_top.png^[transformFY",
	"vending_machine_side_1.png^[transformFX",
	"vending_machine_side_1.png",
	"vending_machine_back_1.png",
	"vending_machine_front_1_empty.png"
}
vending_def_bottom_3.light_source = 2
vending_def_bottom_3.groups.not_in_creative_inventory = 1
vending_def_bottom_4.tiles = {
	"vending_machine_top.png",
	"vending_machine_top.png^[transformFY",
	"vending_machine_side_1.png^[transformFX",
	"vending_machine_side_1.png",
	"vending_machine_back_1.png",
	"vending_machine_front_1_emptied.png"
}
vending_def_bottom_4.light_source = 1
vending_def_bottom_4.groups.not_in_creative_inventory = 1

minetest.register_node("buckshot_test:vending_machine_top", vending_def_top)
minetest.register_node("buckshot_test:vending_machine_top_full", vending_def_top_1)
minetest.register_node("buckshot_test:vending_machine_top_fullish", vending_def_top_2)
minetest.register_node("buckshot_test:vending_machine_top_emptyish", vending_def_top_3)
minetest.register_node("buckshot_test:vending_machine_top_empty", vending_def_top_4)

minetest.register_node("buckshot_test:vending_machine_bottom", vending_def_bottom)
minetest.register_node("buckshot_test:vending_machine_bottom_full", vending_def_bottom_1)
minetest.register_node("buckshot_test:vending_machine_bottom_fullish", vending_def_bottom_2)
minetest.register_node("buckshot_test:vending_machine_bottom_emptyish", vending_def_bottom_3)
minetest.register_node("buckshot_test:vending_machine_bottom_empty", vending_def_bottom_4)