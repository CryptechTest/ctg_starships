local S = minetest.get_translator(minetest.get_current_modname())

local function isInteger(str)
    return tonumber(str) ~= nil
end

function ship_scout.register_scout()

    local data = {}

    local size = {
        w = 12,
        h = 12,
        l = 15
    }

    data.typename = "ship_scout"
    data.modname = "ship_scout"
    data.tier = "LV"
    data.machine_name = "scout"
    data.jump_dist = 2000
    data.size = size;

    local modname = "ship_scout"
    local ltier = string.lower(data.tier)
    local machine_name = data.machine_name
    local machine_desc = "Scout"
    local lmachine_name = string.lower(machine_name)

    local active_groups = {
        cracky = 2,
        -- technic_machine = 1,
        -- ["technic_" .. ltier] = 1,
        -- ctg_machine = 1,
        metal = 1,
        level = 1,
        starship = 1,
        ship_scout = 1,
        ship_jumps = 1
    }

    local on_receive_fields = function(pos, formname, fields, sender)
        if fields.quit then
            return
        end
        local node = minetest.get_node(pos)
        local meta = minetest.get_meta(pos)
        local enabled = false
        if fields.toggle then
            if meta:get_int("enabled") == 1 then
                meta:set_int("enabled", 0)
            else
                meta:set_int("enabled", 1)
                enabled = true
            end
        end

        local jump_dis = meta:get_int("jump_dist")
        local is_deepspace = pos.y > 22000;

        -- local pos_nav = meta:get_string("pos_nav")
        -- local nav = minetest.get_meta(pos_nav)
        -- local nav_ready = nav:get_string("jump_ready")
        local nav_ready = 1

        local changed = false
        local loc = tostring(meta:get_int("dest_dir"))
        if fields.btn_hole_1 then
            loc = "1"
            changed = true
        elseif fields.btn_hole_2 then
            loc = "2"
            changed = true
        elseif fields.btn_hole_3 then
            loc = "3"
            changed = true
        elseif fields.btn_hole_4 then
            loc = "4"
            changed = true
        end
        meta:set_int("dest_dir", tonumber(loc, 10))

        local move_x = 0
        local move_y = 0
        local move_z = 0
        local isNumError = false
        if fields.inp_x then
            if isInteger(fields.inp_x) then
                move_x = tonumber(fields.inp_x, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_y then
            if isInteger(fields.inp_y) then
                move_y = tonumber(fields.inp_y, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_z then
            if isInteger(fields.inp_z) then
                move_z = tonumber(fields.inp_z, 10)
            else
                isNumError = true
            end
        end

        local message = ""
        local offset = {
            x = move_x,
            y = move_y,
            z = move_z
        }
        local dest = ship_scout.get_jump_dest(pos, offset)

        if dest == nil then
            meta:set_int("travel_ready", 0)
            message = "FTL Engines not found..."
        elseif isNumError then
            meta:set_int("travel_ready", 0)
            message = "Must input a valid number..."
        elseif fields.submit_nav and not is_deepspace and vector.distance(pos, dest) < 100 then
            meta:set_int("travel_ready", 0)
            message = "Jump distance below engine range..."
        elseif fields.submit_nav and not is_deepspace and vector.distance(pos, dest) > jump_dis then
            meta:set_int("travel_ready", 0)
            message = "Jump distance beyond engine range..."
        elseif fields.submit_nav and not is_deepspace and dest.y > 22000 then
            meta:set_int("travel_ready", 0)
            message = "Jump destination beyond engine abilities..."
        elseif fields.submit_nav and not is_deepspace and dest.y < 4000 then
            meta:set_int("travel_ready", 0)
            message = "Jump destination beyond engine abilities..."
        elseif fields.submit_nav and ((is_deepspace and loc ~= "0") or (not is_deepspace)) then
            local formspec = ship_scout.update_formspec(dest, data, loc, false, "Preparing Jump..")
            meta:set_string("formspec", formspec)
            local j = ship_scout.engine_jump_activate(pos, dest, data.size)
            if j == 1 then
                meta:set_int("travel_ready", 1)
                message = "FTL Engines preparing for jump..."
                minetest.after(1, function()
                    local metad = minetest.get_meta(dest)
                    local formspec = ship_scout.update_formspec(dest, data, loc, false, "Jump Complete!")
                    metad:set_string("formspec", formspec)
                    meta:set_string("formspec", formspec)
                    metad:set_int("travel_ready", 0)
                end)
            elseif j == 0 then
                meta:set_int("travel_ready", 0)
                message = "FTL Engines require more charge.."
            elseif j == -1 then
                meta:set_int("travel_ready", 0)
                message = "Travel Obstructed at " .. "(" .. dest.x .. "," .. dest.y .. "," .. dest.z .. ")"
            elseif j == -3 then
                meta:set_int("travel_ready", 0)
                message = "FTL Jump Drive not found..."
            else
                meta:set_int("travel_ready", 0)
                message = "FTL Engines Failed to Start.."
            end
        elseif fields.submit_nav and not changed then
            message = "FTL Engines require more charge..."
            meta:set_int("travel_ready", 0)
        elseif fields.submit_nav and nav_ready ~= 1 and not changed then
            message = "Survey Navigator requires more charge..."
            meta:set_int("travel_ready", 0)
        end

        local ready = meta:get_int("travel_ready")
        local formspec = ship_scout.update_formspec(pos, data, loc, ready, message)
        meta:set_string("formspec", formspec)
    end

    minetest.register_node(modname .. ":" .. ltier .. "_" .. lmachine_name .. "", {
        description = machine_desc,
        tiles = {ltier .. "_" .. lmachine_name .. "_top.png", ltier .. "_" .. lmachine_name .. "_bottom.png",
                 ltier .. "_" .. lmachine_name .. "_side.png", ltier .. "_" .. lmachine_name .. "_side.png",
                 ltier .. "_" .. lmachine_name .. "_side.png", ltier .. "_" .. lmachine_name .. "_front.png"},
        param = "light",
        paramtype2 = "facedir",
        light_source = 3,
        drop = modname .. ":" .. ltier .. "_" .. lmachine_name,
        groups = active_groups,
        legacy_facedir_simple = true,
        drawtype = "mesh",
        mesh = "moreblocks_slope_half_raised.obj",
        selection_box = {
            type = "fixed",
            fixed = {{-0.5000, -0.5000, -0.5000, 0.5000, 0.5000, 0.5000}}
        },
        collision_box = {
            type = "fixed",
            fixed = {{-0.5, -0.5, -0.5, 0.5, 0.125, 0.5}, {-0.5, 0.125, -0.25, 0.5, 0.25, 0.5},
                     {-0.5, 0.25, 0, 0.5, 0.375, 0.5}, {-0.5, 0.375, 0.25, 0.5, 0.5, 0.5}}
        },
        sounds = default.node_sound_glass_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Starship Control " .. "-" .. " " .. machine_desc)
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            meta:set_int("enabled", 1)
            meta:set_int("dest_dir", 0)
            meta:set_int("jump_dist", data.jump_dist)
            meta:set_int("travel_ready", 0)
            meta:set_string("formspec", ship_scout.update_formspec(pos, data, "0", false, ''))
            meta:set_string("pos_nav", "{}")
            meta:set_string("pos_eng1", "{}")
            meta:set_string("pos_eng2", "{}")
        end,

        on_receive_fields = on_receive_fields,
        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                action = ship_scout.scout_digiline_effector
            }
        }
    })

end

ship_scout.register_scout()
