-- The supply relay is a generic device which can wirelessly
-- send energy to another supply relay, up to 7 nodes away.
-- The machine is configured by the wiring attached to it.

local digilines_path = core.get_modpath("digilines")

local S = technic.getter

local cable_entry = "^technic_cable_connection_overlay.png"

local function get_facing_vector(pos)
    local node = core.get_node(pos)
    local param2 = node.param2
    -- get direction and rotation from param2
    local dir = math.floor(param2 / 4)
    local rot = param2 % 4
    local dir_x = 0
    local dir_z = 0
    local dir_y = 0
    if dir == 0 or dir == 5 then
        if rot == 0 then
            dir_z = 1
        elseif rot == 1 then
            dir_x = 1
        elseif rot == 2 then
            dir_z = -1
        elseif rot == 3 then
            dir_x = -1
        end
    elseif dir == 1 or dir == 3 then
        if rot == 0 then
            dir_y = -1
        elseif rot == 1 then
            dir_y = -1
        elseif rot == 2 then
            dir_y = 1
        elseif rot == 3 then
            dir_y = 1
        end
    elseif dir == 2 or dir == 4 then
        if rot == 0 then
            dir_y = 1
        elseif rot == 1 then
            dir_y = 1
        elseif rot == 2 then
            dir_y = 1
        elseif rot == 3 then
            dir_y = 1
        end
    end
    return {
        x = dir_x,
        y = dir_y,
        z = dir_z
    }
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

local match_facing = function(pos1, pos2)
    local dir1 = get_facing_vector(pos1)
    local dir2 = get_facing_vector(pos2)
    return dir1.x == -dir2.x and dir1.y == -dir2.y and dir1.z == -dir2.z
end

local function get_eff_by_dist(dist)
	-- 100%, 90%, 80%, 60%, 40%, 20%, 10%, 0%
	if dist <= 0 then
		return 1.0
	elseif dist == 1 then
		return 1.0
	elseif dist == 2 then
		return 0.9
	elseif dist == 3 then
		return 0.8
	elseif dist == 4 then
		return 0.6
	elseif dist == 5 then
		return 0.4
	elseif dist == 6 then
		return 0.2
	elseif dist == 7 then
		return 0.1
	elseif dist == 8 then
		return 0.05
	elseif dist > 8 then
		return 0
	end
end


local function do_beam_damage(pos, p)
    pos = vector.subtract(pos, {x=0,y=0.65,z=0})
    local range = 0.88
    local damage = randFloat(1, 3, 1) * p
    local objs = core.get_objects_inside_radius(pos, range + 0.251)
    for _, obj in pairs(objs) do
        local obj_pos = obj:get_pos()
        local dist = vector.distance(pos, obj_pos)
        local dmg = math.max(0.5, damage - dist)
        if obj:get_luaentity() and not obj:is_player() then
            local ent = obj:get_luaentity()
            if ent.name == "__builtin:item" then
                if math.random(1, 4) == 1 then
                    break
                end
                -- objects...
                local item1 = obj:get_luaentity().itemstring
                local hp = obj:get_hp()
                obj:set_hp(hp - 1)
            elseif ent.name:match("_ship_missile_projectile") then
                -- missiles?
                local hp = obj:get_hp()
                obj:set_hp(hp - 5)
            elseif ent.type and (ent.type == "npc" or ent.type == "animal" or ent.type == "monster") then
                -- mobs
                ent.health = ent.health - dmg
            end
        elseif obj:is_player() then
            local name = obj:get_player_name()
            -- players
            if math.random(1, 6) == 1 then
                break
            end
            local hp = obj:get_hp()
            obj:set_hp(hp - dmg)
        end
    end

end

local function spawn_particle(pos, dir, i, dist, tier, size)
    local grav = 1;
    if (pos.y > 4000) then
        grav = 0.4;
    end
    dir = vector.multiply(dir, {
        x = 0.45,
        y = 0.45,
        z = 0.45
    })
    local i = (dist - (dist - i * 0.1)) * 0.064
    local t = 1.88 + i + randFloat(0, 0.65)
    local texture = "ctg_" .. tier .. "_energy_particle.png"
    if math.random(0,1) == 0 then
        texture = "ctg_" .. tier .. "_energy_particle.png^[transformR90"
    end
    local def = {
        pos = pos,
        velocity = {
            x = dir.x,
            y = dir.y,
            z = dir.z
        },
        acceleration = {
            x = -dir.x * 0.1,
            y = randFloat(-0.02, 0.05) * grav,
            z = -dir.z * 0.1
        },

        expirationtime = t,
        size = randFloat(1.02, 1.42) * ((size + 0.75) / 2),
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        vertical = false,

        texture = {
            name = texture,
            alpha = 1.0,
            alpha_tween = {1, 0.1},
            scale_tween = {{
                x = 1.0,
                y = 1.0
            }, {
                x = 0.0,
                y = 0.0
            }},
            blend = "alpha"
        },
        glow = 13
    }

    core.add_particle(def);
