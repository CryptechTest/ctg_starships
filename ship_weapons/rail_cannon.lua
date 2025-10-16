local S = minetest.get_translator(minetest.get_current_modname())

local time_scl = 30

-- temporary pos store
local player_pos = {}

local recent_cannons = {}

local function round(v)
    return math.floor(v + 0.5)
end

local function randFloat(min, max, precision)
    -- Generate a random floating point number between min and max
    local range = max - min
    local offset = range * math.random()
    local unrounded = min + offset

    -- Return unrounded number if precision isn't given
    if not precision then
        return unrounded
    end

    -- Round number to precision and return
    local powerOfTen = 10 ^ precision
    local n
    n = unrounded * powerOfTen
    n = n + 0.5
    n = math.floor(n)
    n = n / powerOfTen
    return n
end

local function needs_charge(pos)
    local meta = minetest.get_meta(pos)
    local charge = meta:get_int("charge")
    local charge_max = meta:get_int("charge_max")
    return charge < charge_max
end

local function has_charge(pos)
    local meta = minetest.get_meta(pos)
    local charge = meta:get_int("charge")
    return charge > 0
end

-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------

local function spawn_particle2(pos, tier)
    local grav = 1;
    if (pos.y > 4000) then
        grav = 0.4;
    end
    local def = {
        amount = 34,
        time = 0.15,
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        vertical = false,

        texture = {
            name = "ctg_beam_effect2_" .. tier .. ".png",
            alpha_tween = {1, 1, 0},
            scale_tween = {{
                x = 2.5,
                y = 2.5
            }, {
                x = 0.1,
                y = 0.1
            }},
            blend = "alpha"
        },
        glow = 12,

        minpos = {
            x = pos.x + -0.25,
            y = pos.y + -0.15,
            z = pos.z + -0.25
        },
        maxpos = {
            x = pos.x + 0.25,
            y = pos.y + 0.35,
            z = pos.z + 0.25
        },
        minvel = {
            x = -0.21,
            y = 2.76,
            z = -0.21
        },
        maxvel = {
            x = 0.21,
            y = 3.28,
            z = 0.21
        },
        minacc = {
            x = -0.35,
            y = -2.65 * grav,
            z = -0.35
        },
        maxacc = {
            x = 0.35,
            y = -4.65 * grav,
            z = 0.35
        },
        minexptime = 0.5,
        maxexptime = 2.2,
        minsize = 0.28,
        maxsize = 0.72
    }

    minetest.add_particlespawner(def);

    def.minvel = {
        x = -2.41,
        y = 0.176 * grav,
        z = -2.41
    }
    def.maxvel = {
        x = 2.41,
        y = 0.28 * grav,
        z = 2.41
    }

    minetest.add_particlespawner(def);
end

-------------------------------------------------------

function ship_weapons.rail_cannon_frag(def, op, origin, pos_target, object_target)
    local o_y = 0
    local o_x = 0
    local o_z = 0
    if def.mount_dir == "ceiling" then
        o_y = -0.65
    elseif def.mount_dir == "wall" then
        o_y = 0
        local dir = ship_weapons.get_port_wall_direction(origin)
        o_x = (dir.x * 0.65)
        o_z = (dir.z * 0.65)
    else
        o_y = 0.65
    end
    local o_origin = vector.add(origin, {x=o_x,y=o_y,z=o_z}) 
    local origin_str = origin.x .. "," .. origin.y .. "," .. origin.z
    local t_us = core.get_us_time();
    if recent_cannons[origin_str] then
        if (t_us - recent_cannons[origin_str]) / 1000 <= 5000 then
            return 1
        end
    end
    recent_cannons[origin_str] = t_us + (math.random(-1, 3) * 1000 * 1000)

    if pos_target == nil or vector.distance(o_origin, pos_target) < 4.25 then
        --core.log("pos_target nil or target too close!")
        return 0
    end

    local meta = core.get_meta(origin)
    local target = vector.add(pos_target, {
        x = randFloat(-0.12, 0.12),
        y = randFloat(-0.10, 0.12),
        z = randFloat(-0.12, 0.12)
    })

    local dist = vector.distance(o_origin, target)
    --minetest.log("cannon pew pew! " .. tostring(dist))

    local pitch, pitch_deg = ship_weapons.calculatePitch(o_origin, target)
    local yaw, yaw_deg = ship_weapons.calculateYaw(o_origin, target)

    if pitch > 70 then
        return 0
    end

    if yaw_deg < 0 then
        yaw = math.rad(360 + yaw_deg)
    end    
    --minetest.log("adjusting angle:  pitch= " .. tostring(pitch_deg) .. "  yaw= " .. tostring(yaw_deg))
    
    local function num_is_close(target, actual)
        local target_frac = (target * 0.01) + 4.75
        return actual < target + target_frac and actual >= target - target_frac
    end

    local rotation_done = false
    local target_found = false
    local objs = minetest.get_objects_inside_radius(o_origin, 0.15)
    for _, obj in pairs(objs) do
        if obj:get_luaentity() then
            local ent = obj:get_luaentity()
            if ent.name == "ship_weapons:" .. def.tier .. "_rail_cannon_barrel" then
                local rot = {x = pitch, y = yaw, z = 0}
                meta:set_string("target_dir", core.serialize(rot))
                if ent._target_found then
                    target_found = true
                end
                if num_is_close(math.deg(pitch), math.deg(ent._rotation_set.x)) and num_is_close(math.deg(yaw), math.deg(ent._rotation_set.y)) then
                    if ent._rotation_done then
                        rotation_done = true
                    end
                    --minetest.log("new rot yaw= " .. tostring(math.deg(ent._rotation_set.y)))
                end                
                break
            end
        end
    end

    if rotation_done and not target_found then
        local _rot = {x = 0, y = 0, z = 0}
        meta:set_string("target_dir", core.serialize(_rot))
        return 1
    end

    if not target_found then
        --minetest.log("target not found!")
        --return 1
    end
    if not rotation_done then
        --minetest.log("rotation not done!")
        return 1
    end
    --minetest.log("launching frag!")
    ship_weapons.launch_energy_rail_projectile(def, op, o_origin, target, object_target)
    return 3
end

function ship_weapons.rail_cannon_launch(def, op, origin, pos_target, object_target)
    local target = vector.add(pos_target, {
        x = randFloat(-0.2, 0.2),
        y = randFloat(-0.2, 0.2),
        z = randFloat(-0.2, 0.2)
    })

    local dist = vector.distance(origin, target)
    -- minetest.log("missile pew pew! " .. tostring(dist))
    
    local pitch = ship_weapons.calculatePitch(origin, target)
    local yaw = ship_weapons.calculateYaw(origin, target)

    local rotation_done = false
    local objs = minetest.get_objects_inside_radius(origin, 0.15)
    for _, obj in pairs(objs) do
        if obj:get_luaentity() then
            local ent = obj:get_luaentity()
            if ent.name == "ship_weapons:" .. def.tier .. "_rail_cannon_barrel" then
                if ent._target_found then
                    rotation_done = true
                end
                break
            end
        end
    end

    if not rotation_done then
        return false
    end

    ship_weapons.launch_plasma_projectile(def, op, origin, target, object_target)
    return true
end

-------------------------------------------------------
-------------------------------------------------------

