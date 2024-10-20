local S = minetest.get_translator(minetest.get_current_modname())

local time_scl = 30

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

local function spawn_particle(pos, dir, i, dist, tier)
    local grav = 1;
    if (pos.y > 4000) then
        grav = 0.4;
    end
    dir = vector.multiply(dir, {
        x = 0.5,
        y = 0.5,
        z = 0.5
    })
    local i = (dist - (dist - i * 0.1)) * 0.064
    local t = 0.6 + i
    local def = {
        pos = pos,
        velocity = {
            x = dir.x,
            y = dir.y,
            z = dir.z
        },
        acceleration = {
            x = 0,
            y = randFloat(-0.02, 0.05) * grav,
            z = 0
        },

        expirationtime = t,
        size = randFloat(1.32, 1.6),
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        vertical = false,

        texture = {
            name = "ctg_beam_effect_anim_" .. tier .. ".png",
            alpha = 1.0,
            alpha_tween = {1, 0},
            scale_tween = {{
                x = 0.5,
                y = 0.5
            }, {
                x = 1.3,
                y = 1.3
            }},
            blend = "alpha"
        },
        animation = {
            type = "vertical_frames",
            aspect_w = 16,
            aspect_h = 16,
            length = t + 0.1
        },
        glow = 12
    }

    minetest.add_particle(def);
end

local function spawn_particle_hit(pos, tier)
    local def = {
        amount = 13,
        time = 0.6,
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        vertical = false,

        texture = {
            name = "ctg_beam_effect_" .. tier .. ".png",
            alpha_tween = {1, 0},
            scale_tween = {{
                x = 0.5,
                y = 0.5
            }, {
                x = 5,
                y = 5
            }},
            blend = "alpha"
        },
        glow = 12,

        minpos = {
            x = pos.x + -0.1,
            y = pos.y + 0,
            z = pos.z + -0.1
        },
        maxpos = {
            x = pos.x + 0.1,
            y = pos.y + 0.2,
            z = pos.z + 0.1
        },
        minvel = {
            x = 0,
            y = 0,
            z = 0
        },
        maxvel = {
            x = 0,
            y = 0.1,
            z = 0
        },
        minacc = {
            x = -0.5,
            y = 0.25,
            z = -0.5
        },
        maxacc = {
            x = 0.5,
            y = 0.75,
            z = 0.5
        },
        minexptime = 0.7,
        maxexptime = 1.0,
        minsize = 0.9,
        maxsize = 1.4
    }

    minetest.add_particlespawner(def);
end

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