end

local function spawn_particles(pos, dir, i, dist, tier, size)
    local c = 7
    if size <= 0.25 then
        c = 1
    elseif size <= 0.4 then
        c = 2
    elseif size <= 0.55 then
        c = 3
    elseif size <= 0.67 then
        c = 4
    elseif size <= 0.8 then
        c = 5
    elseif size <= 0.9 then
        c = 6
    end
    for n = 1, c do
        local r = 0.18 * ((size + 0.5) / 2)
        local p = vector.add(pos, {x=randFloat(-r,r),y=randFloat(-r,r),z=randFloat(-r,r)})
        spawn_particle(p, dir, i, dist, tier, size)
    end
end

local function create_beam(pos_start, pos_end, tier, p)
    
    local target = vector.add(pos_end, {
        x = randFloat(-0.025, 0.025),
        y = randFloat(-0.025, 0.025),
        z = randFloat(-0.025, 0.025)
    })

    local tier = (tier and tier or "LV"):lower()
    local size = math.max(0.1, p / 20000)
    local dir = vector.direction(pos_start, target)
    local dist = vector.distance(pos_start, target)
    local step_min = 0.10
    if size >= 0.6 then
        step_min = 0.30
    elseif size >= 0.4 then
        step_min = 0.20
    end
    local step = vector.multiply(dir, {
        x = step_min,
        y = step_min,
        z = step_min
    })

    local dmg_step = vector.multiply(dir, {
        x = 1.0,
        y = 1.0,
        z = 1.0
    })

    core.after(0, function()
        local i = 1
        local cur_pos = pos_start
        while (vector.distance(cur_pos, target) > step_min * 3) do
            spawn_particles(cur_pos, dir, i, vector.distance(cur_pos, target), tier, size)
            cur_pos = vector.add(cur_pos, step)
            i = i + 1
            if i > 128 then
                break
            end
        end
    end)

    core.after(0, function()
        local i = 1
        local cur_pos = pos_start
        while (vector.distance(cur_pos, target) > 1.0) do
            do_beam_damage(cur_pos, size)
            cur_pos = vector.add(cur_pos, dmg_step)
            i = i + 1
            if i > 16 then
                break
            end
        end
    end)

    core.after(0, function()
        if math.random(0,1) == 0 then
            core.sound_play("ctg_zap", {
                pos = pos_start,
                gain = 0.0245,
                pitch = randFloat(1.67, 1.8),
                max_hear_distance = 3
            })
        end
        if math.random(0,2) == 0 then
            core.sound_play("ctg_zap", {
                pos = pos_end,
                gain = 0.0167,
                pitch = randFloat(1.87, 1.95),
                max_hear_distance = 2.5
            })
        end
    end)
end

local function set_supply_converter_formspec(meta)
    local formspec = "size[5,3.25]"
    if digilines_path then
        formspec = formspec..
            "field[2.3,0.5;3,1;channel;"..S("Digiline Channel")..";${channel}]"
    end
    if meta:get_int("relay_mode") == 1 then
        formspec = formspec .. "field[0.3,0.5;2,1;power;"..S("Input Power")..";${power}]"
    else
        local eff = 100 - (meta:get_int("relay_eff") or 0)
        formspec = formspec .. "label[0.0,-0.105;Output Power]".."label[0.0,0.4;"..eff.."% Loss]"
    end
    if meta:get_int("mesecon_mode") == 0 then
        formspec = formspec.."button[0,1;5,1;mesecon_mode_1;"..S("Ignoring Mesecon Signal").."]"
    else
        formspec = formspec.."button[0,1;5,1;mesecon_mode_0;"..S("Controlled by Mesecon Signal").."]"
    end
    if meta:get_int("enabled") == 0 then
        formspec = formspec.."button[0,1.75;5,1;enable;"..S("@1 Disabled", S("Supply Relay")).."]"
    else
        formspec = formspec.."button[0,1.75;5,1;disable;"..S("@1 Enabled", S("Supply Relay")).."]"
    end
    if meta:get_int("relay_mode") == 0 then
        formspec = formspec.."button[0,2.5;5,1;mode_emitter;"..S("@1 Receiver", S("Supply Relay")).."]"
    else
        formspec = formspec.."button[0,2.5;5,1;mode_receiver;"..S("@1 Emitter", S("Supply Relay")).."]"
    end
    meta:set_string("formspec", formspec)
end

