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
    local machine_name = data.machine_name
    local machine_desc = "Starship " .. data.machine_desc
    local typename = data.typename
    local tier = data.tier
    local ltier = string.lower(tier)
    local formspec = nil
    if percent then
        percent = round(percent, 100)
    end

    if typename == 'gravity_drive' then
        local charge_percent = 0
        if charge and charge > 0 and charge_max then
            charge_percent = round(math.floor(charge / (charge_max) * 100 * 100) / 100, 2)
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
        local image = "image[4,1;1,1;" .. "lv_gravity_drive.png" .. "]"
        if running then
            image = "image[4,1;1,1;" .. "lv_gravity_drive_active_icon.png" .. "]"
        end
        local meseimg = ""
        if has_mese or running then
            meseimg = "animated_image[5,1;1,1;;" .. "engine_mese_anim.png" .. ";4;400;]"
        end
        local act_msg = ""
        if running and charge_percent >= 100 then
            act_msg = "image[2,4;4.75,1;gravity_active.png]"
        elseif running then
            act_msg = "image[2,4;4.75,1;gravity_offline.png]"
        end
        formspec = "formspec_version[3]" .. "size[8,5;]" .. "real_coordinates[false]" .. "label[0,0;" ..
                       machine_desc:format(tier) .. "]" .. image .. meseimg ..
                       "image[3,1;1,1;gui_furnace_arrow_bg.png^[lowpart:" .. tostring(percent) ..
                       ":gui_furnace_arrow_fg.png^[transformR270]" .. "image[2,1;1,1;" .. ship_machine.mese_image_mask ..
                       "]" .. "button[2,3;4,1;toggle;" .. btnName .. "]" .. "label[2,2;Charge " .. tostring(charge) ..
                       " of " .. tostring(charge_max) .. "]" .. "label[5,2;" .. tostring(charge_percent) .. "%" .. "]" ..
                       act_msg
    end
    if data.upgrade then
        formspec = formspec .. "list[current_name;upgrade1;1,3;1,1;]" .. "list[current_name;upgrade2;2,3;1,1;]" ..
                       "label[1,4;" .. S("Upgrade Slots") .. "]" .. "listring[current_name;upgrade1]" ..
                       "listring[current_player;main]" .. "listring[current_name;upgrade2]" ..
                       "listring[current_player;main]"
    end
    return formspec
end

function ship_machine.update_jumpdrive_formspec(data)
    local machine_name = data.machine_name
    local machine_desc = "Starship " .. data.machine_desc
    local typename = data.typename
    local tier = data.tier
    local ltier = string.lower(tier)
    local formspec = nil

    if typename == 'jump_drive' or typename == 'jump_drive_spawn'  then
        local btnName = "State: "
        if enabled then
            btnName = btnName .. "<Enabled>"
        else
            btnName = btnName .. "<Disabled>"
        end

        local input_name = "field[1,1.45;4,1;file_name;File Name;]"
        local input_save_load = "button[5,1;1,1;save;Save]button[6,1;1,1;load;Load]"
        local input_test =
            "field[1,2;2,1;inp_x;Move X;0]field[3,2;2,1;inp_y;Move Y;0]field[5,2;2,1;inp_z;Move Z;0]button[3,4;2,1;jump;Test]"

        formspec = "formspec_version[3]" .. "size[8,5;]" .. "real_coordinates[false]" .. "label[0,0;" ..
                       machine_desc:format(tier) .. "]" .. "button[2,3;4,1;toggle;" .. btnName .. "]" .. "" ..
                       input_name .. input_save_load
    end

    return formspec
end

local square = math.sqrt;
local get_distance = function(a, b)
    local x, y, z = a.x - b.x, a.y - b.y, a.z - b.z
    return square(x * x + y * y + z * z)
end

local gen_grav = 0.92
local gen_dist = 46
local players_near_gen = {}

ship_machine.apply_gravity = function(_pos, grav)
    local g_grav = grav
    if grav == nil then
        g_grav = gen_grav
    end
    local sz = gen_dist / 2
    local pos1 = vector.subtract(_pos, {
        x = sz,
        y = sz,
        z = sz
    })
    local pos2 = vector.add(_pos, {
        x = sz,
        y = sz,
        z = sz
    })
    -- get cube of area nearby
    local objects = minetest.get_objects_in_area(pos1, pos2) or {}
    for _, obj in pairs(objects) do
        if obj and obj:is_player() then
            local player = obj
            if player then
                local name = player:get_player_name()
                local pos = player:get_pos()
                if pos.y > 1000 then
                    -- center node
                    local pos_center = {
                        x = _pos.x,
                        y = pos.y - 1,
                        z = _pos.z
                    }
                    -- check if beyond lessor y
                    if not (pos.y - 1 < _pos.y and get_distance(_pos, pos_center) >= 13) then
                        -- get node below
                        local pos_below_1 = {
                            x = pos.x,
                            y = pos.y - 1,
                            z = pos.z
                        }
                        local pos_below_2 = {
                            x = pos.x,
                            y = pos.y - 2,
                            z = pos.z
                        }
                        local below_1_node = minetest.get_node(pos_below_1)
                        local below_2_node = minetest.get_node(pos_below_2)
                        -- check for atmos
                        local below_1_atmos = minetest.get_item_group(below_1_node.name, "atmosphere")
                        local below_2_atmos = minetest.get_item_group(below_2_node.name, "atmosphere")
                        -- check for vacuum
                        local below_1_vac = minetest.get_item_group(below_1_node.name, "vacuum")
                        local below_2_vac = minetest.get_item_group(below_2_node.name, "vacuum")

                        local dist = get_distance(_pos, pos)
                        local dist_mod = dist * 0.005 -- modifier based on distance
                        local new_grav = g_grav - dist_mod -- subtract modifier from gravity

                        if (below_1_atmos == 0 or below_2_atmos == 0) or (below_1_vac == 0 or below_2_vac == 0) then
                            otherworlds.gravity.xset(player, new_grav)
                            players_near_gen[name] = player
                        end
                    end
                end
            end
        end
    end

