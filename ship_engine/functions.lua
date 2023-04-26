local S = minetest.get_translator(minetest.get_current_modname())

-- check if enabled
ship_engine.engine_enabled = function(meta)
    return meta:get_int("enabled") == 1
end

local function round(number, steps)
    steps = steps or 1
    return math.floor(number * steps + 0.5) / steps
end

function ship_engine.update_formspec(data, running, enabled, has_mese, percent, charge, charge_max)
    local machine_name = data.machine_name
    local machine_desc = "Starship " .. data.machine_desc
    local typename = data.typename
    local tier = data.tier
    local ltier = string.lower(tier)
    local formspec = nil
    percent = round(percent, 2)

    if typename == 'engine' then
        local charge_percent = 0
        if charge and charge > 0 and charge_max then
            charge_percent = (math.floor(charge / (charge_max) * 100 * 100) / 100)
        end
        local btnName = "State: "
        if enabled then
            btnName = btnName .. "<Enabled>"
        else
            btnName = btnName .. "<Disabled>"
        end

        local image = "image[4,1;1,1;" .. "lv_engine_front.png" .. "]"
        if running then
            image = "image[4,1;1,1;" .. "lv_engine_front_active.png" .. "]"
        end
        local meseimg = ""
        if has_mese or running then
            meseimg = "animated_image[5,1;1,1;;" .. "engine_mese_anim.png" .. ";4;400;]"
        end
        formspec = "size[8,9;]" .. "list[current_name;src;2,1;1,1;]" .. "list[current_name;dst;5,1;1,1;]" ..
                       "list[current_player;main;0,5;8,4;]" .. "label[0,0;" .. machine_desc:format(tier) .. "]" .. image ..
                       meseimg .. "image[3,1;1,1;gui_furnace_arrow_bg.png^[lowpart:" .. tostring(percent) ..
                       ":gui_furnace_arrow_fg.png^[transformR270]" .. "listring[current_name;dst]" ..
                       "listring[current_player;main]" .. "listring[current_name;src]" ..
                       "listring[current_player;main]" .. "image[2,1;1,1;" .. ship_engine.mese_image_mask .. "]" ..
                       "button[3,3;4,1;toggle;" .. btnName .. "]" .. "label[2,2;Charge " .. tostring(charge) .. " of " ..
                       tostring(charge_max) .. "]" .. "label[5,2;" .. tostring(charge_percent) .. "%" .. "]"
    end

    if typename == 'engine_core' then
        local charge_percent = 0
        if charge and charge > 0 and charge_max then
            charge_percent = round(math.floor(charge / (charge_max) * 100 * 100) / 100, 2)
        end
        if charge == nil then
            charge = 0
        end
        if charge_max == nil then
            charge_max = 0
        end
        local btnName = "State: "
        if enabled then
            btnName = btnName .. "<Enabled>"
        else
            btnName = btnName .. "<Disabled>"
        end

        local image = "image[4,1;1,1;" .. "lv_engine_front.png" .. "]"
        if running then
            image = "image[4,1;1,1;" .. "lv_engine_front_active.png" .. "]"
        end
        local meseimg = ""
        if has_mese or running then
            meseimg = "animated_image[5,1;1,1;;" .. "engine_mese_anim.png" .. ";4;400;]"
        end
        formspec = "size[8,5;]" .. "label[0,0;" .. machine_desc:format(tier) .. "]" .. image .. meseimg ..
                       "image[3,1;1,1;gui_furnace_arrow_bg.png^[lowpart:" .. tostring(percent) ..
                       ":gui_furnace_arrow_fg.png^[transformR270]" .. "image[2,1;1,1;" .. ship_engine.mese_image_mask ..
                       "]" .. "button[2,3;4,1;toggle;" .. btnName .. "]" .. "label[2,2;Charge " .. tostring(charge) ..
                       " of " .. tostring(charge_max) .. "]" .. "label[5,2;" .. tostring(charge_percent) .. "%" .. "]"
    end

    if data.upgrade then
        formspec = formspec .. "list[current_name;upgrade1;1,3;1,1;]" .. "list[current_name;upgrade2;2,3;1,1;]" ..
                       "label[1,4;" .. S("Upgrade Slots") .. "]" .. "listring[current_name;upgrade1]" ..
                       "listring[current_player;main]" .. "listring[current_name;upgrade2]" ..
                       "listring[current_player;main]"
    end
    return formspec
end
