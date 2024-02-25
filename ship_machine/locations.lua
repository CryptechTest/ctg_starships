local world_path = minetest.get_worldpath()
local file = world_path .. "/ship_locations"

function ship_machine.read_locations()
    local locations = ship_machine.locations
    local input = io.open(file, "r")
    if input then
        repeat
            local x = input:read("*n")
            if x == nil then
                break
            end
            local y = input:read("*n")
            local z = input:read("*n")
            local name = input:read("*l")
            locations[name:sub(2)] = {
                x = x,
                y = y,
                z = z
            }
        until input:read(0) == nil
        io.close(input)

    end
end

function ship_machine.save_locations()
    if not ship_machine.locations then
        return
    end
    local data = {}
    local output = io.open(file, "w")
    for k, v in pairs(ship_machine.locations) do
        table.insert(data, string.format("%.1f %.1f %.1f %s\n", v.x, v.y, v.z, k))
    end
    output:write(table.concat(data))
    io.close(output)
end

function ship_machine.remove_location_at(pos)
    for name, p in pairs(ship_machine.locations) do
        if vector.equals(vector.round(p), pos) then
            ship_machine.locations[name] = nil
        end
    end
    ship_machine.save_locations()
end

function ship_machine.set_location_for(pos, name)
    ship_machine.locations[name] = pos
    ship_machine.save_locations()
end

ship_machine.read_locations()
