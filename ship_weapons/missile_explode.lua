-- Load support for MT game translation.
local S = minetest.get_translator("ship_weapons")

-- loss probabilities array (one in X will be lost)
local loss_prob = {}

loss_prob["default:cobble"] = 3
loss_prob["default:dirt"] = 4

-- Fill a list with data for content IDs, after all nodes are registered
local cid_data = {}
minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_nodes) do
		cid_data[minetest.get_content_id(name)] = {
			name = name,
			groups = def.groups,
			drop = def.drop,
			drops = def.drops,
			flammable = def.groups.flammable,
			on_blast = def.on_blast,
			tube = (def.tube ~= nil and true) or false,
		}
	end
end)

local function is_atmos(name)
    if name == "air" then
        return true
    elseif name == "vacuum:vacuum" then
        return true
    elseif name == "vacuum:atmos_thin" then
        return true   
    elseif name == "vacuum:atmos_thick" then
        return true     
    elseif name == ":asteroid:atmos" then
        return true
    end
    return false
end

local function rand_pos(center, pos, radius)
	local def
	local reg_nodes = minetest.registered_nodes
	local i = 0
	repeat
		-- Give up and use the center if this takes too long
		if i > 4 then
			pos.x, pos.z = center.x, center.z
			break
		end
		pos.x = center.x + math.random(-radius, radius)
		pos.z = center.z + math.random(-radius, radius)
		def = reg_nodes[minetest.get_node(pos).name]
		i = i + 1
	until def and not def.walkable
end

local function eject_drops(drops, pos, radius)
	local drop_pos = vector.new(pos)
	for _, item in pairs(drops) do
		local count = math.min(item:get_count(), item:get_stack_max())
		while count > 0 do
			local take = math.max(1,math.min(radius * radius,
					count,
					item:get_stack_max()))
			rand_pos(pos, drop_pos, radius)
			local dropitem = ItemStack(item)
			dropitem:set_count(take)
			local obj = minetest.add_item(drop_pos, dropitem)
			if obj then
				obj:get_luaentity().collect = true
				obj:set_acceleration({x = 0, y = -10, z = 0})
				obj:set_velocity({x = math.random(-3, 3),
						y = math.random(0, 10),
						z = math.random(-3, 3)})
			end
			count = count - take
		end
	end
end

local function add_drop(drops, item)
	item = ItemStack(item)
	local name = item:get_name()
	if loss_prob[name] ~= nil and math.random(1, loss_prob[name]) == 1 then
		return
	end

	local drop = drops[name]
	if drop == nil then
		drops[name] = item
	else
		drop:set_count(drop:get_count() + item:get_count())
	end
end

local basic_flame_on_construct -- cached value
local function destroy(drops, npos, cid, c_air, c_fire, on_blast_queue, on_construct_queue, ignore_protection, ignore_on_blast, owner)
	if not ignore_protection and minetest.is_protected(npos, owner) then
		return cid
	end

	local def = cid_data[cid]

	if not def then
		return c_air
	elseif not ignore_on_blast and def.on_blast then
		on_blast_queue[#on_blast_queue + 1] = {
			pos = vector.new(npos),
			on_blast = def.on_blast
		}
		return cid
	elseif def.flammable then
		on_construct_queue[#on_construct_queue + 1] = {
			fn = basic_flame_on_construct,
			pos = vector.new(npos)
		}
		return c_fire
    elseif is_atmos(def.name) then
        return c_air
	else
		local node_drops = minetest.get_node_drops(def.name, "")
		for _, item in pairs(node_drops) do
			add_drop(drops, item)
		end
		return c_air
	end
end

