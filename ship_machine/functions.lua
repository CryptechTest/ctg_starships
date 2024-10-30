local S = minetest.get_translator(minetest.get_current_modname())

ship_machine.mese_image_mask = "default_mese_crystal.png^[colorize:#75757555"

-- check if enabled
ship_machine.generator_enabled = function(meta)
    return meta:get_int("enabled") == 1
end

ship_machine.reset_generator = function(meta)
    meta:set_int("charge", 0)
end

local function round(number, steps)
    steps = steps or 1
    return math.floor(number * steps + 0.5) / steps
end

function ship_machine.update_formspec(data, running, enabled, has_mese, percent, charge, charge_max)
    local tier = data.tier
    local ltier = string.lower(tier)
    local machine_name = data.machine_name
    local machine_desc = tier .. " " .. data.machine_desc
    local typename = data.typename
    local formspec = nil

    if (machine_name == "lv_gravity_drive") then
        machine_desc = "Starship " .. data.machine_desc
    end
    if percent then
        percent = round(percent, 100)
    end

    if typename == 'gravity_drive' then
        local charge_percent = 0
        if charge and charge > 0 and charge_max then
            charge_percent = round(math.floor(charge / (charge_max) * 100 * 100) / 100, 2)
        elseif charge == 0 and charge_max == 0 then
            charge_percent = 100
        end
        if charge == nil then
            charge = 0
        end
        if charge_max == nil then
            charge_max = 0
        end
        local btnName = "State: "
        if enabled then
            btnName = btnName .. "<Enabled>"
        else
            btnName = btnName .. "<Disabled>"
        end
        local image = "image[5,1;1,1;" .. "lv_gravity_drive.png" .. "]"
        if running then
            image = "image[5,1;1,1;" .. "lv_gravity_drive_active_icon.png" .. "]"
        end
        local meseimg = ""
        if has_mese or running then
            meseimg = "animated_image[6,1;1,1;;" .. "engine_mese_anim.png" .. ";4;400;]"
        end
        local act_msg = ""
        if running and charge_percent >= 100 then
            act_msg = "image[3,4;4.75,1;gravity_active.png]"
        elseif running then
            act_msg = "image[3,4;4.75,1;gravity_offline.png]"
        end
        formspec = "formspec_version[3]" .. "size[8,9;]" .. "real_coordinates[false]" ..
                       "list[current_player;main;0,5;8,4;]" .. "listring[current_player;main]" .. "label[0,0;" ..
                       machine_desc:format(tier) .. "]" .. image .. meseimg ..
                       "image[4,1;1,1;gui_furnace_arrow_bg.png^[lowpart:" .. tostring(percent) ..
                       ":gui_furnace_arrow_fg.png^[transformR270]" .. "image[3,1;1,1;" .. ship_machine.mese_image_mask ..
                       "]" .. "button[3,3;4,1;toggle;" .. btnName .. "]" .. "label[3,2;Charge " .. tostring(charge) ..
                       " of " .. tostring(charge_max) .. "]" .. "label[6,2;" .. tostring(charge_percent) .. "%" .. "]" ..
                       act_msg
    end
    if data.upgrade then
        formspec = formspec .. "list[current_name;upgrade1;0.5,3;1,1;]" .. "list[current_name;upgrade2;1.5,3;1,1;]" ..
                       "label[0.5,4;" .. S("Upgrade Slots") .. "]" .. "listring[current_name;upgrade1]" ..
                       "listring[current_player;main]" .. "listring[current_name;upgrade2]" ..
                       "listring[current_player;main]"
    end
    return formspec
end

