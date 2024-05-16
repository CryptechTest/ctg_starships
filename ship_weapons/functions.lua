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
    if is_owner(meta, name) or ship_weapons.is_member(meta, name) then
        return
    end

    local list = get_member_list(meta)

    if #list >= 28 then
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
        formspec = "formspec_version[3]" .. "size[8,9;]" .. "real_coordinates[false]" .. "label[0,0;" ..
                       machine_desc:format(tier) .. "]" .. attacks .. "button[5,0.525;3,1;toggle;" .. btnName .. "]" ..
                       members_list
    end
    if data.upgrade then
        formspec = formspec .. "list[current_name;upgrade1;0.5,3;1,1;]" .. "list[current_name;upgrade2;1.5,3;1,1;]" ..
                       "label[0.5,4;" .. S("Upgrade Slots") .. "]" .. "listring[current_name;upgrade1]" ..
                       "listring[current_player;main]" .. "listring[current_name;upgrade2]" ..
                       "listring[current_player;main]"
    end
    return formspec
end
