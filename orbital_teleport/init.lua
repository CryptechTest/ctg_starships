local S = minetest.get_translator(minetest.get_current_modname())

orbital_teleport = {}

-- load files
local default_path = minetest.get_modpath("orbital_teleport")

local function isInteger(str)
    return tonumber(str) ~= nil
end

local function particle_effect(pos, type)
    local time = 2
    local minpos = {
        x = pos.x - 0.9,
        y = pos.y - 0.3,
        z = pos.z - 0.9
    }
    local maxpos = {
        x = pos.x + 0.9,
        y = pos.y + 0.1,
        z = pos.z + 0.9
    }

    if type == 1 then
        time = 1.5
        minpos = {
            x = pos.x - 0.4,
            y = pos.y - 0.3,
            z = pos.z - 0.4
        }
        maxpos = {
            x = pos.x + 0.4,
            y = pos.y + 0.1,
            z = pos.z + 0.4
        }
    end

    minetest.add_particlespawner({
        amount = 50, -- amount
        time = time, -- time
        minpos = minpos, -- minpos
        maxpos = maxpos, -- maxpos
        minvel = {
            x = 0,
            y = 0,
            z = 0
        }, -- minvel
        maxvel = {
            x = 0,
            y = 0.05,
            z = 0
        }, -- maxvel
        minacc = {
            x = -0,
            y = 1,
            z = -0
        }, -- minacc
        maxacc = {
            x = 0,
            y = 2,
            z = 0
        }, -- maxacc
        minexptime = 0.45, -- minexptime
        maxexptime = time - 0.5, -- maxexptime
        minsize = 0.5, -- minsize
        maxsize = 2.5, -- maxsize
        collisiondetection = false, -- collisiondetection
        collision_removal = false, -- collision_removal
        object_collision = false,
        vertical = true,
        texture = {
            name = "scifi_nodes_tp_part.png",
            fade = "out"
        }, -- texture
        glow = 11 -- glow
    })
end

local function particle_effect_teleport(pos, amount)
    local texture = "orbital_tele_effect.png"
    local r = math.random(0, 4)
    if r == 1 then
        texture = "orbital_tele_effect.png^[transformR90"
    elseif r == 2 then
        texture = "orbital_tele_effect.png^[transformR180"
    elseif r == 3 then
        texture = "orbital_tele_effect.png^[transformR270"
    elseif r == 4 then
        texture = "orbital_tele_effect.png^[transformFX"
    end

    minetest.add_particlespawner({
        amount = amount,
        time = 0.72,
        minpos = {
            x = pos.x - 0.02,
            y = pos.y + 0.15,
            z = pos.z - 0.02
        },
        maxpos = {
            x = pos.x + 0.02,
            y = pos.y + 0.40,
            z = pos.z + 0.02
        },
        minvel = {
            x = 0,
            y = 0,
            z = 0
        },
        maxvel = {
            x = 0,
            y = 0.1,
            z = 0
        },
        minacc = {
            x = -0,
            y = -0,
            z = -0
        },
        maxacc = {
            x = 0,
            y = 0.2,
            z = 0
        },
        minexptime = 0.25,
        maxexptime = 0.4,
        minsize = 11,
        maxsize = 25,
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        vertical = false,
        texture = texture,
        glow = 15
    })
end

