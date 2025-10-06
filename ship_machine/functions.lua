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
        local set_owner_local = "field[1,3.85;4,1;owner_name_local;Owner Local;]button[5,3.85;1,1;set_owner_local;Set]"
        local input_name = "field[1,1.45;4,1;file_name;File Name;]"
        local input_save_load = "button[5,1;1,1;save;Save]button[6,1;1,1;load;Load]"

        formspec = "formspec_version[3]" .. "size[8,5;]" .. "real_coordinates[false]" .. "label[0,0;" ..
                       machine_desc:format(tier) .. "]" .. input_name .. input_save_load .. owner .. set_owner .. set_owner_local
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
        time = prt.time + math.random(0.8, 2.0),
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
    core.set_node(pos, {name = "air"})
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
        schem_lib.func.do_particle_zap(vector.subtract(pos, {x=0,y=1,z=0}))
    end
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

local function do_effect(pos1, pos2)
    local function _effect(obj, i)
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
    -- get cube of area nearby
    local objects = minetest.get_objects_in_area(pos1, pos2) or {}
    local players = {}
    for _, obj in pairs(objects) do
        if (obj ~= nil and obj:is_player()) then
            table.insert(players, obj)
        end
    end
    -- play effects to players in area
    for _, obj in pairs(players) do
        for i = 0, 3 do
            _effect(obj, i)
        end
    end
end

local function post_emerge_complete(meta)
    if not meta or not meta.origin or not meta.size or not meta.dest then
        return
    end
    local pos = meta.origin
    local dest = meta.dest
    local size = meta.size
    local offset = vector.subtract(dest, pos)
    local pos1 = vector.subtract(pos, vector.new(size.width, size.height, size.length))
    local pos2 = vector.add(pos, vector.new(size.width, size.height, size.length))
    -- move beds and update tubes
    move_beds(pos1, pos2, offset)
    update_tubes(pos1, pos2, offset)
    -- move offline player locations
    move_offline_players(pos, offset)
    -- clear prior wire networks
    update_switching_stations(pos1, pos2, true)
    -- update screens
    local dest_pos1 = vector.subtract(dest, vector.new(size.width, size.height, size.length))
    local dest_pos2 = vector.add(dest, vector.new(size.width, size.height, size.length))
    schem_lib.func.update_screens(dest_pos1, dest_pos2)
    -- rebuild wire networks
    update_switching_stations(dest_pos1, dest_pos2, false)
    --core.log("post emerge complete")
end

local function emerge_callback_on_complete(data)
    if data == nil or data.meta == nil then
        return
    end
    minetest.after(0, function()
        post_emerge_complete(data.meta) 
    end)
    minetest.after(0.5, function()
        schem_lib.func.jump_ship_move_contents(data.meta)
    end)
    minetest.after(3, function()
        schem_lib.func.jump_ship_emit_player(data.meta, true)
    end)
    if data.flags and data.flags.origin_clear and data.meta.ttl and data.meta.ttl > 0 then
        local size = data.meta.offset
        local pos1 = vector.subtract(data.meta.origin, vector.new(size.x, size.y, size.z))
        local pos2 = vector.add(data.meta.origin, vector.new(size.x, size.y, size.z))
        minetest.after(data.meta.ttl or 3, function()
            schem_lib.func.clear_position(pos1, pos2)
        end)
        minetest.after((data.meta.ttl or 3) * 2, function()
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
        origin_clear = true
    }
    local ship_name = "jumpship_1_" .. owner
    -- position min/max
    local pos1 = vector.subtract(pos, vector.new(size.w, size.h, size.l))
    local pos2 = vector.add(pos, vector.new(size.w, size.h, size.l))
    local data = {
        filename = ship_name,
        owner = owner,
        ttl = 4,
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
        schem_lib.func.jump_ship_emit_player(schem_data.meta, false)
        -- load the schematic from cache..
        local count, ver, lmeta = schemlib.process_emitted(nil, nil, schem_data, emerge_callback_on_complete)
        -- do jump tele effects
        do_effect(pos1, pos2)
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

    if check_engines_charged(pos, size) == true then
        digilines.receptor_send(pos, technic.digilines.rules_allfaces, 'jumpdrive', 'jump_prepare')

        local dist = vector.distance(pos, dest)
        engines_charged_spend(pos, dist, size)
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

local function perform_jump(pos, size, jcb, offset)

    local dest = vector.add(pos, offset)

    local area_clear = true
    if not schem_lib.func.check_dest_clear(pos, dest, size) then
        area_clear = false
    end

    minetest.after(2, function()
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

        do_jump(pos, dest, size, jcb, offset)

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
        origin_clear = false
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
        return perform_jump(drive, size, jump_callback, dest_offset)
    end

    jump_callback(-3)
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
    local s = size
    for y = pos.y - s.w, pos.y + s.w do
        for x = pos.x - s.w, pos.x + s.w do
            for z = pos.z - s.w, pos.z + s.w do
                local p = {
                    x = x,
                    y = y,
                    z = z
                }
                local meta = minetest.get_meta(p)
                if meta and meta:get_string("owner") and meta:get_string("owner") ~= "" then
                    meta:set_string("owner", new_owner)
                end
            end
        end
    end
end

function ship_machine.update_ship_members_clear(pos, size)
    local s = size
    for y = pos.y - s.w, pos.y + s.w do
        for x = pos.x - s.w, pos.x + s.w do
            for z = pos.z - s.w, pos.z + s.w do
                local p = {
                    x = x,
                    y = y,
                    z = z
                }
                local meta = minetest.get_meta(p)
                if meta and meta:get_string("members") and meta:get_string("members") ~= "" then
                    meta:set_string("members", "")
                end
            end
        end
    end
end
