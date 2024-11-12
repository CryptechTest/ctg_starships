local S = minetest.get_translator(minetest.get_current_modname())

orbital_station = {}

-- load files
local default_path = minetest.get_modpath("orbital_station")

-- dofile(default_path .. DIR_DELIM .. "functions.lua")

local function load_orbital(pos)
    -- load the schematic from file..
    local lmeta = schem_lib.load_emitted_file({
        filename = "spawn_station",
        origin = {
            x = pos.x,
            y = pos.y,
            z = pos.z
        },
        moveObj = false,
        filepath = default_path .. "/schematics/"
    })
end

local function find_spawn_drive(pos)
    local sz = 32
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

    if nodes and #nodes >= 1 then
        return #nodes > 0
    end
    return nil
end

-- minetest.register_on_newplayer(function()
minetest.register_on_joinplayer(function()
    -- minetest.register_on_mods_loaded(function()

    local spawn_spoint = minetest.setting_get_pos("static_spawnpoint") or {
        x = 0,
        y = 4500,
        z = 0
    }

    minetest.after(5, function()
        local pos = vector.add(spawn_spoint, {
            x = 0,
            y = 8,
            z = 0
        })
        if find_spawn_drive(pos) == nil then
            minetest.log("orbital station not found!");
            -- load_orbital(pos)
        end
    end)

end)
