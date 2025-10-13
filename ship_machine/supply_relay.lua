-- The Power Relay is a generic device which can wirelessly
-- send energy to another Power Relay, up to 7 nodes away.
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
        return 0.95
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

local is_player_near = function(pos)
    local objs = core.get_objects_inside_radius(pos, 48)
    for _, obj in pairs(objs) do
        if obj:is_player() then
            return true;
        end
    end
    return false;
end

local function is_atmos_node(pos)
    local node = minetest.get_node(pos)
    if node.name == "air" then
        return true
    end
    if minetest.get_item_group(node.name, "vacuum") == 1 or minetest.get_item_group(node.name, "atmosphere") > 0 then
        return true
    end
    return false
end

local function get_testcoin(items, take, take_amount)
    if not items then
        return nil
    end
    local take = take ~= nil and take or false
    local take_amount = take_amount ~= nil and take_amount or 1
    local new_input = {}
    local output = nil
    local c = 0;
    for i, stack in ipairs(items) do
        if stack:get_name() == 'testcoin:coin' and stack:get_count() > 0 then
            new_input[i] = ItemStack(stack)
            if take and take_amount then
                local sc = stack:get_count()
                new_input[i]:take_item(take_amount)
                if sc - take_amount < 0 then
                    take_amount = math.abs(sc - take_amount)
                else
                    take_amount = 0
                end
            end
            c = c + stack:get_count()
        end
    end
    if (c > 0) then
        output = ItemStack({name = "testcoin:coin", count = c})
        return {
            new_input = new_input,
            output = output,
            count = c
        }
    else
        return nil
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
        x = 0.75,
        y = 0.75,
        z = 0.75
    })
    dir = vector.multiply(dir, ((size + 1) / 2))
    local i = (dist - (dist - i * 0.1)) * 0.064
    local t = 2 + i + randFloat(0, 0.65)
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
            x = -dir.x * 0.15,
            y = randFloat(-0.02, 0.05) * grav,
            z = -dir.z * 0.15
        },

        expirationtime = t,
        size = randFloat(1.02, 1.42) * ((size + 0.5) / 2),
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        vertical = false,

        texture = {
            name = texture,
            alpha = 1,
            alpha_tween = {1, 0.6},
            scale_tween = {{
                x = 1.50,
                y = 1.50
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

local function spawner_particle(pos, dir, i, dist, tier, size, count, r)
    local grav = 1;
    if (pos.y > 4000) then
        grav = 0.4;
    end
    dir = vector.multiply(dir, {
        x = 0.75,
        y = 0.75,
        z = 0.75
    })
    dir = vector.multiply(dir, ((size + 1) / 2))
    local i = (dist - (dist - i * 0.1)) * 0.172
    local t = 2 + i + randFloat(0, 0.65)
    local texture = "ctg_" .. tier .. "_energy_particle.png"
    if math.random(0,1) == 0 then
        texture = "ctg_" .. tier .. "_energy_particle.png^[transformR90"
    end
    local def = {
        count = count,
        --pos = pos,
        minpos = {x=pos.x-r, y=pos.y-r, z=pos.z-r},
        maxpos = {x=pos.x+r, y=pos.y+r, z=pos.z+r},
        minvel = {
            x = dir.x,
            y = dir.y,
            z = dir.z
        },
        maxvel = {
            x = dir.x,
            y = dir.y,
            z = dir.z
        },
        minacc = {
            x = -dir.x * 0.15,
            y = randFloat(-0.02, 0.01) * grav,
            z = -dir.z * 0.15
        },
        maxacc = {
            x = dir.x * 0.15,
            y = randFloat(0.02, 0.05) * grav,
            z = dir.z * 0.15
        },
        time = t * 0.4,
        --expirationtime = t + 0.7,
        minexptime = t - 0.3,
        maxexptime = t,
        --size = randFloat(1.02, 1.42) * ((size + 0.5) / 2),
        minsize = randFloat(1.02, 1.42) * ((size + 0.5) / 2),
        maxsize = randFloat(1.02, 1.42) * ((size + 1) / 2),
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        vertical = false,

        texture = {
            name = texture,
            alpha = 1,
            alpha_tween = {1, 0.6},
            scale_tween = {{
                x = 1.50,
                y = 1.50
            }, {
                x = 0.0,
                y = 0.0
            }},
            blend = "alpha"
        },
        glow = 13
    }

    core.add_particlespawner(def);
end

local function spawn_particles(pos, dir, i, dist, tier, size)
    local c = 8
    if size <= 0.2 then
        c = 1
    elseif size <= 0.3 then
        c = 2
    elseif size <= 0.4 then
        c = 3
    elseif size <= 0.5 then
        c = 4
    elseif size <= 0.6 then
        c = 5
    elseif size <= 0.7 then
        c = 6
    elseif size <= 0.8 then
        c = 7
    end
    local r = 0.25 * ((size + size + 0.2) / 2)
    spawner_particle(pos, dir, i, dist, tier, size, c*15, r)
    r = 0.025 * size
    spawner_particle(pos, dir, i, dist, tier, size, c*15, r)

    --[[for n = 0, c do
        core.after(n * 0.25, function()
            local r = 0.25 * ((size + size + 0.25) / 2)
            if n >= 2 then
                r = 0.05 * size
            end
            local p = vector.add(pos, {x=randFloat(-r,r),y=randFloat(-r,r),z=randFloat(-r,r)})
            spawn_particle(p, dir, i, dist, tier, size)
        end)
    end]]
end

local function toggle_beam_light(pos_start, pos_end, enable)
	local dir = vector.direction(pos_start, pos_end)
	local pos_start_next = vector.add(pos_start, dir)
	local pos_end_before = vector.subtract(pos_end, dir)
	-- FIXME: dummy_light_source is too bright!
	if enable then
		if is_atmos_node(pos_start_next) then
			core.set_node(pos_start_next, {name = "technic:dummy_light_source"})
		end
		if is_atmos_node(pos_end_before) then
			core.set_node(pos_end_before, {name = "technic:dummy_light_source"})
		end
	else
		local node_next = core.get_node(pos_start_next)
		local node_before = core.get_node(pos_end_before)
		if node_next.name == "technic:dummy_light_source" then
			core.set_node(pos_start_next, {name = "vacuum:vacuum"})
		end
		if node_before.name == "technic:dummy_light_source" then
			core.set_node(pos_end_before, {name = "vacuum:vacuum"})
		end
	end
end

local function create_beam(pos_start, pos_end, tier_from, tier_to, p)

    if not is_player_near(pos_start) then
        return
    end
    
    local target = vector.add(pos_end, {
        x = randFloat(-0.025, 0.025),
        y = randFloat(-0.025, 0.025),
        z = randFloat(-0.025, 0.025)
    })

    local tier_from = (tier_from and tier_from or "LV"):lower()
    local tier_to = (tier_to and tier_to or "LV"):lower()
    local size = math.max(0.1, p / 20000)
    local dir = vector.direction(pos_start, target)
    local dist = vector.distance(pos_start, target)
    local step_min = 0.25
    if size >= 0.6 then
        step_min = 0.40
    elseif size >= 0.4 then
        step_min = 0.30
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
        while (vector.distance(cur_pos, target) > step_min * 2) do
            local d = vector.distance(cur_pos, target)
            if d <= dist * 0.8 and d > dist * 0.4 and i % 2 == 0 and math.random(0,3) == 0 then
                spawn_particles(cur_pos, dir, i, d, tier_from, size)
            else
                spawn_particles(cur_pos, dir, i, d, tier_to, size)
            end
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
            core.sound_play("ctg_energy_pulse", {
                pos = pos_start,
                gain = 0.675,
                pitch = randFloat(1.0, 1.025),
                max_hear_distance = 3.05
            })
        end
        if math.random(0,1) == 0 then
            core.sound_play("ctg_energy_pulse", {
                pos = pos_end,
                gain = 0.685,
                pitch = randFloat(1.0, 1.025),
                max_hear_distance = 2.75
            })
        end
    end)
end

local function set_supply_relay_formspec(meta)
    local meter_menu = meta:get_int("meter_menu") or 0
    local name = S("Power Relay");

    if meter_menu == 1 then
        local formspec = "size[8,6]" .. "formspec_version[8]"
        local ready = (meta:get_int("meter_ready") or 0) == 1
        local rate = meta:get_int("meter_rate") 
        local time = meta:get_int("meter_time")
        local power = meta:get_int("meter_power") or 0
		local usage = meta:get_int("meter_usage") or 0
        local tier = meta:get_string("meter_tier") or "LV"
        local tdays = math.floor(time / 1440)
        local trem_days = time % 1440
        local thrs = math.floor(trem_days / 60)
        local tmin = trem_days % 60
        local tmsg = (tdays > 0 and (tdays > 9 and tdays .. ":" or "0" .. tdays .. ":") or "") .. 
                    (thrs > 9 and thrs or "0" .. thrs) .. ":" .. 
                    (tmin > 9 and tmin or "0" .. tmin)
        if time < 3 then
            tmsg = core.colorize('#ff3021ff', tmsg)
        elseif time < 10 then
            tmsg = core.colorize('#ffa621ff', tmsg)
        else
            tmsg = core.colorize('#21daff', tmsg)
        end
        local rmsg = core.colorize('#ff6021ff', rate)
        if rate <= 0 then
            rmsg = core.colorize('#21ff33ff', rate)
        end
        local pwr_req_col = '#ffcb21ff'
        if time > 0 or rate == 0 then
            pwr_req_col = '#42ff29ff'
        end
        local pwr_req = core.colorize(pwr_req_col, technic.EU_string(power).." "..tier)
		local pwr_use = core.colorize('#c2c2c2ff', technic.EU_string(usage).." "..tier)
        formspec = formspec .. "label[0.0,-0.105;Meter Rate (Cost)]".."label[0.0,0.4;"..rmsg.."  Per 10 Min]"
        formspec = formspec .. "label[2.25,-0.105;Meter Time (d:h:m)]".."label[2.25,0.4;"..tmsg.."  Remains]"

        formspec = formspec .. "label[5,-0.105;Purchase: Insert Testcoin]"
        formspec = formspec .. "image[7.0,0.5;1,1;testcoin_coin.png]"

        formspec = formspec .. "label[0,1.0;Get: "..pwr_req.."]"
		if time > 0 then
			formspec = formspec .. "label[0,1.4;Got: "..pwr_use.."]"
		end
        formspec = formspec .. "checkbox[2.25,0.8;meter_ready;Procces Coins;"..tostring(ready).."]"

        formspec = formspec .. "list[current_name;src;5,0.5;2,1;]" .. "listring[current_name;src]"
        formspec = formspec .. "list[current_player;main;0,2.25;8,4;]" .. "listring[current_player;main]"

        meta:set_string("formspec", formspec)
        return
    elseif meter_menu == 2 then
        local formspec = "size[8,7.0]" .. "formspec_version[8]"
        local rate = meta:get_int("meter_rate")
        local time = meta:get_int("meter_time")
        local tdays = math.floor(time / 1440)
        local trem_days = time % 1440
        local thrs = math.floor(trem_days / 60)
        local tmin = trem_days % 60
        local tmsg = (tdays > 0 and (tdays > 9 and tdays .. ":" or "0" .. tdays .. ":") or "") .. 
                    (thrs > 9 and thrs or "0" .. thrs) .. ":" .. 
                    (tmin > 9 and tmin or "0" .. tmin)
        if time < 3 then
            tmsg = core.colorize('#ff3021ff', tmsg)
        elseif time < 10 then
            tmsg = core.colorize('#ffa621ff', tmsg)
        else
            tmsg = core.colorize('#21daff', tmsg)
        end
        local rmsg = core.colorize('#ff6021ff', rate)
        if rate <= 0 then
            rmsg = core.colorize('#21ff33ff', rate)
        end
        formspec = formspec .. "label[0.0,-0.105;Meter Rate]".."label[0.0,0.4;"..rmsg.."  Per 10 Min]"
        formspec = formspec .. "label[2.3,-0.105;Meter Time (d:h:m)]".."label[2.3,0.4;"..tmsg.."  Remains]"

        formspec = formspec .. "field[0.25,2.0;2.4,0.75;meter_rate;"..S("Rate Per 10 Minutes")..";"..rate.."]"
        formspec = formspec .. "image[2.3,1.65;0.8,0.8;testcoin_coin.png]"

        formspec = formspec .. "label[5,-0.105;Testcoin Received]"
        formspec = formspec .. "list[current_name;dst;5,0.5;3,2;]" .. "listring[current_name;dst]"
        formspec = formspec .. "list[current_player;main;0,3.25;8,4;]" .. "listring[current_player;main]"

        meta:set_string("formspec", formspec)
        return
    end

    local power = meta:get_int("power")
    local time = meta:get_int("meter_time")
    local btnColorMode = ""
    if time > 0 then
        btnColorMode = btnColorMode .. "style[mode_emitter;bgcolor=#30333310]"
        btnColorMode = btnColorMode .. "style[mode_receiver;bgcolor=#30333310]"
    end
    local btnColor = ""
    if meta:get_int("enabled") == 1 then
        btnColor = btnColor .. "style[enable;bgcolor=#34eb7420]"
        btnColor = btnColor .. "style[disable;bgcolor=#34eb7420]"
    else
        btnColor = btnColor .. "style[enable;bgcolor=#eb403410]"
        btnColor = btnColor .. "style[disable;bgcolor=#eb403410]"
    end

    local btnMeter = ""
    btnMeter = btnMeter .. "style[meter_buy;bgcolor=#50ebe010]"
    btnMeter = btnMeter .. "style[meter_sell;bgcolor=#50d6eb10]"

    local formspec = "size[5,4.0]" .. "formspec_version[8]"
    if digilines_path then
        formspec = formspec..
            "field[2.3,0.5;3,1;channel;"..S("Digiline Channel")..";${channel}]"
    end
    if meta:get_int("relay_mode") == 1 then
        local pwr_lck = core.colorize('#aa6245ff', S("(locked)"))
        if time > 0 then
            formspec = formspec .. "label[0.0,-0.105;"..S("Input Power").."]" .. "label[0.1,0.425;"..tostring(power).."  "..pwr_lck.."]" 
        else
            formspec = formspec .. "field[0.3,0.5;2,1;power;"..S("Input Power")..";${power}]"
        end
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
        formspec = formspec..btnColor.."button[0,1.75;5,1;enable;"..S("@1 disabled", name).."]"
    else
        formspec = formspec..btnColor.."button[0,1.75;5,1;disable;"..S("@1 Enabled", name).."]"
    end
    if meta:get_int("relay_mode") == 0 then
        formspec = formspec..btnColorMode.."button[0,2.5;5,1;mode_emitter;"..S("@1 Receiver", name).."]"
    else
        formspec = formspec..btnColorMode.."button[0,2.5;5,1;mode_receiver;"..S("@1 Emitter", name).."]"
    end
    if meta:get_int("relay_mode") == 0 then
        formspec = formspec..btnMeter.."button[0,3.25;5,1;meter_buy;"..S("@1 Meter Usage", name).."]"
    else
        formspec = formspec..btnMeter.."button[0,3.25;5,1;meter_sell;"..S("@1 Meter Setup", name).."]"
    end
    meta:set_string("formspec", formspec)
end

local function take_payment(meta, meta_other)
    if not meta or not meta_other then
        return
    end
    local rate = meta:get_int("meter_rate")
    if rate <= 0 then
        -- ignore when rate is zero
        return
    end
    if meta_other:get_int("meter_ready") == 0 then
        -- ignore if ready checkbox not checked
        return
    end
    local time = meta:get_int("meter_time")
    local inv = meta:get_inventory()
    local inv_other = meta_other:get_inventory()
    local result = get_testcoin(inv_other:get_list("src"), false)
    -- only run if time is less than 3 days stored
    if result and result.count >= rate and time < 60 * 24 * 3 then
        -- inv room check...
        if inv:room_for_item("dst", result.output) then
            local mins = 10 -- meter run interval
            local count = math.min(1000, result.count)
            local time = math.floor(count / rate)
            local count = time * rate
            result = get_testcoin(inv_other:get_list("src"), true, count)
            inv_other:set_list("src", result.new_input)
            inv:add_item("dst", result.output)
            local meter_time = meta:get_int("meter_time") or 0
            meta:set_int("meter_time", meter_time + time * mins)
            meta_other:set_int("meter_time", meter_time + time * mins)
            -- update formspecs..
            set_supply_relay_formspec(meta)
            set_supply_relay_formspec(meta_other)
        end
    end
end

local supply_relay_receive_fields = function(pos, formname, fields, sender)
    if not sender or core.is_protected(pos, sender:get_player_name()) then
        return
    end
    local meta = core.get_meta(pos)
    if fields.quit then
        meta:set_int("meter_menu", 0)
    end
    local power = nil
    if fields.power then
        power = tonumber(fields.power) or 0
        power = math.max(power, 0)
        power = math.min(power, 20000)
        power = 100 * math.floor(power / 100)
        if power == meta:get_int("power") then power = nil end
    end
    if power and meta:get_int("meter_time") <= 0 then meta:set_int("power", power) end
    if fields.channel then meta:set_string("channel", fields.channel) end
    if fields.enable  then meta:set_int("enabled", 1) end
    if fields.disable then meta:set_int("enabled", 0) end
    if fields.mesecon_mode_0 then meta:set_int("mesecon_mode", 0) end
    if fields.mesecon_mode_1 then meta:set_int("mesecon_mode", 1) end
    if meta:get_int("meter_time") <= 0 then
        if fields.mode_receiver then meta:set_int("relay_mode", 0) end
        if fields.mode_emitter then meta:set_int("relay_mode", 1) end
    end
    if fields.meter_buy then meta:set_int("meter_menu", 1) end
    if fields.meter_sell then meta:set_int("meter_menu", 2) end
    if fields.meter_ready ~= nil then meta:set_int("meter_ready", fields.meter_ready == 'true' and 1 or 0) end
    if fields.meter_rate then meta:set_int("meter_rate", tonumber(fields.meter_rate) or 0) end
    set_supply_relay_formspec(meta)
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
                    relay_mode   = meta:get_int("relay_mode"),
                    meter_time   = meta:get_int("meter_time"),
                    meter_rate   = meta:get_int("meter_rate"),
                    meter_tier   = meta:get_int("meter_tier"),
                })
                return
            elseif msg == "get_lv" then                
                digilines.receptor_send(pos, technic.digilines.rules, channel, {
                    input        = meta:get_int("LV_EU_input"),
                    suppply      = meta:get_int("LV_EU_supply"),
                    demand       = meta:get_int("LV_EU_demand"),
                })
                return
            elseif msg == "get_mv" then                
                digilines.receptor_send(pos, technic.digilines.rules, channel, {
                    input        = meta:get_int("MV_EU_input"),
                    suppply      = meta:get_int("MV_EU_supply"),
                    demand       = meta:get_int("MV_EU_demand"),
                })
                return
            elseif msg == "get_hv" then                
                digilines.receptor_send(pos, technic.digilines.rules, channel, {
                    input        = meta:get_int("HV_EU_input"),
                    suppply      = meta:get_int("HV_EU_supply"),
                    demand       = meta:get_int("HV_EU_demand"),
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
                if meta:get_int("meter_time") > 0 then
                    return
                end
                power = math.max(power, 0)
                power = math.min(power, 20000)
                power = 100 * math.floor(power / 100)
                meta:set_int("power", power)
            elseif msg:sub(1, 12) == "mesecon_mode" then
                meta:set_int("mesecon_mode", tonumber(msg:sub(14)))
            else
                return
            end
            set_supply_relay_formspec(meta)
        end
    },
}

