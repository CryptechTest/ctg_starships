local S = minetest.get_translator(minetest.get_current_modname())

local function round(v)
    return math.floor(v + 0.5)
end

function shipyard.update_formspec(pos, data, loc, ready, message)
    local meta = minetest.get_meta(pos)
    local machine_name = data.machine_name
    local machine_desc = data.machine_desc .. " - Navigation Interface"
    local typename = data.typename
    local tier = data.tier
    local ltier = string.lower(tier)
    local formspec = nil

    local is_deepspace = pos.y > 22000;

    if typename == 'shipyard' then

        local bg = "image[0,0.5;9.78,6.5;starfield_2.png]image[5,3.25;2.2,0.88;bg2.png]"

        local combat_migration_done = meta:get_int("combat_ready") > 0 or 0
        local combat_migration = (combat_migration_done == false and "button[4,5.25;3,1;submit_migr;Combat Migration]") or ""

        local icon_fan = "image[5,1;1,1;icon_fan.png]"
        local icon_env = "image[6,1;1,1;icon_life_support.png]"
        local icon_eng = "image[5,2;1,1;lv_engine_front_active.png]"
        local icon_lit = "image[6,2;1,1;icon_light.png]"

        local img_ship = "image[2,2;1,1;starship_icon.png]"
        local img_hole_1 = "image_button[2,1;1,1;space_wormhole1.png;btn_hole_1;;true;false;space_wormhole2.png]" -- top
        local img_hole_2 = "image_button[2,3;1,1;space_wormhole1.png;btn_hole_2;;true;false;space_wormhole2.png]" -- bottom
        local img_hole_3 = "image_button[1,2;1,1;space_wormhole1.png;btn_hole_3;;true;false;space_wormhole2.png]" -- left
        local img_hole_4 = "image_button[3,2;1,1;space_wormhole1.png;btn_hole_4;;true;false;space_wormhole2.png]" -- right
        local btn_nav = "button[5,4;2,1;submit_nav;Make it so]"
        local btn_prot = "button[6.5,-0.1;1.5,0.5;protector;Members]"
        local dest = ""
        local busy = ""

        if loc == "1" then
            img_hole_1 = "image_button[2,1;1,1;space_wormhole2.png;btn_hole_1;;true;false]"
            dest = "Forward"
        elseif loc == "2" then
            img_hole_2 = "image_button[2,3;1,1;space_wormhole2.png;btn_hole_2;;true;false]"
            dest = "Backward"
        elseif loc == "3" then
            img_hole_3 = "image_button[1,2;1,1;space_wormhole2.png;btn_hole_3;;true;false]"
            dest = "Left"
        elseif loc == "4" then
            img_hole_4 = "image_button[3,2;1,1;space_wormhole2.png;btn_hole_4;;true;false]"
            dest = "Right"
        else
            dest = "None"
        end
        local nav_label = "label[5.07,3.2;Destination:]" .. "label[5.07,3.5;" .. dest .. "]"
        local busy_bg = "image[0.42,4.15;5.0,0.6;bg2.png]"

        if message ~= nil and message and string.len(message) > 0 then
            busy = busy_bg .. "label[0.5,4.2;" .. minetest.colorize('#f0ce37', message) .. "]"
        end

        if ready and ready > 0 then
            img_hole_1 = ""
            img_hole_2 = ""
            img_hole_3 = ""
            img_hole_4 = ""
            dest = "Locked"
            btn_nav = "label[5,4;" .. minetest.colorize('#8c8c8c', "Interace Locked") .. "]"
            local lbl = minetest.colorize('#ffa600', "Preparing for FTL jump...")
            busy = busy_bg .. "label[0.5,4.2;" .. lbl .. "]"
        end

        local coord_tag = "image[0.7,1.2;4.7,0.9;bg2.png]" .. "label[0.8,1.2;Current Coordinates]"
        local coords_label = coord_tag .. "label[0.8,1.5;X: " .. pos.x .. "]label[2,1.5;Y: " .. pos.y ..
                                 "]label[3.2,1.5;Z: " .. pos.z .. "]"
        local input_field =
            "field[1,3.5;1.4,1;inp_x;Move X;0]field[2.3,3.5;1.4,1;inp_y;Move Y;0]field[3.6,3.5;1.4,1;inp_z;Move Z;0]"

        if is_deepspace then
            formspec = "formspec_version[3]" .. "size[8,6;]" .. "real_coordinates[false]" .. bg .. "label[0,0;" ..
                           machine_desc:format(tier) .. "]" .. btn_prot .. btn_nav .. img_ship .. img_hole_1 ..
                           img_hole_2 .. img_hole_3 .. img_hole_4 .. nav_label .. icon_fan .. icon_env .. icon_eng ..
                           icon_lit .. busy .. message
        else
            formspec = "formspec_version[3]" .. "size[8,6;]" .. "real_coordinates[false]" .. bg .. "label[0,0;" ..
                           machine_desc:format(tier) .. "]" .. btn_prot .. btn_nav .. img_ship .. coords_label ..
                           input_field .. nav_label .. icon_fan .. icon_env .. icon_eng .. icon_lit .. busy .. message
        end
    end

    return formspec
