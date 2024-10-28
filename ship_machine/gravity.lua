
local square = math.sqrt;
local get_distance = function(a, b)
    local x, y, z = a.x - b.x, a.y - b.y, a.z - b.z
    return square(x * x + y * y + z * z)
end

local gen_grav = 0.92
local gen_dist = 64
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