local run_off = function(pos, node, run_stage)
    local node = core.get_node(pos)
    local machine = {name = "ship_machine:supply_relay", param2 = node.param2}
    local meta = core.get_meta(pos)
    meta:set_int("LV".."_EU_demand", 0)
    meta:set_int("MV".."_EU_demand", 0)
    meta:set_int("HV".."_EU_demand", 0)
    core.swap_node(pos, machine)
end

local run = function(pos, node, run_stage)

    --- get meter rate and time from meta data
    ---@param meta table - node metadata
    local get_rate = function(meta)
        local rate = meta:get_int("meter_rate")
        local time = meta:get_int("meter_time")
        local tdays = math.floor(time / 1440)
        local trem_days = time % 1440
        local thrs = math.floor(trem_days / 60)
        local tmin = trem_days % 60
        local tmsg = (tdays > 0 and (tdays > 9 and (tdays .. ":") or "0" .. tdays .. ":") or "") .. 
                    (thrs > 9 and thrs or "0" .. thrs) .. ":" .. 
                    (tmin > 9 and tmin or "0" .. tmin)
        return rate, time, tmsg
    end

    -- Machine information
    local node          = core.get_node(pos)
    local machine         = {name = "ship_machine:supply_relay", param2 = node.param2}
    local machine_name  = S("Power Relay")
    local meta          = core.get_meta(pos)
    local enabled       = meta:get_int("enabled") == 1 and (meta:get_int("mesecon_mode") == 0 or meta:get_int("mesecon_effect") ~= 0)

    local demand = enabled and meta:get_int("power") or 0
    local emitter = meta:get_int("relay_mode") == 1 or false

    -- facing direction vector
    local dir = get_facing_vector(pos)

    local pos_front = vector.subtract(pos, dir)
    local name_front = core.get_node(pos_front).name
    local cable = technic.get_cable_tier(name_front)

    local next_relay = nil
    local next_pos = pos
    local dist = 0

    -- get next relay facing
    if enabled then
        for n = 1, 8 do
            next_pos = vector.add(next_pos, dir)
            local s_node = core.get_node(next_pos)
            local g_node = core.get_item_group(s_node.name, "power_relay")
            if s_node.name == "ship_machine:supply_relay" or g_node > 0 then
                next_relay = next_pos
                dist = n
                break
            end
        end
    end

    local machine_other
    if next_relay then
        local node = core.get_node(next_relay)
        -- setup machine other def
        machine_other = {name = "ship_machine:supply_relay", param2 = node.param2}
    end

    -- get power effeceincey scaler based on distance between relay nodes
    local remain = get_eff_by_dist(dist - 1)

    if run_stage ~= technic.receiver and not next_relay then
        -- run tick if not connected...
        local time_now = math.floor(core.get_us_time() / 1000)
        local time_last = tonumber(meta:get_string("meter_tick")) or 0
        if time_now - time_last > 1 * 60 * 1000 then
            local meter_time = meta:get_int("meter_time") or 0
            meter_time = math.max(0, meter_time - 1)
            meta:set_int("meter_time", meter_time)
            meta:set_string("meter_tick", tostring(time_now))
        end
    end

    if not emitter then
        -- run only on receiver, not emitter.
        if cable and next_relay then
            local self_to = cable
            -- receiver is receiving!
            local dir = get_facing_vector(next_relay)
            local pos_front = vector.subtract(next_relay, dir)
            local name_front = core.get_node(pos_front).name
            local from = technic.get_cable_tier(name_front)
            local meta_next_relay = core.get_meta(next_relay)
            local is_other_enabled = meta_next_relay:get_int("enabled") == 1
            local is_other_receiver = meta_next_relay:get_int("relay_mode") == 0
            if self_to ~= from then
                remain = remain - 0.1
            end
            if not is_other_enabled then
                meta:set_string("infotext", S("@1 Emitter is disabled", machine_name))
                meta:set_int(cable.."_EU_supply", 0)
                core.swap_node(pos, machine)
            elseif is_other_receiver then
                meta:set_string("infotext", S("@1 has bad Bridge setup", machine_name))
                meta:set_int(cable.."_EU_supply", 0)
                core.swap_node(pos, machine)
            elseif not from then
                meta:set_string("infotext", S("@1 has bad Bridge wiring", machine_name))
                meta:set_int(cable.."_EU_supply", 0)
                core.swap_node(pos, machine)
			else
                local input = meta:get_int(cable.."_EU_supply")
                local rate, time, tmsg = get_rate(meta)
                meta:set_string("infotext", S("@1 is Bridged \nReceiving: @2 @3\n@4 @5%  @6", machine_name,
                    technic.EU_string(input), cable, "EU Losses:", (1 - remain) * 100, 
                    time > 0 and "Time: " .. tmsg or ""))
            end
        elseif cable then
            -- reset if cable found...
            if not enabled then
                meta:set_string("infotext", S("@1 is disabled", machine_name))
            else
                meta:set_string("infotext", S("@1 has bad Bridge", machine_name))
            end
            meta:set_int(cable.."_EU_supply", 0)
            core.swap_node(pos, machine)
        end
    elseif run_stage ~= technic.receiver then
        -- only run on producer
        local from = cable
        if from and next_relay then
            -- has cable and next relay
            local faces_match = match_facing(pos, next_relay)
            local dir = get_facing_vector(next_relay)
            local pos_front = vector.subtract(next_relay, dir)
            local name_front = core.get_node(pos_front).name
            local to = technic.get_cable_tier(name_front)
            local meta_next_relay = core.get_meta(next_relay)
            local is_other_receiver = meta_next_relay:get_int("relay_mode") == 0
            local is_other_enabled = meta_next_relay:get_int("enabled") == 1
            -- check if networks match, correct mode, relays are facing each other, and enabled
            if to ~= nil and from ~= nil and is_other_receiver and faces_match and is_other_enabled then
                local input = meta:get_int(from.."_EU_input")
                if (technic.get_timeout(from, pos) <= 0) then
                    -- Power Relay timed out, either RE or PR network is not running anymore
                    input = 0
                    --core.log("FROM network timeout! " .. from)
                end
                if (technic.get_timeout(to, next_relay) <= 0) then
                    -- Power Relay timed out, either RE or PR network is not running anymore
                    input = 0
                    --core.log("TO network timeout! " .. to)
                end
                if to ~= from then
                    remain = remain - 0.1
                end
                -- process payment input
                take_payment(meta, meta_next_relay)
                local rate, time, tmsg = get_rate(meta)
                meta_next_relay:set_int("meter_rate", rate)
                meta_next_relay:set_int("meter_time", time)
                meta:set_int("meter_time", time)
                meta:set_int("meter_power", demand * remain)
                meta_next_relay:set_int("meter_power", demand * remain)
                meta_next_relay:set_string("meter_tier", to)
                meta:set_string("meter_tier", cable)
                if rate > 0 and time == 0 then
                    -- payment required for this
                    meta:set_string("infotext", S("@1 Payment Required from Receiver", machine_name))
                    meta_next_relay:set_string("infotext", S("@1 Payment Required to Emitter", machine_name))
                    core.swap_node(pos, machine)
                    core.swap_node(next_relay, machine_other)
					meta_next_relay:set_int("meter_usage", 0)
                    return
                elseif input > 0 and rate > 0 and time > 0 then
                    -- check payment time decrement
                    local time_now = math.floor(core.get_us_time() / 1000)
                    local time_last = tonumber(meta:get_string("meter_tick")) or 0
                    if time_now - time_last > 1 * 60 * 1000 then
                        -- perform payment time decrement
                        local meter_time = meta:get_int("meter_time") or 0
                        meter_time = math.max(0, meter_time - 1)
                        meta:set_int("meter_time", meter_time)
                        meta_next_relay:set_int("meter_time", meter_time)
                        meta:set_string("meter_tick", tostring(time_now))
                        meta_next_relay:set_string("meter_tick", tostring(time_now))
    					set_supply_relay_formspec(meta)
    					set_supply_relay_formspec(meta_next_relay)
                    end
					local usage = meta_next_relay:get_int("meter_usage") or 0
					meta_next_relay:set_int("meter_usage", usage + input * remain)
                end
                -- set power network fields
                meta:set_int(from.."_EU_demand", demand)
                meta:set_int(from.."_EU_supply", 0)
                meta_next_relay:set_int(to.."_EU_demand", 0)
                meta_next_relay:set_int(to.."_EU_supply", input * remain)
                meta_next_relay:set_int("relay_eff", remain * 100)
                meta:set_string("infotext", S("@1 is Bridged \n@2 @3 -> @4 @5\n@6 @7%  @8", machine_name,
                    technic.EU_string(input), from,
                    technic.EU_string(input * remain), to,
                    "EU Losses:", (1 - remain) * 100,
                    time > 0 and "Time: " .. tmsg or ""))
                if demand > 0 and input > 0 then
                    -- create beam particle effect if functioning
                    create_beam(pos, next_relay, from, to, input * remain)
                    local r_node = core.get_node(next_relay)
                    local active_relay = "ship_machine:" .. to:lower() .. "_supply_relay"
                    core.swap_node(pos, {name = active_relay, param2 = node.param2})
                    core.swap_node(next_relay, { name = active_relay, param2 = r_node.param2})
					--toggle_beam_light(pos, next_relay, true)
                else
                    core.swap_node(pos, machine)
                    core.swap_node(next_relay, machine_other)
					--toggle_beam_light(pos, next_relay, false)
                end
            elseif not faces_match then
                meta:set_string("infotext", S("@1 has bad Bridge direction", machine_name))
                if from then
                    meta:set_int(from.."_EU_demand", 0)
                    core.swap_node(pos, machine)
                end
                if to then
                    meta_next_relay:set_int(to.."_EU_supply", 0)
                    core.swap_node(next_relay, machine_other)
                end
            elseif not is_other_enabled then
                meta:set_string("infotext", S("@1 Receiver is disabled", machine_name))
                if from then
                    meta:set_int(from.."_EU_demand", 0)
                    core.swap_node(pos, machine)
                end
                if to then
                    meta_next_relay:set_int(to.."_EU_supply", 0)
                    core.swap_node(next_relay, machine_other)
                end
            else
                --core.log("Bridge Failed!" .. from)
                if not is_other_receiver then
                    meta:set_string("infotext", S("@1 Failed to find Receiver", machine_name))
				elseif to == nil then
                	meta:set_string("infotext", S("@1 Receiver has bad wiring", machine_name))
				else
                    meta:set_string("infotext", S("@1 has mismatched Bridge voltage", machine_name))
                end
                if to then
                    meta_next_relay:set_int(to.."_EU_supply", 0)
                    core.swap_node(next_relay, machine_other)
                end
                meta:set_int(from.."_EU_demand", 0)
                core.swap_node(pos, machine)
            end
			if to == nil and from ~= nil and is_other_receiver and faces_match and is_other_enabled then
				-- run tick if wire not valid...
				local time_now = math.floor(core.get_us_time() / 1000)
				local time_last = tonumber(meta:get_string("meter_tick")) or 0
				if time_now - time_last > 1 * 60 * 1000 then
					local meter_time = meta:get_int("meter_time") or 0
					meter_time = math.max(0, meter_time - 1)
					meta:set_int("meter_time", meter_time)
					meta:set_string("meter_tick", tostring(time_now))
				end
			end
        else
            if not enabled then
                meta:set_string("infotext", S("@1 is disabled", machine_name))
            else
                meta:set_string("infotext", S("@1 has bad Bridge wiring", machine_name))
            end
            if from then
                meta:set_int(from.."_EU_demand", 0)
            else
                meta:set_int("LV".."_EU_demand", 0)
                meta:set_int("MV".."_EU_demand", 0)
                meta:set_int("HV".."_EU_demand", 0)
            end
            core.swap_node(pos, machine)
            if next_relay then
                local meta_next_relay = core.get_meta(next_relay)
                meta_next_relay:set_int("LV".."_EU_demand", 0)
                meta_next_relay:set_int("MV".."_EU_demand", 0)
                meta_next_relay:set_int("HV".."_EU_demand", 0)
                core.swap_node(next_relay, machine_other)
            end
        end
    end

