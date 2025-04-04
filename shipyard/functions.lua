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

        local shipp = ship_machine.get_protector(pos, data.size)
        if not shipp then
            return nil
        end
        local ship_meta = minetest.get_meta(shipp)

        -- ship hp
        local ship_hp_max = ship_meta:get_int("hp_max") or 1
        local ship_hp = ship_meta:get_int("hp") or 1
        local ship_hp_prcnt = (ship_hp / ship_hp_max) * 100
        local hp_tag = "image[5.0,1.2;2.2,0.9;bg2.png]" .. "label[5.1,1.2;Hull Integrity]"
        local hp_col = ship_machine.colorize_text_hp(ship_hp, ship_hp_max)
        local hp_prcnt_col = minetest.colorize(hp_col, string.format("%.1f", ship_hp_prcnt) .. "%")
        local hit_points = hp_tag .. "label[5.45,1.55;" .. hp_prcnt_col .. "]"
        -- shield
        local ship_shield_max = ship_meta:get_int("shield_max") or 1
        local ship_shield = ship_meta:get_int("shield") or 1
        local ship_shield_prcnt = (ship_shield / ship_shield_max) * 100
        local shield_tag = "image[5.0,2.0;2.2,0.9;bg2.png]" .. "label[5.1,2.0;Shield Charge]"
        local shield_col = ship_machine.colorize_text_hp(ship_shield, ship_shield_max)
        local shield_prcnt_col = minetest.colorize(shield_col, string.format("%.1f", ship_shield_prcnt) .. "%")
        local shield_points = shield_tag .. "label[5.45,2.35;" .. shield_prcnt_col .. "]"
        -- refresh
        local refresh =
            "image_button[5.65,-0.225;0.8,0.8;ctg_ship_refresh_btn.png;refresh;;true;false;ctg_ship_refresh_btn_press.png]"

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

        local combat_migration_done = meta:get_int("combat_ready") > 0 or 0
        local combat_migration =
            (combat_migration_done == false and "button[4,5.25;3,1;submit_migr;Combat Migration]") or ""

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

        local holo = "image_button[4.85,-0.225;0.8,0.8;ctg_radar_on.png;holo;;true;false]"

        if is_deepspace then
            formspec = "formspec_version[3]" .. "size[8,6;]" .. "real_coordinates[false]" .. bg .. "label[0,0;" ..
                           machine_desc:format(tier) .. "]" .. btn_prot .. btn_nav .. img_ship .. img_hole_1 ..
                           img_hole_2 .. img_hole_3 .. img_hole_4 .. damage_warn .. nav_label .. holo .. refresh ..
                           hit_points .. shield_points .. busy .. message
        else
            formspec = "formspec_version[3]" .. "size[8,6;]" .. "real_coordinates[false]" .. bg .. "label[0,0;" ..
                           machine_desc:format(tier) .. "]" .. btn_prot .. btn_nav .. img_ship .. coords_label ..
                           input_field .. damage_warn .. nav_label .. holo .. refresh ..
                           hit_points .. shield_points .. busy .. message
        end
    end

    return formspec
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

    local nodes = minetest.find_nodes_in_area(pos1, pos2, "shipyard:shield_protect")

    local drive = nil
    for _, p in pairs(nodes) do
        local ship_meta = minetest.get_meta(p)
        local _size = {
            w = ship_meta and ship_meta:get_int("p_width") or size.w,
            l = ship_meta and ship_meta:get_int("p_length") or size.l,
            h = ship_meta and ship_meta:get_int("p_height") or size.h
        }
        if pos.x <= p.x + _size.w and pos.x >= p.x - _size.w then
            if pos.z <= p.z + _size.l and pos.z >= p.z - _size.l then
                if pos.y <= p.y + _size.h and pos.y >= p.y - _size.h then
                    drive = p
                end
            end
        end
        if drive ~= nil then
            break
        end
    end

    if drive then
        return drive
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
