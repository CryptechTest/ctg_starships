local S = minetest.get_translator(minetest.get_current_modname())

local time_scl = 30

local has_pipeworks = minetest.get_modpath("pipeworks")
local tube_entry_metal = ""
if has_pipeworks then
    tube_entry_metal = "^pipeworks_tube_connection_metallic.png"
end

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

local function get_missile(items, tier)
    local new_input = {}
    local new_output = nil
    local found_item = false;
    for i, stack in ipairs(items) do
        if stack:get_name() == 'ship_weapons:' .. tier .. '_missile' then
            new_input[i] = ItemStack(stack)
            new_input[i]:take_item(1)
            new_output = nil
            found_item = true
            break
        end
    end
    if (found_item) then
        return {
            new_input = new_input,
            output = new_output
        }
    else
        return nil
    end
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

local function calculateDisplacement(pos, dir, power, angleForceDirection)
    -- Convert pitch and yaw to a unit vector for direction in 2D if necessary.
    local pitch = math.rad(angleForceDirection.pitch or 0)
    local yaw = math.rad(angleForceDirection.yaw or 0)

    local flipped = false
    local xz1 = pos.x
    local xz2 = pos.z
    local yy1 = pos.y
    --[[if dir.x == 1 or dir.x == -1 then
        xz1 = pos.z
        xz2 = pos.x
        flipped = true
    elseif dir.z == 1 or dir.z == -1 then
        xz1 = pos.x
        xz2 = pos.z
    end]] --

    -- Calcaulate displacement
    local displacementX = xz1 + (power * math.sin(yaw)) * 2 + (10 * dir.x)
    local displacementY = yy1 + (power * math.sin(pitch)) * 2 + (10 * dir.y)
    local displacementZ = xz2 + (power * math.cos(yaw)) * 2 + (10 * dir.z)
    -- Return target coordinates considering force direction.
    if flipped then
        return {
            x = displacementZ,
            y = displacementY,
            z = displacementX
        }
    else
        return {
            x = displacementX,
            y = displacementY,
            z = displacementZ
        }
    end
end

local function calculateNewPoint(pos, dir, power, pitchDegrees, yawDegrees)
    local pitch = 90
    local yaw = 0
    local vertical = false

    if dir.x == 1 then
        yaw = -180
    elseif dir.x == -1 then
        yaw = 0
    elseif dir.z == 1 then
        yaw = -90
    elseif dir.z == -1 then
        yaw = 90
    elseif dir.y == 1 then
        pitch = 0
        yaw = 180
        vertical = true
    elseif dir.y == -1 then
        pitch = -180
        yaw = 0
        vertical = true
    end

    -- Spherical to Cartesian coordinates conversion formulae:
    -- x = r * sin(theta) * cos(phi)
    -- y = r * sin(theta) * sin(phi)
    -- z = r * cos(theta)

    if not vertical then
        -- Convert degrees to radians
        local pitchRad = math.rad((pitchDegrees * 0.5) - pitch)
        local yawRad = math.rad(-(yawDegrees * 0.5) + yaw)

        local newX = power * math.sin(pitchRad) * math.cos(yawRad)
        local newZ = power * math.sin(pitchRad) * math.sin(yawRad)
        local newY = power * math.cos(pitchRad)
        return vector.add(pos, {
            x = newX,
            y = newY,
            z = newZ
        })
    else
        -- Convert degrees to radians
        local pitchRad = math.rad((pitchDegrees * 0.5) + pitch)
        local yawRad = math.rad(-(yawDegrees * 0.5) + yaw)

        local newX = power * math.sin(pitchRad) * math.cos(yawRad)
        local newZ = power * math.cos(pitchRad) * math.sin(yawRad)
        local newY = power * math.cos(pitchRad)
        return vector.add(pos, {
            x = newX,
            y = newY,
            z = newZ
        })
    end
end

-------------------------------------------------------