function ship_weapons.register_rail_cannon(data)
    local tier = data.tier
    local ltier = string.lower(tier)
    local machine_name = data.machine_name
    local machine_desc = tier .. " " .. data.machine_desc
    local tmachine_name = string.lower(machine_name)

    local groups = {
        cracky = 2,
        technic_machine = 1,
        ["technic_" .. ltier] = 1,
        ctg_machine = 1,
        metal = 1,
        level = 2,
        ship_machine = 1,
        ship_weapon = 1,
        ship_cannon = 2
    }

    local active_groups = {
        not_in_creative_inventory = 1
    }
    for k, v in pairs(groups) do
        active_groups[k] = v
    end

    local connect_sides_floor = { bottom = 1 }
    local connect_sides_wall = { back = 1 }
    local connect_sides_ceiling = { top = 1 }

    local default_digi_data = {
        launch = false,
        target_pos = nil,
        power = 1,
        pitch = 0,
        yaw = 0,
        count = 1,
        delay = 0
    }

    -------------------------------------------------------
    
    local rightclick = function(pos, node, clicker, itemstack)
        local meta = core.get_meta(pos)
        local name = clicker:get_player_name()
        local s = {
            l = 1,
            h = 1,
            w = 1
        }
        if meta then
            player_pos[name] = pos
            core.show_formspec(name, data.modname .. ":" .. ltier .. "_" .. tmachine_name, ship_weapons.update_formspec(data, meta))
        end
    end

    local on_punch = function(pos, node, puncher, pointed_thing)
        -- minetest.log("punched node")
        local function on_hit(self, target)

            local node = minetest.get_node(target)
            -- minetest.log("hit node " .. node.name)
            if node.name == "ship_weapons:" .. ltier .. "_" .. tmachine_name then

                technic.swap_node(target, "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_broken")
            end

            -- return old_def(self, target)
        end
        on_hit(pos, pos)
    end

    local on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        --technic.swap_node(pos, "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_idle")
        meta:set_int("broken", 0);
        local o_pos = vector.add(pos, {x=0,y=0.65,z=0})
        local objs = minetest.get_objects_inside_radius(o_pos, 0.15)
        for _, obj in pairs(objs) do
            if obj:get_luaentity() then
                local ent = obj:get_luaentity()
                if ent.name == "ship_weapons:" .. ltier .. "_rail_cannon_barrel" then
                    obj:set_properties({
                        is_visible = true
                    })
                    break
                end
            end
        end
    end

    local on_receive_fields = function(pos, formname, fields, sender)
        local name = sender:get_player_name()
        if not name or not pos then
            return
        end        
        if fields.quit then
            player_pos[name] = nil
            return
        end
        local node = minetest.get_node(pos)
        local meta = minetest.get_meta(pos)
        local owner = meta:get_string("owner")
        if name ~= owner then
            return
        end
        local enabled = meta:get_int("enabled") == 1
        if fields.toggle then
            if meta:get_int("enabled") == 1 then
                meta:set_int("enabled", 0)
            else
                meta:set_int("enabled", 1)
                enabled = true
            end
        end
        local attack_type = meta:get_int("attack_type")
        if fields.attack_type then
            local attack = fields.attack_type
            if attack == 'None' then
                attack_type = 1
            elseif attack == 'Any' then
                attack_type = 2
            elseif attack == 'Monster' then
                attack_type = 3
            elseif attack == 'Player' then
                attack_type = 4
            elseif attack == 'Monster/Player' then
                attack_type = 5
            elseif attack == 'Jumpship' then
                attack_type = 6
            end
            meta:set_int("attack_type", attack_type)
        end

        local add_member_input = fields.add_member
        -- reset formspec until close button pressed
        if (fields.close_me or fields.quit) and (not add_member_input or add_member_input == "") then
            player_pos[name] = nil
            return
        end
        -- add member [+]
        if add_member_input then
            for _, i in pairs(add_member_input:split(" ")) do
                ship_weapons.add_member(meta, i)
            end
        end

        -- remove member [x]
        for field, value in pairs(fields) do
            if string.sub(field, 0, string.len("del_member_")) == "del_member_" then
                ship_weapons.del_member(meta, string.sub(field, string.len("del_member_") + 1))
            end
        end

        local charge = meta:get_int("charge")
        local charge_max = meta:get_int("charge_max")
        local running = true
        local formspec = ship_weapons.update_formspec(data, meta)
        meta:set_string("formspec", formspec)
    end

    local function remove_attached(pos)
        local node = core.get_node(pos)
        local o_y = 0
        if node.name:match("_ceiling") then
            o_y = -0.65
        elseif node.name:match("_wall") then
            o_y = 0
        else
            o_y = 0.65
        end
        local o_pos = vector.add(pos, {x=0,y=o_y,z=0})
        local objs = minetest.get_objects_inside_radius(o_pos, 0.15)
        for _, obj in pairs(objs) do
            if obj:get_luaentity() then
                local ent = obj:get_luaentity()
                if ent.name == "ship_weapons:" .. ltier .. "_rail_cannon_display" then
                    obj:remove()
                elseif ent.name == "ship_weapons:" .. ltier .. "_rail_cannon_barrel" then
                    obj:remove()
                end
            end
        end
    end

    local function check_display(pos)
        if not core.compare_block_status(pos, "active") then
            return
        end
        local found_display = false
        local node = core.get_node(pos)
        local meta = core.get_meta(pos)
        local mount_dir = meta:get_string("mount_dir")
        local o_y = 0
        local o_x = 0
        local o_z = 0
        if mount_dir == "ceiling" then
            o_y = -0.65
        elseif mount_dir == "wall" then
            o_y = 0
            local dir = ship_weapons.get_port_wall_direction(pos)
            o_x = (dir.x * 0.65)
            o_z = (dir.z * 0.65)
        else
            o_y = 0.65
        end
        local o_pos = vector.add(pos, {x=o_x,y=o_y,z=o_z})
        local objs = core.get_objects_inside_radius(o_pos, 0.05)
        for _, obj in pairs(objs) do
            if obj:get_luaentity() then
                local ent = obj:get_luaentity()
                if ent.name == "ship_weapons:" .. ltier .. "_rail_cannon_barrel" then
                    if found_display then
                        obj:remove()
                    end
                    found_display = true
                end
            end
        end
        if not found_display then
            --local o_pos = vector.add(pos, {x=0,y=0.65,z=0})
            core.add_entity(o_pos, "ship_weapons:" .. ltier .. "_rail_cannon_barrel")
            core.get_node_timer(pos):start(30)
        end
    end

    -------------------------------------------------------
    -------------------------------------------------------

    local function can_see_target(origin, pos_target, flip_y)
        if vector.distance(origin, pos_target) < 1.25 then
            return true
        end
        local bClear = true;
        local y = (flip_y and -0.725) or 0.725
        local origin_offset = vector.add(origin, {x = 0, y = y, z = 0})
        local ray = core.raycast(origin_offset, pos_target, true, false)
        for pointed_thing in ray do
            local pos = pointed_thing.intersection_point
            if (vector.distance(origin, pos) > 1.15) then
                if pointed_thing.type == "object" and vector.distance(pos, pos_target) > 2 then
                    if vector.distance(origin, pos) < 11 then
                        bClear = false;
                    end
                elseif pointed_thing.type == "node" then
                    local node = core.get_node(pos)
                    if node.name ~= "air" and node.name ~= "vacuum:vacuum" and node.name ~= "vacuum:atmos_thin" then
                        bClear = false;
                        break
                    end
                end
            end
        end
        return bClear    
    end

    local function find_target(pos, range, check_sight, meta)
        local meta = meta or core.get_meta(pos)
        local node = core.get_node(pos)
        local flip_y = false
        if node.name:match("_ceiling") then
            flip_y = true
        end
        local attack_type = meta:get_int("attack_type")
        local bFoundTarget = false
        local target_pos = nil
        local objs = core.get_objects_inside_radius(pos, range + 0.251)
        for _, obj in pairs(objs) do
            local obj_pos = obj:get_pos()
            if obj:get_luaentity() and not obj:is_player() then
                local ent = obj:get_luaentity()
                if ent.name == "__builtin:item" and (attack_type == 2) then
                    -- objects...
                    local is_proj = ent.type == "projectile"
                    if is_proj == false and check_sight == false then
                        bFoundTarget = true
                        target_pos = obj_pos
                    elseif is_proj == false and can_see_target(pos, obj_pos, flip_y) then
                        bFoundTarget = true
                        target_pos = obj_pos
                    end
                elseif ent.type and (ent.type == "npc" or ent.type == "animal" or ent.type == "monster") then
                    -- monsters
                    if ent.type == "monster" and (attack_type == 2 or attack_type == 3 or attack_type == 5) then
                        if check_sight == false then
                            bFoundTarget = true
                            target_pos = obj_pos
                        elseif can_see_target(pos, obj_pos, flip_y) then
                            bFoundTarget = true
                            target_pos = obj_pos
                        end
                    end
                end
            elseif obj:is_player() and (attack_type == 2 or attack_type == 4 or attack_type == 5) then
                local name = obj:get_player_name()
                -- players
                if name ~= meta:get_string("owner") and not ship_weapons.is_member(meta, name) and not ship_weapons.is_ally(meta, name) then
                    if check_sight == false or can_see_target(pos, obj_pos, flip_y) then
                        bFoundTarget = true
                        target_pos = obj_pos
                    end
                end
            end
            if bFoundTarget then
                break
            end
        end
        -- end find target
        return bFoundTarget, target_pos
    end

    local function find_targets(pos, count)
        local meta = core.get_meta(pos)
        local node = core.get_node(pos)
        local flip_y = false
        if node.name:match("_ceiling") then
            flip_y = true
        end
        local attack_type = meta:get_int("attack_type")
        local bFoundTarget = false
        local targets = {}
        local objs = core.get_objects_inside_radius(pos, data.range + 0.251)
        for _, obj in pairs(objs) do
            local obj_pos = obj:get_pos()
            if obj:get_luaentity() and not obj:is_player() then
                local ent = obj:get_luaentity()
                if ent.name == "__builtin:item" and (attack_type == 2) then
                    -- objects...
                    local item1 = obj:get_luaentity().itemstring
                    local is_proj = ent.type == "projectile"
                    if not is_proj and can_see_target(pos, obj_pos, flip_y) then
                        bFoundTarget = true
                        table.insert(targets, {obj = obj, pos = obj_pos})
                    end
                elseif ent.type and (ent.type == "npc" or ent.type == "animal" or ent.type == "monster") then
                    -- monsters
                    if ent.type == "monster" and (attack_type == 2 or attack_type == 3 or attack_type == 5) then
                        if can_see_target(pos, obj_pos, flip_y) then
                            bFoundTarget = true
                            table.insert(targets, {obj = obj, pos = obj_pos})
                        end
                    end
                end
            elseif obj:is_player() and (attack_type == 2 or attack_type == 4 or attack_type == 5) then
                local name = obj:get_player_name()
                -- players
                if name ~= meta:get_string("owner") and not ship_weapons.is_member(meta, name) and not ship_weapons.is_ally(meta, name) then
                    if can_see_target(pos, obj_pos, flip_y) then
                        bFoundTarget = true
                        table.insert(targets, {obj = obj, pos = obj_pos})
                    end
                end
            end
            if bFoundTarget and #targets >= count then
                break
            end
        end
        -- end find target
        return targets
    end

    local function find_random_target(pos)
        local meta = core.get_meta(pos)
        local node = core.get_node(pos)
        local flip_y = false
        if node.name:match("_ceiling") then
            flip_y = true
        end
        --local p_prcnt = (math.floor((meta:get_int("src_time") / round(time_scl * 10)) * 100))
        local last_target = core.deserialize(meta:get_string("last_target"))
        local target = nil
        if last_target == nil then
            local targets = find_targets(pos, 10)
            if #targets > 0 then
                target = targets[math.random(1, #targets)]
            end
        end
        if last_target == nil and target then
            meta:set_string("last_target", core.serialize(target.pos))
            return target
        elseif target ~= nil then
            meta:set_string("last_target", core.serialize(target.pos))
            return target
        elseif last_target ~= nil then
            local l_targ = vector.add(last_target, {x=0,y=2.5,z=0});
            local found, n_target = find_target(l_targ, 4.751, false, meta)
            if found and can_see_target(pos, n_target, flip_y) then
                --core.log("found near retarget...")
                --meta:set_string("last_target", core.serialize(n_target))
                return {obj = nil, pos = n_target}
            end
            --core.log("no retarget found")
            meta:set_string("last_target", nil)
            return {obj = nil, pos = nil}
        end
        --[[local found, n_target = find_target(pos, data.range, true)
        if found then
            meta:set_string("last_target", core.serialize(n_target))
            return {obj = nil, pos = n_target}
        end]]
        --core.log("no targets...")
        if last_target then
            meta:set_string("last_target", nil)
        end
        return {obj = nil, pos = last_target}
    end


    local function find_ship(pos, r)
        local ships = {}
        local bFoundTarget = false
        local nTargetCount = 0
        local objs = minetest.get_objects_inside_radius(pos, r + 0.251)
        for _, obj in pairs(objs) do
            if nTargetCount >= 3 then
                break
            end
            local obj_pos = obj:get_pos()
            if obj_pos then
                -- handle entities
                if obj:get_luaentity() and not obj:is_player() then
                    local ent = obj:get_luaentity()
                    if ent.type and (ent.type == "jumpship") then
                        -- ships
                        table.insert(ships, {pos = vector.subtract(obj_pos, {x=0,y=2,z=0})})
                        nTargetCount = nTargetCount + 1
                    end
                end
            end
        end
        return ships
        --return schem_lib.func.find_nodes_large(pos, r, {"group:jumpdrive"}, {limit = 5})
    end

    local function find_ship_protect(pos, r)
        local nodes = minetest.find_nodes_in_area({
            x = pos.x - r,
            y = pos.y - r,
            z = pos.z - r
        }, {
            x = pos.x + r,
            y = pos.y + r,
            z = pos.z + r
        }, {"group:ship_protector"})
        return nodes
    end

    local function check_path(origin, pos_target)
        if (not pos_target) then
            return -1
        end
        local bClear = 0;
        local ray = minetest.raycast(origin, pos_target, true, false)
        for pointed_thing in ray do
            if pointed_thing.type == "node" then
                local pos = pointed_thing.intersection_point
                if (vector.distance(origin, pos) > 1.25) and (vector.distance(pos_target, pos) > 3) then
                    local node = minetest.get_node(pos)
                    if node.name ~= "air" and node.name ~= "vacuum:vacuum" and node.name ~= "vacuum:atmos_thin" and
                        node.name ~= ":asteroid:atmos" then
                        bClear = bClear + 1;
                        break
                    end
                end
            end
        end
        return bClear
    end

    local function find_target_ships(pos, range)
        local meta = minetest.get_meta(pos)
        if range > 79 * 2 then
            range = 79 * 2
        end
        -------------------------------------------------------
        -- strike launch to target object
        local bFoundTarget = false
        local nTargetCount = 0
        local targets = {}
        local nodes = find_ship(pos, range)
        local protects = find_ship_protect(pos, 72)
        local our_ship = nil
        for _, node in pairs(protects) do
            local ship_meta = minetest.get_meta(node)
            local name = ship_meta:get_string("owner")
            if name == meta:get_string("owner") then
                our_ship = {
                    pos = node,
                    meta = ship_meta
                }
            end
        end
        if our_ship == nil then
            --return nTargetCount
        end
        for _, node in pairs(nodes) do
            if nTargetCount >= 1 then
                break
            end
            local node_pos = node.pos
            -- check for line of sight...
            local nodes_in_path = check_path(pos, node_pos)
            if node_pos and nodes_in_path < 48 then
                local ship_meta = minetest.get_meta(node_pos)
                local name = ship_meta:get_string("owner")
                local r = (nodes_in_path * 0.7) + 1
                local target_pos = vector.add(node_pos, {
                    x = math.random(-r, r),
                    y = math.random(-r, r),
                    z = math.random(-r, r)
                })
                -- ships
                if name ~= meta:get_string("owner") then -- and (our_ship ~= nil and not ship_weapons.is_member(our_ship.meta, name)) 
                    bFoundTarget = true;
                    nTargetCount = nTargetCount + 1
                    table.insert(targets, {ship_pos = node_pos, pos = target_pos})
                end
            end
        end
        -- end strike
        return targets
    end

    local function find_target_ship(pos, target)
        local meta = minetest.get_meta(pos)
        -------------------------------------------------------
        -- strike launch to target object
        local bFoundTarget = false
        local nTargetCount = 0
        -- check for line of sight...
        local nodes_in_path = check_path(pos, target)
        if target and nodes_in_path < 48 then
            local ship_meta = minetest.get_meta(target)
            local name = ship_meta:get_string("owner")
            bFoundTarget = true;
            nTargetCount = nTargetCount + 1
        end
        -- end strike
        return bFoundTarget, target
    end


    local function find_random_target_ship(pos)
        local meta = core.get_meta(pos)
        --local p_prcnt = (math.floor((meta:get_int("src_time") / round(time_scl * 10)) * 100))
        local last_target = core.deserialize(meta:get_string("last_target"))
        local target = nil
        if last_target == nil then
            local targets = find_target_ships(pos, data.range + 1)
            if #targets > 0 then
                target = targets[math.random(1, #targets)]
            end
        end
        if last_target == nil and target then
            meta:set_string("last_target", core.serialize(target.pos))
            return target
        elseif target ~= nil then
            meta:set_string("last_target", core.serialize(target.pos))
            return target
        end
        if last_target ~= nil then
            local l_targ = vector.add(last_target, {x=0,y=0,z=0});
            local found, n_target = find_target_ship(pos, l_targ)
            if found then
                --core.log("found near retarget...")
                --meta:set_string("last_target", core.serialize(n_target))
                return {obj = nil, pos = n_target}
            end
            --core.log("no retarget found")
            meta:set_string("last_target", nil)
            return {obj = nil, pos = nil}
        end
        --[[local found, n_target = find_target(pos, data.range, true)
        if found then
            meta:set_string("last_target", core.serialize(n_target))
            return {obj = nil, pos = n_target}
        end]]
        --core.log("no targets...")
        if last_target then
            meta:set_string("last_target", nil)
        end
        return {obj = nil, pos = last_target}
    end


    -- technic run
    local run = function(pos, node)
        local meta = minetest.get_meta(pos)
        local owner = meta:get_string("owner")
        --local operator = minetest.get_player_by_name(owner);
        local inv = meta:get_inventory()
        local eu_input = meta:get_int(tier .. "_EU_input")
        local mount_dir = meta:get_string("mount_dir") or "floor"

        local machine_desc_tier = machine_desc:format(tier)
        local machine_node = data.modname .. ":" .. ltier .. "_" .. machine_name
        local machine_demand_active = data.demand
        local machine_demand_idle = data.demand[1] * 0.20

        local charge_max = meta:get_int("charge_max") or 0
        local charge = meta:get_int("charge") or 0

        -- Get digiline data storage
        local digiline_data = minetest.deserialize(meta:get_string("digiline_data")) or default_digi_data

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

        if meta:get_int("broken") == 0 and meta:get_int("last_hit") <= 0 then
            check_display(pos)
        end

        local powered = eu_input >= machine_demand_idle
        if powered then
            meta:set_int("src_time", meta:get_int("src_time") + round(data.speed * 1.0))
        end
        while true do
            local enabled = meta:get_int("enabled") == 1

            if meta:get_int("broken") == 1 then
                if mount_dir == "ceiling" then
                    technic.swap_node(pos, machine_node .. "_ceiling_broken")
                elseif mount_dir == "wall" then
                    technic.swap_node(pos, machine_node .. "_wall_broken")
                else
                    technic.swap_node(pos, machine_node .. "_broken")
                end
                meta:set_string("infotext", machine_desc_tier .. S(" - Damaged"))
                meta:set_int(tier .. "_EU_demand", machine_demand_idle)
                meta:set_int("src_time", 0)
                return
            end

            if (not enabled) then
                technic.swap_node(pos, machine_node)
                meta:set_string("infotext",
                    machine_desc_tier .. S(" Disabled") .. "\nHP: " .. meta:get_int("hp") .. "/" .. data.hp .. "\n" ..
                        S("Charge: ") .. meta:get_int("charge") .. "/" .. meta:get_int("charge_max"))
                meta:set_int(tier .. "_EU_demand", 0)
                meta:set_int("src_time", 0)
                --[[local formspec = ship_weapons.update_formspec(data, false, enabled, 0, charge, charge_max,
                    meta:get_int("attack_type"), meta)
                meta:set_string("formspec", formspec)]] --
                return
            end

            if needs_charge(pos) then
                meta:set_int(tier .. "_EU_demand", machine_demand_active[1])
            else
                meta:set_int(tier .. "_EU_demand", machine_demand_idle)
            end

            if meta:get_int("last_hit") >= 1 then
                meta:set_int("last_hit", meta:get_int("last_hit") - 1)
            end

            local isFiring = meta:get_int("firing") ~= 0
            meta:set_int("firing", 0)

            if powered and (not needs_charge(pos) or (isFiring and has_charge(pos))) and meta:get_int("last_hit") == 0 then
                --technic.swap_node(pos, machine_node .. "_idle")
                meta:set_string("infotext",
                    machine_desc_tier .. S(" Operational") .. "\nHP: " .. meta:get_int("hp") .. "/" .. data.hp .. "\n" ..
                        S("Charge: ") .. meta:get_int("charge") .. "/" .. meta:get_int("charge_max"))
                -- meta:set_int(tier .. "_EU_demand", machine_demand_idle)
                --meta:set_int("src_time", 0)

                -- Get a missile from inventory...
                local last_target = core.deserialize(meta:get_string("last_target")) or nil

                if digiline_data.launch then
                    -------------------------------------------------------
                    -- strike launch to target location
                    local proj_def = {
                        tier = ltier,
                        delay = digiline_data.delay,
                        count = 1
                    }
                    local bFoundTarget = false
                    local nTargetCount = digiline_data.count
                    local dir = ship_weapons.get_port_direction(pos)
                    local target_pos = digiline_data.target_pos or 
                            ship_weapons.calculateNewPoint(pos, dir, digiline_data.power, digiline_data.pitch, digiline_data.yaw)
                    -- minetest.log("nx= " .. target_pos.x .. "  ny=" .. target_pos.y .. "  nz=" .. target_pos.z)
                    --[[if ship_weapons.rail_cannon_launch(proj_def, owner, pos, target_pos, nil) then
                        bFoundTarget = true;
                    end]]
                    if bFoundTarget then
                        meta:set_int("firing", 1)
                        charge = charge - (10 * nTargetCount)
                        meta:set_int("charge", charge)
                        digiline_data.count = nTargetCount - 1
                        if digiline_data.count <= 0 then
                            digiline_data.launch = false
                            digiline_data.target_pos = nil
                        end
                        -- Update digiline data...
                        meta:set_string("digiline_data", minetest.serialize(digiline_data))
                        --break;
                    end
                elseif meta:get_int("attack_type") == 6 then
                    -------------------------------------------------------
                    -- strike launch to target ship
                    local proj_def = {
                        delay = 1,
                        tier = ltier
                    }
                    local attack_type = meta:get_int("attack_type")
                    local bFoundTarget = false
                    local nTargetCount = 0
                    local target = find_random_target_ship(pos)
                    local v = 0
                    if target ~= nil and target.pos ~= nil then
                        v = ship_weapons.rail_cannon_frag(proj_def, owner, pos, target.pos, nil)
                    end
                    if v > 0 then
                        meta:set_string("last_target", core.serialize(target.pos)) 
                        bFoundTarget = true;
                        if v > 1 then
                            nTargetCount = nTargetCount + 1
                        end
                    else
                        local _rot = {x = 0, y = 0, z = 0}
                        meta:set_string("target_dir", core.serialize(_rot))
                    end
                    if bFoundTarget then
                        meta:set_int("firing", 1)
                        charge = charge - (10 * nTargetCount)
                        if charge < 0 then
                            charge = 0
                        end                        
                        meta:set_int("charge", charge)
                        --break;
                    else
                        meta:set_int("firing", 0)
                    end
                    -- end strike
                elseif meta:get_int("attack_type") > 1 then
                    -------------------------------------------------------
                    -- strike launch to target object
                    local proj_def = {
                        mount_dir = mount_dir,
                        delay = 1,
                        tier = ltier
                    }
                    local attack_type = meta:get_int("attack_type")
                    local bFoundTarget = false
                    local nTargetCount = 0
                    local target = find_random_target(pos)
                    local v = 0
                    if target ~= nil and target.pos ~= nil then
                        v = ship_weapons.rail_cannon_frag(proj_def, owner, pos, target.pos, target.obj)
                    else
                        local _rot = {x = 0, y = 0, z = 0}
                        meta:set_string("target_dir", core.serialize(_rot))
                    end
                    if v > 0 then
                        meta:set_string("last_target", core.serialize(target.pos)) 
                        bFoundTarget = true;
                        if v > 1 then
                            nTargetCount = nTargetCount + 1
                        end
                    end
                    if bFoundTarget then
                        meta:set_int("firing", 1)
                        charge = charge - (10 * nTargetCount)
                        if charge < 0 then
                            charge = 0
                        end
                        meta:set_int("charge", charge)
                        --break;
                    else
                        meta:set_int("firing", 0)
                    end
                    -- end strike
                end
                --return
            end
            if needs_charge(pos) then
                --technic.swap_node(pos, machine_node .. "_active")
                local chrg = math.random(0, 2)
                if charge + chrg > charge_max then
                    chrg = 0;
                end
                meta:set_int("charge", charge + chrg)
            end

            if meta:get_int("last_hit") >= 1 then
                meta:set_int("last_hit", meta:get_int("last_hit") - 1)
                return
            end

            local charging = S(" Charging")
            if not needs_charge(pos) then
                charging = S(" Charged")
            end
            meta:set_string("infotext",
                machine_desc_tier .. charging .. "\nHP: " .. meta:get_int("hp") .. "/" .. data.hp .. "\n" ..
                    S("Charge: ") .. meta:get_int("charge") .. "/" .. meta:get_int("charge_max"))
            if meta:get_int("src_time") < round(time_scl * 10) then
                if not powered then
                    meta:set_string("infotext", machine_desc_tier .. S(" Unpowered"))
                    return
                end
                return
            end

            meta:set_int("src_time", 0)
            local last_target = core.deserialize(meta:get_string("last_target")) or nil
            if last_target and not find_target(last_target, 5, false, meta) then
                meta:set_string("last_target", nil) 
            end
            --core.log("reset cannon tick last_target...")
            --return
        end
    end

    -------------------------------------------------------
    -- register machine node

    local node_name = data.modname .. ":" .. ltier .. "_" .. machine_name
    local _def_node = {
        description = machine_desc,
        tiles = {ltier .. "_" .. tmachine_name .. "_base_top.png", ltier .. "_" .. tmachine_name .. "_base.png",
                 ltier .. "_" .. tmachine_name .. "_base_side.png", ltier .. "_" .. tmachine_name .. "_base_side.png",
                 ltier .. "_" .. tmachine_name .. "_base_side.png",
                 ltier .. "_" .. tmachine_name .. "_base_side.png"},
        param = "light",
        --paramtype2 = "facedir",
	    paramtype2 = "wallmounted",
        light_source = 5,
        drawtype = "mesh",
        mesh = "cannon_base1.obj",
        --tiles = {"lv_rail_cannon_base.png", "lv_rail_cannon_base_top.png"},
        --[[drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, 0.5, -0.3125, 0.5}, -- NodeBox1
                {-0.375, -0.3125, -0.375, 0.375, -0.125, 0.375}, -- NodeBox2
                {-0.25, -0.125, -0.25, 0.25, 0.25, 0.25}, -- NodeBox3
                {-0.1875, 0.25, -0.1875, 0.1875, 0.5, 0.1875}, -- NodeBox4
            }
        },]]
        --inventory_image = "rail_cannon_inv_image.png",
        --wield_image = "rail_cannon_inv_image.png",
        inventory_image = ltier .. "_rail_cannon_inv_image.png",
        wield_image = ltier .. "_rail_cannon_inv_image.png",
        drop = data.modname .. ":" .. ltier .. "_" .. machine_name,
        groups = groups,
        connect_sides = connect_sides_floor,
        --legacy_facedir_simple = true,
        sounds = default.node_sound_metal_defaults(),
        on_rotate = screwdriver.disallow,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            if placer:is_player() then
                meta:set_string("owner", placer:get_player_name())
                meta:set_string("members", "")
            end
            meta:set_int("hp", data.hp)
            meta:set_int("attack_type", 1)
            meta:set_int("last_hit", 0)
                        
            local under = pointed_thing.under
            local above = pointed_thing.above
            local wdir = minetest.dir_to_wallmounted(vector.subtract(under, above))
            --local mount_dir = meta:get_string("mount_dir")
            local gun_pos = pos
            local mount_dir = "wall"
            local yaw = 0
            if wdir == 0 then
                mount_dir = "ceiling"
                gun_pos = vector.add(pos, {x = 0, y =-0.65, z = 0})
            elseif wdir == 1 then
                mount_dir = "floor"
                gun_pos = vector.add(pos, {x = 0, y =0.65, z = 0})
            elseif wdir == 2 then
                mount_dir = "wall"
                gun_pos = vector.add(pos, {x = -0.65, y =0, z = 0})
                yaw = math.rad(270)
            elseif wdir == 3 then
                mount_dir = "wall"
                gun_pos = vector.add(pos, {x = 0.65, y =0, z = 0})
                yaw = math.rad(90)
            elseif wdir == 4 then
                mount_dir = "wall"
                gun_pos = vector.add(pos, {x = 0, y =0, z = -0.65})
                yaw = math.rad(0)
            elseif wdir == 5 then
                mount_dir = "wall"
                gun_pos = vector.add(pos, {x = 0, y =0, z = 0.65})
                yaw = math.rad(180)
            end
            local ent_obj = minetest.add_entity(gun_pos, "ship_weapons:" .. ltier .. "_rail_cannon_barrel")
            if wdir == 1 then
                ent_obj:set_properties({_mount_dir = "floor"})
            elseif wdir == 0 then
                ent_obj:set_properties({_mount_dir = "ceiling"})
                ent_obj:set_rotation({x=0,y=0,z=math.rad(180)})
            else
                ent_obj:set_properties({_mount_dir = "wall"})
                ent_obj:set_rotation({x=0,y=yaw,z=0})
                meta:set_string("target_dir", core.serialize({x = 0, y = yaw, z = 0}))
            end
            --core.log(mount_dir .. " " .. tostring(wdir))
            meta:set_string("mount_dir", mount_dir)
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            remove_attached(pos)
            local origin_str = pos.x .. "," .. pos.y .. "," .. pos.z
            recent_cannons[origin_str] = nil
            return technic.machine_after_dig_node
        end,
        --can_dig = technic.machine_can_dig,
        on_rightclick = rightclick,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "LV Rail Cannon")
            local inv = meta:get_inventory()
            inv:set_size("src", 1)
            meta:set_int("enabled", 1)
            meta:set_int("charge", 0)
            meta:set_int("broken", 0)
            meta:set_int("charge_max", data.charge_max)
            meta:set_int("demand", data.demand[1])
            meta:set_string("target_dir", core.serialize({x = 0, y = 0, z = 0}))
            local formspec = ship_weapons.update_formspec(data, meta)
            meta:set_string("formspec", formspec)
            meta:set_string("digiline_data", minetest.serialize(default_digi_data))
        end,
        allow_metadata_inventory_put = technic.machine_inventory_put,
        allow_metadata_inventory_take = function(pos, listname, index, stack, player)
            if listname == "src" then
                return 0
            end
            return technic.machine_inventory_take(pos, listname, index, stack, player)
        end,
        allow_metadata_inventory_move = technic.machine_inventory_move,
        technic_run = run,
        on_receive_fields = on_receive_fields,
        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                rules = technic.digilines.rules_allfaces,
                action = data.digiline_effector
            }
        },
        --on_punch = on_punch,
        on_timer = on_timer
    }
    local def_node_floor = table.copy(_def_node)
    local def_node_ceiling = table.copy(_def_node)
    local def_node_wall = table.copy(_def_node)
    def_node_floor.on_place = function(itemstack, placer, pointed_thing)
        local under = pointed_thing.under
        local node = minetest.get_node(under)
        local def = minetest.registered_nodes[node.name]
        if def and def.on_rightclick and
            not (placer and placer:is_player() and placer:get_player_control().sneak) then
            return def.on_rightclick(under, node, placer, itemstack, pointed_thing) or itemstack
        end
        local above = pointed_thing.above
        local wdir = minetest.dir_to_wallmounted(vector.subtract(under, above))
        local fakestack = itemstack
        if wdir == 0 then
            fakestack:set_name(node_name .. "_ceiling")
        elseif wdir == 1 then
            fakestack:set_name(node_name)
        else
            fakestack:set_name(node_name .. "_wall")
        end
        itemstack = minetest.item_place(fakestack, placer, pointed_thing, wdir)
        itemstack:set_name(node_name)
        return itemstack
    end
    def_node_ceiling.node_box = {
        type = "fixed",
        fixed = {
			{-0.5, 0.3125, -0.5, 0.5, 0.5, 0.5}, -- NodeBox1
			{-0.375, 0.125, -0.375, 0.375, 0.3125, 0.375}, -- NodeBox2
			{-0.25, -0.25, -0.25, 0.25, 0.125, 0.25}, -- NodeBox3
			{-0.1875, -0.5, -0.1875, 0.1875, -0.25, 0.1875}, -- NodeBox4
        }
    }
    --[[def_node_ceiling.after_place_node = function(pos, placer, itemstack, pointed_thing)
        local gun_pos = vector.add(pos, {x = 0, y =-0.65, z = 0})
        local ent_obj = minetest.add_entity(gun_pos, "ship_weapons:" .. ltier .. "_rail_cannon_barrel")
        --local cannon = etc:get_luaentity()
        ent_obj:set_properties({_mount_dir = "ceiling"})
        ent_obj:set_rotation({x=0,y=0,z=math.rad(180)})
        local meta = minetest.get_meta(pos)
        if placer:is_player() then
            meta:set_string("owner", placer:get_player_name())
            meta:set_string("members", "")
        end
        meta:set_int("hp", data.hp)
        meta:set_int("attack_type", 1)
        meta:set_int("last_hit", 0)
    end]]
    --[[def_node_ceiling.tiles = {ltier .. "_" .. tmachine_name .. "_base.png", ltier .. "_" .. tmachine_name .. "_base_top.png",
             ltier .. "_" .. tmachine_name .. "_base_side.png^[transformFY", ltier .. "_" .. tmachine_name .. "_base_side.png^[transformFY",
             ltier .. "_" .. tmachine_name .. "_base_side.png^[transformFY",
             ltier .. "_" .. tmachine_name .. "_base_side.png^[transformFY"}]]
    def_node_ceiling.connect_sides = connect_sides_ceiling
    def_node_ceiling.groups = active_groups
	def_node_ceiling.paramtype2 = "wallmounted"
    def_node_wall.connect_sides = connect_sides_wall
    def_node_wall.groups = active_groups
	def_node_wall.paramtype2 = "wallmounted"
    minetest.register_node(node_name .. "", def_node_floor)
    minetest.register_node(node_name .. "_wall", def_node_wall)
    minetest.register_node(node_name .. "_ceiling", def_node_ceiling)
    
    minetest.register_on_player_receive_fields(function(player, formname, fields)
        if formname ~= data.modname .. ":" .. ltier .. "_" .. tmachine_name then
            return
        end
        local name = player:get_player_name()
        local pos = player_pos[name]
        if not name or not pos then
            return
        end
        on_receive_fields(pos, formname, fields, player)
        if fields.quit or fields.close_me then
            return
        end
        local meta = core.get_meta(pos)
        core.show_formspec(name, data.modname .. ":" .. ltier .. "_" .. tmachine_name, ship_weapons.update_formspec(data, meta))
    end)

    local _def_node_broken = {
        description = machine_desc,
        tiles = {ltier .. "_" .. machine_name .. "_base_top_broken.png", ltier .. "_" .. tmachine_name .. "_base_broken.png",
                 ltier .. "_" .. machine_name .. "_base_side_broken.png",
                 ltier .. "_" .. machine_name .. "_base_side_broken.png",
                 ltier .. "_" .. machine_name .. "_base_side_broken.png",
                 ltier .. "_" .. machine_name .. "_base_side_broken.png"},
        param = "light",
        --paramtype2 = "facedir",
	    paramtype2 = "wallmounted",
        drawtype = "mesh",
        mesh = "cannon_base1.obj",
        --[[drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, 0.5, -0.3125, 0.5}, -- NodeBox1
                {-0.375, -0.3125, -0.375, 0.375, -0.125, 0.375}, -- NodeBox2
                {-0.25, -0.125, -0.25, 0.25, 0.25, 0.25}, -- NodeBox3
                {-0.1875, 0.25, -0.1875, 0.1875, 0.5, 0.1875}, -- NodeBox4
            }
        },]]
        light_source = 1,
        drop = data.modname .. ":" .. ltier .. "_" .. machine_name .. "_broken",
        groups = active_groups,
        connect_sides = connect_sides_floor,
        legacy_facedir_simple = true,
        sounds = default.node_sound_metal_defaults(),
        on_rotate = screwdriver.disallow,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            --minetest.get_node_timer(pos):start(30)
            meta:set_int("attack_type", 1)
            meta:set_int("last_hit", 0)
            if placer:is_player() then
                meta:set_string("owner", placer:get_player_name())
                meta:set_string("members", "")
            end
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            remove_attached(pos)
            local origin_str = pos.x .. "," .. pos.y .. "," .. pos.z
            recent_cannons[origin_str] = nil
            return technic.machine_after_dig_node
        end,
        --can_dig = technic.machine_can_dig,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Broken " .. tier .. " Rail Cannon")
            local inv = meta:get_inventory()
            inv:set_size("src", 1)
            meta:set_int("enabled", 1)
            meta:set_int("charge", 0)
            meta:set_int("broken", 1)
            meta:set_int("charge_max", data.charge_max)
            meta:set_int("demand", data.demand[1])
            local formspec = ship_weapons.update_formspec(data, meta)
            meta:set_string("formspec", formspec)
            meta:set_string("digiline_data", minetest.serialize(default_digi_data))
        end,
        allow_metadata_inventory_put = technic.machine_inventory_put,
        allow_metadata_inventory_take = technic.machine_inventory_take,
        allow_metadata_inventory_move = technic.machine_inventory_move,
        technic_run = run,
        on_receive_fields = on_receive_fields,
        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                rules = technic.digilines.rules_allfaces,
                action = data.digiline_effector
            }
        },
        on_timer = function(pos, elapsed)
            local meta = minetest.get_meta(pos)
            local time = meta:get_int("time") + elapsed
            if time >= 1 then
                local mount_dir = meta:get_string("mount_dir")
                if mount_dir == "floor" then
                    technic.swap_node(pos, "ship_weapons:" .. ltier .. "_" .. tmachine_name)
                elseif mount_dir == "wall" then
                    technic.swap_node(pos, "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_wall")
                elseif mount_dir == "ceiling" then
                    technic.swap_node(pos, "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_ceiling")
                end
                meta:set_int("broken", 0);
                --minetest.add_entity(pos, "ship_weapons:" .. ltier .. "_rail_cannon_display")
                meta:set_int("hp", data.hp)
                meta:set_int("charge", 0)
            else
                meta:set_int("time", time)
                return true
            end
        end

    }
    local def_node_broken_floor = table.copy(_def_node_broken)
    local def_node_broken_wall = table.copy(_def_node_broken)
    local def_node_broken_ceiling = table.copy(_def_node_broken)
    def_node_broken_wall.connect_sides = connect_sides_wall;
    def_node_broken_ceiling.connect_sides = connect_sides_ceiling;
    def_node_broken_floor.on_place = function(itemstack, placer, pointed_thing)
        local under = pointed_thing.under
        local node = minetest.get_node(under)
        local def = minetest.registered_nodes[node.name]
        if def and def.on_rightclick and
            not (placer and placer:is_player() and placer:get_player_control().sneak) then
            return def.on_rightclick(under, node, placer, itemstack, pointed_thing) or itemstack
        end
        local above = pointed_thing.above
        local wdir = minetest.dir_to_wallmounted(vector.subtract(under, above))
        local fakestack = itemstack
        if wdir == 0 then
            fakestack:set_name(node_name .. "_broken" .. "_ceiling")
        elseif wdir == 1 then
            fakestack:set_name(node_name .. "_broken")
        else
            fakestack:set_name(node_name .. "_broken" .. "_wall")
        end

        itemstack = minetest.item_place(fakestack, placer, pointed_thing, wdir)
        itemstack:set_name(node_name)
        return itemstack
    end
    --[[def_node_broken_ceiling.node_box = {
        type = "fixed",
        fixed = {
			{-0.5, 0.3125, -0.5, 0.5, 0.5, 0.5}, -- NodeBox1
			{-0.375, 0.125, -0.375, 0.375, 0.3125, 0.375}, -- NodeBox2
			{-0.25, -0.25, -0.25, 0.25, 0.125, 0.25}, -- NodeBox3
			{-0.1875, -0.5, -0.1875, 0.1875, -0.25, 0.1875}, -- NodeBox4
        }
    }]]
    --[[def_node_broken_ceiling.tiles = {ltier .. "_" .. tmachine_name .. "_base_broken.png", ltier .. "_" .. tmachine_name .. "_base_top_broken.png",
             ltier .. "_" .. tmachine_name .. "_base_side_broken.png^[transformFY", ltier .. "_" .. tmachine_name .. "_base_side_broken.png^[transformFY",
             ltier .. "_" .. tmachine_name .. "_base_side_broken.png^[transformFY",
             ltier .. "_" .. tmachine_name .. "_base_side_broken.png^[transformFY"}]]
    def_node_broken_ceiling.connect_sides = connect_sides_ceiling
    
	def_node_broken_ceiling.paramtype2 = "wallmounted"
	def_node_broken_wall.paramtype2 = "wallmounted"

    minetest.register_node(node_name .. "_broken", def_node_broken_floor)
    minetest.register_node(node_name .. "_wall_broken", def_node_broken_wall)
    minetest.register_node(node_name .. "_ceiling_broken", def_node_broken_ceiling)

    technic.register_machine(tier, node_name, technic.receiver)
    technic.register_machine(tier, node_name .. "_wall", technic.receiver)
    technic.register_machine(tier, node_name .. "_wall_broken", technic.receiver)
    technic.register_machine(tier, node_name .. "_ceiling", technic.receiver)
    technic.register_machine(tier, node_name .. "_ceiling_broken", technic.receiver)
    technic.register_machine(tier, node_name .. "_broken", technic.receiver)

    -------------------------------------------------------
    -------------------------------------------------------

    -------------------------------------------------------
    -------------------------------------------------------

    -- display entity shown for turret top and barrels
    minetest.register_entity("ship_weapons:" .. ltier .. "_rail_cannon_barrel", {
        initial_properties = {
            physical = true,
            collide_with_objects = true,
            collisionbox = {-0.21875, -0.25, -0.21875, 0.21875, 0.28125, 0.21875},
            visual = "wielditem",
            wield_item = "ship_weapons:" .. ltier .. "_rail_cannon_barrel_node",
            --textures = {"ship_weapons:" .. ltier .. "_rail_cannon_barrel_node"},
            -- wielditem seems to be scaled to 1.5 times original node size
            --[[visual_size = {
                x = 0.67,
                y = 0.67
            },]]
            type = "turret",
            hp_max = data.hp,
            glow = 3,
            infotext = "HP: " .. data.hp .. "/" .. data.hp .. "",
        },

        _timer = 1,
        _time_idler = 0,
        _rotating = false,
        _rotation_done = false,
        _rotation_set = {x = 0, y = 0, z = 0},
        _rotation_dir = 1,
        _target_found = false,
        _reset_tick = 0,
        _mount_dir = "floor",

        on_step = function(self, dtime)
            self._timer = self._timer + 1
            if self._timer <= 3 then
                return
            end
            self._timer = 0
            local t_update = false
            local pos = nil
            local mount_dir = ""
            local pos_ceiling = vector.add(self.object:get_pos(), {x=0,y=0.65,z=0})
            local pos_wall =  minetest.find_node_near(self.object:get_pos(), 1.05, "group:ship_cannon")
            if core.get_node(pos_ceiling).name:match("_ceiling") then
                self._mount_dir = "ceiling"
                mount_dir = "ceiling"
                pos = pos_ceiling
            elseif pos_wall and core.get_node(pos_wall).name:match("_wall") then
                self._mount_dir = "wall"
                mount_dir = "wall"
                pos = pos_wall
            else
                self._mount_dir = "floor"
                mount_dir = "floor"
                pos = vector.add(self.object:get_pos(), {x=0,y=-0.65,z=0})
            end
            local node = core.get_node(pos)
            local meta = core.get_meta(pos)
            if node and not node.name:gsub("_" .. mount_dir, ""):match(ltier .. "_" .. tmachine_name) then
                --core.log('node not match entity')
                self.object:remove()
                return
            end
            
            local function num_is_close(target, actual, thrs)
                local target_frac = (target * 0.001) + thrs
                return actual < target + target_frac and actual >= target - target_frac
            end

            local function do_move(rot_from, rot_to)
                if rot_from == nil then
                    return false
                end
                local cur_pitch_deg = math.deg(rot_from.x)
                local cur_yaw_deg = math.deg(rot_from.y)
                local cur_roll_deg = math.deg(rot_from.z)
                local new_pitch_deg = math.deg(rot_to.x) - 1.5
                local new_yaw_deg = math.deg(rot_to.y)
                local new_roll_deg = 0
                if mount_dir == "ceiling" then
                    new_roll_deg = 180
                    if new_pitch_deg > 80 then
                        new_pitch_deg = 80
                    elseif new_pitch_deg < -10 then
                        new_pitch_deg = -10
                    end
                elseif mount_dir == "wall" then
                    new_roll_deg = 0
                    local dir = ship_weapons.get_port_wall_direction(pos)
                    if dir.x == 1 then
                        if new_yaw_deg > 180 then
                            new_yaw_deg = math.random(0, 180)
                            t_update = true
                        end
                    elseif dir.x == -1 then
                        if new_yaw_deg < 180 then
                            new_yaw_deg = math.random(180, 360)
                            t_update = true
                        end
                    end
                    if dir.z == 1 then
                        if new_yaw_deg > 270 or new_yaw_deg < 90 then
                            new_yaw_deg = math.random(90, 270)
                            t_update = true
                        end
                    elseif dir.z == -1 then
                        if new_yaw_deg < 270 and new_yaw_deg > 90 then
                            new_yaw_deg = math.random(-90, 90)
                            if new_yaw_deg < 0 then
                                new_yaw_deg = new_yaw_deg + 360
                            end
                            t_update = true
                        end
                    end
                    if new_pitch_deg > 70 then
                        new_pitch_deg = 70
                    elseif new_pitch_deg < -70 then
                        new_pitch_deg = -70
                    end
                else
                    if new_pitch_deg > 30 then
                        new_pitch_deg = 30
                    elseif new_pitch_deg < -60 then
                        new_pitch_deg = -60
                    end
                end
                --core.log(new_pitch_deg)
                local n_pitchDegrees = ((cur_pitch_deg * 15) + new_pitch_deg) / 16
                local n_yawDegrees = cur_yaw_deg
                if not self._rotation_done and not num_is_close(new_yaw_deg, cur_yaw_deg, 1) then
                    local amt = 3
                    if num_is_close(new_yaw_deg, cur_yaw_deg, 10) then
                        amt = 0.25
                    end
                    local dir_to = self._rotation_dir or 1
                    if not self._rotating and cur_yaw_deg > new_yaw_deg then
                        dir_to = -1
                    elseif not self._rotating and cur_yaw_deg < new_yaw_deg then
                        dir_to = 1
                    end
                    if not self._rotating and math.abs(cur_yaw_deg) + math.abs(new_yaw_deg) > 180 then
                        if math.abs(new_yaw_deg) - math.abs(cur_yaw_deg) > 180 or math.abs(cur_yaw_deg) - math.abs(new_yaw_deg) > 180 then
                            if cur_yaw_deg > new_yaw_deg then
                                dir_to = 1
                            elseif cur_yaw_deg < new_yaw_deg then
                                dir_to = -1
                            end
                            self._rotating = true
                        end
                    end
                    n_yawDegrees = cur_yaw_deg + (amt * dir_to)
                    if n_yawDegrees > 360 then
                        n_yawDegrees = 5
                        self._rotating = false
                    elseif n_yawDegrees < 0 then
                        n_yawDegrees = 355
                        self._rotating = false
                    end
                    self._rotation_dir = dir_to
                elseif not self._rotation_done and self._rotating then
                    n_yawDegrees = ((cur_yaw_deg * 5) + new_yaw_deg) / 6
                end
                --self._rotation_done = false
                if num_is_close(new_pitch_deg, n_pitchDegrees, 1.25) and num_is_close(new_yaw_deg, n_yawDegrees, 1.45) then
                    self._rotation_done = true
                    self._rotating = false
                    --return false
                end
                local pitchRad = math.rad(n_pitchDegrees)
                local yawRad = math.rad(n_yawDegrees)
                local rollRad = math.rad(new_roll_deg)
                local rot = {x = pitchRad, y = yawRad, z = rollRad}
                self.object:set_rotation(rot);
                if t_update then
                    local t_rot = {x = rot_to.x, y = math.rad(new_yaw_deg), z = rot_to.z}
                    meta:set_string("target_dir", core.serialize(t_rot))
                    self._rotation_set = t_rot
                end
                return true
            end

            local target_rot = core.deserialize(meta:get_string("target_dir")) or {x = 0, y = 0, z = 0}
            if target_rot.x ~= 0 and target_rot.y ~= 0 then
                self._rotation_set = target_rot
                self._target_found = true
                self._reset_tick = 0
                local a_yaw = math.abs(math.deg(self.object:get_rotation().y))
                local t_yaw = math.abs(math.deg(target_rot.y))
                if math.abs(a_yaw - t_yaw) > 7 then
                    --core.log("resetting fire_tick")
                    self._rotation_done = false
                    self._target_found = false
                    self._time_idler = 0
                end
            else
                self._target_found = false
            end

            if self._rotation_set == nil then
                local new_rot = { x = math.rad(-(math.random(-25, 30))), y = math.rad((math.random(0, 360))), z = 0}
                self._rotation_set = new_rot
                self._rotation_done = false
            end
            
            if self._reset_tick < 500 then
                self._reset_tick = self._reset_tick + 1
            else                
                self._reset_tick = 0
                self._target_found = false
                local new_rot = { x = 0, y = 0, z = 0}
                meta:set_string("target_dir", core.serialize(new_rot))
                local new_rot = { x = math.rad(-(math.random(-25, 30))), y = math.rad((math.random(0, 360))), z = 0}
                self._rotation_set = new_rot
            end

            self._time_idler = self._time_idler + 1
            if self.object and not do_move(self.object:get_rotation(), self._rotation_set) then
                self._time_idler = self._time_idler + math.random(1, 2)
            end

            if self._time_idler > 200 and self._rotation_done then
                self._time_idler = 0
                if not self._target_found then
                    self._rotation_done = false
                    self._reset_tick = 0
                    if mount_dir == "ceiling" then
                        local new_rot = { x = math.rad(-(math.random(-60, 10))), y = math.rad((math.random(0, 360))), z = 0}
                        self._rotation_set = new_rot
                    else
                        local new_rot = { x = math.rad(-(math.random(-25, 30))), y = math.rad((math.random(0, 360))), z = 0}
                        self._rotation_set = new_rot
                    end
                end
            end
        end,

        on_death = function(self, killer)
            local pos = self.object:get_pos()
            local y = -0.65
            local _tmachine_name = tmachine_name
            local o_pos = pos
            if self._mount_dir == "ceiling" then
                y = 0.65
                o_pos = vector.add(pos, {x=0,y=y,z=0})
            elseif self._mount_dir == "wall" then
                local pos_wall =  minetest.find_node_near(self.object:get_pos(), 1.05, "group:ship_cannon")
                o_pos = pos_wall
            end
            local o_pos = vector.add(pos, {x=0,y=y,z=0}) 
            technic.swap_node(o_pos, "ship_weapons:" .. ltier .. "_" .. _tmachine_name .. "_broken")
            if o_pos then
                spawn_particle2(o_pos, ltier)
                minetest.get_node_timer(pos):start(30)
                local meta = core.get_meta(o_pos)
                meta:set_int("broken", 1)
                meta:set_int("hp", 0)
            end
        end,

        on_rightclick = function(self, clicker)
            local pos = self.object:get_pos()            
            local y = -0.65
            local o_pos = vector.add(pos, {x=0,y=y,z=0})
            if self._mount_dir == "ceiling" then
                y = 0.65
                o_pos = vector.add(pos, {x=0,y=y,z=0})
            elseif self._mount_dir == "wall" then
                local pos_wall =  minetest.find_node_near(self.object:get_pos(), 1.05, "group:ship_cannon")
                o_pos = pos_wall
            end
            local node = core.get_node(o_pos)
            core.registered_nodes[node.name].on_rightclick(o_pos, node, clicker, nil)
        end,

        on_punch = function(puncher, time_from_last_punch, tool_capabilities, direction, damage)

            local function on_hit(self, target)
                local o_y = -0.65
                local _tmachine_name = tmachine_name
                local _target = vector.add(target, {x=0,y=o_y,z=0}) 
                if self._mount_dir == "ceiling" then
                    o_y = 0.65
                    _target = vector.add(target, {x=0,y=o_y,z=0}) 
                    _tmachine_name = tmachine_name .. "_ceiling"
                elseif self._mount_dir == "wall" then
                    local pos_wall =  minetest.find_node_near(target, 1.07, "group:ship_cannon")
                    o_y = 0
                    _target = pos_wall
                    _tmachine_name = tmachine_name .. "_wall"
                end
                target = _target
                local node = minetest.get_node(target)
                local meta = minetest.get_meta(target)
                -- minetest.log("hit " .. node.name)

                if node.name == "ship_weapons:" .. ltier .. "_" .. _tmachine_name then
                    --technic.swap_node(target, "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "")
                    spawn_particle2(target, ltier)

                    local hp = meta:get_int("hp") or 1
                    meta:set_int("hp", hp - 1)
                    meta:set_int("last_hit", meta:get_int("last_hit") + math.random(2, 7))

                    self.object:set_properties({
                        infotext = "HP: " .. meta:get_int("hp") .. "/" .. data.hp .. ""
                    })

                    if hp - 1 <= 0 then
                        technic.swap_node(target, "ship_weapons:" .. ltier .. "_" .. _tmachine_name .. "_broken")
                        meta:set_int("broken", 1)
                        self.object:remove()
                        minetest.get_node_timer(target):start(math.random(data.repair_length, data.repair_length + 30))
                        minetest.sound_play("ctg_zap", {
                            pos = target,
                            gain = 0.5,
                            pitch = randFloat(5.2, 5.25)
                        })
                    end

                    return true
                elseif node.name == "ship_weapons:" .. ltier .. "_" .. _tmachine_name .. "_broken" then
                    local meta = minetest.get_meta(target)
                    if meta:get_int("broken") == 1 then
                        self.object:remove()
                    end
                end
                return false
            end

            if puncher and puncher.object then
                local pos = puncher.object:get_pos();
                on_hit(puncher, pos)
                return 0;
            end

            return damage;
        end
    })

    -- Display-zone node, Do NOT place the display as a node,
    -- it is made to be used as an entity (see above)

    minetest.register_node("ship_weapons:" .. ltier .. "_rail_cannon_barrel_node", {
        tiles = {
            ltier .. "_rail_cannon_top.png", -- top
            ltier .. "_rail_cannon_bottom.png", -- bottom
            ltier .. "_rail_cannon_right.png", -- right
            ltier .. "_rail_cannon_left.png", -- left
            ltier .. "_rail_cannon_back.png", -- back
            ltier .. "_rail_cannon_front.png" -- front
        },
        use_texture_alpha = "clip",
        walkable = false,
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {
                {-0.1875, -0.1875, -0.1875, 0.1875, 0.1875, 0.1875}, -- base1
                {-0.09375, -0.125, -0.375, 0.09375, 0.125, -0.25}, -- base2
                {-0.0625, -0.0625, -0.625, 0.0625, 0.0625, -0.375}, -- base_arm
                {-0.046875, 0.03125, -1, 0.046875, 0.0625, -0.625}, -- arm_top
                {0.03125, -0.0625, -1.125, 0.0625, 0, -0.625}, -- arm_right
                {-0.0625, -0.0625, -1.125, -0.03125, 0, -0.625}, -- arm_left
                {-0.125, -0.15625, -0.25, 0.125, 0.15625, -0.1875}, -- base3
                {-0.125, -0.1875, 0.1875, 0.125, 0.125, 0.25}, -- base4
                {-0.125, 0.1875, 0, 0.125, 0.21875, 0.1875}, -- base_top
                {-0.125, -0.25, -0.125, 0.125, -0.1875, 0.125}, -- base_bottom
                {-0.0625, 0.1875, -0.1875, 0.0625, 0.25, 0.0625}, -- base_top2
            }
        },
        collision_box = {
            type = "fixed",
            fixed = {
                {-0.21875, -0.25, -0.21875, 0.21875, 0.28125, 0.21875}
            }
        },
        selection_box = {
            type = "fixed",
            fixed = {
                {-0.21875, -0.25, -0.21875, 0.21875, 0.28125, 0.21875}
            }
        },
        paramtype = "light",
        groups = {
            dig_immediate = 3,
            not_in_creative_inventory = 1
        },
        drop = ""

    })

    -------------------------------------------------------

    local function spawn_particle_area(pos, tier)
        local dir = ship_weapons.get_port_wall_direction(pos)
        local meta = minetest.get_meta(pos)
        local hp = meta:get_int("hp")
        --local amount = hp + math.random(1, hp + 1)
        local def = {
            amount = 20,
            time = randFloat(2.6, 5.2),
            collisiondetection = true,
            collision_removal = false,
            object_collision = false,
            vertical = false,
                texture = {
                name = "ctg_beam_effect2_".. tier .. ".png",
                alpha_tween = {1, 0.2},
                scale_tween = {{
                    x = 2.0,
                    y = 2.2
                }, {
                    x = 0.1,
                    y = 0.0
                }},
                blend = "alpha"
            },
            glow = 13,
                minpos = {
                x = pos.x + (0.66 * dir.x),
                y = pos.y + (0.67 * dir.y),
                z = pos.z + (0.66 * dir.z)
            },
            maxpos = {
                x = pos.x + (0.76 * dir.x),
                y = pos.y + (0.74 * dir.y),
                z = pos.z + (0.76 * dir.z)
            },
            minvel = {
                x = -0.13,
                y = 0.09,
                z = -0.13
            },
            maxvel = {
                x = 0.13 + (dir.x * 0.25),
                y = 0.12 + (dir.y * 0.25),
                z = 0.13 + (dir.z * 0.25)
            },
            minacc = {
                x = -0.07,
                y = -0.08,
                z = -0.07
            },
            maxacc = {
                x = 0.07,
                y = 0.12,
                z = 0.07
            },
            minexptime = 4.6,
            maxexptime = 6.8,
            minsize = 0.5,
            maxsize = 0.8
        }
    
        minetest.add_particlespawner(def);
    end

    minetest.register_abm({
        label = "rail cannon effect",
        nodenames = {"ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_broken", "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_wall_broken", "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_ceiling_broken"},
        interval = 2,
        chance = 3,
        -- min_y = 0,
        action = function(pos)
            spawn_particle_area(pos, ltier)
        end
    })