end

local on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
    local meta = core.get_meta(pos)
    meta:set_int("meter_menu", 0)
    set_supply_relay_formspec(meta)
    return nil
end

local on_dig = function(pos, node, digger)
    if core.is_protected(pos, digger:get_player_name()) then
        return 0
    end
    local drop = "ship_machine:supply_relay"
    if node.name == core.get_node(pos).name then
        local meta = core.get_meta(pos)
        if meta:get_int("meter_time") > 0 then
            core.chat_send_player(digger:get_player_name(),
                S("This Power Relay has unspent time! You must connect with an adjacent Relay and spend first."))
            return 0
        end
        --[[if meta:get_int("enabled") > 0 then
            core.chat_send_player(digger:get_player_name(),
                S("The Power Relay must be disabled to pickup!"))
            return 0
        end]]--
        local leftover = digger:get_inventory():add_item("main", ItemStack(drop))
        if not leftover:is_empty() then
            local drop_pos = {
                x=math.random(pos.x - 0.5, pos.x + 0.5),
                y=math.random(pos.y - 0.0, pos.x + 0.75),
                z=math.random(pos.z - 0.5, pos.z + 0.5)}
            core.add_item(drop_pos, leftover)
        end
        local list = meta:get_inventory():get_list("src")
        if list then
            for _,item in pairs(list) do
                local drop_pos = {
                    x=math.random(pos.x - 0.5, pos.x + 0.5),
                    y=math.random(pos.y - 0.0, pos.x + 0.5),
                    z=math.random(pos.z - 0.5, pos.z + 0.5)}
                core.add_item(pos, item:to_string())
            end
        end
        local list = meta:get_inventory():get_list("dst")
        if list then
            for _,item in pairs(list) do
                local drop_pos = {
                    x=math.random(pos.x - 0.5, pos.x + 0.5),
                    y=math.random(pos.y - 0.0, pos.x + 0.5),
                    z=math.random(pos.z - 0.5, pos.z + 0.5)}
                core.add_item(pos, item:to_string())
            end
        end
        -- Remove node
        core.remove_node(pos)
    end
