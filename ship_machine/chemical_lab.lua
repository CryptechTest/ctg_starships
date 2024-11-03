local S = minetest.get_translator(minetest.get_current_modname())

local time_scl = 10

local has_pipeworks = minetest.get_modpath("pipeworks")

local tube_entry_metal = ""

if has_pipeworks then
    tube_entry_metal = "^pipeworks_tube_connection_metallic.png"
end

local connect_default = {"bottom", "back"}

local function isNumber(str)
    return tonumber(str) ~= nil
end

local function round(v)
    return math.floor(v + 0.5)
end

----------------------------------------------------

local function update_formspec(meta, data)
    local machine_desc = data.tier .. " " .. data.machine_desc
    local typename = data.typename
    local tier = data.tier
    local ltier = string.lower(tier)
    local formspec = nil
    if typename == 'chem_lab' then
        local enabled = ctg_machines.machine_enabled(meta)
        local btnName = "Status: "
        if enabled then
            btnName = btnName .. "Enabled"
        else
            btnName = btnName .. "Disabled"
        end

        local percent1 = 0
        if meta:get_int("output_count") and meta:get_int("output_max") then
            percent1 = (meta:get_int("output_count") / meta:get_int("output_max")) * 100
        end
        local progress_proc = "image[3.25,1.5;1.5,1;gui_furnace_arrow_bg.png^[lowpart:" .. tostring(percent1) ..
        ":gui_furnace_arrow_fg.png^[transformR270]]";
        
        local percent2 = 0
        if meta:get_int("src_time") then
            percent2 = (meta:get_int("src_time") / round(time_scl * 10)) * 100
        end
        local progress_time = "image[3.25,1.0;1.5,0.5;gui_furnace_arrow_bg.png^[lowpart:" .. tostring(percent2) ..
        ":gui_furnace_arrow_fg.png^[transformR270]]"

        local bg_images = {
            "bucket_cave_cavewater.png^[colorize:#75757575", 
            "technic_sulfur_dust.png^[colorize:#75757575", 
            "saltd_salt_crystals.png^[colorize:#75757575", 
            "livingcaves_mushroom_top.png^[colorize:#75757575"
        }
        local images = "image[1,1;1,1;" .. bg_images[1] .. "]" .. "image[2,1;1,1;" .. bg_images[2] .. "]" ..
                       "image[1,2;1,1;" .. bg_images[3] .. "]" .. "image[2,2;1,1;" .. bg_images[4] .. "]"

        local recipe_dropdown = "dropdown[1,3.6;2.5;recipe;Coolant;1;]"

        formspec = "size[8,9;]" .. images..
                    "list[current_name;src1;1,1;1,1;]" .. "list[current_name;src2;2,1;1,1;]" ..
                    "list[current_name;src3;1,2;1,1;]" .. "list[current_name;src4;2,2;1,1;]" ..
                    "list[current_name;dst;5,1;2,2;]" ..
                    "list[current_player;main;0,5;8,4;]" .. "label[0,0;" .. machine_desc:format(tier) .. "]" .. 
                    progress_proc .. progress_time .. "listring[current_name;dst]" ..
                    "listring[current_player;main]" .. "listring[current_name;src1]" .. "listring[current_name;src2]" ..
                    "listring[current_name;src3]" .. "listring[current_name;src4]" .. "listring[current_player;main]" .. 
                    recipe_dropdown .. "button[4.5,3.5;2.5,1;toggle;" .. btnName .. "]"
    end

    if data.upgrade then
        formspec = formspec .. "list[current_name;upgrade1;1,3;1,1;]" .. "list[current_name;upgrade2;2,3;1,1;]" ..
                       "label[1,4;" .. S("Upgrade Slots") .. "]" .. "listring[current_name;upgrade1]" ..
                       "listring[current_player;main]" .. "listring[current_name;upgrade2]" ..
                       "listring[current_player;main]"
    end
    return formspec
end

----------------------------------------------------