end

-------------------------------------------------------
-------------------------------------------------------

local function register_lv_rail_cannon(ref)
    local data = ref or {}
    data.modname = "ship_weapons"
    data.machine_name = "rail_cannon"
    data.machine_desc = "Rail Cannon"
    data.charge_max = 25
    data.demand = {8000}
    data.speed = 10
    data.tier = "LV"
    data.typename = "rail_cannon"
    data.digiline_effector = ship_weapons.mstatic_turret_digiline_effector
    data.range = 80
    data.hp = 10
    data.repair_length = 300
    data.targets = 1
    data.damage = 1.0
    data.connect_sides = {
        bottom = 1
    }
    ship_weapons.register_rail_cannon(data)
end

local function register_mv_rail_cannon(ref)
    local data = ref or {}
    data.modname = "ship_weapons"
    data.machine_name = "rail_cannon"
    data.machine_desc = "Rail Cannon"
    data.charge_max = 40
    data.demand = {8000}
    data.speed = 15
    data.tier = "MV"
    data.typename = "rail_cannon"
    data.digiline_effector = ship_weapons.static_turret_digiline_effector
    data.range = 92
    data.hp = 16
    data.repair_length = 300
    data.targets = 1
    data.damage = 1.0
    data.connect_sides = {
        bottom = 1
    }
    ship_weapons.register_rail_cannon(data)
end

local function register_hv_rail_cannon(ref)
    local data = ref or {}
    data.modname = "ship_weapons"
    data.machine_name = "rail_cannon"
    data.machine_desc = "Rail Cannon"
    data.charge_max = 70
    data.demand = {8000}
    data.speed = 20
    data.tier = "HV"
    data.typename = "rail_cannon"
    data.digiline_effector = ship_weapons.static_turret_digiline_effector
    data.range = 104
    data.hp = 21
    data.repair_length = 300
    data.targets = 1
    data.damage = 1.0
    data.connect_sides = {
        bottom = 1
    }
    ship_weapons.register_rail_cannon(data)
end

register_lv_rail_cannon()
--register_mv_rail_cannon()
--register_hv_rail_cannon()