end

local on_blast = function(pos)
    local drop = "ship_machine:supply_relay"
    core.add_item(pos, drop)
    local meta = core.get_meta(pos)
    local list = meta:get_inventory():get_list("src")
    if list then
        for _,item in pairs(list) do
            local drop_pos = {x=math.random(pos.x - 0.5, pos.x + 0.5), y=pos.y, z=math.random(pos.z - 0.5, pos.z + 0.5)}
            core.add_item(pos, item:to_string())
        end
    end
    local list = meta:get_inventory():get_list("dst")
    if list then
        for _,item in pairs(list) do
            local drop_pos = {x=math.random(pos.x - 0.5, pos.x + 0.5), y=pos.y, z=math.random(pos.z - 0.5, pos.z + 0.5)}
            core.add_item(pos, item:to_string())
        end
    end
    core.remove_node(pos)
    return nil
end

local allow_metadata_inventory_move = function(pos, from_list, from_index,
        to_list, to_index, count, player)
    local meta = core.get_meta(pos)
    if core.is_protected(pos, player:get_player_name()) then
        return 0
    end
    return count
end

local allow_metadata_inventory_put = function(pos, listname, index, stack, player)
    local meta = core.get_meta(pos)
    if core.is_protected(pos, player:get_player_name()) then
        return 0
    end
    local stackname = stack:get_name()
    local is_coin = stackname == "testcoin:coin"
    if not is_coin then
        return 0
    end
    return stack:get_count()
