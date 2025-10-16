local S = minetest.get_translator(minetest.get_current_modname())

local mese_image_mask = "default_mese_crystal.png^[colorize:#75757555"

local function round(number, steps)
    steps = steps or 1
    return math.floor(number * steps + 0.5) / steps
end

function ship_machine.update_formspec(data, meta, running, percent)
    local enabled = meta:get_int("enabled") > 0
    local has_mese = meta:get_int("has_mese")
    local charge = meta:get_int("charge")
    local charge_max = meta:get_int("charge_max")

    local tier = data.tier
    local ltier = string.lower(tier)
    local machine_name = data.machine_name
    local machine_desc = tier .. " " .. data.machine_desc
    local typename = data.typename
    local formspec = nil

    local eu_input = meta:get_int(tier .. "_EU_input")
    local eu_demand = meta:get_int(tier .. "_EU_demand")

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
        local btnColor = ""
        if enabled then
            btnName = btnName .. "<Enabled>"
            btnColor = "style[toggle;bgcolor=#34eb7420]"
        else
            btnName = btnName .. "<Disabled>"
            btnColor = "style[toggle;bgcolor=#eb403410]"
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
            act_msg = "image[3,3.45;4.75,0.9;gravity_active.png]"
        elseif running then
            act_msg = "image[3,3.45;4.75,0.9;gravity_offline.png]"
        end
        local power_field = "label[0.5,0.8;" .. minetest.colorize('#21daff', "Energy Stats") .. "]"
        local input_field = "label[0.5,1.2;Input Eu]label[0.5,1.55;" .. minetest.colorize('#03fc56', "+" .. eu_input) .. "]"
        local demand_field = "label[0.5,1.9;Demand Eu]label[0.5,2.25;" .. minetest.colorize('#fca903', "-" .. eu_demand) .. "]"

        formspec = "formspec_version[8]" .. "size[8,9;]" .. "real_coordinates[false]" ..
                       "list[current_player;main;0,5;8,4;]" .. "listring[current_player;main]" .. "label[0,0;" ..
                       machine_desc:format(tier) .. "]" .. image .. meseimg ..
                       "image[4,1;1,1;gui_furnace_arrow_bg.png^[lowpart:" .. tostring(percent) ..
                       ":gui_furnace_arrow_fg.png^[transformR270]" .. "image[3,1;1,1;" .. mese_image_mask .. "]" ..
                       btnColor .. "button[3,2.6;4,1;toggle;" .. btnName .. "]" .. 
                       "label[3,2;Charge " .. tostring(charge) .. " of " .. tostring(charge_max) .. "]" .. 
                       "label[6,2;" .. tostring(charge_percent) .. "%" .. "]" .. 
                       act_msg .. power_field .. demand_field .. input_field
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
        return ''
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
        local set_owner_local = "field[1,3.85;4,1;owner_name_local;Owner Local;]button[5,3.45;1,1;set_owner_local;Set]"
        local input_name = "field[1,1.45;4,1;file_name;File Name;]"
        local input_save_load = "button[5,1;1,1;save;Save]button[6,1;1,1;load;Load]"
        local btn_lock = "button[6,3.45;1,1;lock;Lock]"

        formspec = "formspec_version[3]" .. "size[8,5;]" .. "real_coordinates[false]" .. 
                    "label[0,0;" .. machine_desc:format(tier) .. "]" .. input_name .. 
                    input_save_load .. owner .. set_owner .. set_owner_local .. btn_lock
    end

    return formspec
end

