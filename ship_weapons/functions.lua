local function round(v)
    return math.floor(v + 0.5)
end

-- return list of members as a table
local get_member_list = function(meta)

    return meta:get_string("members"):split(" ")
end

-- write member list table in protector meta as string
local set_member_list = function(meta, list)

    meta:set_string("members", table.concat(list, " "))
end

-- check for owner name
local is_owner = function(meta, name)

    return name == meta:get_string("owner")
end

-- check for member name
ship_weapons.is_member = function(meta, name)

    for _, n in pairs(get_member_list(meta)) do

        if n == name then
            return true
        end
    end

    return false
end

-- add player name to table as member
ship_weapons.add_member = function(meta, name)

    -- Validate player name for MT compliance
    if name ~= string.match(name, "[%w_-]+") then
        return
    end

    -- Constant (20) defined by player.h
    if name:len() > 25 then
        return
    end

    -- does name already exist?
    if is_owner(meta, name) or ship_weapons.is_member(meta, name) or ship_machine.is_ally(meta, name) then
        return
    end

    local list = get_member_list(meta)

    if #list >= 16 then
        return
    end

    table.insert(list, name)

    set_member_list(meta, list)
end

-- remove player name from table
ship_weapons.del_member = function(meta, name)

    local list = get_member_list(meta)

    for i, n in pairs(list) do

        if n == name then
            table.remove(list, i)
            break
        end
    end

    set_member_list(meta, list)
end

----------------------------------------------------

-- return list of allies as a table
local get_ally_list = function(meta)
    return meta:get_string("allies"):split(" ")
end

-- write ally list table in protector meta as string
local set_ally_list = function(meta, list)
    meta:set_string("allies", table.concat(list, " "))
end

-- check for ally name
ship_weapons.is_ally = function(meta, name)
    for _, n in pairs(get_ally_list(meta)) do
        if n == name then
            return true
        end
    end
    return false
end

-- add player name to table as ally
ship_weapons.add_ally = function(meta, name)
    -- Validate player name for MT compliance
    if name ~= string.match(name, "[%w_-]+") then
        return
    end
    -- Constant (20) defined by player.h
    if name:len() > 25 then
        return
    end
    -- does name already exist?
    if is_owner(meta, name) or ship_machine.is_member(meta, name) or ship_machine.is_ally(meta, name) then
        return
    end
    local list = get_ally_list(meta)
    if #list >= 16 then
        return
    end
    table.insert(list, name)
    set_ally_list(meta, list)
end

-- remove player name from table
ship_weapons.del_ally = function(meta, name)
    local list = get_ally_list(meta)
    for i, n in pairs(list) do
        if n == name then
            table.remove(list, i)
            break
        end
    end
    set_ally_list(meta, list)
end

----------------------------------------------------

function ship_weapons.get_port_direction(pos)
    local node = minetest.get_node(pos)
    local param2 = node.param2
    local dir_x = 0.0
    local dir_z = 0.0
    local dir_y = 0.0
    if param2 == 1 then -- west
        dir_x = -1
    elseif param2 == 2 then -- north?
        dir_z = 1
    elseif param2 == 3 then -- east
        dir_x = 1
    elseif param2 == 0 then -- south
        dir_z = -1
    elseif param2 == 8 or param2 == 15 or param2 == 6 then
        -- down
        dir_y = -1
    elseif param2 == 10 or param2 == 13 or param2 == 4 then
        -- up
        dir_y = 1
    end
    return {
        x = dir_x,
        y = dir_y,
        z = dir_z
    }
end

-------------------------------------------------------