local function do_particle_effect(pos, amount)
    local grav = 0.25;
    if (pos.y > 4000) then
        grav = 0.4;
    end
    local prt = {
        animation = {
            type = "vertical_frames",
            aspect_w = 16,
            aspect_h = 16,
            length = 1
        },
        texture = {
            name = "ctg_coolant_bubble_anim.png",
            alpha = 1.0,
            alpha_tween = {1, 0},
            scale_tween = {{
                x = 0.1,
                y = 0
            }, {
                x = 3,
                y = 3
            }}
        },
        texture_r180 = {
            name = "ctg_coolant_bubble_anim.png" .. "^[transformR180",
            alpha = 1.0,
            alpha_tween = {1, 0},
            scale_tween = {{
                x = 0.1,
                y = 0.0
            }, {
                x = 3,
                y = 3
            }}
        },
        vel = 2.7,
        time = 2.5,
        size = 0.7,
        glow = 6,
        cols = false
    }
    local rx = math.random(-0.064, 0.064) * 0.2
    local rz = math.random(-0.064, 0.064) * 0.2
    local texture = prt.texture
    if (math.random() >= 0.52) then
        texture = prt.texture_r180
    end

    minetest.add_particlespawner({
        amount = amount,
        time = prt.time + math.random(-0.3, 1),
        minpos = {
            x = pos.x - 0.4,
            y = pos.y + 0.46,
            z = pos.z - 0.4
        },
        maxpos = {
            x = pos.x + 0.4,
            y = pos.y + 0.67,
            z = pos.z + 0.4
        },
        minvel = {
            x = rx,
            y = prt.vel * 0.2 * grav,
            z = rz
        },
        maxvel = {
            x = rx,
            y = prt.vel * 0.7 * grav,
            z = rz
        },
        minacc = {
            x = -0.1,
            y = -0.15,
            z = -0.1
        },
        maxacc = {
            x = 0.1,
            y = 0.23 * grav,
            z = 0.1
        },
        minexptime = prt.time * 0.30,
        maxexptime = prt.time * 0.96,
        minsize = prt.size * 0.5,
        maxsize = prt.size * 1.2,
        collisiondetection = prt.cols,
        collision_removal = false,
        object_collision = false,
        vertical = false,
        animation = prt.animation,
        texture = texture,
        glow = prt.glow
    })
end

----------------------------------------------------
----------------------------------------------------

local function get_sulfur(items, take)
    if not items then
        return nil
    end
    local new_input = nil
    local c = 0;
    for i, stack in ipairs(items) do
        if stack:get_name() == 'technic:sulfur_dust' and stack:get_count() > 0 then
            new_input = ItemStack(stack)
            if take then
                new_input:take_item(1)
            end
            c = c + 1
            break
        end
    end
    if (c > 0) then
        return {
            new_input = new_input
        }
    else
        return nil
    end
end

local function get_bio_water(items, take)
    if not items then
        return nil
    end
    local new_input = nil
    local c = 0;
    for i, stack in ipairs(items) do
        if stack:get_name() == "livingcaves:bucket_cavewater" and stack:get_count() > 0 then
            new_input = ItemStack(stack)
            if (take) then
                new_input:take_item(1)
            end
            c = c + 1
            break
        end
    end
    if (c > 0) then
        return {
            new_input = new_input
        }
    else
        return nil
    end
end

local function get_shrooms(items, take)
    if not items then
        return nil
    end
    local new_input = nil
    local c = 0;
    for i, stack in ipairs(items) do
        local group = minetest.get_item_group(stack:get_name(), "glow_shroom")
        if group > 0 then
            new_input = ItemStack(stack)
            if (take) then
                new_input:take_item(1)
            end
            c = c + 1
            break
        end
    end
    if (c > 0) then
        return {
            new_input = new_input
        }
    else
        return nil
    end
end

local function get_salt(items, take)
    if not items then
        return nil
    end
    local new_input = nil
    local c = 0;
    for i, stack in ipairs(items) do
        local group = minetest.get_item_group(stack:get_name(), "salt")
        if group > 0 then
            new_input = ItemStack(stack)
            if (take) then
                new_input:take_item(1)
            end
            c = c + 1
            break
        end
    end
    if (c > 0) then
        return {
            new_input = new_input
        }
    else
        return nil
    end