end

local allow_metadata_inventory_take = function(pos, listname, index, stack, player)
    local meta = core.get_meta(pos)
    if core.is_protected(pos, player:get_player_name()) then
        return 0
    end
    return stack:get_count()
end

core.register_node("ship_machine:supply_relay", {
    description = S("Power Relay"),
    tiles  = {
        "ctg_power_relay_side_s2.png".."^[transformFXR90",
        "ctg_power_relay_side_s2.png".."^[transformR90",
        "ctg_power_relay_side_s2.png".."^[transformFX",
        "ctg_power_relay_side_s2.png",
        "ctg_power_relay_back_offline_s.png",
        "ctg_power_relay_back_offline_s.png".."^[transformFX"..cable_entry
        },
    paramtype = "light",
    paramtype2 = "facedir",
    light_source = 1,
    sunlight_propagates = true,
    legacy_facedir_simple = true,
    groups = {snappy=2, choppy=2, cracky=2, level=1, technic_machine=1, technic_all_tiers=1, axey=2, handy=1, power_relay=1},
    is_ground_content = false,
    _mcl_blast_resistance = 1,
    _mcl_hardness = 0.8,
    connect_sides = {"front", "top", "bottom"},
    sounds = technic.sounds.node_sound_metal_defaults(),
    on_receive_fields = supply_relay_receive_fields,
    on_construct = function(pos)
        local meta = core.get_meta(pos)
        meta:set_string("infotext", S("Power Relay"))
        meta:set_int("power", 2000)
        meta:set_int("enabled", 1)
        meta:set_int("mesecon_mode", 0)
        meta:set_int("mesecon_effect", 0)
        meta:set_int("relay_mode", 0)
        meta:set_int("meter_menu", 0)
        meta:set_int("meter_rate", 0)
        meta:set_int("meter_time", 0)
        meta:set_int("meter_ready", 0)
        meta:set_int("meter_power", 0)
        local inv = meta:get_inventory()
        inv:set_size("src", 2)
        inv:set_size("dst", 6)
        set_supply_relay_formspec(meta)
    end,
    mesecons = mesecons,
    digiline = digiline_def,
    technic_run = run,
    technic_on_disable = run_off,
    drop = "ship_machine:supply_relay",
    on_rightclick = on_rightclick,
    on_dig =  on_dig,
    on_blast = on_blast,
    allow_metadata_inventory_move = allow_metadata_inventory_move,
    allow_metadata_inventory_put = allow_metadata_inventory_put,
    allow_metadata_inventory_take = allow_metadata_inventory_take,
})