local function destroy_safe(drops, npos, cid, c_air, c_fire, on_blast_queue, on_construct_queue, ignore_protection, ignore_on_blast, owner)
	local def = cid_data[cid]
	local stor = {
		pos = npos,
		name = def.name,
		param1 = nil,
		param2 = nil,
		tube = def.tube,
		meta = {}
	}

	if def.groups['not_in_creative_inventory'] then
		if def.drop then
			stor.name = def.drop
		end
	end

	local function get_stor(npos, sto)
		local node = minetest.get_node(npos)
		sto.param1 = node.param1 ~= 0 and node.param1 or nil
		sto.param2 = node.param2 ~= 0 and node.param2 or nil
		sto.meta = minetest.get_meta(npos):to_table()
		return sto
	end

	if not def then
		return c_air, nil
	elseif not ignore_on_blast and def.on_blast then
		stor = get_stor(npos, stor)
		on_blast_queue[#on_blast_queue + 1] = {
			pos = vector.new(npos),
			on_blast = def.on_blast
		}
		return cid, stor
	elseif def.flammable then
		stor = get_stor(npos, stor)
		on_construct_queue[#on_construct_queue + 1] = {
			fn = basic_flame_on_construct,
			pos = vector.new(npos)
		}
		return c_fire, stor
    elseif is_atmos(def.name) then
        return c_air, nil
	else
		stor = get_stor(npos, stor)
		local node_drops = minetest.get_node_drops(def.name, "")
		for _, item in pairs(node_drops) do
			add_drop(drops, item)
		end
		return c_air, stor
	end
end

local function calc_velocity(pos1, pos2, old_vel, power)
	-- Avoid errors caused by a vector of zero length
	if vector.equals(pos1, pos2) then
		return old_vel
	end

	local vel = vector.direction(pos1, pos2)
	vel = vector.normalize(vel)
	vel = vector.multiply(vel, power)

	-- Divide by distance
	local dist = vector.distance(pos1, pos2)
	dist = math.max(dist, 1)
	vel = vector.divide(vel, dist)

	-- Add old velocity
	vel = vector.add(vel, old_vel)

	-- randomize it a bit
	vel = vector.add(vel, {
		x = math.random() - 0.5,
		y = math.random() - 0.5,
		z = math.random() - 0.5,
	})

	-- Limit to terminal velocity
	dist = vector.length(vel)
	if dist > 250 then
		vel = vector.divide(vel, dist / 250)
	end
	return vel
end

local function entity_physics(pos, radius, drops)
	local objs = minetest.get_objects_inside_radius(pos, radius)
	for _, obj in pairs(objs) do
		local obj_pos = obj:get_pos()
		if obj_pos then
			local dist = math.max(1, vector.distance(pos, obj_pos))

			local damage = (4 / dist) * radius
			if obj:is_player() then
				local dir = vector.normalize(vector.subtract(obj_pos, pos))
				local moveoff = vector.multiply(dir, 2 / dist * radius)
				obj:add_velocity(moveoff)

				obj:set_hp(obj:get_hp() - damage)
			else
				local luaobj = obj:get_luaentity()

				-- object might have disappeared somehow
				if luaobj and not luaobj.name:match("_ship_missile_projectile") and
						not luaobj.name:match("_tower_display") then
					local do_damage = true
					local do_knockback = true
					local entity_drops = {}
					local objdef = minetest.registered_entities[luaobj.name]

					if objdef and objdef.on_blast then
						do_damage, do_knockback, entity_drops = objdef.on_blast(luaobj, damage)
					end

					if do_knockback then
						local obj_vel = obj:get_velocity()
						obj:set_velocity(calc_velocity(pos, obj_pos,
								obj_vel, radius * 10))
					end
					if do_damage then
						if not obj:get_armor_groups().immortal then
							obj:punch(obj, 1.0, {
								full_punch_interval = 1.0,
								damage_groups = {fleshy = damage},
							}, nil)
						end
					end
					for _, item in pairs(entity_drops) do
						add_drop(drops, item)
					end
				end
			end
		end
	end
end

local function add_effects_hit_shield(pos, radius)
	minetest.add_particlespawner({
		amount = 5,
		time = 0.4,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x = -0.1, y = -0.1, z = -0.1},
		maxvel = {x = 0.1, y = 0.1, z = 0.1},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 1.1,
		maxexptime = 2.8,
		minsize = radius * 3,
		maxsize = radius * 10,
        texture = {
            name = "ctg_shield_hit_effect.png",
            blend = "alpha",
            scale = 1,
            alpha = 0.6,
            alpha_tween = {0.6, 0.0},
            scale_tween = {{
                x = 1,
                y = 1
            }, {
                x = 8,
                y = 8
            }}
        },
        animation = {
            type = "vertical_frames",
            aspect_w = 16,
            aspect_h = 16,
            length = 3
        },
		vertical = true,
        collisiondetection = false,
        glow = 8,
	})