function ship_machine.update_jumpdrive_formspec(data, meta)
    local locked = meta:get_int("locked") == 1
    if locked then
        return formspec
    end

    local machine_name = data.machine_name
    local machine_desc = "Starship " .. data.machine_desc
    local typename = data.typename
    local tier = data.tier
    local ltier = string.lower(tier)
    local formspec = nil

    if typename == 'jump_drive' or typename == 'jump_drive_spawn' then
        local owner = "label[5,0;Owner:]label[6,0;" .. meta:get_string("owner") .. "]"
        local set_owner = "field[1,2.65;4,1;owner_name;Owner Name;]button[5,2.25;1,1;set_owner;Set]"
        local input_name = "field[1,1.45;4,1;file_name;File Name;]"
        local input_save_load = "button[5,1;1,1;save;Save]button[6,1;1,1;load;Load]"
        local setup_button = "button[3,3.5;2.5,1;setup;Complete Setup]"
        local input_test =
            "field[1,2;2,1;inp_x;Move X;0]field[3,2;2,1;inp_y;Move Y;0]field[5,2;2,1;inp_z;Move Z;0]button[3,4;2,1;jump;Test]"

        formspec = "formspec_version[3]" .. "size[8,5;]" .. "real_coordinates[false]" .. "label[0,0;" ..
                       machine_desc:format(tier) .. "]" .. input_name .. input_save_load .. owner .. set_owner
    end

    return formspec
end

local function do_particles(pos, amount)
    local prt = {
        texture = {
            name = "vacuum_air_particle_1.png",
            fade = "out"
        },
        animation = {},
        texture_r180 = {
            name = "vacuum_air_particle_1.png" .. "^[transformR180",
            fade = "out"
        },
        vel = 0.6,
        time = 3,
        size = 10,
        glow = 3,
        cols = false
    }
    local exm = pos
    exm.y = exm.y + 1.5
    local rx = math.random(-0.01, 0.01) * 0.5
    local rz = math.random(-0.01, 0.01) * 0.5
    local texture = prt.texture
    if (math.random() >= 0.6) then
        texture = prt.texture_r180
    end

    minetest.add_particlespawner({
        amount = amount,
        time = prt.time + math.random(0.5, 1),
        minpos = {
            x = exm.x - 5,
            y = exm.y - 1,
            z = exm.z - 5
        },
        maxpos = {
            x = exm.x + 5,
            y = exm.y + 4,
            z = exm.z + 5
        },
        minvel = {
            x = rx,
            y = prt.vel * 0.2,
            z = rz
        },
        maxvel = {
            x = rx,
            y = prt.vel * 0.7,
            z = rz
        },
        minacc = {
            x = -0.02,
            y = -0.05,
            z = -0.02
        },
        maxacc = {
            x = 0.02,
            y = -0.03,
            z = 0.02
        },
        minexptime = prt.time * 1.76,
        maxexptime = prt.time * 3.2,
        minsize = prt.size * 0.7,
        maxsize = prt.size * 1.5,
        collisiondetection = prt.cols,
        collision_removal = false,
        object_collision = false,
        vertical = false,
        animation = prt.animation,
        texture = texture,
        glow = prt.glow
    })

    --[[minetest.add_particle({
        pos = exm,
        velocity = {
            x = rx,
            y = prt.vel * -math.random(0.2 * 100, 0.7 * 100) / 100,
            z = rz
        },
        minacc = {
            x = -0.02,
            y = -0.05,
            z = -0.02
        },
        maxacc = {
            x = 0.02,
            y = -0.03,
            z = 0.02
        },
        expirationtime = ((math.random() / 5) + 0.25) * prt.time,
        size = ((math.random()) * 7 + 0.1) * prt.size,
        collisiondetection = prt.cols,
        vertical = false,
        texture = texture,
        glow = prt.glow
    })]] --
end

