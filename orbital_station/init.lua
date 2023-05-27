local S = minetest.get_translator(minetest.get_current_modname())

orbital_station = {}

-- load files
local default_path = minetest.get_modpath("orbital_station")

-- dofile(default_path .. DIR_DELIM .. "functions.lua")

local function load_orbital(pos)
    -- load the schematic from file..
    local lmeta = schemlib.load_emitted_file({
        filename = "spawn_station",
        origin = {
            x = pos.x,
            y = pos.y,
            z = pos.z
        },
        moveObj = false,
        filepath = default_path .. "\\schematics\\"
    })
end

local function find_spawn_drive(pos)
    local sz = 16
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

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "group:jumpdrive")

    if nodes and #nodes == 1 then
        return nodes[1]
    end
    return nil
end

minetest.register_on_mods_loaded(function()

    minetest.after(0, function()
        local pos = {
            x = 0,
            y = 4508,
            z = 0
        }
        if find_spawn_drive(pos) == nil then
            load_orbital(pos)
        end
    end)

end)