local function spawn_particle_hit2(pos, tier)
    local grav = 1;
    if (pos.y > 4000) then
        grav = 0.4;
    end
    local def = {
        amount = 17,
        time = 0.35,
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        vertical = false,

        texture = {
            name = "ctg_beam_effect2_" .. tier .. ".png",
            alpha_tween = {1, 1, 0},
            scale_tween = {{
                x = 2.0,
                y = 2.0
            }, {
                x = 0.1,
                y = 0.1
            }},
            blend = "alpha"
        },
        glow = 12,

        minpos = {
            x = pos.x + -0.05,
            y = pos.y + -0.1,
            z = pos.z + -0.05
        },
        maxpos = {
            x = pos.x + 0.05,
            y = pos.y + 0.05,
            z = pos.z + 0.05
        },
        minvel = {
            x = -0.41,
            y = 2.76,
            z = -0.41
        },
        maxvel = {
            x = 0.41,
            y = 4.20,
            z = 0.41
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
        minexptime = 0.8,
        maxexptime = 2.5,
        minsize = 0.25,
        maxsize = 0.34
    }

    minetest.add_particlespawner(def);
end

local function spawn_particle_area(pos, tier)
    local meta = minetest.get_meta(pos)
    local hp = meta:get_int("hp")
    local amount = hp + math.random(1, hp + 1)
    local def = {
        amount = amount,
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
            x = pos.x + -0.66,
            y = pos.y + -0.46,
            z = pos.z + -0.66
        },
        maxpos = {
            x = pos.x + 0.66,
            y = pos.y + 0.54,
            z = pos.z + 0.66
        },
        minvel = {
            x = -0.13,
            y = 0.09,
            z = -0.13
        },
        maxvel = {
            x = 0.13,
            y = 0.12,
            z = 0.13
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
        minsize = 0.45,
        maxsize = 1.44
    }

    minetest.add_particlespawner(def);
end

function ship_weapons.strike_effect(pos1, pos2, tier)
    local bClear = true;
    local ray = minetest.raycast(pos1, pos2, true, false)
    for pointed_thing in ray do
        if pointed_thing.type == "node" then
            local pos = pointed_thing.intersection_point
            if (vector.distance(pos1, pos) > 0.25) and (vector.distance(pos2, pos) > 1) then
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

    local target = vector.add(pos2, {
        x = randFloat(-0.2, 0.2),
        y = randFloat(-0.15, 0.21),
        z = randFloat(-0.2, 0.2)
    })

    local dir = vector.direction(pos1, target)
    local dist = vector.distance(pos1, target)
    local step_min = 0.25
    local step = vector.multiply(dir, {
        x = step_min,
        y = step_min,
        z = step_min
    })

    minetest.after(0, function()
        minetest.sound_play("ctg_zap", {
            pos = pos1,
            gain = 1.3,
            pitch = randFloat(1.3, 1.5)
        })
    end)

    -- minetest.log("pew pew! " .. tostring(dist))

    minetest.after(0, function()
        local i = 1
        local cur_pos = pos1
        while (vector.distance(cur_pos, target) > step_min) do
            if math.random(1, 10) > 1 then
                spawn_particle(cur_pos, dir, i, vector.distance(cur_pos, target), tier)
            end
            cur_pos = vector.add(cur_pos, step)
            i = i + 1
            if i > 256 then
                break
            end
        end
    end)

    minetest.after(0.1, function()
        spawn_particle_hit(target, tier)
        spawn_particle_hit2(target, tier)
        minetest.sound_play("ctg_zap", {
            pos = target,
            gain = 0.4,
            pitch = randFloat(1.4, 1.6)
        })
        minetest.sound_play("ctg_hit3", {
            pos = target,
            gain = 0.3,
            pitch = randFloat(1.15, 1.3)
        })
    end)

    return true
end

-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------

function ship_weapons.register_beam_tower(data)
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

    local active_groups = {
        not_in_creative_inventory = 1
    }
    for k, v in pairs(groups) do
        active_groups[k] = v
    end

    -------------------------------------------------------

    local on_punch = function(pos, node, puncher, pointed_thing)

        -- minetest.log("punched node")

        local function on_hit(self, target)

            local node = minetest.get_node(target)
            -- minetest.log("hit node " .. node.name)
            if node.name == "ship_weapons:" .. ltier .. "_" .. tmachine_name or 
                node.name == "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_active" or
                node.name == "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_idle" then

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
                if ent.name == "ship_weapons:" .. ltier .. "_tower_display" then
                    obj:set_properties({
                        is_visible = true
                    })
                    break
                else
                    minetest.add_entity(pos, "ship_weapons:" .. ltier .. "_tower_display")
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
                if ent.name == "ship_weapons:" .. ltier .. "_tower_display" then
                    obj:remove()
                    break
                end
            end
        end
    end

    -------------------------------------------------------
    -------------------------------------------------------
    -- technic run
    local run = function(pos, node)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local eu_input = meta:get_int(tier .. "_EU_input")

        local machine_desc_tier = machine_desc:format(tier)
        local machine_node = data.modname .. ":" .. ltier .. "_" .. machine_name
        local machine_demand_active = data.demand
        local machine_demand_idle = data.demand[1] * 0.1

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

            if (not needs_charge(pos) or (isFiring and has_charge(pos))) and meta:get_int("last_hit") == 0 then
                technic.swap_node(pos, machine_node .. "_idle")
                meta:set_string("infotext",
                    machine_desc_tier .. S(" Operational") .. "\nHP: " .. meta:get_int("hp") .. "/" .. data.hp .. "\n" ..
                        S("Charge: ") .. meta:get_int("charge") .. "/" .. meta:get_int("charge_max"))
                -- meta:set_int(tier .. "_EU_demand", machine_demand_idle)
                meta:set_int("src_time", 0)
                --[[local formspec = ship_weapons.update_formspec(data, true, enabled, 0, charge, charge_max,
                    meta:get_int("attack_type"), meta)
                meta:set_string("formspec", formspec)]] --

                -------------------------------------------------------
                -- strike

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
                            if math.random(1, 4) == 1 then
                                bFoundTarget = true;
                                break
                            end
                            -- objects...
                            local item1 = obj:get_luaentity().itemstring
                            -- local obj2 = minetest.add_entity(exit, "__builtin:item")
                            if ship_weapons.strike_effect(pos, obj_pos, ltier) then
                                local hp = obj:get_hp()
                                obj:set_hp(hp - 1)
                                bFoundTarget = true;
                                nTargetCount = nTargetCount + 1
                            end

                        elseif ent.type and (ent.type == "npc" or ent.type == "animal" or ent.type == "monster") then

                            -- animals?
                            -- npc?

                            -- monsters
                            if ent.type == "monster" and (attack_type == 2 or attack_type == 3 or attack_type == 5) then
                                if math.random(1, 8) == 1 then
                                    bFoundTarget = true;
                                    break
                                end
                                if ship_weapons.strike_effect(pos, obj_pos, ltier) then
                                    ent.health = ent.health - (randFloat(1, 2.7, 1) * data.damage)
                                    obj:move_to({ x = obj_pos.x, y = obj_pos.y + 0.25, z = obj_pos.z })
                                    bFoundTarget = true;
                                    nTargetCount = nTargetCount + 1
                                end
                            end
                        end
                    elseif obj:is_player() and (attack_type == 2 or attack_type == 4 or attack_type == 5) then
                        local name = obj:get_player_name()
                        -- players
                        if name ~= meta:get_string("owner") and not ship_weapons.is_member(meta, name) then
                            if math.random(1, 6) == 1 then
                                bFoundTarget = true;
                                break
                            end
                            if ship_weapons.strike_effect(pos, obj_pos, ltier) then
                                local tool_capabilities = {
                                    full_punch_interval = 0.4,
                                    damage_groups = {
                                        fleshy = 3,
                                        level = 1
                                    },
                                    -- This is only used for digging nodes, but is still required
                                    max_drop_level = 1,
                                    groupcaps = {
                                        fleshy = {
                                            times = {
                                                [1] = 2.5,
                                                [2] = 1.20,
                                                [3] = 0.35
                                            },
                                            uses = 30,
                                            maxlevel = 2
                                        }
                                    }
                                }
                                local time_since_last_punch = tool_capabilities.full_punch_interval
                                obj:punch(obj, time_since_last_punch, tool_capabilities)

                                local hp = obj:get_hp()
                                obj:set_hp(hp - (randFloat(1, 2.5, 1) * data.damage))
                                obj:move_to({ x = obj_pos.x, y = obj_pos.y + 0.3, z = obj_pos.z })

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
                else
                    meta:set_int("firing", 0)
                end

                -- end strike
                return
            end
            if needs_charge(pos) then
                technic.swap_node(pos, machine_node .. "_active")
            end

            if meta:get_int("last_hit") >= 1 then
                --meta:set_int("last_hit", meta:get_int("last_hit") - 1)
                return
            end

            meta:set_int("firing", 0)

            meta:set_string("infotext",
                machine_desc_tier .. S(" Charging") .. "\nHP: " .. meta:get_int("hp") .. "/" .. data.hp .. "\n" ..
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
                 ltier .. "_" .. tmachine_name .. "_side.png", ltier .. "_" .. tmachine_name .. "_side.png"},
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
            minetest.add_entity(pos, "ship_weapons:" .. ltier .. "_tower_display")

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
            meta:set_string("infotext", "Beam Tower Emitter")
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
                action = data.digiline_effector
            }
        },
        -- on_punch = on_punch,
        on_timer = on_timer
    })

    local texture_active = {
        image = ltier .. "_" .. machine_name .. "_side_active_anim.png",
        animation = {
            type = "vertical_frames",
            aspect_w = 16,
            aspect_h = 16,
            length = 2
        }
    }

    minetest.register_node(node_name .. "_active", {
        description = machine_desc,
        tiles = {ltier .. "_" .. machine_name .. "_top_active.png", ltier .. "_" .. tmachine_name .. "_top.png",
                 texture_active, texture_active, texture_active, texture_active},
        param = "light",
        -- paramtype2 = "facedir",
        light_source = 10,
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
                action = data.digiline_effector
            }
        },
        -- on_punch = on_punch,
        on_timer = on_timer
    })

    minetest.register_node(node_name .. "_idle", {
        description = machine_desc,
        tiles = {ltier .. "_" .. machine_name .. "_top_active.png", ltier .. "_" .. tmachine_name .. "_top.png",
                 ltier .. "_" .. machine_name .. "_side_active.png", ltier .. "_" .. machine_name .. "_side_active.png",
                 ltier .. "_" .. machine_name .. "_side_active.png", ltier .. "_" .. machine_name .. "_side_active.png"},
        param = "light",
        -- paramtype2 = "facedir",
        light_source = 10,
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
                 ltier .. "_" .. machine_name .. "_side_cracked.png",
                 ltier .. "_" .. machine_name .. "_side_cracked.png"},
        -- param = "light",
        -- paramtype2 = "facedir",
        -- light_source = 10,
        drop = data.modname .. ":" .. ltier .. "_" .. machine_name .. "_broken",
        groups = active_groups,
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
            meta:set_string("infotext", "Broken Starship Laser Emitter")
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
                action = data.digiline_effector
            }
        },

        on_timer = function(pos, elapsed)
            local meta = minetest.get_meta(pos)
            local time = meta:get_int("time") + elapsed
            if time >= 1 then
                technic.swap_node(pos, "ship_weapons:" .. ltier .. "_" .. tmachine_name)
                meta:set_int("broken", 0);
                minetest.add_entity(pos, "ship_weapons:" .. ltier .. "_tower_display")
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
    minetest.register_entity("ship_weapons:" .. ltier .. "_tower_display", {
        physical = false,
        collisionbox = {-0.75, -0.75, -0.75, 0.75, 0.75, 0.75},
        visual = "wielditem",
        -- wielditem seems to be scaled to 1.5 times original node size
        visual_size = {
            x = 0.67,
            y = 0.67
        },
        hp_max = 10,
        textures = {"ship_weapons:" .. ltier .. "_tower_display_node"},
        glow = 3,

        infotext = "HP: " .. data.hp .. "/" .. data.hp .. "",

        on_death = function(self, killer)
            technic.swap_node(self.pos, "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_broken")
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

                if node.name == "ship_weapons:" .. ltier .. "_" .. tmachine_name or 
                    node.name == "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_active" or
                    node.name == "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_idle" then

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
    minetest.register_node("ship_weapons:" .. ltier .. "_tower_display_node", {
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

    minetest.register_abm({
        label = "beam emitterer effect",
        nodenames = {"ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_active", "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_idle"},
        interval = 3,
        chance = 3,
        -- min_y = 0,
        action = function(pos)
            local meta = minetest.get_meta(pos)
            if meta:get_int("last_hit") == 0 then
                spawn_particle_area(pos, ltier)
            end
        end
    })

end

-------------------------------------------------------
-------------------------------------------------------

local function register_lv_beam_tower(data)
    data.modname = "ship_weapons"
    data.machine_name = "beam_tower"
    data.machine_desc = "Beam Emitter"
    data.charge_max = 13
    data.demand = {2000}
    data.speed = 5
    data.tier = "LV"
    data.typename = "beam_tower"
    data.digiline_effector = nil
    data.range = 44
    data.hp = 8
    data.repair_length = 300
    data.targets = 2
    data.damage = 1.0

    ship_weapons.register_beam_tower(data)
end

local function register_mv_beam_tower(data)
    data.modname = "ship_weapons"
    data.machine_name = "beam_tower"
    data.machine_desc = "Beam Emitter"
    data.charge_max = 20
    data.demand = {5000}
    data.speed = 8
    data.tier = "MV"
    data.typename = "beam_tower"
    data.digiline_effector = nil
    data.range = 56
    data.hp = 13
    data.repair_length = 270
    data.targets = 2
    data.damage = 2.07

    ship_weapons.register_beam_tower(data)
end

local function register_hv_beam_tower(data)
    data.modname = "ship_weapons"
    data.machine_name = "beam_tower"
    data.machine_desc = "Beam Emitter"
    data.charge_max = 25
    data.demand = {8000}
    data.speed = 9
    data.tier = "HV"
    data.typename = "beam_tower"
    data.digiline_effector = nil
    data.range = 68
    data.hp = 15
    data.repair_length = 250
    data.targets = 3
    data.damage = 3.2

    ship_weapons.register_beam_tower(data)
end

register_lv_beam_tower({})
register_mv_beam_tower({})
register_hv_beam_tower({})