local function do_particle_tele(pos, amount)
    local prt = {
        texture = "teleport_effect01.png",
        texture_r180 = "teleport_effect01.png" .. "^[transformR180",
        vel = 13,
        time = 0.6,
        size = 5,
        glow = 7,
        cols = false
    }
    local exm = pos
    exm.y = exm.y - 2.25
    local rx = math.random(-0.01, 0.01) * 0.1
    local rz = math.random(-0.01, 0.01) * 0.1
    local texture = prt.texture
    if (math.random() >= 0.6) then
        texture = prt.texture_r180
    end

    minetest.add_particlespawner({
        amount = amount,
        time = prt.time + math.random(0.8, 2.7),
        minpos = {
            x = exm.x - 5,
            y = exm.y - 3,
            z = exm.z - 5
        },
        maxpos = {
            x = exm.x + 5,
            y = exm.y + 1,
            z = exm.z + 5
        },
        minvel = {
            x = rx,
            y = prt.vel * 0.2,
            z = rz
        },
        maxvel = {
            x = rx,
            y = prt.vel * 0.7,
            z = rz
        },
        minacc = {
            x = -0.02,
            y = -0.05,
            z = -0.02
        },
        maxacc = {
            x = 0.02,
            y = -0.03,
            z = 0.02
        },
        minexptime = prt.time * 0.28,
        maxexptime = prt.time * 1.00,
        minsize = prt.size * 0.8,
        maxsize = prt.size * 1.2,
        collisiondetection = prt.cols,
        collision_removal = false,
        object_collision = false,
        vertical = true,
        animation = prt.animation,
        texture = texture,
        glow = prt.glow
    })

    --[[
    minetest.add_particle({
        pos = exm,
        velocity = {
            x = rx,
            y = prt.vel * math.random(0.2 * 100, 0.7 * 100) / 100,
            z = rz
        },
        minacc = {
            x = -0.02,
            y = 0.05,
            z = -0.02
        },
        maxacc = {
            x = 0.02,
            y = 0.03,
            z = 0.02
        },
        expirationtime = ((math.random() / 5) + 0.25) * prt.time,
        size = ((math.random()) * 7 + 0.1) * prt.size,
        collisiondetection = prt.cols,
        vertical = true,
        texture = texture,
        glow = prt.glow
    })]] --
end

function ship_machine.move_offline_players(drive, offset)
    -- local node = minetest.get_node(drive)
    local dmeta = minetest.get_meta(drive)

    local stor_str = dmeta:get_string("player_storage")
    local contents = {}
    if stor_str ~= nil and #stor_str > 0 then
        contents = minetest.deserialize(stor_str)
    end

    for p, _ in pairs(contents) do
        local lpos = ship_machine.locations[p];
        if lpos then
            local npos = vector.add(lpos, offset);
            ship_machine.locations[p] = npos
            --minetest.log("updated loc for player " .. p)
        else 
            contents[p] = false
        end
        ship_machine.save_locations();
    end
    dmeta:set_string("player_storage", minetest.serialize(contents))
end

function ship_machine.move_bed(pos, pos_new, n)

    local node = minetest.get_node(pos)
    local other

    if n == 2 then
        local dir = minetest.facedir_to_dir(node.param2)
        other = vector.subtract(pos, dir)
    elseif n == 1 then
        local dir = minetest.facedir_to_dir(node.param2)
        other = vector.add(pos, dir)
    end

    -- try and fetch player from beds db...
    local player_name = beds.player_bed[minetest.serialize(pos)]

    if player_name == nil then
        local node_meta = minetest.get_meta(pos)
        if node_meta:get_string("owner") then
            -- fetch player from node meta
            player_name = node_meta:get_string("owner")
        end
    end

    if player_name then
        local old_spawn = beds.spawn[player_name]

        beds.remove_spawns_at(pos)
        beds.remove_spawns_at(other)
        beds.remove_player_beds_at(pos)

        if n == 2 then
            pos = other
        end

        local player = minetest.get_player_by_name(player_name)
        if player ~= nil then
            for i = 1, 24 do
                local inv = player:get_inventory()
                local bed = inv:get_stack("beds", i)
                if not bed:is_empty() then
                    local meta = bed:get_meta()
                    local ppos = meta:get_string("pos")
                    if minetest.serialize(pos) == ppos then

                        beds.player_bed[minetest.serialize(pos_new)] = player_name
                        beds.bed_cooldown[minetest.serialize(pos_new)] = false

                        if old_spawn ~= nil then
                            if old_spawn.x == pos.x and old_spawn.y == pos.y and old_spawn.z == pos.z then
                                beds.spawn[player_name] = {
                                    x = pos_new.x,
                                    y = pos_new.y + 1,
                                    z = pos_new.z
                                }
                            end
                        end

                        meta:set_string("pos", minetest.serialize(pos_new))
                        inv:set_stack("beds", i, bed)

                        -- minetest.log("moved bed!")
                        break
                    end
                end
            end
            beds.save_player_beds()
            beds.save_spawns()
            unified_inventory.set_inventory_formspec(player, unified_inventory.current_page[player_name])
        end
    end

