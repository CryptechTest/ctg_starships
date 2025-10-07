local S = minetest.get_translator(minetest.get_current_modname())

local mese_image_mask = "default_mese_crystal.png^[colorize:#75757555"

-- check if enabled
ship_engine.engine_enabled = function(meta)
    return meta:get_int("enabled") == 1
end

local function round(number, steps)
    steps = steps or 1
    return math.floor(number * steps + 0.5) / steps
end

function ship_engine.update_formspec(data, running, enabled, has_mese, percent, charge, charge_max, eu_input, eu_supply,
    tick, tick_max, digi_channel, editing)
    local machine_name = data.machine_name
    local machine_desc = "Jumpship " .. data.machine_desc
    local typename = data.typename
    local tier = data.tier
    local ltier = string.lower(tier)
    local formspec = nil
    if percent then
        percent = round(percent, 100)
    end
    local digi_channel = digi_channel or machine_name
    local editing = editing or false

    if typename == 'engine' and editing then
        formspec = "size[6,2.75;]" ..
            "background[0.65,0.75;4.35,1.125;console_bg.png]"..
            "field[0.95,1.25;3.2,1;digiline;Digiline Channel;"..digi_channel.."]"..
            "button[3.75,0.95;1.25,1;digiline_save;Save]"

        return formspec
    end

    if typename == 'engine' then
        local tick_percent = round((tick / tick_max) * 100, 100)
        local charge_percent = 0
        if charge and charge > 0 and charge_max then
            charge_percent = round(math.floor(charge / (charge_max) * 100 * 100) / 100, 100)
        end
        local btnName = "State: "
        local btnColor = ""
        if enabled then
            btnName = btnName .. "<Enabled>"
            btnColor = "style[toggle;bgcolor=#34eb7420]"
        else
            btnName = btnName .. "<Disabled>"
            btnColor = "style[toggle;bgcolor=#eb403410]"
        end

        local image = "image[4,1;1,1;" .. "lv_engine_front.png" .. "]"
        if running then
            image = "image[4,1;1,1;" .. "lv_engine_front_active.png" .. "]"
        end
        local meseimg = ""
        if has_mese or running then
            meseimg = "animated_image[5,1;1,1;;" .. "engine_mese_anim.png" .. ";4;400;]"
        end
        local power_field = "label[0.5,2.5;" .. minetest.colorize('#21daff', "Energy Stats") .. "]"
        local input_field = "label[0.5,3.6;Drawing]label[0.5,3.9;" .. minetest.colorize('#fca903', "-" .. eu_input) ..
                                "]"
        local output_field =
            "label[0.5,2.9;Generating]label[0.5,3.2;" .. minetest.colorize('#03fc56', "+" .. eu_supply) .. "]"

        formspec = "size[8,9;]" .. "list[current_name;src;2,1;1,1;]" .. "list[current_name;dst;5,1;1,1;]" ..
                       "list[current_player;main;0,5;8,4;]" .. "label[0,0;" .. machine_desc:format(tier) .. "]" .. image ..
                       meseimg .. "image[3,0.65;1,1;gui_furnace_arrow_bg.png^[lowpart:" .. tostring(tick_percent) ..
                       ":gui_furnace_arrow_fg.png^[transformR270]" .. "listring[current_name;dst]" ..
                       "listring[current_player;main]" .. "listring[current_name;src]" ..
                       "listring[current_player;main]" .. "image[2,1;1,1;" .. mese_image_mask .. "]" ..
                       btnColor .. "button[3,2.5;3,1;toggle;" .. btnName .. "]" .. 
                       "label[2,2;Charge " .. tostring(charge) .. " of " .. tostring(charge_max) .. "]" .. 
                       "label[5,2;" .. tostring(charge_percent) .. "%" .. "]" ..
                       power_field .. input_field .. output_field ..
                       "image[3,1.25;1,1;gui_furnace_arrow_bg.png^[lowpart:" .. tostring(percent) ..
                       ":gui_furnace_arrow_fg.png^[transformR270]" .. "label[4,0.6;" .. tostring(tick_percent) .. "%" ..
                       "]".. -- .. "label[2,0.6;" .. tostring(percent) .. "%" .. "]" ..
                       "button[6.75,3.95;1.25,1;editing;Edit]"..
                       "background[3.65,3.75;4.35,1.125;console_bg.png]"..
                       "field[3.95,4.25;3.2,1;digiline;Digiline Channel;"..digi_channel.."]"
                       --"button[6.75,3.95;1.25,1;digiline_save;Save]"
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
                       ":gui_furnace_arrow_fg.png^[transformR270]" .. "image[2,1;1,1;" .. mese_image_mask ..
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

