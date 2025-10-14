local square = math.sqrt;
local get_distance = function(a, b)
    local x, y, z = a.x - b.x, a.y - b.y, a.z - b.z
    return square(x * x + y * y + z * z)
end

local check_time = 2
local gen_grav = 0.92
local gen_dist = 100
local players_near_gen = {}

local function node_is_solid(pos)
	local node_check = core.get_node({x=pos.x,y=pos.y,z=pos.z})
	local rtn = false 
	if core.registered_nodes[node_check.name] then
		local nc_draw = core.registered_nodes[node_check.name].drawtype
		if nc_draw ~= "liquid" and nc_draw ~= "flowingliquid" and nc_draw ~= "airlike" then
            rtn = true
		end
	end	
	return rtn
end

local function pos_equals(pos1, pos2)
    return pos1.x == pos2.x and pos1.x == pos2.x and pos1.z == pos2.z
end

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
    local objects = core.get_objects_in_area(pos1, pos2) or {}
    for _, obj in pairs(objects) do
        if obj and obj:is_player() then
            local player = obj
            if player then
                local name = player:get_player_name()
                local pos = player:get_pos()
                local current = players_near_gen[name] or nil
                if pos.y > 1000 then
                    if current then
                        local t_delta = os.clock() - current.last_check
                        if t_delta >= check_time then
                            current.gravity = 0
                        end
                    end
                    -- center node
                    local pos_center = {
                        x = _pos.x,
                        y = pos.y - 1,
                        z = _pos.z
                    }
                    -- check if beyond lessor y
                    if not (pos.y - 1 < _pos.y and get_distance(_pos, pos_center) >= 32) then
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

                        local below_1_solid = node_is_solid(pos_below_1)
                        local below_2_solid = node_is_solid(pos_below_2)

                        local solid_count = 0
                        for y = pos.y - 1, pos.y + 1 do
                            for x = pos.x - 1, pos.x + 1 do
                                for z = pos.z - 1, pos.z + 1 do
                                    local p = {x = x, y = y, z =z}
                                    if not pos_equals(p, pos_below_1) and not pos_equals(p, pos_below_2) then
                                        if node_is_solid(p) then
                                            solid_count = solid_count + 1
                                        end
                                    end
                                end
                            end
                        end

                        local cur_grav = otherworlds.gravity.get(player)
                        local dist = get_distance(_pos, pos)
                        local dist_y = math.max(0, math.abs(_pos.y - pos.y) - 1)
                        local scalor = 0.00128 -- scaler for modifier
                        local mod = 0.218 -- modifier scaling
                        local exp = dist ^ 0.101
                        local dist_mod = (dist ^ 2) * (scalor * mod * exp) -- modifier based on distance
                        local dist_y_mod = dist_y * 0.0075
                        dist_mod = dist_mod + dist_y_mod
                        local max_grav = math.min(g_grav - dist_mod, 1)
                        local new_grav = math.max(max_grav, cur_grav) -- subtract modifier from gravity
                        local do_grav = false
                        local grav_prcnt = 0
                        if below_1_solid then
                            do_grav = true
                            grav_prcnt = grav_prcnt + 0.51
                        end
                        if below_2_solid then
                            do_grav = true
                            grav_prcnt = grav_prcnt + 0.3
                        end
                        if solid_count > 0 then
                            grav_prcnt = grav_prcnt + (solid_count * 0.1)
                        end
                        if grav_prcnt > 1 then
                            grav_prcnt = 1
                        end
                        if (do_grav) then
                            new_grav = math.max(new_grav * grav_prcnt, cur_grav)
                            if (not current or new_grav > current.gravity) then
                                if current then
                                    new_grav = math.min(1, ((3*new_grav) + cur_grav) / 4)
                                    otherworlds.gravity.xset(player, new_grav)
                                end
                                players_near_gen[name] = {
                                    player = player,
                                    gravity = new_grav,
                                    last_check = os.clock(),
                                    distance = dist
                                }
                            end
                        end
                    end
                end
            end
        end
    end

end

local timer = 0
core.register_globalstep(function(dtime)
    timer = timer + dtime

    if timer < 3 then
        return
    end

    timer = 0

    for _, player in pairs(core.get_connected_players()) do
        local name = player:get_player_name()
        local pos = player:get_pos()
        local current = players_near_gen[name] or nil

        local node = core.find_node_near(pos, gen_dist * 0.5, "group:gravity_gen")

        if node then
            -- center node
            local pos_center = {
                x = node.x,
                y = pos.y - 1,
                z = node.z
            }
            local meta = core.get_meta(node)
            if current ~= nil and (meta:get_int("enabled") == 0 or meta:get_int("charge") < meta:get_int("charge_max")) then
                -- nearby grav gen..
                otherworlds.gravity.reset(player)
                players_near_gen[name] = nil
            elseif (current == nil) then
                players_near_gen[name] = {
                    player = player,
                    gravity = 0,
                    last_check = os.clock(),
                    distance = 0
                }
            end
        elseif current ~= nil then
            otherworlds.gravity.reset(player)
            players_near_gen[name] = nil
        end
    end

end)