core.register_node("ship_machine:lv_supply_relay", {
    description = S("Power Relay"),
    tiles  = {
        "ctg_power_relay_side_s2.png".."^[transformFXR90",
        "ctg_power_relay_side_s2.png".."^[transformR90",
        "ctg_power_relay_side_s2.png".."^[transformFX",
        "ctg_power_relay_side_s2.png",
        "ctg_lv_power_relay_back_s.png",
        "ctg_lv_power_relay_back_s.png".."^[transformFX"..cable_entry
        },
    paramtype = "light",
    paramtype2 = "facedir",
    light_source = 6,
    sunlight_propagates = true,
    legacy_facedir_simple = true,
    groups = {snappy=2, choppy=2, cracky=2, level=1, not_in_creative_inventory=1, technic_machine=1, technic_all_tiers=1, axey=2, handy=1, power_relay=1},
    is_ground_content = false,
    _mcl_blast_resistance = 1,
    _mcl_hardness = 0.8,
    connect_sides = {"front", "top", "bottom"},
    sounds = technic.sounds.node_sound_metal_defaults(),
    on_receive_fields = supply_relay_receive_fields,
    mesecons = mesecons,
    digiline = digiline_def,
    technic_run = run,
    technic_on_disable = run_off,
    drop = "ship_machine:supply_relay",
    on_rightclick = on_rightclick,
    on_dig =  on_dig,
    on_blast = on_blast,
    allow_metadata_inventory_move = allow_metadata_inventory_move,
    allow_metadata_inventory_put = allow_metadata_inventory_put,
    allow_metadata_inventory_take = allow_metadata_inventory_take,
})