function ship_engine.get_mese(items, take)
    if not items then
        return nil
    end
    local new_input = nil
    local input_type = 0
    local c = 0;
    for i, stack in ipairs(items) do
        if stack:get_name() == 'default:mese_crystal_fragment' and stack:get_count() >= 9 then
            new_input = ItemStack(stack)
            if take then
                new_input:take_item(9)
            end
            input_type = 9
            c = c + 1
            break
        end
        if stack:get_name() == 'default:mese_crystal_fragment' and stack:get_count() >= 1 then
            new_input = ItemStack(stack)
            if take then
                new_input:take_item(1)
            end
            input_type = 1
            c = c + 1
            break
        end
        if stack:get_name() == 'default:mese_crystal' and stack:get_count() >= 1 then
            new_input = ItemStack(stack)
            if take then
                new_input:take_item(1)
            end
            input_type = 9
            c = c + 1
            break
        end
        if stack:get_name() == 'default:mese' and stack:get_count() >= 1 then
            new_input = ItemStack(stack)
            if take then
                new_input:take_item(1)
            end
            input_type = 81
            c = c + 1
            break
        end
    end
    if (c > 0) then
        return {
            new_input = new_input,
            input_type = input_type,
            count = c
        }
    else
        return nil
    end
end

function ship_engine.needs_charge(pos)
    local meta = minetest.get_meta(pos)
    local charge = meta:get_int("charge")
    local charge_max = meta:get_int("charge_max")
    return charge < charge_max
end

local function reset_charge(pos)
    local meta = minetest.get_meta(pos)
    local charge = meta:get_int("charge")
    local charge_max = meta:get_int("charge_max")
    meta:set_int("charge", charge - charge_max)
end

local function spend_charge(pos, amt)
    local meta = minetest.get_meta(pos)
    local charge = meta:get_int("charge")
    local new_charge = charge - amt
    if new_charge < 0 then
        new_charge = 0
    end
    meta:set_int("charge", new_charge)
end

function ship_engine.ship_jump(pos, chrg)
    spend_charge(pos, chrg)
end

function ship_engine.spawn_particle(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, size, time, amount)
    local texture = {
        name = "ctg_engine_spark.png",
        blend = "alpha",
        scale = 1,
        alpha = 1.0,
        alpha_tween = {1, 0.1},
        scale_tween = {{
            x = 1.5,
            y = 1.5
        }, {
            x = 0.1,
            y = 0.25
        }}
    }

    local prt = {
        texture = texture,
        vel = 1,
        time = (time or 6),
        size = (size or 1),
        glow = math.random(6, 10),
        cols = false
    }

    local rx = dir_x * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
    local ry = dir_y * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
    local rz = dir_z * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
    minetest.add_particlespawner({
        amount = amount,
        -- pos = pos,
        minpos = {
            x = pos.x + -0.35,
            y = pos.y + -0.35,
            z = pos.z + -0.35
        },
        maxpos = {
            x = pos.x + 0.35,
            y = pos.y + 0.35,
            z = pos.z + 0.35
        },
        minvel = {
            x = rx * 0.8,
            y = ry * 0.8,
            z = rz * 0.8
        },
        maxvel = {
            x = rx,
            y = ry,
            z = rz
        },
        minacc = {
            x = acl_x,
            y = acl_y,
            z = acl_z
        },
        maxacc = {
            x = acl_x,
            y = acl_y,
            z = acl_z
        },
        time = prt.time + 2,
        minexptime = prt.time - math.random(1, 3),
        maxexptime = prt.time,
        minsize = ((math.random(0.57, 0.63)) * 2 + 1.6) * prt.size,
        maxsize = ((math.random(0.77, 0.93)) * 2 + 1.6) * prt.size,
        collisiondetection = prt.cols,
        vertical = false,
        texture = texture,
        -- animation = animation,
        glow = prt.glow
    })
end