end

local function add_effects_hit(pos, radius, drops)
	minetest.add_particle({
		pos = pos,
		velocity = vector.new(),
		acceleration = vector.new(),
		expirationtime = 0.64,
		size = radius * 16,
		collisiondetection = false,
		vertical = false,
		texture = "tnt_boom.png",
		glow = 15,
	})
	minetest.add_particlespawner({
		amount = 16,
		time = 0.6,
		minpos = vector.subtract(pos, radius / 4),
		maxpos = vector.add(pos, radius / 4),
		minvel = {x = -1, y = -1, z = -1},
		maxvel = {x = 1, y = 1, z = 1},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 3,
		maxexptime = 7,
		minsize = radius * 4,
		maxsize = radius * 7,
        texture = {
            name = "ctg_missile_vapor.png",
            blend = "alpha",
            scale = 1,
            alpha = 1.0,
            alpha_tween = {1, 0},
            scale_tween = {{
                x = 0.5,
                y = 0.5
            }, {
                x = 5,
                y = 5
            }}
        },
        collisiondetection = true,
        glow = 3,
	})
	minetest.add_particlespawner({
		amount = 16,
		time = 0.7,
		minpos = vector.subtract(pos, radius / 3),
		maxpos = vector.add(pos, radius / 3),
		minvel = {x = -1, y = -1, z = -1},
		maxvel = {x = 1, y = 1, z = 1},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 2,
		maxexptime = 5,
		minsize = radius * 5,
		maxsize = radius * 7,
		--texture = "tnt_smoke.png",
        texture = {
            name = "ctg_missile_smoke.png",
            blend = "alpha",
            scale = 1,
            alpha = 1.0,
            alpha_tween = {1, 0},
            scale_tween = {{
                x = 0.25,
                y = 0.25
            }, {
                x = 6,
                y = 5
            }}
        },
        collisiondetection = true,
        glow = 5,
	})
	minetest.add_particlespawner({
		amount = 72,
		time = 0.45,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x = -3.5, y = -3.5, z = -3.5},
		maxvel = {x = 3.5, y = 5.0, z = 3.5},
		minacc = {x = -0.5, y = -2.0, z = -0.5},
		maxacc = {x = 0.5, y = 0.5, z = 0.5},
		minexptime = 0.5,
		maxexptime = 2,
		minsize = radius * 0.2,
		maxsize = radius * 0.6,
        texture = {
            name = "ctg_spark.png",
            blend = "alpha",
            scale = 1,
            alpha = 1.0,
            alpha_tween = {1, 0.5},
            scale_tween = {{
                x = 1.0,
                y = 1.0
            }, {
                x = 0,
                y = 0
            }}
        },
        collisiondetection = true,
        glow = 15,
	})

	-- we just dropped some items. Look at the items entities and pick
	-- one of them to use as texture
	local texture = "tnt_blast.png" --fallback texture
	local node
	local most = 0
	for name, stack in pairs(drops) do
		local count = stack:get_count()
		if count > most then
			most = count
			local def = minetest.registered_nodes[name]
			if def then
				node = { name = name }
				if def.tiles and type(def.tiles[1]) == "string" then
					texture = def.tiles[1]
				end
			end
		end
	end

	minetest.add_particlespawner({
		amount = 64,
		time = 0.1,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x = -3, y = 0, z = -3},
		maxvel = {x = 3, y = 5,  z = 3},
		minacc = {x = 0, y = -5, z = 0}, -- FIXME: gravity
		maxacc = {x = 0, y = -5, z = 0}, -- FIXME: gravity
		minexptime = 0.8,
		maxexptime = 2.0,
		minsize = radius * 0.33,
		maxsize = radius,
		texture = texture,
		-- ^ only as fallback for clients without support for `node` parameter
		node = node,
		collisiondetection = true,
	})
end

function ship_weapons.burn(pos, nodename)
	local name = nodename or minetest.get_node(pos).name
	local def = minetest.registered_nodes[name]
	if not def then
		return
	elseif def.on_ignite then
		def.on_ignite(pos)
	elseif minetest.get_item_group(name, "tnt") > 0 then
		minetest.swap_node(pos, {name = name .. "_burning"})
		minetest.sound_play("tnt_ignite", {pos = pos, gain = 1.0}, true)
		minetest.get_node_timer(pos):start(1)
	end
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