if true then

    local data = {
        desc = S("Teleport Pad"),
        node = "tele_pad"
    }

    local update_formspec = function(pos, data)
        local node = minetest.get_node(pos)
        local meta = minetest.get_meta(pos)
        local exit = nil
        local formspec = nil

        if meta:get_string("exit") then
            exit = minetest.deserialize(meta:get_string("exit"))
        end

        if exit == nil then
            local input_pos = "field[1,1;2,1;inp_x;Dest X;0]field[3,1;2,1;inp_y;Dest Y;0]field[5,1;2,1;inp_z;Dest Z;0]"
            local input_save = "button[3,2;2,1;save;Save]"

            formspec = {"formspec_version[6]", "size[8,4]", -- "real_coordinates[false]",
            input_pos, input_save}
        else
            formspec = {}
        end

        return table.concat(formspec)
    end

    local on_receive_fields = function(pos, formname, fields, sender)
        if fields.quit or fields.exit then
            return
        end
        local node = minetest.get_node(pos)
        local meta = minetest.get_meta(pos)

        local dest_x = 0
        local dest_y = 0
        local dest_z = 0
        local isNumError = false
        if fields.inp_x then
            if isInteger(fields.inp_x) then
                dest_x = tonumber(fields.inp_x, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_y then
            if isInteger(fields.inp_y) then
                dest_y = tonumber(fields.inp_y, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_z then
            if isInteger(fields.inp_z) then
                dest_z = tonumber(fields.inp_z, 10)
            else
                isNumError = true
            end
        end

        if fields.save and not isNumError then
            local dest = {
                x = dest_x,
                y = dest_y,
                z = dest_z
            }
            meta:set_string("exit", minetest.serialize(dest))
        end

        local formspec = update_formspec(pos, data)
        meta:set_string("formspec", formspec)
    end

    minetest.register_node("orbital_teleport:" .. data.node, {
        description = data.desc,
        tiles = {"orbital_telepad_top.png", "orbital_telepad_bottom.png", "orbital_telepad_side.png", 
                "orbital_telepad_side.png", "orbital_telepad_side.png", "orbital_telepad_side.png"},
        drawtype = "nodebox",
        paramtype = "light",
        groups = {
            cracky = 1,
            oddly_breakable_by_hand = 1
        },
        light_source = 5,

        on_receive_fields = on_receive_fields,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local placer_name = placer:get_player_name()
            local meta = minetest.get_meta(pos)
            -- meta:set_string("exit", '')
		    meta:set_string("infotext", data.desc)
            local formspec = update_formspec(pos, data)
            meta:set_string("formspec", formspec)
        end,
        on_rightclick = function(pos, node, clicker)
            local clicker_name = clicker:get_player_name()
            local meta = minetest.get_meta(pos)
            local exit = nil
            if meta:get_string("exit") then
                exit = minetest.deserialize(meta:get_string("exit"))
            end
            if exit ~= nil then
                local objs = minetest.get_objects_inside_radius(pos, 2)
                if #objs > 0 then
                    particle_effect(pos, 0)
                    particle_effect(exit, 1)
                    if clicker:is_player() then
                        local name = clicker:get_player_name()
                        minetest.sound_play("tele_drone", { to_player = name, gain = 1.0 })
                    end
                    minetest.after(1, function()
                        local ppos = clicker:get_pos()
                        if minetest.get_node({
                            x = ppos.x,
                            y = ppos.y,
                            z = ppos.z
                        }).name == "orbital_teleport:" .. data.node then
                            clicker:set_pos(exit)
                            local name = clicker:get_player_name()
                            minetest.sound_play("tele_zap", { to_player = name, gain = 1.2, pitch = 0.6 })
                        end
                        particle_effect_teleport(exit, 1)
                        local objs = minetest.get_objects_inside_radius(pos, 2.25)
                        for _, obj in pairs(objs) do
                            if obj:get_luaentity() and not obj:is_player() then
                                if obj:get_luaentity().name == "__builtin:item" then
                                    local item1 = obj:get_luaentity().itemstring
                                    local obj2 = minetest.add_entity(exit, "__builtin:item")
                                    obj2:get_luaentity():set_item(item1)
                                    obj:remove()
                                    particle_effect_teleport(exit, 1)
                                else
                                    obj:set_pos(exit)
                                    particle_effect_teleport(exit, 1)
                                end
                            elseif obj:is_player() then
                                local name = obj:get_player_name()
		                        minetest.sound_play("tele_zap", { to_player = name, gain = 1.2, pitch = 0.6 })
                                obj:set_pos(exit)
                                particle_effect_teleport(exit, 1)
                            end
                        end
                    end)
                end
            else
                minetest.chat_send_player(clicker_name, "Teleporter exit is not defined!")
            end
        end,
        on_destruct = function(pos, oldnode, placer)
            local meta = minetest.get_meta(pos)

        end,
        node_box = {
            type = "fixed",
            fixed = {
                {-0.6250, -0.5000, -0.6250, 0.6250, -0.3438, 0.6250},
                {-0.8125, -0.5000, -0.5625, -0.6250, -0.4375, 0.5625},
                {0.6250, -0.5000, -0.5625, 0.8125, -0.4375, 0.5625},
                {-0.5625, -0.5000, -0.8125, 0.5625, -0.4375, -0.6250},
                {-0.5625, -0.5000, 0.6250, 0.5625, -0.4375, 0.8125}
            }
        },
        sounds = scifi_nodes.node_sound_metal_defaults()
    })
end
