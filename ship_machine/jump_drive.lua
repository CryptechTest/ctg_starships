local S = minetest.get_translator(minetest.get_current_modname())

local time_scl = 50

local function round(v)
    return math.floor(v + 0.5)
end

local function needs_charge(pos)
    local meta = minetest.get_meta(pos)
    local charge = meta:get_int("charge")
    local charge_max = meta:get_int("charge_max")
    return charge < charge_max
end

function ship_machine.register_jumpship(data)
    data.modname = "ship_machine"
    -- data.machine_name = "jump_drive"
    -- data.machine_desc = "Jump Drive Allocator"
    -- data.typename = "jump_drive"
    data.jump_distance = 1
    data.speed = 1
    data.tier = "LV"

    local texture_active = {
        image = data.machine_name .. "_active.png",
        animation = {
            type = "vertical_frames",
            aspect_w = 32,
            aspect_h = 32,
            length = 3
        }
    }

    local nodename = data.modname .. ":" .. data.machine_name
    minetest.register_node(nodename, {
        description = S(data.machine_desc),
        tiles = {texture_active, data.machine_name .. "_bottom.png", texture_active, texture_active, texture_active,
                 texture_active},

        paramtype = "light",
        paramtype2 = "facedir",
        light_source = 3,
        groups = {
            cracky = 1,
            metal = 1,
            jumpdrive = 1,
            ship_machine = 1,
            jump_dist = 1
        },
        sounds = default.node_sound_metal_defaults(),

        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            meta:set_string("owner", placer:get_player_name())
            local formspec = ship_machine.update_jumpdrive_formspec(data, meta)
            meta:set_string("formspec", formspec)
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)

            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
        --[[can_dig = function(pos, player)
            local is_admin = player:get_player_name() == "squidicuzz"
            return player and is_admin
            --return false
        end,]] --
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Starship Jump Drive Allocator")
            meta:set_int("enabled", 1)
            meta:set_int("ready", 0)
            meta:set_int("jumps", 0)
            local formspec = ship_machine.update_jumpdrive_formspec(data, meta)
            meta:set_string("formspec", formspec)
        end,

        allow_metadata_inventory_put = technic.machine_inventory_put,
        allow_metadata_inventory_take = technic.machine_inventory_take,
        allow_metadata_inventory_move = technic.machine_inventory_move,
        -- technic_run = run,

        on_receive_fields = function(pos, formname, fields, sender)
            if fields.quit then
                return
            end
            local is_admin = sender:get_player_name() == "squidicuzz"
            if not is_admin then
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
            local owner_name = ""
            if fields.set_owner and fields.owner_name then
                owner_name = fields.owner_name
                meta:set_string("owner", owner_name)
                local prot = minetest.find_node_near(pos, 3, "ship_machine:protect2")
                if prot then
                    local meta2 = minetest.get_meta(prot.pos)
                    meta2:set_string("owner", owner_name)
                    meta2:set_string("infotext", S("Protection (owned by @1)", meta2:get_string("owner")))
                end
            end
            local move_x = 0
            local move_y = 0
            local move_z = 0
            if fields.inp_x then
                move_x = fields.inp_x
            end
            if fields.inp_y then
                move_y = fields.inp_y
            end
            if fields.inp_z then
                move_z = fields.inp_z
            end
            local file_name = ""
            if fields.file_name then
                file_name = fields.file_name
            end
            if fields.save then
                local size = {
                    w = 20,
                    h = 12,
                    l = 30
                }
                if data.typename == 'jump_drive_spawn' then
                    size = {
                        w = 171,
                        h = 56,
                        l = 219
                    }
                end
                minetest.after(0, function()
                    ship_machine.save_jumpship(pos, size, sender, file_name)
                end)
            end
            if fields.load then
                minetest.after(0, function()
                    ship_machine.load_jumpship(pos, sender, file_name)
                end)
            end
            if fields.jump then
                local dest = {
                    x = pos.x + move_x,
                    y = pos.y + move_y,
                    z = pos.z + move_z
                }
                local perform = true;
                if vector.distance(pos, dest) < 32 then
                    perform = false;
                end
                local size = {
                    w = 16,
                    h = 16,
                    l = 32
                }
                if not schemlib.check_dest_clear(pos, dest, size) then
                    perform = false;
                end
                if perform then
                    minetest.after(0, function()
                        if ship_machine.check_engines_charged(pos) then
                            ship_machine.transport_jumpship(pos, dest, size, sender)
                        end
                    end)
                end
            end
            local formspec = ship_machine.update_jumpdrive_formspec(data, meta)
            meta:set_string("formspec", formspec)
        end,

        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                action = ship_machine.jumpdrive_digiline_effector
            }
        }
    })
end