local function missile_safe_explode(pos, radius, ignore_protection, ignore_on_blast, owner, explode_center)
	pos = vector.round(pos)
	-- scan for nearby ship protection shields
	local shipp = find_ship_protect(pos)
	-- scan for adjacent TNT nodes first, and enlarge the explosion
	local vm1 = VoxelManip()
	local p1 = vector.subtract(pos, 2)
	local p2 = vector.add(pos, 2)
	local minp, maxp = vm1:read_from_map(p1, p2)
	local a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm1:get_data()
	local count = 0
	local c_tnt = minetest.get_content_id("tnt:tnt")
	local c_tnt_burning = minetest.get_content_id("tnt:tnt_burning")
	local c_tnt_boom = minetest.get_content_id("tnt:boom")
	local c_vac = minetest.get_content_id("vacuum:vacuum")
	local c_air = minetest.CONTENT_AIR
	local c_ignore = minetest.CONTENT_IGNORE
	local drops = {}
	-- make sure we still have explosion even when centre node isnt tnt related
	if explode_center then
		count = 1
	end

    if pos.y > 4000 then
        c_air = c_vac
    end

	for z = pos.z - 2, pos.z + 2 do
		for y = pos.y - 2, pos.y + 2 do
			local vi = a:index(pos.x - 2, y, z)
			for x = pos.x - 2, pos.x + 2 do
				local cid = data[vi]
				if cid == c_tnt or cid == c_tnt_boom or cid == c_tnt_burning then
					count = count + 1
					data[vi] = c_air
				end
				vi = vi + 1
			end
		end
	end

	vm1:set_data(data)
	vm1:write_to_map()

	-- recalculate new radius
	radius = math.floor(radius * math.pow(count, 1/3))

	if not shipp then
		return drops, radius
	end

	local ship_meta = minetest.get_meta(shipp)

	local ship_combat_ready = ship_meta:get_int("combat_ready") > 1
	local ship_hp_max = ship_meta:get_int("hp_max") or 1000
	local ship_hp = ship_meta:get_int("hp") or 1000
	local ship_hp_prcnt = (ship_hp / ship_hp_max) * 100
	
	local ship_shield_max = ship_meta:get_int("shield_max") or 1000
	local ship_shield = ship_meta:get_int("shield") or 1000
	local ship_shield_prcnt = (ship_shield / ship_shield_max) * 100
	
	local ship_shield_hit = ship_meta:get_int("shield_hit") or 0

	-- perform the explosion
	local vm = VoxelManip()
	local pr = PseudoRandom(os.time())
	p1 = vector.subtract(pos, radius)
	p2 = vector.add(pos, radius)
	minp, maxp = vm:read_from_map(p1, p2)
	a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	data = vm:get_data()

	local on_blast_queue = {}
	local on_construct_queue = {}
	basic_flame_on_construct = minetest.registered_nodes["fire:basic_flame"].on_construct

	local dam_thres = 1
	local hit_damage = 0
	local n_hits = {}
	local c_fire = minetest.get_content_id("fire:basic_flame")
	for z = -radius, radius do
	for y = -radius, radius do
	local vi = a:index(pos.x + (-radius), pos.y + y, pos.z + z)
	for x = -radius, radius do
		local r = vector.length(vector.new(x, y, z))
		if (radius * radius) / (r * r) >= (pr:next(80, 125) / 100) then
			local cid = data[vi]
			local p = {x = pos.x + x, y = pos.y + y, z = pos.z + z}
			if cid ~= c_air and cid ~= c_ignore then
				local n_hit = nil
				local dcid = nil
				dcid, n_hit = destroy_safe(drops, p, cid, c_air, c_fire, on_blast_queue, on_construct_queue, ignore_protection, ignore_on_blast, owner)
				if n_hit ~= nil then
					hit_damage = hit_damage + 1
				end
				if ship_combat_ready and ship_shield_prcnt <= dam_thres then
					data[vi] = dcid
					if n_hit ~= nil and n_hit.name then
						table.insert(n_hits, n_hit)
					end
				end
			end
		end
		vi = vi + 1
	end
	end
	end

	if ship_combat_ready and ship_shield_prcnt <= dam_thres then
		vm:set_data(data)
		vm:write_to_map()
		vm:update_map()
		vm:update_liquids()

		-- get node hit storage
		local hits = minetest.deserialize(ship_meta:get_string("node_damage_list")) or {}
		-- check node hit list
		for _, hit in pairs(n_hits) do
			local o_pos = vector.subtract(hit.pos, shipp)
			hit.pos = o_pos
			table.insert(hits, hit)
		end
		ship_meta:set_string("node_damage_list", minetest.serialize(hits))

	else
		add_effects_hit_shield(pos, radius)
		drops = {}

	end

	if ship_combat_ready then
		ship_shield_hit = ship_shield_hit + math.random(1, 5)
		ship_meta:set_int("shield_hit", ship_shield_hit)
		if ship_shield > 0 then
			ship_shield = ship_shield - math.floor(hit_damage * radius * 5)
			if ship_shield <= 0 then
				ship_shield = 0
			end
			ship_meta:set_int("shield", ship_shield)
		end
		if ship_hp > 0 and ship_shield <= 0 then
			ship_hp = ship_hp - math.floor(hit_damage * radius * 4)
			ship_meta:set_int("hp", ship_hp)
		end
	end

	-- call check_single_for_falling for everything within 1.5x blast radius
	for y = -radius * 1.5, radius * 1.5 do
	for z = -radius * 1.5, radius * 1.5 do
	for x = -radius * 1.5, radius * 1.5 do
		local rad = {x = x, y = y, z = z}
		local s = vector.add(pos, rad)
		local r = vector.length(rad)
		if r / radius < 1.4 then
			minetest.check_single_for_falling(s)
		end
	end
	end
	end

	if ship_combat_ready and ship_shield_prcnt < dam_thres then
		for _, queued_data in pairs(on_blast_queue) do
			local dist = math.max(1, vector.distance(queued_data.pos, pos))
			local intensity = (radius * radius) / (dist * dist)
			local node_drops = queued_data.on_blast(queued_data.pos, intensity)
			if node_drops then
				for _, item in pairs(node_drops) do
					add_drop(drops, item)
				end
			end
		end

		for _, queued_data in pairs(on_construct_queue) do
			queued_data.fn(queued_data.pos)
		end
	end

	minetest.log("action", "MISSILE owned by " .. owner .. " detonated at " ..
		minetest.pos_to_string(pos) .. " with radius " .. radius)

	return drops, radius