local supply_converter_receive_fields = function(pos, formname, fields, sender)
    if not sender or core.is_protected(pos, sender:get_player_name()) then
        return
    end
    local meta = core.get_meta(pos)
    local power = nil
    if fields.power then
        power = tonumber(fields.power) or 0
        power = math.max(power, 0)
        power = math.min(power, 20000)
        power = 100 * math.floor(power / 100)
        if power == meta:get_int("power") then power = nil end
    end
    if power then meta:set_int("power", power) end
    if fields.channel then meta:set_string("channel", fields.channel) end
    if fields.enable  then meta:set_int("enabled", 1) end
    if fields.disable then meta:set_int("enabled", 0) end
    if fields.mesecon_mode_0 then meta:set_int("mesecon_mode", 0) end
    if fields.mesecon_mode_1 then meta:set_int("mesecon_mode", 1) end
    if fields.mode_receiver then meta:set_int("relay_mode", 0) end
    if fields.mode_emitter then meta:set_int("relay_mode", 1) end
    set_supply_converter_formspec(meta)
end

local mesecons = {
    effector = {
        action_on = function(pos, node)
            core.get_meta(pos):set_int("mesecon_effect", 1)
        end,
        action_off = function(pos, node)
            core.get_meta(pos):set_int("mesecon_effect", 0)
        end
    }
}


local digiline_def = {
    receptor = {
        rules = technic.digilines.rules,
        action = function() end
    },
    effector = {
        rules = technic.digilines.rules,
        action = function(pos, node, channel, msg)
            if type(msg) ~= "string" then
                return
            end
            local meta = core.get_meta(pos)
            if channel ~= meta:get_string("channel") then
                return
            end
            msg = msg:lower()
            if msg == "get" then
                digilines.receptor_send(pos, technic.digilines.rules, channel, {
                    enabled      = meta:get_int("enabled"),
                    power        = meta:get_int("power"),
                    mesecon_mode = meta:get_int("mesecon_mode"),
                    relay_mode   = meta:get_int("relay_mode")
                })
                return
            elseif msg == "off" then
                meta:set_int("enabled", 0)
            elseif msg == "on" then
                meta:set_int("enabled", 1)
            elseif msg == "emitter" then
                meta:set_int("relay_mode", 1)
            elseif msg == "receiver" then
                meta:set_int("relay_mode", 0)
            elseif msg == "toggle" then
                local onn = meta:get_int("enabled")
                onn = 1-onn -- Mirror onn with pivot 0.5, so switch between 1 and 0.
                meta:set_int("enabled", onn)
            elseif msg:sub(1, 5) == "power" then
                local power = tonumber(msg:sub(7))
                if not power then
                    return
                end
                power = math.max(power, 0)
                power = math.min(power, 10000)
                power = 100 * math.floor(power / 100)
                meta:set_int("power", power)
            elseif msg:sub(1, 12) == "mesecon_mode" then
                meta:set_int("mesecon_mode", tonumber(msg:sub(14)))
            else
                return
            end
            set_supply_converter_formspec(meta)
        end
    },
}