end

local function has_items(pos)
    if not pos then
        return nil
    end
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local src2 = inv:get_list("src2")
    local src3 = inv:get_list("src3")
    local src4 = inv:get_list("src4")

    local has_sulfur = false
    local has_salt = false
    local has_shroom = false

    if src2[1]:get_name() == 'technic:sulfur_dust' and src2[1]:get_count() > 0 then
        has_sulfur = true
    end
    local group = minetest.get_item_group(src3[1]:get_name(), "salt")
    if group > 0 then
        has_salt = true
    end
    local group = minetest.get_item_group(src4[1]:get_name(), "glow_shroom")
    if group > 0 then
        has_shroom = true
    end
    return has_sulfur and has_shroom and has_salt
end

local function has_water(pos)
    if not pos then
        return nil
    end
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local src1 = inv:get_list("src1")

    local has_water = false

    if src1[1]:get_name() == 'livingcaves:bucket_cavewater' and src1[1]:get_count() > 0 then
        has_water = true
    end
    return has_water
end

local function add_output(pos, do_run, do_use)
    local output = {}
    if do_use then
        output = {"ship_machine:bottle_of_coolant"}
    end
    if do_run then
        table.insert(output, "livingcaves:bucket_empty")
    end
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    if type(output) ~= "table" then
        output = {output}
    end
    local output_stacks = {}
    for _, o in ipairs(output) do
        table.insert(output_stacks, ItemStack(o))
    end
    local room_for_output = true
    inv:set_size("dst_tmp", inv:get_size("dst"))
    inv:set_list("dst_tmp", inv:get_list("dst"))
    for _, o in ipairs(output_stacks) do
        if not inv:room_for_item("dst_tmp", o) then
            room_for_output = false
            break
        end
        inv:add_item("dst_tmp", o)
    end
    if not room_for_output then
        return false
    end
    inv:set_list("dst", inv:get_list("dst_tmp"))
    return true
end

----------------------------------------------------
----------------------------------------------------
----------------------------------------------------