end

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime

    if timer < 2 then
        return
    end

    timer = 0

    for _, player in pairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local pos = player:get_pos()
        local current = players_near_gen[name] or nil

        local node = minetest.find_node_near(pos, gen_dist, "group:gravity_gen")

        if node then
            -- center node
            local pos_center = {
                x = node.x,
                y = pos.y - 1,
                z = node.z
            }
            local meta = minetest.get_meta(node)
            if current ~= nil and (meta:get_int("enabled") == 0 or meta:get_int("charge") < meta:get_int("charge_max")) then
                -- nearby grav gen..
                otherworlds.gravity.reset(player)
                players_near_gen[name] = nil
            elseif current ~= nil and pos.y - 1 < node.y and get_distance(node, pos_center) >= 5 then
                -- check if beyond lessor y
                otherworlds.gravity.reset(player)
                players_near_gen[name] = nil
            elseif (current == nil) then
                players_near_gen[name] = player
            end
        elseif current ~= nil then
            otherworlds.gravity.reset(player)
            players_near_gen[name] = nil
        end
    end

end)

local function do_particles(pos)
    local prt = {
        texture = "ctg_jetpack_vapor_cloud.png",
        texture_r180 = "ctg_jetpack_vapor_cloud.png" .. "^[transformR180",
        vel = 0.6,
        time = 7,
        size = 6,
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
    local v = vector.new()
    minetest.add_particle({
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
    })
end

local function do_particle_tele(pos)
    local prt = {
        texture = "teleport_effect01.png",
        texture_r180 = "teleport_effect01.png" .. "^[transformR180",
        vel = 13,
        time = 4,
        size = 4,
        glow = 7,
        cols = false
    }
    local exm = pos
    exm.y = exm.y - 2.5
    local rx = math.random(-0.01, 0.01) * 0.1
    local rz = math.random(-0.01, 0.01) * 0.1
    local texture = prt.texture
    if (math.random() >= 0.6) then
        texture = prt.texture_r180
    end
    local v = vector.new()
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
        vertical = false,
        texture = texture,
        glow = prt.glow
    })
end

function ship_machine.transport_jumpship(pos, dest, size, owner)
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
                        for i = 1, 200 do
                            if (obj ~= nil and obj:get_pos() ~= nil) then
                                local p = {
                                    x = obj:get_pos().x + math.random(-6, 6),
                                    y = obj:get_pos().y + math.random(-3, 4),
                                    z = obj:get_pos().z + math.random(-6, 6)
                                }
                                if math.random(0,1) == 1 then
                                    do_particles(p)
                                end
                                do_particle_tele(p)
                            end
                        end
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

    minetest.chat_send_player(player:get_player_name(), "Loading Jumpship...")
end

function ship_machine.check_engines_charged(pos)
    local sz = 28
    local pos1 = vector.subtract(pos, {
        x = sz,
        y = sz,
        z = sz
    })
    local pos2 = vector.add(pos, {
        x = sz,
        y = sz,
        z = sz
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
    end
    return false
end

function ship_machine.engines_charged_spend(pos, dist)
    local sz = 28
    local pos1 = vector.subtract(pos, {
        x = sz,
        y = sz,
        z = sz
    })
    local pos2 = vector.add(pos, {
        x = sz,
        y = sz,
        z = sz
    })

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "group:ship_engine")

    if #nodes == 2 then

        local max = 2000
        local c_max = 160
        local chrg = (c_max / max) * dist

        ship_engine.ship_jump(nodes[1], chrg)
        ship_engine.ship_jump(nodes[2], chrg)

        return true
    end
    return false
end

function ship_machine.perform_jump(pos, dest)
    local meta = minetest.get_meta(pos)
    local owner = meta:get_string("owner")
    local size = {
        w = 20,
        h = 12,
        l = 30
    }

    if not schemlib.check_dest_clear(pos, dest, size) then
        return -1
    end

    if ship_machine.check_engines_charged(pos) == true then
        digilines.receptor_send(pos, digilines.rules.default, 'jumpdrive', {
            command = 'jumping'
        })
        local dist = vector.distance(pos, dest)
        ship_machine.engines_charged_spend(pos, dist)
        ship_machine.transport_jumpship(pos, dest, size, owner)
        minetest.after(3, function()
            local metad = minetest.get_meta(dest)
            metad:set_int("travel_ready", 0)
        end)
        return 1
    end
    return 0
end