function ship_weapons.update_formspec(data, meta)
    local tier = data.tier
    local ltier = string.lower(tier)
    local machine_name = data.machine_name
    local machine_desc = tier .. " " .. data.machine_desc
    local typename = data.typename
    local formspec = nil

    local charge = meta:get_int("charge") or 0
    local charge_max = meta:get_int("charge_max") or 1
    local attack_index = meta:get_int("attack_type") or 1
    local enabled = meta:get_int("enabled") == 1

    if typename == 'beam_tower' then
        -- BEAM TOWER

        local charge_percent = 0
        if charge and charge > 0 and charge_max then
            charge_percent = round(math.floor(charge / (charge_max) * 100 * 100) / 100, 2)
        elseif charge == 0 and charge_max == 0 then
            charge_percent = 100
        end
        local btnName = "State: "
        if enabled then
            btnName = btnName .. "<Enabled>"
        else
            btnName = btnName .. "<Disabled>"
        end

        local attack_type = "None"
        if attack_index == 1 then
            attack_type = "None"
        elseif attack_index == 2 then
            attack_type = "Any"
        elseif attack_index == 3 then
            attack_type = "Monster"
        elseif attack_index == 4 then
            attack_type = "Player"
        elseif attack_index == 5 then
            attack_type = "Monster/Player"
        end

        local attacks = "label[0,0.8;Attack:]" .. -- "label[3.2,0;" .. attack_type .. "]" ..
                            "dropdown[1.2,0.6;3,0.5;attack_type;None,Any,Monster,Player,Monster/Player;" .. attack_index ..
                            "]"

        local members_list = "label[0,1.35;" .. S("Members:") .. "]" .. "button_exit[6,0.1;2,0.25;close_me;" ..
                                 S("Close") .. "]" .. "field_close_on_enter[add_member;false]"

        if meta then
            local members = get_member_list(meta)
            local npp = 28
            local i = 0
            for n = 1, #members do
                if i < npp then
                    -- show username
                    members_list = members_list .. "button[" .. (i % 4 * 2) .. "," .. math.floor(i / 4 + 2) ..
                                       ";1.5,.5;member;" .. (members[n]) .. "]" -- username remove button
                    .. "button[" .. (i % 4 * 2 + 1.25) .. "," .. math.floor(i / 4 + 2) .. ";.75,.5;del_member_" ..
                                       (members[n]) .. ";X]"
                end
                i = i + 1
            end
            if i < npp then
                -- user name entry field
                members_list =
                    members_list .. "field[" .. (i % 4 * 2 + 1 / 3) .. "," .. (math.floor(i / 4 + 2) + 1 / 3) ..
                        ";1.433,.5;add_member;;]" -- username add button
                    .. "button[" .. (i % 4 * 2 + 1.25) .. "," .. math.floor(i / 4 + 2) .. ";.75,.5;submit;+]"
            end
        end

        -- "list[current_player;main;0,5;8,4;]" .. "listring[current_player;main]" .. 
        formspec = "formspec_version[3]" .. "size[8,9;]" .. "real_coordinates[false]" .. "label[0,0;" .. machine_desc ..
                       "]" .. attacks .. "button[5,0.525;3,1;toggle;" .. btnName .. "]" .. members_list
    elseif typename == 'missile_tower' then
        -- MISSILE TOWER

        local btnName = "State: "
        if enabled then
            btnName = btnName .. "<Enabled>"
        else
            btnName = btnName .. "<Disabled>"
        end

        formspec = "formspec_version[8]" .. "size[6.5,3]" .. "label[0.2,0.3;" .. machine_desc:format(tier) .. "]" ..
                       "label[0.2,0.3;]" .. "button[1,1;3,1;toggle;" .. btnName .. "]" ..
                       "list[current_name;src;4.5,1;1,1;]"

    elseif typename == 'missile_tower_old' then
        -- MISSILE TOWER

        local charge_percent = 0
        if charge and charge > 0 and charge_max then
            charge_percent = round(math.floor(charge / (charge_max) * 100 * 100) / 100, 2)
        elseif charge == 0 and charge_max == 0 then
            charge_percent = 100
        end
        local btnName = "State: "
        if enabled then
            btnName = btnName .. "<Enabled>"
        else
            btnName = btnName .. "<Disabled>"
        end

        local attack_type = "None"
        if attack_index == 1 then
            attack_type = "None"
            -- elseif attack_index == 2 then
            -- attack_type = "Any"
        elseif attack_index == 3 then
            attack_type = "Monster"
        elseif attack_index == 4 then
            attack_type = "Player"
        elseif attack_index == 5 then
            attack_type = "Monster/Player"
        end

        local attacks = "label[0,0.8;Attack:]" .. -- "label[3.2,0;" .. attack_type .. "]" ..
                            "dropdown[1.2,0.6;3,0.5;attack_type;None,Monster,Player,Monster/Player;" .. attack_index ..
                            "]"

        local members_list = "label[0,1.35;" .. S("Members:") .. "]" .. "button_exit[6,0.1;2.2,0.25;close_me;" ..
                                 S("Close") .. "]" .. "field_close_on_enter[add_member;false]"

        if meta then
            local members = get_member_list(meta)
            local npp = 28
            local i = 0
            for n = 1, #members do
                if i < npp then
                    -- show username
                    members_list = members_list .. "button[" .. (i % 4 * 2) .. "," .. math.floor(i / 4 + 2) ..
                                       ";1.5,.5;member;" .. (members[n]) .. "]" -- username remove button
                    .. "button[" .. (i % 4 * 2 + 1.25) .. "," .. math.floor(i / 4 + 2) .. ";.75,.5;del_member_" ..
                                       (members[n]) .. ";X]"
                end
                i = i + 1
            end
            if i < npp then
                -- user name entry field
                members_list =
                    members_list .. "field[" .. (i % 4 * 2 + 1 / 3) .. "," .. (math.floor(i / 4 + 2) + 1 / 3) ..
                        ";1.433,.5;add_member;;]" -- username add button
                    .. "button[" .. (i % 4 * 2 + 1.25) .. "," .. math.floor(i / 4 + 2) .. ";.75,.5;submit;+]"
            end
        end

        local inv = "list[current_name;src;4.25,0.5;1,1;]"

        -- "list[current_player;main;0,5;8,4;]" .. "listring[current_player;main]" .. 
        formspec = "formspec_version[3]" .. "size[8,9;]" .. "real_coordinates[false]" .. inv .. "label[0,0;" ..
                       machine_desc:format(tier) .. "]" .. attacks .. "button[5.5,0.525;2.7,1;toggle;" .. btnName .. "]" ..
                       members_list
    elseif typename == 'target_computer' then
        -- TARGET COMPUTER

        local mode_index = meta:get_int("attack_mode") or 1
        local sel = meta:get_int("selected_dir")
        local lock = meta:get_int("target_locked")
        local select = (mode_index == 1 and ((lock == 1 and "^[colorize:green:25") or "^[colorize:yellow:25")) or ''
        local disabled = (mode_index > 1 and "^[colorize:black:120") or ''

        if mode_index > 1 then
            sel = 0
        end

        local b1_sel = (sel == 1 and select) or disabled
        local b2_sel = (sel == 2 and select) or disabled
        local b3_sel = (sel == 3 and select) or disabled
        local b4_sel = (sel == 4 and select) or disabled
        local b5_sel = (sel == 5 and select) or disabled
        local b6_sel = (sel == 6 and select) or disabled
        local b7_sel = (sel == 7 and select) or disabled
        local b8_sel = (sel == 8 and select) or disabled
        local b9_sel = (sel == 9 and select) or disabled
        local b10_sel = (sel == 10 and select) or disabled
        local b11_sel = (sel == 11 and select) or disabled
        local b12_sel = (sel == 12 and select) or disabled
        local b13_sel = (sel == 13 and select) or disabled
        local b14_sel = (sel == 14 and select) or disabled
        local b15_sel = (sel == 15 and select) or disabled
        local b16_sel = (sel == 16 and select) or disabled
        local b17_sel = (sel == 17 and select) or disabled
        local b18_sel = (sel == 18 and select) or disabled
        local b19_sel = (sel == 19 and select) or disabled
        local b20_sel = (sel == 20 and select) or disabled
        local b21_sel = (sel == 21 and select) or disabled
        local b22_sel = (sel == 22 and select) or disabled
        local b23_sel = (sel == 23 and select) or disabled
        local b24_sel = (sel == 24 and select) or disabled
        local b25_sel = (sel == 25 and select) or disabled

        local fsetup =
            "image_button[1,1;1,1;b1.png" .. b1_sel .. ";btn1;]" .. "image_button[2,1;1,1;b6.png" .. b6_sel .. ";btn6;]" ..
                "image_button[3,1;1,1;b11.png" .. b11_sel .. ";btn11;]" .. "image_button[4,1;1,1;b16.png" .. b16_sel ..
                ";btn16;]" .. "image_button[5,1;1,1;b21.png" .. b21_sel .. ";btn21;]" .. "image_button[1,2;1,1;b2.png" ..
                b2_sel .. ";btn2;]" .. "image_button[2,2;1,1;b7.png" .. b7_sel .. ";btn7;]" ..
                "image_button[3,2;1,1;b12.png" .. b12_sel .. ";btn12;]" .. "image_button[4,2;1,1;b17.png" .. b17_sel ..
                ";btn17;]" .. "image_button[5,2;1,1;b22.png" .. b22_sel .. ";btn22;]" .. "image_button[1,3;1,1;b3.png" ..
                b3_sel .. ";btn3;]" .. "image_button[2,3;1,1;b8.png" .. b8_sel .. ";btn8;]" ..
                "image_button[3,3;1,1;b13.png" .. b13_sel .. ";btn13;]" .. "image_button[4,3;1,1;b18.png" .. b18_sel ..
                ";btn18;]" .. "image_button[5,3;1,1;b23.png" .. b23_sel .. ";btn23;]" .. "image_button[1,4;1,1;b4.png" ..
                b4_sel .. ";btn4;]" .. "image_button[2,4;1,1;b9.png" .. b9_sel .. ";btn9;]" ..
                "image_button[3,4;1,1;b14.png" .. b14_sel .. ";btn14;]" .. "image_button[4,4;1,1;b19.png" .. b19_sel ..
                ";btn19;]" .. "image_button[5,4;1,1;b24.png" .. b24_sel .. ";btn24;]" .. "image_button[1,5;1,1;b5.png" ..
                b5_sel .. ";btn5;]" .. "image_button[2,5;1,1;b10.png" .. b10_sel .. ";btn10;]" ..
                "image_button[3,5;1,1;b15.png" .. b15_sel .. ";btn15;]" .. "image_button[4,5;1,1;b20.png" .. b20_sel ..
                ";btn20;]" .. "image_button[5,5;1,1;b25.png" .. b25_sel .. ";btn25;]"

        local btnName = ""
        if enabled then
            btnName = btnName .. "ON"
        else
            btnName = btnName .. "OFF"
        end
        local btn_toggle = "button[6.5,3;2,1;toggle;" .. btnName .. "]"

        local inp_power = meta:get_float("target_power")
        local inp_pitch = meta:get_float("target_pitch")
        local inp_yaw = meta:get_float("target_yaw")

        local input_field = "field[1,6.5;1.4,1;inp_power;Power;" .. inp_power .. "]" ..
                                "field[2.3,6.5;1.4,1;inp_pitch;Pitch;" .. inp_pitch .. "]" ..
                                "field[3.6,6.5;1.4,1;inp_yaw;Yaw;" .. inp_yaw .. "]"

        local inp_delay = meta:get_int("target_delay")
        local input_delay = "field[6.5,5;2,1;inp_delay;Delay;" .. inp_delay .. "]"

        local inp_count = meta:get_int("target_count")
        local input_count = "field[6.5,3;2,1;inp_count;Count;" .. inp_count .. "]"

        local input_mode = "label[6.5,2.8;Attack:]" ..
                               "dropdown[6.5,3.0;2,1;attack_mode;Manual,Automatic,Auto Player,Auto Ship;" .. mode_index ..
                               "]"

        local num_error = meta:get_int("target_error_number")
        local btn_tgt_clr = (num_error == 1 and "style[submit_target;bgcolor=#eb403410]") or
                                (lock == 1 and "style[submit_target;bgcolor=#38c72c05]") or ""
        if mode_index > 1 then
            btn_tgt_clr = "style[submit_target;bgcolor=#34ebe510]"
        end
        local btn_tgt = btn_tgt_clr .. "button[5.5,6.5;3,1;submit_target;Target Lock]"
        local btn_lnc_clr = (mode_index > 1 and "^[colorize:black:150") or ''
        local btn_lnc = "image_button[6.5,1.0;2,1;b_launch.png" .. btn_lnc_clr ..
                            ";submit_launch;Launch;0;1;b_launch_press.png" .. btn_lnc_clr .. "]"

        -- "list[current_player;main;0,5;8,4;]" .. "listring[current_player;main]" .. 
        formspec = "formspec_version[8]" .. "size[9.5,8]" .. "label[0.2,0.3;" .. machine_desc:format(tier) .. "]" ..
                       fsetup .. input_field .. btn_tgt .. btn_lnc .. input_delay ..
                       ((ltier == "lv" and input_count) or input_mode)
    end

    if data.upgrade then
        formspec = formspec .. "list[current_name;upgrade1;0.5,3;1,1;]" .. "list[current_name;upgrade2;1.5,3;1,1;]" ..
                       "label[0.5,4;" .. S("Upgrade Slots") .. "]" .. "listring[current_name;upgrade1]" ..
                       "listring[current_player;main]" .. "listring[current_name;upgrade2]" ..
                       "listring[current_player;main]"
    end
    return formspec
end