end

function ship_machine.transport_jumpship(pos, dest, size, owner, offset)
    local save = false
    local flags = {
        file_cache = save,
        keep_inv = true,
        keep_meta = true,
        origin_clear = true
    }
    local ship_name = "jumpship_1_" .. owner
    -- save to cache
    local sdata = schemlib.emit({
        filename = ship_name,
        owner = owner,
        ttl = 300, -- ???
        w = size.w,
        h = size.h,
        l = size.l,
        origin = {
            x = pos.x,
            y = pos.y,
            z = pos.z
        },
        dest = {
            x = dest.x,
            y = dest.y,
            z = dest.z
        }
    }, flags)

    if save then
        -- load the schematic from file..
        local lmeta = schemlib.load_emitted({
            filename = ship_name,
            moveObj = true
        })
    else
        -- load the schematic from cache..
        local count, ver, lmeta = schemlib.process_emitted(nil, nil, sdata, true)

        ship_machine.move_offline_players(pos, offset)

        minetest.after(5, function()
            local pos1 = vector.subtract(pos, {
                x = size.w,
                y = size.h,
                z = size.l
            })
            local pos2 = vector.add(pos, {
                x = size.w,
                y = size.h,
                z = size.l
            })

            local beds = minetest.find_nodes_in_area(pos1, pos2, "group:bed")
            for _, bedpos in pairs(beds) do
                local bed = minetest.get_node(bedpos)
                if bed ~= nil then
                    local g = minetest.get_item_group(bed.name, "bed");
                    if minetest.get_item_group(bed.name, "bed") >= 1 then
                        local bed_dest = vector.add(bedpos, offset)
                        ship_machine.move_bed(bedpos, bed_dest, g)
                    end
                end
            end

        end)
    end

    local pos1 = vector.subtract(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })
    local pos2 = vector.add(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })

    -- get cube of area nearby
    local objects = minetest.get_objects_in_area(pos1, pos2) or {}
    for _, obj in pairs(objects) do
        if (obj ~= nil and obj:is_player()) then
            for i = 0, 3 do
                minetest.after(i, function()
                    if (obj ~= nil) then
                        local name = obj:get_player_name()
                        minetest.sound_play("tele_drone", {
                            to_player = name,
                            gain = math.random(0.8, 1.1),
                            pitch = math.random(0.8, 1)
                        })
                        local p = obj:get_pos()
                        do_particles(p, 40)
                        do_particle_tele(p, 110)
                    end
                end)
            end
        end
    end

    --[[minetest.chat_send_player(player:get_player_name(), "Jumping in... 3")
    minetest.after(1, function()
        minetest.chat_send_player(player:get_player_name(), "Jumping in... 2")
    end)
    minetest.after(2, function()
        minetest.chat_send_player(player:get_player_name(), "Jumping in... 1")
    end)
    minetest.after(3, function()
        minetest.chat_send_player(player:get_player_name(), "Jumping...")
    end)--]]
end

-- save to file
function ship_machine.save_jumpship(pos, size, player, ship_name)
    local save = true
    local flags = {
        file_cache = save,
        keep_inv = true,
        keep_meta = true,
        origin_clear = false
    }
    local owner = player:get_player_name()
    -- save to cache
    local sdata = schemlib.emit({
        filename = ship_name,
        owner = owner,
        ttl = 300,
        w = size.w,
        h = size.h,
        l = size.l,
        origin = {
            x = pos.x,
            y = pos.y,
            z = pos.z
        }
    }, flags)

    minetest.chat_send_player(player:get_player_name(), "Saving Jumpship as... " .. ship_name)
end