core.register_node("ship_machine:mv_supply_relay", {
    description = S("Power Relay"),
    tiles  = {
        "ctg_power_relay_side_s2.png".."^[transformFXR90",
        "ctg_power_relay_side_s2.png".."^[transformR90",
        "ctg_power_relay_side_s2.png".."^[transformFX",
        "ctg_power_relay_side_s2.png",
        "ctg_mv_power_relay_back_s.png",
        "ctg_mv_power_relay_back_s.png".."^[transformFX"..cable_entry
        },
    paramtype = "light",
    paramtype2 = "facedir",
    light_source = 6,
    sunlight_propagates = true,
    legacy_facedir_simple = true,
    groups = {snappy=2, choppy=2, cracky=2, level=1, not_in_creative_inventory=1, technic_machine=1, technic_all_tiers=1, axey=2, handy=1, power_relay=1},
    is_ground_content = false,
    _mcl_blast_resistance = 1,
    _mcl_hardness = 0.8,
    connect_sides = {"front", "top", "bottom"},
    sounds = technic.sounds.node_sound_metal_defaults(),
    on_receive_fields = supply_relay_receive_fields,
    mesecons = mesecons,
    digiline = digiline_def,
    technic_run = run,
    technic_on_disable = run_off,
    drop = "ship_machine:supply_relay",
    on_rightclick = on_rightclick,
    on_dig =  on_dig,
    on_blast = on_blast,
    allow_metadata_inventory_move = allow_metadata_inventory_move,
    allow_metadata_inventory_put = allow_metadata_inventory_put,
    allow_metadata_inventory_take = allow_metadata_inventory_take,
})