local function do_particles(pos, amount, radius)
    local r = radius ~= nil and radius or 5
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
            x = exm.x - r,
            y = exm.y - 1,
            z = exm.z - r
        },
        maxpos = {
            x = exm.x + r,
            y = exm.y + 4,
            z = exm.z + r
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
end

local function do_particle_tele(pos, amount, radius)
    local r = radius ~= nil and radius or 5
    local prt = {
        texture = "teleport_effect01.png",
        texture_r180 = "teleport_effect01.png" .. "^[transformR180",
        vel = 13,
        time = 0.67,
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
        time = prt.time + math.random(1, 2.25),
        minpos = {
            x = exm.x - r,
            y = exm.y - 3,
            z = exm.z - r
        },
        maxpos = {
            x = exm.x + r,
            y = exm.y + 1,
            z = exm.z + r
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
end

local function move_offline_players(origin, offset)
    local dest = vector.add(origin, offset)
    local dmeta = minetest.get_meta(dest)

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
            -- minetest.log("updated loc for player " .. p)
        else
            contents[p] = false
        end
        ship_machine.save_locations();
    end
    dmeta:set_string("player_storage", minetest.serialize(contents))
end

local function move_bed(pos, pos_new, n)

    local node = minetest.get_node(pos)
    local other
    local player_name = nil

    if n == 2 then
        -- if top, get bottom
        other = pos
        local dir = minetest.facedir_to_dir(node.param2)
        pos = vector.subtract(pos, dir) -- pos = other
        pos_new = vector.subtract(pos_new, dir)
        -- try and fetch player from beds db...
        player_name = beds.player_bed[minetest.serialize(pos)]
    elseif n == 1 then
        -- try and fetch player from beds db...
        player_name = beds.player_bed[minetest.serialize(pos)]
        -- if bottom, get top
        local dir = minetest.facedir_to_dir(node.param2)
        other = vector.add(pos, dir)
    else
        core.log("[ship_machine] failed to lookup bed!")
    end

    if not player_name then
        player_name = beds.player_bed[minetest.serialize(other)]
    end

    if player_name == nil then
        --core.log("[ship_machine] failed to lookup player_name, using owner!")
        local node_meta = minetest.get_meta(pos)
        if node_meta:get_string("owner") then
            -- fetch player from node meta
            player_name = node_meta:get_string("owner")
        end
    end

    if player_name then

        beds.remove_spawns_at(pos)
        beds.remove_spawns_at(other)
        beds.remove_player_beds_at(pos)

        local player = minetest.get_player_by_name(player_name)
        if player ~= nil then
            local old_spawn = beds.spawn[player_name]
            if old_spawn ~= nil then
                if old_spawn.x == pos.x and old_spawn.y == pos.y + 1 and old_spawn.z == pos.z then
                    beds.spawn[player_name] = {
                        x = pos_new.x,
                        y = pos_new.y + 1,
                        z = pos_new.z
                    }
                end
            end
            local inv = player:get_inventory()
            local slot = 0
            for i = 1, 24 do                
                local bed = inv:get_stack("beds", i)
                if not bed:is_empty() then
                    local meta = bed:get_meta()
                    local ppos = meta:get_string("pos")
                    local spos = core.deserialize(ppos)
                    if pos.x == spos.x and pos.y == spos.y and pos.z == spos.z then

                        meta:set_string("pos", minetest.serialize(pos_new))
                        inv:set_stack("beds", i, bed)

                        beds.player_bed[minetest.serialize(pos_new)] = player_name
                        beds.bed_cooldown[minetest.serialize(pos_new)] = false

                        --core.chat_send_player(player_name, "[Debug] Bed Moved on Jump!")
                        break;
                    end
                end
            end
            core.after(0, function()
                unified_inventory.set_inventory_formspec(player, unified_inventory.current_page[player_name])
            end)            
        end
    end

end

local function move_beds(pos1, pos2, offset)
    local bed_nodes = minetest.find_nodes_in_area(pos1, pos2, "group:bed")
    for _, bedpos in pairs(bed_nodes) do
        local bed = minetest.get_node(bedpos)
        if bed ~= nil then
            local g = minetest.get_item_group(bed.name, "bed");
            if g >= 1 then
                local bed_dest = vector.add(bedpos, offset)
                move_bed(bedpos, bed_dest, g)
            end
        end
    end
    if #bed_nodes > 0 then
        beds.save_player_beds()
        beds.save_spawns()
    end
end

local function update_tubes(pos1, pos2, offset)
    local tubes = minetest.find_nodes_in_area(pos1, pos2, "group:tube")
    if tubes == nil or #tubes == 0 then
        return
    end
    for _, tubepos in pairs(tubes) do
        local node = minetest.get_node(tubepos)
        if node ~= nil then
            if node.name:find("pipeworks:teleport_tube") then
                local meta = minetest.get_meta(tubepos)
                local channel = meta:get_string("channel")
                local cr = meta:get_int("can_receive")
                local player_name = meta:get_string("owner")
                if channel == nil or cr == nil or player_name == nil then
                    return
                end
                if channel == "" or player_name == "" then
                    return
                end
                local tube_db = pipeworks.tptube.get_db()
                if tube_db == nil then
                    return
                end
                local receivers = {}
                for key, val in pairs(tube_db) do
                    if val.cr == 1 and val.channel == channel and not vector.equals(val, tubepos) then
                        minetest.load_area(val)
                        local node_name = minetest.get_node(val).name
                        if node_name:find("pipeworks:teleport_tube") then
                            table.insert(receivers, val)
                        end
                    end
                end
                pipeworks.tptube.set_tube(vector.add(tubepos, offset), channel, cr)
                for _, val in pairs(receivers) do
                    pipeworks.tptube.set_tube(val, val.channel, val.cr)
                end
            end
        end
    end
end

local function clear_switching_station(pos)
    local node = core.get_node(pos)
    if node.name ~= "technic:switching_station" then
        return
    end
    local network_id = technic.sw_pos2network(pos)
    if network_id then
        technic.remove_network(network_id)
    end
    minetest.get_node_timer(pos):stop()
end

local function setup_switching_station(pos)
    local node = core.get_node(pos)
    if node.name ~= "technic:switching_station" then
        return
    end
    local network_id = technic.create_network(pos)
    local network = network_id and technic.networks[network_id]
    if network and technic.switch_insert(pos, network) > 0 then
        technic.activate_network(network_id)
        schem_lib.func.do_particle_zap(vector.subtract(pos, {x=0,y=1,z=0}), 1)
    end
    minetest.get_node_timer(pos):start(1.0)
end

local function update_switching_stations(pos1, pos2, clear)
    local switch_nodes = minetest.find_nodes_in_area(pos1, pos2, "technic:switching_station")
    for _, sw_pos in pairs(switch_nodes) do
        if clear then
            clear_switching_station(sw_pos)
        else
            setup_switching_station(sw_pos)
        end
    end
end

local function clear_active_miners(pos1, pos2)
    if not minetest.get_modpath("testcoin") then
        return
    end
    local rigs = minetest.find_nodes_in_area(pos1, pos2, "group:mining_rig")
    for _, r_pos in pairs(rigs) do
        testcoin.remove_active_miner(r_pos)
    end
end

local function do_effect(pos, pos1, pos2)
    local function _effect(obj, i)
        minetest.after(i+0.5, function()
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
    -- get cube of area nearby
    local objects = minetest.get_objects_in_area(pos1, pos2) or {}
    local players = {}
    for _, obj in pairs(objects) do
        if (obj ~= nil and obj:is_player()) then
            table.insert(players, obj)
        end
    end
    do_particle_tele(pos, 50, 7)
    -- play effects to players in area
    for _, obj in pairs(players) do
        for i = 0, 1 do
            _effect(obj, i)
        end
    end
end

local function post_emerge_complete(meta)
    if meta == nil then
        core.log("post_emerge_complete() meta nil")
        return
    elseif not meta.origin or not meta.offset or not meta.dest then
        core.log("post_emerge_complete() meta data nil")
        return
    end
    local pos = meta.origin
    local dest = meta.dest
    local size = meta.offset
    local offset = vector.subtract(dest, pos)
    -- origin positions
    local pos1 = vector.subtract(pos, vector.new(size.x, size.y, size.z))
    local pos2 = vector.add(pos, vector.new(size.x, size.y, size.z))
    -- move beds and update tubes
    move_beds(pos1, pos2, offset)
    update_tubes(pos1, pos2, offset)
    -- clear miners active in area
    clear_active_miners(pos1, pos2)
    -- move offline player locations
    move_offline_players(pos, offset)
    -- dest positions
    local dest_pos1 = vector.subtract(dest, vector.new(size.x, size.y, size.z))
    local dest_pos2 = vector.add(dest, vector.new(size.x, size.y, size.z))
    -- update screens
    schem_lib.func.update_screens(dest_pos1, dest_pos2)
    -- rebuild wire networks
    update_switching_stations(dest_pos1, dest_pos2, false)
    -- effects
    do_particles(dest, 128, math.min(size.x, size.z))
    do_particle_tele(dest, 256, math.min(size.x, size.z))
    --core.log("post emerge complete")
end

local function emerge_callback_on_complete(meta, flags)
    if meta == nil or flags == nil then
        core.log("emerge_callback_on_complete data is nil")
        return
    end
    local ttl = 3;
    if meta.ttl ~= nil and meta.ttl > 0 then
        ttl = meta.ttl
    end
    minetest.after(0, function()
        post_emerge_complete(meta) 
    end)
    minetest.after(0.5, function()
        schem_lib.func.jump_ship_move_contents(meta)
    end)
    minetest.after(ttl - 0.5, function()
        schem_lib.func.jump_ship_emit_player(meta, true)
    end)
    if flags and flags.origin_clear then
        local size = meta.offset
        local pos1 = vector.subtract(meta.origin, vector.new(size.x, size.y, size.z))
        local pos2 = vector.add(meta.origin, vector.new(size.x, size.y, size.z))
        minetest.after(ttl + 0.25, function()
            schem_lib.func.clear_position(pos1, pos2)
        end)
    end
end

local function transport_jumpship(pos, dest, size, owner, offset)
    local save = false
    local flags = {
        file_cache = save,
        keep_inv = true,
        keep_meta = true,
        origin_clear = true,
        keep_timers = true,
        stop_timers = true,
        ignored_nodes = {"vacuum:vacuum", "asteroid:atmos"}
    }
    local ship_name = "jumpship_1_" .. owner
    -- position min/max
    local pos1 = vector.subtract(pos, vector.new(size.w, size.h, size.l))
    local pos2 = vector.add(pos, vector.new(size.w, size.h, size.l))
    local data = {
        filename = ship_name,
        owner = owner,
        ttl = 3,
        min = pos1,
        max = pos2,
        offset = vector.new(size.w, size.h, size.l),
        origin = vector.new(pos),
        dest = vector.new(dest)
    }
    -- save to cache
    local schem_data = schemlib.emit(data, flags)

    if save then
        -- load the schematic from file..
        local lmeta = schem_lib.load_emitted({
            filename = ship_name,
            moveObj = true
        })
    else
        -- do jump tele effects
        do_effect(pos, pos1, pos2)
        do_particle_tele(pos, 64, math.min(size.l, size.w))
        -- clear prior wire networks
        update_switching_stations(pos1, pos2, true)
        -- emit players
        schem_lib.func.jump_ship_emit_player(schem_data.meta, false)
        -- clear screens...
        schem_lib.func.clear_screens(pos1, pos2)
        -- load the schematic from cache..
        local count, ver, lmeta = schemlib.process_emitted(nil, nil, schem_data, emerge_callback_on_complete)
    end
end

local function check_engines_charged(pos, size, dist, use_charge)

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

        local max = 2500
        local c_max = 160
        local req_charge = math.max(3, (c_max / max) * dist)

        local charged1 = false
        local charged2 = false
        if (charge1 >= charge_max1 or charge1 >= req_charge) then
            charged1 = true
        end
        if (charge2 >= charge_max2 or charge2 >= req_charge) then
            charged2 = true
        end

        if charged1 and charged2 then
            return true
        end
    elseif #nodes > 2 then
        --core.log("found " .. tostring(#nodes) .. " engines")

        local max = 2500
        local c_max = 160
        local req_charge = math.max(3, ((c_max / max) * dist) / #nodes)
        --core.log("required charge: " .. tostring(req_charge))

        local charged = 0

        for _, node in pairs(nodes) do
            local eng = minetest.get_meta(node)
            local charge = eng:get_int('charge')
            local charge_max = eng:get_int('charge_max')
            local _charged = false
            if (charge >= charge_max or charge >= req_charge) then
                _charged = true
            end
            if _charged then
                charged = charged + 1;
            end
        end
        --core.log("engines charged: " .. tostring(charged))
        return charged >= 2
    end
    return false
end

local function get_engines_charge(pos, size)

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

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "group:jumpdrive")

    local drive = nil
    for _, p in pairs(nodes) do
        local prot = vector.add(p, vector.new(0, 2, 0))
        local ship_meta = minetest.get_meta(prot)
        local _size = {
            w = ship_meta and ship_meta:get_int("p_width") or size.w,
            l = ship_meta and ship_meta:get_int("p_length") or size.l,
            h = ship_meta and ship_meta:get_int("p_height") or size.h
        }
        if pos.x <= p.x + _size.w and pos.x >= p.x - _size.w then
            if pos.z <= p.z + _size.l and pos.z >= p.z - _size.l then
                if pos.y <= p.y + _size.h and pos.y >= p.y - _size.h then
                    drive = p
                end
            end
        end
        if drive ~= nil then
            break
        end
    end

    if drive == nil then
        return 0, 0, 0
    end

    local c_pos1 = vector.subtract(drive, {
        x = size.w,
        y = size.h,
        z = size.l
    })
    local c_pos2 = vector.add(drive, {
        x = size.w,
        y = size.h,
        z = size.l
    })

    local nodes = minetest.find_nodes_in_area(c_pos1, c_pos2, "group:ship_engine")
    local charge = 0

    if #nodes == 2 then

        local eng1 = minetest.get_meta(nodes[1])
        local eng2 = minetest.get_meta(nodes[2])

        local charge1 = eng1:get_int('charge')
        local charge2 = eng2:get_int('charge')

        charge = math.min(charge1, charge2)

    elseif #nodes > 2 then

        for _, node in pairs(nodes) do
            local eng = minetest.get_meta(node)
            local _charge = eng:get_int('charge')
            charge = charge + _charge
        end

        charge = charge / #nodes

    end

    local count = #nodes
    local max = 2500
    local c_max = 160
    local distance = math.max(3, (charge * max) / c_max)

    return charge, distance, count
end

ship_machine.get_engines_charge = get_engines_charge

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

        local max = 2500
        local c_max = 160
        local chrg = math.max(3, (c_max / max) * dist)

        ship_engine.ship_jump(nodes[1], chrg)
        ship_engine.ship_jump(nodes[2], chrg)

        return true
    elseif #nodes > 2 then
        local max = 2500
        local c_max = 160
        local chrg = math.max(3, ((c_max / max) * dist) / #nodes)
        for _, eng in pairs(nodes) do
            ship_engine.ship_jump(eng, chrg)
        end
        return true
    end
    return false
end

local function do_jump(pos, dest, size, jcb, offset, use_charge)
    local meta = minetest.get_meta(pos)
    local owner = meta:get_string("owner")
    local dist = vector.distance(pos, dest)

    if not use_charge or check_engines_charged(pos, size, dist, use_charge) == true then
        digilines.receptor_send(pos, technic.digilines.rules_allfaces, 'jumpdrive', 'jump_prepare')

        if use_charge then
            engines_charged_spend(pos, dist, size)
        end
        transport_jumpship(pos, dest, size, owner, offset)

        local drv = vector.add(pos, offset)
        minetest.after(0.5, function()
            digilines.receptor_send(drv, technic.digilines.rules_allfaces, 'jumpdrive', 'jump_complete')
        end)
        jcb(1)
        return
    end
    jcb(0)
    return
end

local function check_jump_dest_jump(pos, size, jcb, offset)

    local hash = core.hash_node_position(pos)
    local dest = vector.add(pos, offset)

    local area_clear = true
    if not schem_lib.func.check_dest_clear(pos, dest, size) then
        area_clear = false
    end

    minetest.after(0.5, function()
        if area_clear then
            jcb(1, hash)
        else
            area_clear = schem_lib.func.check_dest_clear(pos, dest, size)
            if not area_clear then
                jcb(-1, hash)
                return
            else
                jcb(1, hash)
            end
        end
    end)
end

local function perform_jump(pos, size, jcb, offset, use_charge)

    local dest = vector.add(pos, offset)

    local area_clear = true
    if not schem_lib.func.check_dest_clear(pos, dest, size) then
        area_clear = false
    end

    minetest.after(1, function()
        if not area_clear then
            area_clear = schem_lib.func.check_dest_clear(pos, dest, size)
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

        do_jump(pos, dest, size, jcb, offset, use_charge)

        do_particles(dest, 20)
    end)

end

----------------------------------------------------
----------------------------------------------------
----------------------------------------------------

-- save to file
function ship_machine.save_jumpship(pos, size, player, ship_name)
    local save = true
    local flags = {
        file_cache = save,
        keep_inv = true,
        keep_meta = true,
        origin_clear = false,
        keep_timers = true,
        stop_timers = false,
    }
    local owner = player:get_player_name()
    -- save to cache
    local sdata = schem_lib.emit({
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
    local lmeta = schem_lib.load_emitted({
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

    local prots = minetest.find_nodes_in_area(pos1, pos2, "group:ship_protector")

    local prot = nil
    for _, p in pairs(prots) do
        local ship_meta = minetest.get_meta(p)
        local _size = {
            w = ship_meta:get_int("p_width") or 10,
            l = ship_meta:get_int("p_length") or 10,
            h = ship_meta:get_int("p_height") or 10
        }
        if pos.x <= p.x + _size.w and pos.x >= p.x - _size.w then
            if pos.z <= p.z + _size.l and pos.z >= p.z - _size.l then
                if pos.y <= p.y + _size.h and pos.y >= p.y - _size.h then
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

function ship_machine.get_ship_contains(pos, size, name)
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

    local nodes = minetest.find_nodes_in_area(pos1, pos2, name)

    local prot = nil
    for _, p in pairs(nodes) do
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

function ship_machine.engine_do_jump(pos, size, jump_callback, dest_offset)
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

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "group:jumpdrive")

    local drive = nil
    for _, p in pairs(nodes) do
        local prot = vector.add(p, vector.new(0, 2, 0))
        local ship_meta = minetest.get_meta(prot)
        local _size = {
            w = ship_meta and ship_meta:get_int("p_width") or size.w,
            l = ship_meta and ship_meta:get_int("p_length") or size.l,
            h = ship_meta and ship_meta:get_int("p_height") or size.h
        }
        if pos.x <= p.x + _size.w and pos.x >= p.x - _size.w then
            if pos.z <= p.z + _size.l and pos.z >= p.z - _size.l then
                if pos.y <= p.y + _size.h and pos.y >= p.y - _size.h then
                    drive = p
                end
            end
        end
        if drive ~= nil then
            break
        end
    end

    if drive then
        return perform_jump(drive, size, jump_callback, dest_offset, true)
    end

    jump_callback(-3)
end

local function engine_do_jump_ship(ship, jump_callback, dest_offset)
    local pos = ship.ship_pos
    local size = ship.size
    if ship.priority == 1 then
        return perform_jump(pos, size, jump_callback, dest_offset, true)
    end
    jump_callback(-3)
end

local function engine_do_jump_ships(ship, fleet, jump_callback, dest_offset)
    local pos = ship.ship_pos
    local size = ship.size

    local fleet_cache = {}
    for _, f_ship in pairs(fleet) do
        local h = core.hash_node_position(f_ship.ship_pos)
        fleet_cache[h] = false
    end

    local hash = core.hash_node_position(pos)
    ship_machine.jumpships.cache[hash] = { ready = false, base_clear = false, fleet = fleet_cache }

    local function ship_do_jump()

        local function jump_callback1(j)
            ship_machine.jumpships.cache[hash] = nil
            jump_callback(j)
        end

        local function jump_callback2(j)
            --core.log("Ship jumped by fleet... " .. j)
        end

        perform_jump(pos, size, jump_callback1, dest_offset, true)

        core.after(0.5, function()
            for _, f_ship in pairs(fleet) do
                perform_jump(f_ship.ship_pos, f_ship.size, jump_callback2, dest_offset, false)
            end
        end)
    end

    local function ship_check_final(h)
        local c = ship_machine.jumpships.cache[h]
        local fleet_clear = true
        if c.base_clear then
            for _, f in pairs(c.fleet) do
                if not f then
                    fleet_clear = false
                end
            end
        end
        if c.base_clear and fleet_clear then
            c.ready = true
        end
        if not c.ready then
            jump_callback(-1)
            return
        else
            ship_do_jump()
        end
    end

    local function ship_check_dest_callback(r, h)
        if r == 1 then
            ship_machine.jumpships.cache[hash].fleet[h] = true
        end
    end

    local function ship_check_dest_callback_final(r, h)
        if hash ~= h then
            core.log("hash mismatch on ship_check_dest_callback_final()")
            jump_callback(-3)
            return
        end
        if r == 1 then
            ship_machine.jumpships.cache[hash].base_clear = true
        end
        ship_check_final(hash)
    end
    
    for _, f_ship in pairs(fleet) do
        check_jump_dest_jump(f_ship.ship_pos, f_ship.size, ship_check_dest_callback, dest_offset)
    end

    check_jump_dest_jump(pos, size, ship_check_dest_callback_final, dest_offset)

end

function ship_machine.engine_do_jump_fleet(ship, fleet, jump_callback, dest_offset)
    if ship.priority == 1 then
        return engine_do_jump_ship(ship, jump_callback, dest_offset)
    elseif ship.priority == 2 then
        return engine_do_jump_ships(ship, fleet, jump_callback, dest_offset)
    end
    core.log("Priority invalid on engine_do_jump_fleet()")
    jump_callback(-3)
end

local function find_ship_by_beacon(pos, r)
    local ships = {}
    local objs = core.get_objects_inside_radius(pos, r + 0.251)
    for _, obj in pairs(objs) do
        local obj_pos = obj:get_pos()
        if obj_pos then
            -- handle entities
            if obj:get_luaentity() and not obj:is_player() then
                local ent = obj:get_luaentity()
                if ent.type and (ent.type == "jumpship") then -- jumpship beacon
                    table.insert(ships, {pos = vector.subtract(obj_pos, {x=0,y=2,z=0})})
                end
            end
        end
    end
    return ships
end

local function find_ship_by_beacon_in_area(pos1, pos2)
    local ships = {}
    local objs = core.get_objects_in_area(pos1, pos2)
    for _, obj in pairs(objs) do
        local obj_pos = obj:get_pos()
        if obj_pos then
            -- handle entities
            if obj:get_luaentity() and not obj:is_player() then
                local ent = obj:get_luaentity()
                if ent.type and (ent.type == "jumpship") then -- jumpship beacon
                    --table.insert(ships, {pos = vector.subtract(obj_pos, {x=0,y=2,z=0})})
                    table.insert(ships, {pos = obj_pos})
                end
            end
        end
    end
    return ships
end

local function is_vector_equal(v1, v2)
    return v1.x == v2.x and v1.y == v2.y and v1.z == v2.z
end

local function get_ship_volume(pos, size)
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
    return schemlib.volume(pos1, pos2)
end

local function check_cuboid_overlap(cuboid1, cuboid2)
    -- Check for overlap on the X-axis
    local overlapX = (cuboid1.minX <= cuboid2.maxX) and (cuboid1.maxX >= cuboid2.minX)
    -- Check for overlap on the Y-axis
    local overlapY = (cuboid1.minY <= cuboid2.maxY) and (cuboid1.maxY >= cuboid2.minY)
    -- Check for overlap on the Z-axis
    local overlapZ = (cuboid1.minZ <= cuboid2.maxZ) and (cuboid1.maxZ >= cuboid2.minZ)
    -- If there's overlap on all three axes, the cuboids overlap
    return overlapX and overlapY and overlapZ
end

local function is_in_cuboid(pos, pos2, size)
    local min_bounds = { x = pos2.x - size.w, y = pos2.y - size.h, z = pos2.z - size.l }
    local max_bounds = { x = pos2.x + size.w, y = pos2.y + size.h, z = pos2.z + size.l }
    return (pos.x >= min_bounds.x and pos.x <= max_bounds.x)
        and (pos.y >= min_bounds.y and pos.y <= max_bounds.y)
        and (pos.z >= min_bounds.z and pos.z <= max_bounds.z)
end

local function check_for_overlap(this, others)
    local s_pos = this.ship_pos
    local s_size = this.size
    -- build cuboid for ship
    local cube1 = {
        minX = s_pos.x - s_size.w,
        maxX = s_pos.x + s_size.w,
        minY = s_pos.z - s_size.l,
        maxY = s_pos.z + s_size.l,
        minZ = s_pos.y - s_size.h,
        maxZ = s_pos.y + s_size.h
    }
    local overlapping = {}
    -- iterate over ship positions
    for _, ship in pairs(others) do
        local o_pos = ship.ship_pos
        local o_prot = ship.prot_pos
        local o_size = ship.size
        -- build cuboid for other ship
        local cube2 = {
            minX = o_pos.x - o_size.w,
            maxX = o_pos.x + o_size.w,
            minY = o_pos.z - o_size.l,
            maxY = o_pos.z + o_size.l,
            minZ = o_pos.y - o_size.h,
            maxZ = o_pos.y + o_size.h
        }
        -- check for overlaps
        local overlap = check_cuboid_overlap(cube1, cube2)
        if overlap then
            table.insert(overlapping, ship)
        end
    end
    return overlapping
end

local function find_ships_near(pos, size)
    local pos1 = vector.subtract(pos, {
        x = size.w * 2.05,
        y = size.h * 2.05,
        z = size.l * 2.05
    })
    local pos2 = vector.add(pos, {
        x = size.w * 2.05,
        y = size.h * 2.05,
        z = size.l * 2.05
    })
    local beacons = find_ship_by_beacon_in_area(pos1, pos2)
    local ship_pos = vector.subtract(pos, {x=0, y=2, z=0})
    local this_ship = { ship_pos = ship_pos, prot_pos = pos, size = size }

    for _, beacon in pairs(beacons) do
        ship_pos = vector.subtract(beacon.pos, {x=0, y=2, z=0})
        if is_in_cuboid(pos, ship_pos, size) then
            local volume = get_ship_volume(ship_pos, size)
            this_ship = { ship_pos = ship_pos, prot_pos = beacon.pos, size = size, volume = volume }
            break
        end
    end

    --core.log("found beacons= " .. tostring(#beacons))

    local ships = {}
    for _, beacon in pairs(beacons) do
        if not is_vector_equal(beacon.pos, this_ship.prot_pos) then
            local ship_pos = vector.subtract(beacon.pos, {x=0, y=2, z=0})
            local ship_meta = core.get_meta(beacon.pos)
            local _size = {
                w = ship_meta and ship_meta:get_int("p_width") or size.w,
                l = ship_meta and ship_meta:get_int("p_length") or size.l,
                h = ship_meta and ship_meta:get_int("p_height") or size.h
            }
            local volume = get_ship_volume(ship_pos, _size)
            --core.log("found volume= " .. tostring(volume))
            table.insert(ships, { ship_pos = ship_pos, prot_pos = beacon.pos, size = _size, volume = volume })
        end
    end
    local overlaps = check_for_overlap(this_ship, ships)
    return this_ship, overlaps
end

function ship_machine.get_local_ships(pos, size)

    local this_ship, overlaps = find_ships_near(pos, size)

    --core.log("found overlaps= " .. tostring(#overlaps))

    this_ship.priority = 0
    if this_ship and #overlaps == 0 then
        this_ship.priority = 1
        
    elseif this_ship and #overlaps > 0 then
        this_ship.priority = 1
        for _, o_ship in pairs(overlaps) do
            if this_ship.volume > o_ship.volume then
                this_ship.priority = 2
                o_ship.priority = 1
            end
        end

    end

    --core.log("local priority= " .. tostring(this_ship.priority))

    return this_ship, overlaps
end

function ship_machine.get_jump_dest_from_drive(pos, offset)
    local node = core.get_node(pos)
    local group = minetest.get_item_group(node.name, "jumpdrive");
    if group then
        return vector.add(pos, offset)
    end
    return nil
end

function ship_machine.get_jump_dest(pos, offset, size)
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

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "group:jumpdrive")

    local drive = nil
    for _, p in pairs(nodes) do
        local prot = vector.add(p, vector.new(0, 2, 0))
        local ship_meta = minetest.get_meta(prot)
        local _size = {
            w = ship_meta and ship_meta:get_int("p_width") or size.w,
            l = ship_meta and ship_meta:get_int("p_length") or size.l,
            h = ship_meta and ship_meta:get_int("p_height") or size.h
        }
        if pos.x <= p.x + _size.w and pos.x >= p.x - _size.w then
            if pos.z <= p.z + _size.l and pos.z >= p.z - _size.l then
                if pos.y <= p.y + _size.h and pos.y >= p.y - _size.h then
                    drive = p
                end
            end
        end
        if drive ~= nil then
            break
        end
    end
    if drive then
        return #nodes, vector.add(drive, offset)
    end
    return #nodes, nil
end

function ship_machine.get_jumpdrive(pos, size)
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

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "group:jumpdrive")

    local drive = nil
    for _, p in pairs(nodes) do
        local prot = vector.add(p, vector.new(0, 2, 0))
        local ship_meta = minetest.get_meta(prot)
        local _size = {
            w = ship_meta and ship_meta:get_int("p_width") or size.w,
            l = ship_meta and ship_meta:get_int("p_length") or size.l,
            h = ship_meta and ship_meta:get_int("p_height") or size.h
        }
        if pos.x <= p.x + _size.w and pos.x >= p.x - _size.w then
            if pos.z <= p.z + _size.l and pos.z >= p.z - _size.l then
                if pos.y <= p.y + _size.h and pos.y >= p.y - _size.h then
                    drive = p
                end
            end
        end
        if drive ~= nil then
            break
        end
    end
    return drive
end

function ship_machine.colorize_text_hp(hp, hp_max)
    local col = '#FFFFFF'
    local qua = hp_max / 8
    if hp <= qua then
        col = "#FF0000"
    elseif hp <= (qua * 2) then
        col = "#FF3D00"
    elseif hp <= (qua * 3) then
        col = "#FF7A00"
    elseif hp <= (qua * 4) then
        col = "#FFB500"
    elseif hp <= (qua * 5) then
        col = "#FFFF00"
    elseif hp <= (qua * 6) then
        col = "#B4FF00"
    elseif hp <= (qua * 7) then
        col = "#00FF00"
    elseif hp > (qua * 7) then
        col = "#00FF50"
    end
    return col
end

function ship_machine.update_ship_owner_all(pos, size, new_owner)
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
    for y = pos1.y, pos2.y do
        for x = pos1.x, pos2.x do
            for z = pos1.z, pos2.z do
                local p = {
                    x = x,
                    y = y,
                    z = z
                }
                local meta = core.get_meta(p)
                if meta and meta:get_string("owner") and meta:get_string("owner") ~= "" then
                    meta:set_string("owner", new_owner)
                end
            end
        end
    end
end

function ship_machine.update_ship_members_clear(pos, size)
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
    for y = pos1.y, pos2.y do
        for x = pos1.x, pos2.x do
            for z = pos1.z, pos2.z do
                local p = {
                    x = x,
                    y = y,
                    z = z
                }
                local meta = core.get_meta(p)
                if meta and meta:get_string("members") and meta:get_string("members") ~= "" then
                    meta:set_string("members", "")
                end
            end
        end
    end
end

function ship_machine.update_ship_vents_all(pos, size)
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
    for y = pos1.y, pos2.y do
        for x = pos1.x, pos2.x do
            for z = pos1.z, pos2.z do
                local p = vector.new(x,y,z)
                if ctg_airs.is_duct_tube(p) then
                    local meta = core.get_meta(p)
                    if meta and meta:get_string("infotext") ~= nil then
                        meta:set_string("infotext", "")
                    end
                end
            end
        end
    end
end