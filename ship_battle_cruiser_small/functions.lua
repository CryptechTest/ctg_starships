local S = minetest.get_translator(minetest.get_current_modname())

local function round(v)
    return math.floor(v + 0.5)
end

function ship_battle_cruiser_small.update_formspec(pos, data, loc, ready, message)
    local machine_name = data.machine_name
    local machine_desc = "Starship Navigation Interface"
    local typename = data.typename
    local tier = data.tier
    local ltier = string.lower(tier)
    local formspec = nil

    local is_deepspace = pos.y > 22000;

    local spos = {
        x = 0,
        y = 5350,
        z = 0
    }
    local near_shipyard = false -- vector.distance(pos, spos) <= 192

    if typename == 'ship_battle_cruiser_small' then

        local bg = "image[0,0.5;9.78,6.5;starfield_2.png]image[5,3.25;2.2,0.88;bg2.png]"

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
        local btn_doc = ""
        local btn_prot = "button[6.5,-0.1;1.5,0.5;protector;Members]"
        local dest = ""
        local busy = ""

        if near_shipyard then
            btn_doc = "button[5,4.8;2,1;submit_dock;Dock Ship]"
        end

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
            btn_doc = ""
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
                           machine_desc:format(tier) .. "]" .. btn_prot .. btn_nav --[[.. btn_doc]] .. img_ship ..
                           coords_label .. input_field .. nav_label .. icon_fan .. icon_env .. icon_eng .. icon_lit ..
                           busy .. message
        end
    end

    return formspec
end

function ship_battle_cruiser_small.engine_do_jump(pos, dest, size, jump_callback, dest_offset)
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

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "group:jumpdrive")

    if #nodes == 1 then
        return ship_machine.perform_jump(nodes[1], dest, size, jump_callback, dest_offset)
    end

    jump_callback(-3)
end

function ship_battle_cruiser_small.engine_jump_activate(pos, dest, size)
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

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "group:jumpdrive")

    if #nodes == 1 then
        return ship_machine.perform_jump(nodes[1], dest, size)
    end
    return -3
end

function ship_battle_cruiser_small.get_jump_dest(pos, offset, size)
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

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "group:jumpdrive")

    if #nodes == 1 then
        return #nodes, vector.add(nodes[1], offset)
    end
    return #nodes, nil
end

function ship_battle_cruiser_small.get_jumpdrive(pos, size)
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

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "group:jumpdrive")

    if #nodes == 1 then
        return nodes[1]
    end
    return nil
end

function ship_battle_cruiser_small.get_protector(pos, size)
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

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "ship_battle_cruiser_small:shield_protect")

    if #nodes == 1 then
        return nodes[1]
    end
    return nil
end