end

local function missile_explode(pos, radius, ignore_protection, ignore_on_blast, owner, explode_center)
	pos = vector.round(pos)
	-- scan for adjacent TNT nodes first, and enlarge the explosion
	local vm1 = VoxelManip()
	local p1 = vector.subtract(pos, 2)
	local p2 = vector.add(pos, 2)
	local minp, maxp = vm1:read_from_map(p1, p2)
	local a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm1:get_data()
	local count = 0
	local c_tnt = minetest.get_content_id("tnt:tnt")
	local c_tnt_burning = minetest.get_content_id("tnt:tnt_burning")
	local c_tnt_boom = minetest.get_content_id("tnt:boom")
	local c_vac = minetest.get_content_id("vacuum:vacuum")
	local c_air = minetest.CONTENT_AIR
	local c_ignore = minetest.CONTENT_IGNORE
	-- make sure we still have explosion even when centre node isnt tnt related
	if explode_center then
		count = 1
	end

    if pos.y > 4000 then
        c_air = c_vac
    end

	for z = pos.z - 2, pos.z + 2 do
		for y = pos.y - 2, pos.y + 2 do
			local vi = a:index(pos.x - 2, y, z)
			for x = pos.x - 2, pos.x + 2 do
				local cid = data[vi]
				if cid == c_tnt or cid == c_tnt_boom or cid == c_tnt_burning then
					count = count + 1
					data[vi] = c_air
				end
				vi = vi + 1
			end
		end
	end

	vm1:set_data(data)
	vm1:write_to_map()

	-- recalculate new radius
	radius = math.floor(radius * math.pow(count, 1/3))

	-- perform the explosion
	local vm = VoxelManip()
	local pr = PseudoRandom(os.time())
	p1 = vector.subtract(pos, radius)
	p2 = vector.add(pos, radius)
	minp, maxp = vm:read_from_map(p1, p2)
	a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	data = vm:get_data()

	local drops = {}
	local on_blast_queue = {}
	local on_construct_queue = {}
	basic_flame_on_construct = minetest.registered_nodes["fire:basic_flame"].on_construct

	local c_fire = minetest.get_content_id("fire:basic_flame")
	for z = -radius, radius do
	for y = -radius, radius do
	local vi = a:index(pos.x + (-radius), pos.y + y, pos.z + z)
	for x = -radius, radius do
		local r = vector.length(vector.new(x, y, z))
		if (radius * radius) / (r * r) >= (pr:next(80, 125) / 100) then
			local cid = data[vi]
			local p = {x = pos.x + x, y = pos.y + y, z = pos.z + z}
			if cid ~= c_air and cid ~= c_ignore then
				data[vi] = destroy(drops, p, cid, c_air, c_fire,
					on_blast_queue, on_construct_queue,
					ignore_protection, ignore_on_blast, owner)
			end
		end
		vi = vi + 1
	end
	end
	end

	vm:set_data(data)
	vm:write_to_map()
	vm:update_map()
	vm:update_liquids()

	-- call check_single_for_falling for everything within 1.5x blast radius
	for y = -radius * 1.5, radius * 1.5 do
	for z = -radius * 1.5, radius * 1.5 do
	for x = -radius * 1.5, radius * 1.5 do
		local rad = {x = x, y = y, z = z}
		local s = vector.add(pos, rad)
		local r = vector.length(rad)
		if r / radius < 1.4 then
			minetest.check_single_for_falling(s)
		end
	end
	end
	end

	for _, queued_data in pairs(on_blast_queue) do
		local dist = math.max(1, vector.distance(queued_data.pos, pos))
		local intensity = (radius * radius) / (dist * dist)
		local node_drops = queued_data.on_blast(queued_data.pos, intensity)
		if node_drops then
			for _, item in pairs(node_drops) do
				add_drop(drops, item)
			end
		end
	end

	for _, queued_data in pairs(on_construct_queue) do
		queued_data.fn(queued_data.pos)
	end

	minetest.log("action", "MISSILE owned by " .. owner .. " detonated at " ..
		minetest.pos_to_string(pos) .. " with radius " .. radius)

	return drops, radius