function ship_machine.load_jumpship(pos, player, ship_name)
    -- load the schematic from file..
    local lmeta = schemlib.load_emitted({
        filename = ship_name,
        origin = {
            x = pos.x,
            y = pos.y,
            z = pos.z
        },
        moveObj = false
    })

    if lmeta then
        minetest.chat_send_player(player:get_player_name(), "Loading Jumpship...")
    else
        minetest.chat_send_player(player:get_player_name(), "Loading Jumpship Failed!")
    end
end

local function check_engines_charged(pos, size)

    local pos1 = vector.subtract(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })
    local pos2 = vector.add(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "group:ship_engine")

    if #nodes == 2 then

        local eng1 = minetest.get_meta(nodes[1])
        local eng2 = minetest.get_meta(nodes[2])

        local charge1 = eng1:get_int('charge')
        local charge2 = eng2:get_int('charge')

        local charge_max1 = eng1:get_int('charge_max')
        local charge_max2 = eng2:get_int('charge_max')

        local charged1 = false
        local charged2 = false
        if (charge1 >= charge_max1) then
            charged1 = true
        end
        if (charge2 >= charge_max2) then
            charged2 = true
        end

        if charged1 and charged2 then
            return true
        end
    elseif #nodes > 2 then
        local charged = 0
        for _, node in pairs(nodes) do
            local eng = minetest.get_meta(node)
            local charge = eng:get_int('charge')
            local charge_max = eng:get_int('charge_max')
            local _charged = false
            if (charge >= charge_max) then
                _charged = true
            end
            if _charged then
                charged = charged + 1;
            end
        end
        return charged >= 2
    end
    return false
end

local function engines_charged_spend(pos, dist, size)

    local pos1 = vector.subtract(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })
    local pos2 = vector.add(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "group:ship_engine")

    if #nodes == 2 then

        local max = 2000
        local c_max = 160
        local chrg = (c_max / max) * dist

        ship_engine.ship_jump(nodes[1], chrg)
        ship_engine.ship_jump(nodes[2], chrg)

        return true
    elseif #nodes > 2 then
        local max = 2000
        local c_max = 160
        local chrg = ((c_max / max) * dist) / #nodes
        for _, eng in pairs(nodes) do
            ship_engine.ship_jump(eng, chrg)
        end
        return true
    end
    return false
end

local function do_jump(pos, dest, size, jcb, offset)
    local meta = minetest.get_meta(pos)
    local owner = meta:get_string("owner")

    local pos1 = vector.subtract(dest, {
        x = size.w,
        y = size.h,
        z = size.l
    })
    local pos2 = vector.add(dest, {
        x = size.w,
        y = size.h,
        z = size.l
    })

    if check_engines_charged(pos, size) == true then
        digilines.receptor_send(pos, digilines.rules.default, 'jumpdrive', {
            command = 'jumping'
        })
        local dist = vector.distance(pos, dest)
        engines_charged_spend(pos, dist, size)
        ship_machine.transport_jumpship(pos, dest, size, owner, offset)
        jcb(1)
        return
    end
    jcb(0)
    return
end

function ship_machine.perform_jump(pos, dest, size, jcb, offset)

    local area_clear = true
    if not schemlib.func.check_dest_clear(pos, dest, size) then
        area_clear = false
    end

    minetest.after(2, function()
        if not area_clear then
            area_clear = schemlib.func.check_dest_clear(pos, dest, size)
            if not area_clear then
                jcb(-1)
                return
            end
        end

        local meta = minetest.get_meta(pos)
        if meta:get_int("jumps") == nil then
            meta:set_int("jumps", 0)
        end
        meta:set_int("jumps", meta:get_int("jumps") + 1)

        do_jump(pos, dest, size, jcb, offset)

        do_particles(dest, 20)
    end)

end

function ship_machine.get_protector(pos, size)
    local pos1 = vector.subtract(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })
    local pos2 = vector.add(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "ship_scout:protect2")

    if #nodes == 1 then
        return nodes[1]
    end
    return nil
end

function ship_machine.get_jump_drive(pos)
    return minetest.find_node_near(pos, 15, {"ship_machine:jump_drive"})
end