local run = function(pos, node, run_stage)

    -- Machine information
    local machine_name  = S("Supply Relay")
    local meta          = core.get_meta(pos)
    local enabled       = meta:get_int("enabled") == 1 and
        (meta:get_int("mesecon_mode") == 0 or meta:get_int("mesecon_effect") ~= 0)

    local demand = enabled and meta:get_int("power") or 0
    local emitter = meta:get_int("relay_mode") == 1 or false

    local dir = get_facing_vector(pos)

    local pos_front = vector.subtract(pos, dir)
    local name_front = core.get_node(pos_front).name
    local cable = technic.get_cable_tier(name_front)

    local next_relay = nil
    local next_pos = pos

    local dist = 0
    if enabled then
        for n = 1, 8 do
            next_pos = vector.add(next_pos, dir)
            local s_node = core.get_node(next_pos)
            if s_node.name == "ship_machine:supply_relay" then
                next_relay = next_pos
                dist = n
                break
            end
        end
    end

	local remain = get_eff_by_dist(dist - 1)

    if not emitter then
        if cable and next_relay then
            local meta_next_relay = core.get_meta(next_relay)
            local is_enabled = meta_next_relay:get_int("enabled") == 1
            if not is_enabled then
                meta:set_string("infotext", S("@1 Emitter is Disabled", machine_name))
            else
                local input = meta:get_int(cable.."_EU_supply")
                meta:set_string("infotext", S("@1 is Bridged \nReceiving: @2 @3\n@4 @5%", machine_name,
                    technic.EU_string(input), cable, "EU Losses:", (1 - remain) * 100))
            end
        elseif cable then
            if not enabled then
                meta:set_string("infotext", S("@1 is Disabled", machine_name))
            else
                meta:set_string("infotext", S("@1 Has Bad Bridge", machine_name))
            end
            meta:set_int(cable.."_EU_supply", 0)
        end
    elseif run_stage ~= technic.receiver then
        local from = cable
        if from and next_relay then
            local faces_match = match_facing(pos, next_relay)
            local dir = get_facing_vector(next_relay)
            local pos_front = vector.subtract(next_relay, dir)
            local name_front = core.get_node(pos_front).name
            local to = technic.get_cable_tier(name_front)

            local meta_next_relay = core.get_meta(next_relay)
            local is_receiver = meta_next_relay:get_int("relay_mode") == 0
            local is_enabled = meta_next_relay:get_int("enabled") == 1
            
            if to == from and is_receiver and faces_match and is_enabled then
                local input = meta:get_int(from.."_EU_input")
                if (technic.get_timeout(from, pos) <= 0) or (technic.get_timeout(to, next_relay) <= 0) then
                    -- Supply converter timed out, either RE or PR network is not running anymore
                    input = 0
                end
                meta:set_int(from.."_EU_demand", demand)
                meta:set_int(from.."_EU_supply", 0)
                meta_next_relay:set_int(to.."_EU_demand", 0)
                meta_next_relay:set_int(to.."_EU_supply", input * remain)
                meta_next_relay:set_int("relay_eff", remain * 100)
                meta:set_string("infotext", S("@1 is Bridged \n@2 @3 -> @4 @5\n@6 @7%", machine_name,
                    technic.EU_string(input), from,
                    technic.EU_string(input * remain), to,
				 	"EU Losses:", (1 - remain) * 100))
                if demand > 0 and input > 0 then
                    create_beam(pos, next_relay, from, input)
                end
            elseif not faces_match then
                meta:set_string("infotext", S("@1 Has Bad Bridge Direction", machine_name))
                if from then
                    meta:set_int(from.."_EU_demand", 0)
                end
            elseif not is_enabled then
                meta:set_string("infotext", S("@1 Receiver is Disabled", machine_name))
                if from then
                    meta:set_int(from.."_EU_demand", 0)
                end
            else
                if not is_receiver then
                    meta:set_string("infotext", S("@1 Failed to find Receiver", machine_name))
                else
                    meta:set_string("infotext", S("@1 Has Mismatched Bridge Voltage", machine_name))
                end
                if to then
                    meta:set_int(to.."_EU_supply", 0)
                end
                meta:set_int(from.."_EU_demand", 0)
            end
        else
            if not enabled then
                meta:set_string("infotext", S("@1 is Disabled", machine_name))
            else
                meta:set_string("infotext", S("@1 Has Bad Bridge Wiring", machine_name))
            end
            if from then
                meta:set_int(from.."_EU_demand", 0)
            end
        end
    end

end

core.register_node("ship_machine:supply_relay", {
    description = S("Supply Relay"),
    tiles  = {
        "ctg_power_relay_side.png".."^[transformFXR90",
        "ctg_power_relay_side.png".."^[transformR90",
        "ctg_power_relay_side.png".."^[transformFX",
        "ctg_power_relay_side.png",
        "ctg_power_relay_back.png",
        "ctg_power_relay_back.png".."^[transformFX"..cable_entry
        },
	paramtype = "light",
    paramtype2 = "facedir",
	light_source = 2,
    legacy_facedir_simple = true,
    groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2,
        technic_machine=1, technic_all_tiers=1, axey=2, handy=1, power_relay = 1},
    is_ground_content = false,
    _mcl_blast_resistance = 1,
    _mcl_hardness = 0.8,
    connect_sides = {"front", "top", "bottom"},
    sounds = technic.sounds.node_sound_metal_defaults(),
    on_receive_fields = supply_converter_receive_fields,
    on_construct = function(pos)
        local meta = core.get_meta(pos)
        meta:set_string("infotext", S("Supply Relay"))
        meta:set_int("power", 2000)
        meta:set_int("enabled", 1)
        meta:set_int("mesecon_mode", 0)
        meta:set_int("mesecon_effect", 0)
        meta:set_int("relay_mode", 0)
        set_supply_converter_formspec(meta)
    end,
    mesecons = mesecons,
    digiline = digiline_def,
    technic_run = run,
    technic_on_disable = run,
})

core.register_craft({
    output = 'ship_machine:supply_relay 1',
    recipe = {
        {'technic:copper_coil', 'group:crystal', 'ship_parts:circuit_standard'},
        {'basic_materials:gold_wire', 'technic:supply_converter', 'basic_materials:gold_wire'},
        {'technic:copper_coil', 'basic_materials:brass_ingot', 'technic:copper_coil'},
    },
    replacements = { {"basic_materials:gold_wire", "basic_materials:empty_spool 2"}, },
})

for tier, machines in pairs(technic.machines) do
    technic.register_machine(tier, "ship_machine:supply_relay", technic.producer_receiver)
end