end

function ship_weapons.safe_boom(pos, def)
	def = def or {}
	def.radius = def.radius or 1
	def.damage_radius = def.damage_radius or def.radius * 2
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	
	local sound = def.sound or "tnt_explode"
	minetest.sound_play(sound, {pos = pos, gain = 2.5,
			max_hear_distance = math.min(def.radius * 20, 128)}, true)
	local drops, radius = missile_safe_explode(pos, def.radius, def.ignore_protection,
			def.ignore_on_blast, owner, true)
	-- append entity drops
	local damage_radius = (radius / math.max(1, def.radius)) * def.damage_radius
	entity_physics(pos, damage_radius, drops)
	if not def.disable_drops then
		eject_drops(drops, pos, radius)
	end
	add_effects_hit(pos, radius, drops)
	minetest.log("action", "A SAFE MISSILE explosion occurred at " .. minetest.pos_to_string(pos) ..
		" with radius " .. radius)
end

function ship_weapons.boom(pos, def)
	def = def or {}
	def.radius = def.radius or 1
	def.damage_radius = def.damage_radius or def.radius * 2
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	local sound = def.sound or "tnt_explode"
	minetest.sound_play(sound, {pos = pos, gain = 2.5,
			max_hear_distance = math.min(def.radius * 20, 128)}, true)
	local drops, radius = missile_explode(pos, def.radius, def.ignore_protection,
			def.ignore_on_blast, owner, true)
	-- append entity drops
	local damage_radius = (radius / math.max(1, def.radius)) * def.damage_radius
	entity_physics(pos, damage_radius, drops)
	if not def.disable_drops then
		eject_drops(drops, pos, radius)
	end
	add_effects_hit(pos, radius, drops)
	minetest.log("action", "A MISSILE explosion occurred at " .. minetest.pos_to_string(pos) ..
		" with radius " .. radius)
end