function ship_weapons.missile_strike(def, op, origin, pos_target, object_target)
    local bClear = true;
    local ray = minetest.raycast(origin, pos_target, true, false)
    for pointed_thing in ray do
        if pointed_thing.type == "node" then
            local pos = pointed_thing.intersection_point
            if (vector.distance(origin, pos) > 0.25) and (vector.distance(pos_target, pos) > 1) then
                local node = minetest.get_node(pos)
                if node.name ~= "air" and node.name ~= "vacuum:vacuum" and node.name ~= "vacuum:atmos_thin" then
                    bClear = false;
                    break
                end
            end
        end
    end

    if not bClear then
        return false
    end

    local target = vector.add(pos_target, {
        x = randFloat(-0.2, 0.2),
        y = randFloat(-0.15, 0.2),
        z = randFloat(-0.2, 0.2)
    })

    local dist = vector.distance(origin, target)
    -- minetest.log("missile pew pew! " .. tostring(dist))

    ship_weapons.launch_missile_projectile(def, op, origin, target, object_target)
    return true
end

function ship_weapons.missile_launch(def, op, origin, pos_target, object_target)
    local target = vector.add(pos_target, {
        x = randFloat(-0.2, 0.2),
        y = randFloat(-0.2, 0.2),
        z = randFloat(-0.2, 0.2)
    })

    local dist = vector.distance(origin, target)
    -- minetest.log("missile pew pew! " .. tostring(dist))

    ship_weapons.launch_missile_projectile(def, op, origin, target, object_target)
    return true
end

-------------------------------------------------------
-------------------------------------------------------

