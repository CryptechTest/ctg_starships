local S = minetest.get_translator(minetest.get_current_modname())

local function round(v)
    return math.floor(v + 0.5)
end

function ship_cube.update_formspec(pos, data, loc, ready, message)
    local meta = minetest.get_meta(pos)
    local machine_name = data.machine_name
    local machine_desc = data.machine_desc .. " - Navigation Interface"
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
    local near_shipyard = vector.distance(pos, spos) <= 192

    if typename == 'ship_cube' then

        local bg = "image[0,0.5;9.78,6.5;starfield_2.png]image[5,3.25;2.2,0.88;bg2.png]"

        local combat_migration_done = meta:get_int("combat_ready") and meta:get_int("combat_ready") > 1 or false
        local combat_migration = combat_migration_done == false and "button[4,5;3,1;submit_migr;Combat Migration]" or ""

        local shipp = ship_cube.get_protector(pos, data.size)
        local ship_meta = minetest.get_meta(shipp)

        -- ship hp
        local ship_hp_max = ship_meta:get_int("hp_max") or 1
        local ship_hp = ship_meta:get_int("hp") or 1
        local ship_hp_prcnt = (ship_hp / ship_hp_max) * 100
        local hp_tag = "image[5.0,1.2;2.2,0.9;bg2.png]" .. "label[5.1,1.2;Hull Integrity]"
        local hp_col = ship_machine.colorize_text_hp(ship_hp, ship_hp_max)
        local hp_prcnt_col = minetest.colorize(hp_col, string.format("%.1f", ship_hp_prcnt) .. "%")
        local hit_points = hp_tag .. "label[5.45,1.55;"..hp_prcnt_col.."]"
        -- shield
        local ship_shield_max = ship_meta:get_int("shield_max") or 1
        local ship_shield = ship_meta:get_int("shield") or 1
        local ship_shield_prcnt = (ship_shield / ship_shield_max) * 100
        local shield_tag = "image[5.0,2.0;2.2,0.9;bg2.png]" .. "label[5.1,2.0;Shield Charge]"
        local shield_col = ship_machine.colorize_text_hp(ship_shield, ship_shield_max)
        local shield_prcnt_col = minetest.colorize(shield_col, string.format("%.1f", ship_shield_prcnt) .. "%")
        local shield_points = shield_tag .. "label[5.45,2.35;"..shield_prcnt_col.."]"
        -- refresh
        local refresh = "image_button[5.65,-0.225;0.8,0.8;ctg_ship_refresh_btn.png;refresh;;true;false;ctg_ship_refresh_btn_press.png]"

        -- damage warning
        local d_warn_bg = "image[0.42,5.1;5.2,0.74;bg2.png]"
        local damage_warn = ""
        if ship_hp_prcnt < 10 then
            local d_mes = "Critical Damage - Defense Offline!"
            damage_warn = d_warn_bg .. "label[0.5,5.2;" .. minetest.colorize('#f02618', d_mes) .. "]"
        elseif ship_hp_prcnt < 40 then
            local d_mes = "Severe Damage - Shield Offline!"
            damage_warn = d_warn_bg .. "label[0.5,5.2;" .. minetest.colorize('#f04a18', d_mes) .. "]"
        elseif ship_meta:get_int("shield_hit") > 0 then
            local d_mes = "Hostile Warning - Recent Attack!"
            damage_warn = d_warn_bg .. "label[0.5,5.2;" .. minetest.colorize('#f0ac18', d_mes) .. "]"
        end
        -- ship owner seize
        local ship_owner = ""
        if ship_hp_prcnt < 10 then
            ship_owner = "button[5,5.0;2.5,1;submit_ctl;Seize Control]"
        end

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
                           img_hole_2 .. img_hole_3 .. img_hole_4 .. damage_warn .. ship_owner ..
                           nav_label .. hit_points .. shield_points ..
                           busy .. combat_migration .. refresh .. message
        else
            formspec = "formspec_version[3]" .. "size[8,6;]" .. "real_coordinates[false]" .. bg .. "label[0,0;" ..
                           machine_desc:format(tier) .. "]" .. btn_prot .. btn_nav --[[.. btn_doc]] .. img_ship ..
                           coords_label .. input_field .. nav_label .. hit_points .. shield_points ..
                           damage_warn .. ship_owner ..
                           busy .. combat_migration .. refresh .. message
        end
    end

    return formspec
end

function ship_cube.engine_do_jump(pos, dest, size, jump_callback, dest_offset)
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

function ship_cube.engine_jump_activate(pos, dest, size)
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

function ship_cube.get_jump_dest(pos, offset, size)
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

function ship_cube.get_jumpdrive(pos, size)
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

function ship_cube.get_protector(pos, size)
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

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "ship_cube:shield_protect")

    if #nodes == 1 then
        return nodes[1]
    end
    return nil
end
