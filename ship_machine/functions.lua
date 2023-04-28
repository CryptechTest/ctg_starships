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
        formspec = "size[8,5;]" .. "label[0,0;" .. machine_desc:format(tier) .. "]" .. image .. meseimg ..
                       "image[3,1;1,1;gui_furnace_arrow_bg.png^[lowpart:" .. tostring(percent) ..
                       ":gui_furnace_arrow_fg.png^[transformR270]" .. "image[2,1;1,1;" .. ship_machine.mese_image_mask ..
                       "]" .. "button[2,3;4,1;toggle;" .. btnName .. "]" .. "label[2,2;Charge " .. tostring(charge) ..
                       " of " .. tostring(charge_max) .. "]" .. "label[5,2;" .. tostring(charge_percent) .. "%" .. "]"
    end

    if data.upgrade then
        formspec = formspec .. "list[current_name;upgrade1;1,3;1,1;]" .. "list[current_name;upgrade2;2,3;1,1;]" ..
                       "label[1,4;" .. S("Upgrade Slots") .. "]" .. "listring[current_name;upgrade1]" ..
                       "listring[current_player;main]" .. "listring[current_name;upgrade2]" ..
                       "listring[current_player;main]"
    end
    return formspec
end

local square = math.sqrt;
local get_distance = function(a, b)
    local x, y, z = a.x - b.x, a.y - b.y, a.z - b.z
    return square(x * x + y * y + z * z)
end

local gen_grav = 0.92
local gen_dist = 28
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
                    if not (pos.y - 1 < _pos.y and get_distance(_pos, pos_center) >= 1) then
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