function ship_weapons.register_missile_tower(data)
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
        ship_weapon = 1
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

    local tube = technic.new_default_tube()
    if data.can_insert then
        tube.can_insert = data.can_insert
    end
    if data.insert_object then
        tube.insert_object = data.insert_object
    end
    if data.connect_sides then
        tube.connect_sides = data.connect_sides
    end

    local connect_sides = {"top", "bottom", "left", "right"}

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

    local on_punch = function(pos, node, puncher, pointed_thing)

        -- minetest.log("punched node")

        local function on_hit(self, target)

            local node = minetest.get_node(target)
            -- minetest.log("hit node " .. node.name)
            if node.name == "ship_weapons:" .. ltier .. "_" .. tmachine_name or node.name == "ship_weapons:" .. ltier ..
                "_" .. tmachine_name .. "_active" or node.name == "ship_weapons:" .. ltier .. "_" .. tmachine_name ..
                "_idle" then

                technic.swap_node(target, "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_broken")
            end

            -- return old_def(self, target)
        end

        on_hit(pos, pos)
    end

    local on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        technic.swap_node(pos, "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_idle")
        meta:set_int("broken", 0);
        local objs = minetest.get_objects_inside_radius(pos, 0.45)
        for _, obj in pairs(objs) do
            if obj:get_luaentity() then
                local ent = obj:get_luaentity()
                if ent.name == "ship_weapons:" .. ltier .. "_missile_tower_display" then
                    obj:set_properties({
                        is_visible = true
                    })
                    break
                end
            end
        end
    end

    local on_receive_fields = function(pos, formname, fields, sender)
        if fields.quit then
            return
        end
        local name = sender:get_player_name()
        if not name or not pos then
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
            end
            meta:set_int("attack_type", attack_type)
        end

        local add_member_input = fields.add_member
        -- reset formspec until close button pressed
        if (fields.close_me or fields.quit) and (not add_member_input or add_member_input == "") then
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
        local objs = minetest.get_objects_inside_radius(pos, 0.25)
        for _, obj in pairs(objs) do
            if obj:get_luaentity() then
                local ent = obj:get_luaentity()
                if ent.name == "ship_weapons:" .. ltier .. "_missile_tower_display" then
                    obj:remove()
                    break
                end
            end
        end
    end

    local function check_display(pos)
        if not minetest.compare_block_status(pos, "active") then
            return
        end
        local found_display = false
        local objs = minetest.get_objects_inside_radius(pos, 0.5)
        for _, obj in pairs(objs) do
            if obj:get_luaentity() then
                local ent = obj:get_luaentity()
                if ent.name == "ship_weapons:" .. ltier .. "_missile_tower_display" then
                    if found_display then
                        obj:remove()
                    end
                    found_display = true
                end
            end
        end
        if not found_display then
            minetest.add_entity(pos, "ship_weapons:" .. ltier .. "_missile_tower_display")
            minetest.get_node_timer(pos):start(30)
        end
    end

    -------------------------------------------------------
    -------------------------------------------------------
    -- technic run
    local run = function(pos, node)
        local meta = minetest.get_meta(pos)
        local owner = meta:get_string("owner")
        --local operator = minetest.get_player_by_name(owner);
        local inv = meta:get_inventory()
        local eu_input = meta:get_int(tier .. "_EU_input")

        local machine_desc_tier = machine_desc:format(tier)
        local machine_node = data.modname .. ":" .. ltier .. "_" .. machine_name
        local machine_demand_active = data.demand
        local machine_demand_idle = data.demand[1] * 0.1

        local charge_max = meta:get_int("charge_max")
        local charge = meta:get_int("charge")

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

        local EU_upgrade, tube_upgrade = 0, 0
        if data.upgrade then
            EU_upgrade, tube_upgrade = technic.handle_machine_upgrades(meta)
        end
        if data.tube then
            technic.handle_machine_pipeworks(pos, tube_upgrade)
        end

        local powered = eu_input >= machine_demand_idle
        if powered then
            meta:set_int("src_time", meta:get_int("src_time") + round(data.speed * 10 * 1.0))
        end
        while true do
            local enabled = meta:get_int("enabled") == 1

            if meta:get_int("broken") == 1 then
                technic.swap_node(pos, machine_node .. "_broken")
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
                meta:set_int(tier .. "_EU_demand", machine_demand_active[EU_upgrade + 1])
            else
                meta:set_int(tier .. "_EU_demand", machine_demand_idle)
            end

            if meta:get_int("last_hit") >= 1 then
                meta:set_int("last_hit", meta:get_int("last_hit") - 1)
            end

            local isFiring = meta:get_int("firing") ~= 0

            if powered and (not needs_charge(pos) or (isFiring and has_charge(pos))) and meta:get_int("last_hit") == 0 then
                technic.swap_node(pos, machine_node .. "_idle")
                meta:set_string("infotext",
                    machine_desc_tier .. S(" Operational") .. "\nHP: " .. meta:get_int("hp") .. "/" .. data.hp .. "\n" ..
                        S("Charge: ") .. meta:get_int("charge") .. "/" .. meta:get_int("charge_max"))
                -- meta:set_int(tier .. "_EU_demand", machine_demand_idle)
                meta:set_int("src_time", 0)

                -- Get a missile from inventory...
                local missile_item = get_missile(inv:get_list("src"), ltier)

                if missile_item and digiline_data.launch then
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
                                           calculateNewPoint(pos, dir, digiline_data.power, digiline_data.pitch,
                            digiline_data.yaw)
                    -- minetest.log("nx= " .. target_pos.x .. "  ny=" .. target_pos.y .. "  nz=" .. target_pos.z)
                    if ship_weapons.missile_launch(proj_def, owner, pos, target_pos, nil) then
                        bFoundTarget = true;
                    end
                    if bFoundTarget then
                        meta:set_int("firing", 1)
                        meta:set_int("charge", charge - 1)
                        digiline_data.count = nTargetCount - 1
                        if digiline_data.count <= 0 then
                            digiline_data.launch = false
                            digiline_data.target_pos = nil
                        end
                        -- Update digiline data...
                        meta:set_string("digiline_data", minetest.serialize(digiline_data))
                        -- Reduce inventory storage
                        if (missile_item.new_input) then
                            inv:set_list("src", missile_item.new_input)
                        end
                    end
                elseif missile_item and meta:get_int("attack_type") > 1 then
                    -------------------------------------------------------
                    -- strike launch to target object
                    local proj_def = {
                        delay = 3,
                        tier = ltier
                    }
                    local attack_type = meta:get_int("attack_type")
                    local bFoundTarget = false
                    local nTargetCount = 0
                    local objs = minetest.get_objects_inside_radius(pos, data.range + 0.251)
                    for _, obj in pairs(objs) do
                        if nTargetCount >= data.targets then
                            break
                        end
                        local obj_pos = obj:get_pos()
                        if obj:get_luaentity() and not obj:is_player() then
                            local ent = obj:get_luaentity()
                            if ent.name == "__builtin:item" and (attack_type == 2) then
                                -- objects...
                                local item1 = obj:get_luaentity().itemstring
                                -- local obj2 = minetest.add_entity(exit, "__builtin:item")
                                if ship_weapons.missile_strike(proj_def, owner, pos, obj_pos, obj) then
                                    bFoundTarget = true;
                                    nTargetCount = nTargetCount + 1
                                end

                            elseif ent.type and (ent.type == "npc" or ent.type == "animal" or ent.type == "monster") then
                                -- monsters
                                if ent.type == "monster" and (attack_type == 2 or attack_type == 3 or attack_type == 5) then
                                    if ship_weapons.missile_strike(proj_def, owner, pos, obj_pos, obj) then
                                        bFoundTarget = true;
                                        nTargetCount = nTargetCount + 1
                                    end
                                end
                            end
                        elseif obj:is_player() and (attack_type == 2 or attack_type == 4 or attack_type == 5) then
                            local name = obj:get_player_name()
                            -- players
                            if name ~= meta:get_string("owner") and not ship_weapons.is_member(meta, name) and not ship_weapons.is_ally(meta, name) then
                                if ship_weapons.missile_strike(proj_def, owner, pos, obj_pos, obj) then
                                    bFoundTarget = true;
                                    nTargetCount = nTargetCount + 1
                                end
                            end
                        end
                        if bFoundTarget and math.random(1, 20) == 1 then
                            break
                        end
                    end

                    if bFoundTarget then
                        meta:set_int("firing", 1)
                        meta:set_int("charge", charge - nTargetCount)
                        -- Reduce inventory storage
                        if (missile_item.new_input) then
                            inv:set_list("src", missile_item.new_input)
                        end
                    else
                        meta:set_int("firing", 0)
                    end

                    -- end strike
                end
                return
            end
            if needs_charge(pos) then
                technic.swap_node(pos, machine_node .. "_active")
            end

            if meta:get_int("last_hit") >= 1 then
                -- meta:set_int("last_hit", meta:get_int("last_hit") - 1)
                return
            end

            meta:set_int("firing", 0)

            local charging = S(" Charging")
            if not needs_charge(pos) then
                charging = S(" Charged")
            end
            meta:set_string("infotext",
                machine_desc_tier .. charging .. "\nHP: " .. meta:get_int("hp") .. "/" .. data.hp .. "\n" ..
                    S("Charge: ") .. meta:get_int("charge") .. "/" .. meta:get_int("charge_max"))
            if meta:get_int("src_time") < round(time_scl * 10) then
                local item_percent = (math.floor(meta:get_int("src_time") / round(time_scl * 10) * 100))
                if not powered then
                    technic.swap_node(pos, machine_node)
                    meta:set_string("infotext", machine_desc_tier .. S(" Unpowered"))
                    --[[local formspec = ship_weapons.update_formspec(data, false, enabled, item_percent, charge,
                        charge_max, meta:get_int("attack_type"), meta)
                    meta:set_string("formspec", formspec)]] --
                    -- ship_machine.reset_generator(meta)
                    return
                end
                --[[local formspec = ship_weapons.update_formspec(data, true, enabled, item_percent, charge, charge_max,
                    meta:get_int("attack_type"), meta)
                meta:set_string("formspec", formspec)]] --
                return
            end

            local chrg = math.random(1, 2)
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
        tiles = {ltier .. "_" .. tmachine_name .. "_top.png", ltier .. "_" .. tmachine_name .. "_top.png",
                 ltier .. "_" .. tmachine_name .. "_side.png", ltier .. "_" .. tmachine_name .. "_side.png",
                 ltier .. "_" .. tmachine_name .. "_side.png" .. tube_entry_metal,
                 ltier .. "_" .. tmachine_name .. "_front.png"},
        paramtype2 = "facedir",
        drop = data.modname .. ":" .. ltier .. "_" .. machine_name,
        groups = groups,
        connect_sides = connect_sides,
        tube = data.tube and tube or nil,
        legacy_facedir_simple = true,
        sounds = default.node_sound_metal_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            if data.tube then
                pipeworks.after_place(pos)
            end
            minetest.add_entity(pos, "ship_weapons:" .. ltier .. "_missile_tower_display")

            local meta = minetest.get_meta(pos)
            if placer:is_player() then
                meta:set_string("owner", placer:get_player_name())
                meta:set_string("members", "")
            end
            meta:set_int("hp", data.hp)
            meta:set_int("attack_type", 1)
            meta:set_int("last_hit", 0)
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            remove_attached(pos)
            if data.tube then
                pipeworks.after_dig(pos)
            end
            return technic.machine_after_dig_node
        end,
        -- on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Missile Tower Emitter")
            meta:set_int("tube_time", 0)
            local inv = meta:get_inventory()
            inv:set_size("src", 1)
            inv:set_size("dst", 1)
            inv:set_size("upgrade1", 1)
            inv:set_size("upgrade2", 1)
            meta:set_int("enabled", 1)
            meta:set_int("charge", 0)
            meta:set_int("broken", 0)
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
        -- on_punch = on_punch,
        on_timer = on_timer
    })

    minetest.register_node(node_name .. "_active", {
        description = machine_desc,
        tiles = {ltier .. "_" .. machine_name .. "_top.png", ltier .. "_" .. tmachine_name .. "_top.png",
                 ltier .. "_" .. tmachine_name .. "_side.png", ltier .. "_" .. tmachine_name .. "_side.png",
                 ltier .. "_" .. tmachine_name .. "_side.png" .. tube_entry_metal,
                 ltier .. "_" .. tmachine_name .. "_front.png"},
        param = "light",
        paramtype2 = "facedir",
        light_source = 4,
        drop = data.modname .. ":" .. ltier .. "_" .. machine_name,
        groups = active_groups,
        connect_sides = connect_sides,
        tube = data.tube and tube or nil,
        legacy_facedir_simple = true,
        sounds = default.node_sound_metal_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            if data.tube then
                pipeworks.after_place(pos)
            end
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            if data.tube then
                pipeworks.after_dig(pos)
            end
            remove_attached(pos)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,

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
        -- on_punch = on_punch,
        on_timer = on_timer
    })

    minetest.register_node(node_name .. "_idle", {
        description = machine_desc,
        tiles = {ltier .. "_" .. machine_name .. "_top.png", ltier .. "_" .. tmachine_name .. "_top.png",
                 ltier .. "_" .. machine_name .. "_side.png", ltier .. "_" .. machine_name .. "_side.png",
                 ltier .. "_" .. machine_name .. "_side.png" .. tube_entry_metal,
                 ltier .. "_" .. tmachine_name .. "_front.png"},
        param = "light",
        paramtype2 = "facedir",
        light_source = 3,
        drop = data.modname .. ":" .. ltier .. "_" .. machine_name,
        groups = active_groups,
        connect_sides = connect_sides,
        tube = data.tube and tube or nil,
        legacy_facedir_simple = true,
        sounds = default.node_sound_metal_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            if data.tube then
                pipeworks.after_place(pos)
            end
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            remove_attached(pos)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,

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
        -- on_punch = on_punch,
        on_timer = on_timer
    })

    minetest.register_node(node_name .. "_broken", {
        description = machine_desc,
        tiles = {ltier .. "_" .. machine_name .. "_top.png", ltier .. "_" .. tmachine_name .. "_top.png",
                 ltier .. "_" .. machine_name .. "_side_cracked.png",
                 ltier .. "_" .. machine_name .. "_side_cracked.png",
                 ltier .. "_" .. machine_name .. "_side_cracked.png" .. tube_entry_metal,
                 ltier .. "_" .. machine_name .. "_front_cracked.png"},
        -- param = "light",
        paramtype2 = "facedir",
        -- light_source = 1,
        drop = data.modname .. ":" .. ltier .. "_" .. machine_name .. "_broken",
        groups = active_groups,
        connect_sides = connect_sides,
        tube = data.tube and tube or nil,
        legacy_facedir_simple = true,
        sounds = default.node_sound_metal_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            if data.tube then
                pipeworks.after_place(pos)
            end
            local meta = minetest.get_meta(pos)
            minetest.get_node_timer(pos):start(30)
            meta:set_int("attack_type", 1)
            meta:set_int("last_hit", 0)
            if placer:is_player() then
                meta:set_string("owner", placer:get_player_name())
                meta:set_string("members", "")
            end
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            remove_attached(pos)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Broken Starship Missile Emitter")
            meta:set_int("tube_time", 0)
            local inv = meta:get_inventory()
            inv:set_size("src", 1)
            inv:set_size("dst", 1)
            inv:set_size("upgrade1", 1)
            inv:set_size("upgrade2", 1)
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
                technic.swap_node(pos, "ship_weapons:" .. ltier .. "_" .. tmachine_name)
                meta:set_int("broken", 0);
                minetest.add_entity(pos, "ship_weapons:" .. ltier .. "_missile_tower_display")
                meta:set_int("hp", data.hp)
                meta:set_int("charge", 0)
            else
                meta:set_int("time", time)
                return true
            end
        end

    })

    technic.register_machine(tier, node_name, technic.receiver)
    technic.register_machine(tier, node_name .. "_active", technic.receiver)
    technic.register_machine(tier, node_name .. "_idle", technic.receiver)
    technic.register_machine(tier, node_name .. "_broken", technic.receiver)

    -------------------------------------------------------
    -------------------------------------------------------

    -- display entity shown for tower hit effect
    minetest.register_entity("ship_weapons:" .. ltier .. "_missile_tower_display", {
        initial_properties = {
            physical = false,
            collisionbox = {-0.75, -0.75, -0.75, 0.75, 0.75, 0.75},
            visual = "wielditem",
            -- wielditem seems to be scaled to 1.5 times original node size
            visual_size = {
                x = 0.67,
                y = 0.67
            },
            hp_max = 10,
            textures = {"ship_weapons:" .. ltier .. "_missile_tower_display_node"},
            glow = 8,
            infotext = "HP: " .. data.hp .. "/" .. data.hp .. "",
        },

        timer = 1,

        on_step = function(self, dtime)
            self.timer = self.timer + 1
            if self.timer < 3 then
                return
            end
            self.timer = 0
            local pos = self.object:get_pos()
            local node = minetest.get_node(pos)
            if node and not node.name:match(ltier .. "_" .. tmachine_name) then
                self.object:remove()
            end
        end,

        on_death = function(self, killer)
            local pos = self.object:get_pos()
            technic.swap_node(pos, "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_broken")
            minetest.get_node_timer(self.pos):start(30)
            local meta = minetest.get_meta(self.pos)
            meta:set_int("broken", 1)
            meta:set_int("hp", 0)
        end,

        on_rightclick = function(self, clicker)
            local pos = self.object:get_pos();
            if pos then
                -- self.object:remove()
                self.object:set_properties({
                    is_visible = false
                })
                minetest.get_node_timer(pos):start(3)
            end
        end,

        on_punch = function(puncher, time_from_last_punch, tool_capabilities, direction, damage)

            local function on_hit(self, target)

                local node = minetest.get_node(target)
                local meta = minetest.get_meta(target)
                -- minetest.log("hit " .. node.name)

                if node.name == "ship_weapons:" .. ltier .. "_" .. tmachine_name or node.name == "ship_weapons:" ..
                    ltier .. "_" .. tmachine_name .. "_active" or node.name == "ship_weapons:" .. ltier .. "_" ..
                    tmachine_name .. "_idle" then

                    -- and self.object:get_player_name() == meta:get_string("owner") 

                    technic.swap_node(target, "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "")
                    spawn_particle2(target, ltier)

                    local hp = meta:get_int("hp") or 1
                    meta:set_int("hp", hp - 1)
                    meta:set_int("last_hit", meta:get_int("last_hit") + math.random(2, 7))

                    self.object:set_properties({
                        infotext = "HP: " .. meta:get_int("hp") .. "/" .. data.hp .. ""
                    })

                    if hp - 1 <= 0 then
                        technic.swap_node(target, "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_broken")
                        meta:set_int("broken", 1)
                        self.object:remove()
                        minetest.get_node_timer(target):start(math.random(data.repair_length, data.repair_length + 30))
                        minetest.sound_play("ctg_zap", {
                            pos = target,
                            gain = 0.8,
                            pitch = randFloat(2.2, 2.25)
                        })
                    end

                    return true
                elseif node.name == "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_broken" then
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

    local x = 0.2
    local y = 0.2
    local z = 0.2
    minetest.register_node("ship_weapons:" .. ltier .. "_missile_tower_display_node", {
        tiles = {"ctg_tower_select_" .. ltier .. ".png"},
        use_texture_alpha = "clip",
        walkable = false,
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = { -- sides
            {-(x + .55), -(y + .55), -(z + .55), -(x + .45), (y + .55), (z + .55)},
            {-(x + .55), -(y + .55), (z + .45), (x + .55), (y + .55), (z + .55)},
            {(x + .45), -(y + .55), -(z + .55), (x + .55), (y + .55), (z + .55)},
            {-(x + .55), -(y + .55), -(z + .55), (x + .55), (y + .55), -(z + .45)}, -- top
            {-(x + .55), (y + .45), -(z + .55), (x + .55), (y + .55), (z + .55)}, -- bottom
            {-(x + .55), -(y + .55), -(z + .55), (x + .55), -(y + .45), (z + .55)} -- middle (surround protector)
            -- {-.55, -.55, -.55, .55, .55, .55}
            }
        },
        selection_box = {
            type = "regular"
        },
        paramtype = "light",
        groups = {
            dig_immediate = 3,
            not_in_creative_inventory = 1
        },
        drop = ""

    })

    -------------------------------------------------------

    --[[minetest.register_abm({
        label = "missile emitter effect",
        nodenames = {"ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_active", "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_idle"},
        interval = 3,
        chance = 3,
        -- min_y = 0,
        action = function(pos)
            local meta = minetest.get_meta(pos)
            if meta:get_int("last_hit") == 0 then
                --spawn_particle_area(pos, ltier)
            end
        end
    })]] --

end

-------------------------------------------------------
-------------------------------------------------------

local function register_lv_missile_tower(ref)
    local data = ref or {}
    data.modname = "ship_weapons"
    data.machine_name = "missile_tower"
    data.machine_desc = "Missile Emitter"
    data.charge_max = 9
    data.demand = {1000}
    data.speed = 20
    data.tier = "LV"
    data.typename = "missile_tower"
    data.digiline_effector = ship_weapons.missile_tower_digiline_effector
    data.range = 64
    data.hp = 5
    data.repair_length = 300
    data.targets = 1
    data.damage = 1.0
    data.tube = 1
    data.connect_sides = {
        back = 1
    }
    ship_weapons.register_missile_tower(data)
end

local function register_mv_missile_tower(ref)
    local data = ref or {}
    data.modname = "ship_weapons"
    data.machine_name = "missile_tower"
    data.machine_desc = "Missile Emitter"
    data.charge_max = 9
    data.demand = {2000}
    data.speed = 25
    data.tier = "MV"
    data.typename = "missile_tower"
    data.digiline_effector = ship_weapons.missile_tower_digiline_effector
    data.range = 72
    data.hp = 10
    data.repair_length = 270
    data.targets = 2
    data.damage = 2.07
    data.tube = 1
    data.connect_sides = {
        back = 1
    }
    ship_weapons.register_missile_tower(data)
end

local function register_hv_missile_tower(ref)
    local data = ref or {}
    data.modname = "ship_weapons"
    data.machine_name = "missile_tower"
    data.machine_desc = "Missile Emitter"
    data.charge_max = 9
    data.demand = {3000}
    data.speed = 30
    data.tier = "HV"
    data.typename = "missile_tower"
    data.digiline_effector = ship_weapons.missile_tower_digiline_effector
    data.range = 85
    data.hp = 15
    data.repair_length = 250
    data.targets = 3
    data.damage = 3.2
    data.tube = 1
    data.connect_sides = {
        back = 1
    }
    ship_weapons.register_missile_tower(data)
end

register_lv_missile_tower()
register_mv_missile_tower()
register_hv_missile_tower()