end

function shipyard.engine_do_jump(pos, dest, size, jump_callback, dest_offset)
    local pos1 = vector.subtract(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })
    local pos2 = vector.add(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "shipyard:jump_drive")

    if #nodes == 1 then
        return ship_machine.perform_jump(nodes[1], dest, size, jump_callback, dest_offset)
    end

    jump_callback(-3)
end

function shipyard.engine_jump_activate(pos, dest, size)
    local pos1 = vector.subtract(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })
    local pos2 = vector.add(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "shipyard:jump_drive")

    if #nodes == 1 then
        return ship_machine.perform_jump(nodes[1], dest, size)
    end
    return -3
end

function shipyard.get_jump_dest(pos, offset, size)
    local pos1 = vector.subtract(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })
    local pos2 = vector.add(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "shipyard:jump_drive")

    if #nodes == 1 then
        return #nodes, vector.add(nodes[1], offset)
    end
    return #nodes, nil
end

function shipyard.get_jumpdrive(pos, size)
    local pos1 = vector.subtract(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })
    local pos2 = vector.add(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "shipyard:jump_drive")

    if #nodes == 1 then
        return nodes[1]
    end
    return nil
end

function shipyard.get_protector(pos, size)
    local pos1 = vector.subtract(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })
    local pos2 = vector.add(pos, {
        x = size.w,
        y = size.h,
        z = size.l
    })

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "shipyard:protect2")

    if #nodes == 1 then
        return nodes[1]
    end
    return nil
end

function shipyard.do_particle_effects(pos, amount)
    for i = 0, 3 do
        minetest.after(i, function()   
            shipyard.do_particle_effect(pos, amount);
        end)
    end
end

function shipyard.do_particle_effect(pos, amount)
    local prt = {
        texture = {
            name = "tele_effect03.png",
            alpha = 1.0,
            alpha_tween = {1, 0.0},
            scale_tween = {{
                x = 0.1,
                y = 0
            }, {
                x = 1,
                y = 1
            }}
        },
        texture_r180 = {
            name = "tele_effect03.png" .. "^[transformR180",
            alpha = 1.0,
            alpha_tween = {1, 0.0},
            scale_tween = {{
                x = 0.1,
                y = 0.0
            }, {
                x = 1,
                y = 1
            }}
        },
        vel = 2.7,
        time = 0.85,
        size = 7,
        glow = 9,
        cols = false
    }
    local exm = vector.copy(pos)
    exm.y = exm.y - 2.25
    local rx = math.random(-0.05, 0.05) * 0.2
    local rz = math.random(-0.05, 0.05) * 0.2
    local texture = prt.texture
    if (math.random() >= 0.6) then
        texture = prt.texture_r180
    end

    minetest.add_particlespawner({
        amount = amount,
        time = prt.time + math.random(-0.1, 0.4),
        minpos = {
            x = pos.x - 10,
            y = pos.y - 10,
            z = pos.z - 13
        },
        maxpos = {
            x = pos.x + 10,
            y = pos.y + 10,
            z = pos.z + 13
        },
        minvel = {
            x = rx,
            y = prt.vel * 0.2,
            z = rz
        },
        maxvel = {
            x = rx,
            y = prt.vel * 0.7,
            z = rz
        },
        minacc = {
            x = -0.2,
            y = 0.15,
            z = -0.2
        },
        maxacc = {
            x = 0.2,
            y = 0.23,
            z = 0.2
        },
        minexptime = prt.time * 0.28,
        maxexptime = prt.time * 0.72,
        minsize = prt.size * 0.7,
        maxsize = prt.size * 1.2,
        collisiondetection = prt.cols,
        collision_removal = false,
        object_collision = false,
        vertical = true,
        animation = prt.animation,
        texture = texture,
        glow = prt.glow
    })
end