function ship_machine.register_chem_lab(custom_data)

    local data = custom_data or {}

    data.tube = 1
    data.speed = custom_data.speed or 1
    data.demand = custom_data.demand or {200, 180, 150}
    data.tier = (custom_data and custom_data.tier) or "LV"
    data.typename = (custom_data and custom_data.typename) or "chem_lab"
    data.modname = (custom_data and custom_data.modname) or "ship_machine"
    data.machine_name = (custom_data and custom_data.machine_name) or string.lower(data.tier) ..
                            "_chemical_lab"
    data.machine_desc = (custom_data and custom_data.machine_desc) or "Chemical Lab"

    local tier = data.tier
    local ltier = string.lower(tier)
    local modname = data.modname
    local machine_name = data.machine_name
    local machine_desc = tier .. " " .. data.machine_desc
    local lmachine_name = string.lower(machine_name)
    local node_name = modname .. ":" .. machine_name


    local groups = {
        cracky = 2,
        technic_machine = 1,
        ["technic_" .. ltier] = 1,
        ctg_machine = 1,
        metal = 1,
        ship_machine = 1
    }
    if data.tube then
        groups.tubedevice = 1
        groups.tubedevice_receiver = 1
    end
    local active_groups = {
        not_in_creative_inventory = 1
    }
    for k, v in pairs(groups) do
        active_groups[k] = v
    end

    local tube = {
        input_inventory = 'dst',
        insert_object = function(pos, node, stack, direction)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            local added = nil
            local g_water = stack:get_name() == "livingcaves:bucket_cavewater"
            if g_water then
                added = inv:add_item("src1", stack)
            end
            local g_sulfur = stack:get_name() == "technic:sulfur_dust"
            if g_sulfur then
                added = inv:add_item("src2", stack)
            end
            local g_salt = minetest.get_item_group(stack:get_name(), "salt")
            if g_salt > 0 then
                added = inv:add_item("src3", stack)
            end
            local g_shroom = minetest.get_item_group(stack:get_name(), "glow_shroom")
            if g_shroom > 0 then
                added = inv:add_item("src4", stack)
            end
            return added
        end,
        can_insert = function(pos, node, stack, direction)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            local g_water = stack:get_name() == "livingcaves:bucket_cavewater"
            if g_water then
                return inv:room_for_item("src1", stack)
            end
            local g_sulfur = stack:get_name() == "technic:sulfur_dust"
            if g_sulfur then
                return inv:room_for_item("src2", stack)
            end
            local g_salt = minetest.get_item_group(stack:get_name(), "salt")
            if g_salt > 0 then
                return inv:room_for_item("src3", stack)
            end
            local g_shroom = minetest.get_item_group(stack:get_name(), "glow_shroom")
            if g_shroom > 0 then
                return inv:room_for_item("src4", stack)
            end
            return false
        end,
        connect_sides = {
            --left = 1,
            right = 1,
            back = 1,
            top = 1,
            bottom = 1,
        }
    }

    if data.can_insert then
        tube.can_insert = data.can_insert
    end
    if data.insert_object then
        tube.insert_object = data.insert_object
    end

    -------------------------------------------------------
    -------------------------------------------------------
    -- technic run
    local run = function(pos, node)
        local meta = minetest.get_meta(pos)
        local owner = meta:get_string("owner")
        local operator = minetest.get_player_by_name(owner);
        local inv = meta:get_inventory()
        local eu_input = meta:get_int(tier .. "_EU_input")

        local machine_desc_tier = machine_desc:format(tier)
        local machine_node = data.modname .. ":" .. machine_name
        local machine_demand_active = data.demand

        -- Setup meta data if it does not exist.
        if not eu_input then
            meta:set_int(tier .. "_EU_demand", machine_demand_active[1])
            meta:set_int(tier .. "_EU_input", 0)
            return
        end

        local powered = eu_input >= machine_demand_active[1]
        if powered then
            if meta:get_int("src_time") < round(time_scl * 10) then
                meta:set_int("src_time", meta:get_int("src_time") + round(data.speed * 10))
            end
        end
        while true do
            local enabled = meta:get_int("enabled") == 1
            if not enabled then
                meta:set_int(tier .. "_EU_demand", 0)
                technic.swap_node(pos, machine_node)
                return
            end

            meta:set_int(tier .. "_EU_demand", machine_demand_active[1])

            if not powered then
                meta:set_string("infotext", machine_desc_tier .. S(" - Not Powered"))
                technic.swap_node(pos, machine_node)
                return
            end

            meta:set_string("infotext", machine_desc_tier .. S(" - Online"))

            if meta:get_int("output_count") == 0 and not has_water(pos) then
                technic.swap_node(pos, machine_node)
                meta:set_int("input_valid", 0)
                meta:set_int("src_time", 0)
            end
            if meta:get_int("input_valid") <= 1 and not has_items(pos) then
                meta:set_int("src_time", 0)
                technic.swap_node(pos, machine_node)
                break;
            end

            if (meta:get_int("src_time") % 2 == 0) then
                local formspec = update_formspec(meta, data)
                meta:set_string("formspec", formspec)
            end

            if (meta:get_int("src_time") < round(time_scl * 10)) then
                if meta:get_int("input_valid") >= 1 then
                    technic.swap_node(pos, machine_node .. "_active")
                end
                break
            end

            local used_bucket = false
            if meta:get_int("input_valid") == 0 and has_water(pos) then
                local input1 = get_bio_water(inv:get_list("src1"), true)
                if input1 ~= nil then
                    inv:set_list("src1", {input1.new_input})
                    used_bucket = true
                end
                if used_bucket then
                    meta:set_int("input_valid", 1)
                    meta:set_int("output_count", 0)
                end
            end
            if meta:get_int("input_valid") >= 1 and has_items(pos) then
                local input2 = get_sulfur(inv:get_list("src2"), true)
                local input3 = get_salt(inv:get_list("src3"), true)
                local input4 = get_shrooms(inv:get_list("src4"), true)
                if input2 and input2.new_input then
                    inv:set_list("src2", {input2.new_input})
                end
                if input3 and input3.new_input then
                    inv:set_list("src3", {input3.new_input})
                end
                if input4 and input4.new_input then
                    inv:set_list("src4", {input4.new_input})
                end
                meta:set_int("input_valid", 2)
                technic.swap_node(pos, machine_node .. "_active")
            elseif meta:get_int("input_valid") >= 1 then
                meta:set_int("input_valid", 1)
                technic.swap_node(pos, machine_node)
            end
            if meta:get_int("input_valid") == 2 then
                meta:set_int("input_valid", 1)
                local tick_max = meta:get_int("output_max")
                local tick = meta:get_int("output_count")
                if tick < tick_max then
                    tick = tick + 1
                end
                meta:set_int("output_count", tick)
                if tick >= tick_max then
                    meta:set_int("input_valid", 0)
                    meta:set_int("output_count", 0)
                end
                add_output(pos, used_bucket, true)
                meta:set_string("infotext", machine_desc_tier .. S(" - Processing"))
                do_particle_effect(pos, 16)
            end            

            meta:set_int("src_time", 0)
            break
        end
    end
    
    local on_receive_fields = function(pos, formname, fields, sender)
        local meta = minetest.get_meta(pos)
        if fields.quit then
            return
        end
        local enabled = meta:get_int("enabled")
        if fields.toggle then
            if enabled >= 1 then
                meta:set_int("enabled", 0)
            else
                meta:set_int("enabled", 1)
            end
        end
        local formspec = update_formspec(meta, data)
        meta:set_string("formspec", formspec)
    end

    minetest.register_node(node_name, {
        description = machine_desc,
        tiles = {"ctg_" .. ltier .. "_chem_lab_top.png^[transformR90" .. tube_entry_metal,
                 "ctg_" .. ltier .. "_chem_lab_bottom.png^[transformFXR90" .. tube_entry_metal, "ctg_" .. ltier .. "_chem_lab_side_r.png" .. tube_entry_metal,
                 "ctg_" .. ltier .. "_chem_lab_side_l.png^[transformFX", "ctg_" .. ltier .. "_chem_lab_back.png" .. tube_entry_metal,
                 "ctg_" .. ltier .. "_chem_lab_front.png"},
        param = "light",
        paramtype2 = "facedir",
        light_source = 1,
        drop = node_name,
        groups = groups,
        tube = data.tube and tube or nil,
        connect_sides = data.connect_sides or connect_default,
        legacy_facedir_simple = true,
        drawtype = "nodebox",
        paramtype = "light",

        node_box = {
            type = "fixed",
            fixed = {
                {-0.46875, -0.5, -0.46875, 0.5, 0.46875, 0.5}, -- base
                {0.0625, -0.5, -0.5, 0.5, 0.5, -0.4375}, -- front_r
                {-0.5, -0.5, -0.5, 0.5, -0.125, -0.4375}, -- front_bottom
                {-0.5, -0.5, 0.0625, -0.4375, 0.5, 0.5}, -- left
                {-0.5, -0.5, -0.5, -0.4375, -0.125, 0.5}, -- left_bottom
                {0.0625, 0.4375, -0.46875, 0.5, 0.5, 0.5}, -- top_0
                {-0.4375, 0.4375, 0.0625, 0.0625, 0.5, 0.5}, -- top_1
                {-0.1875, 0.4375, -0.1875, 0.0625, 0.5, 0.0625}, -- top_m
            }
        },
        selection_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, -- col_base
            }
        },

        sounds = default.node_sound_metal_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            if data.tube then
                pipeworks.after_place(pos)
            end
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", machine_desc)
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            if data.tube then
                pipeworks.after_dig(pos)
            end
            return technic.machine_after_dig_node
        end,
        can_dig = technic.machine_can_dig,
        allow_metadata_inventory_put = technic.machine_inventory_put,
        allow_metadata_inventory_take = technic.machine_inventory_take,
        allow_metadata_inventory_move = technic.machine_inventory_move,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            meta:set_int("enabled", 0)            
            meta:set_int("tube_time", 0)
            local inv = meta:get_inventory()
            inv:set_size("src1", 1)
            inv:set_size("src2", 1)
            inv:set_size("src3", 1)
            inv:set_size("src4", 1)
            inv:set_size("dst", 4)
            local formspec = update_formspec(meta, data)
            meta:set_string("formspec", formspec)
            meta:set_int("input_valid", 0)
            meta:set_int("output_count", 0)
            meta:set_int("output_max", data.produced or 1)
        end,

        on_punch = function(pos, node, puncher)
        end,

        technic_run = run,
        on_receive_fields = on_receive_fields,

        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                rules = technic.digilines.rules_allfaces,
                action = ship_machine.chem_lab_digiline_effector
            }
        }
    })

    minetest.register_node(node_name .. "_active", {
        description = machine_desc,
        tiles = {"ctg_" .. ltier .. "_chem_lab_top_active.png^[transformR90" .. tube_entry_metal,
                 "ctg_" .. ltier .. "_chem_lab_bottom.png^[transformFXR90" .. tube_entry_metal, "ctg_" .. ltier .. "_chem_lab_side_r_active.png" .. tube_entry_metal,
                 "ctg_" .. ltier .. "_chem_lab_side_l.png^[transformFX", "ctg_" .. ltier .. "_chem_lab_back.png" .. tube_entry_metal,
                 "ctg_" .. ltier .. "_chem_lab_front_active.png"},
        param = "light",
        paramtype2 = "facedir",
        light_source = 4,
        drop = node_name,
        groups = active_groups,
        tube = data.tube and tube or nil,
        connect_sides = data.connect_sides or connect_default,
        legacy_facedir_simple = true,
        drawtype = "nodebox",
        paramtype = "light",
        
        node_box = {
            type = "fixed",
            fixed = {
                {-0.46875, -0.5, -0.46875, 0.5, 0.46875, 0.5}, -- base
                {0.0625, -0.5, -0.5, 0.5, 0.5, -0.4375}, -- front_r
                {-0.5, -0.5, -0.5, 0.5, -0.125, -0.4375}, -- front_bottom
                {-0.5, -0.5, 0.0625, -0.4375, 0.5, 0.5}, -- left
                {-0.5, -0.5, -0.5, -0.4375, -0.125, 0.5}, -- left_bottom
                {0.0625, 0.4375, -0.46875, 0.5, 0.5, 0.5}, -- top_0
                {-0.4375, 0.4375, 0.0625, 0.0625, 0.5, 0.5}, -- top_1
                {-0.1875, 0.4375, -0.1875, 0.0625, 0.5, 0.0625}, -- top_m
            }
        },
        selection_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, -- col_base
            }
        },

        sounds = default.node_sound_metal_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            if data.tube then
                pipeworks.after_dig(pos)
            end
            return technic.machine_after_dig_node
        end,
        can_dig = technic.machine_can_dig,
        allow_metadata_inventory_put = technic.machine_inventory_put,
        allow_metadata_inventory_take = technic.machine_inventory_take,
        allow_metadata_inventory_move = technic.machine_inventory_move,
        on_construct = function(pos)
        end,

        on_punch = function(pos, node, puncher)
        end,

        technic_run = run,
        on_receive_fields = on_receive_fields,

        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                rules = technic.digilines.rules_allfaces,
                action = ship_machine.chem_lab_digiline_effector
            }
        }
    })

    technic.register_machine(tier, node_name, technic.receiver)
    technic.register_machine(tier, node_name .. "_active", technic.receiver)
end

ship_machine.register_chem_lab({
    tier = "LV",
    demand = {500, 480, 450},
    produced = 20,
    speed = 2,
});
ship_machine.register_chem_lab({
    tier = "MV",
    demand = {700, 670, 640},
    produced = 30,
    speed = 3.35,
});
ship_machine.register_chem_lab({
    tier = "HV",
    demand = {1200, 1080, 950},
    produced = 50,
    speed = 5,
});