core.register_node("ship_machine:hv_supply_relay", {
    description = S("Power Relay"),
    tiles  = {
        "ctg_power_relay_side_s2.png".."^[transformFXR90",
        "ctg_power_relay_side_s2.png".."^[transformR90",
        "ctg_power_relay_side_s2.png".."^[transformFX",
        "ctg_power_relay_side_s2.png",
        "ctg_hv_power_relay_back_s.png",
        "ctg_hv_power_relay_back_s.png".."^[transformFX"..cable_entry
        },
    paramtype = "light",
    paramtype2 = "facedir",
    light_source = 6,
    sunlight_propagates = true,
    legacy_facedir_simple = true,
    groups = {snappy=2, choppy=2, cracky=2, level=1, not_in_creative_inventory=1, technic_machine=1, technic_all_tiers=1, axey=2, handy=1, power_relay=1},
    is_ground_content = false,
    _mcl_blast_resistance = 1,
    _mcl_hardness = 0.8,
    connect_sides = {"front", "top", "bottom"},
    sounds = technic.sounds.node_sound_metal_defaults(),
    on_receive_fields = supply_relay_receive_fields,
    mesecons = mesecons,
    digiline = digiline_def,
    technic_run = run,
    technic_on_disable = run_off,
    drop = "ship_machine:supply_relay",
    on_rightclick = on_rightclick,
    on_dig =  on_dig,
    on_blast = on_blast,
    allow_metadata_inventory_move = allow_metadata_inventory_move,
    allow_metadata_inventory_put = allow_metadata_inventory_put,
    allow_metadata_inventory_take = allow_metadata_inventory_take,
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
    technic.register_machine(tier, "ship_machine:".."lv".."_supply_relay", technic.producer_receiver)
    technic.register_machine(tier, "ship_machine:".."mv".."_supply_relay", technic.producer_receiver)
    technic.register_machine(tier, "ship_machine:".."hv".."_supply_relay", technic.producer_receiver)
end

