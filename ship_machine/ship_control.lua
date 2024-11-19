local S = minetest.get_translator(minetest.get_current_modname())

local function isInteger(str)
    return tonumber(str) ~= nil
end

local function update_formspec_nav(pos, data, message)
    local meta = minetest.get_meta(pos)
    local machine_name = data.machine_name
    local machine_desc = data.machine_desc .. " - Navigation"
    local typename = data.typename
    local tier = data.tier
    local ltier = string.lower(tier)

    local is_deepspace = pos.y > 22000;
    local loc = meta:get_int("dest_dir")
    local ready = meta:get_int("travel_ready")

    -- shipyard position...
    local spos = {
        x = 0,
        y = 5350,
        z = 0
    }

    local near_shipyard = false
    if typename == 'ship_raider' or typename == "ship_scout" then
        near_shipyard = vector.distance(pos, spos) <= 192
    end
    local near_docks = false
    if typename ~= 'shipyard' then
        near_docks = ship_dock.get_docks(pos, data.size)
    end

    local formspec = nil
    if typename ~= '' then

        -- formspec defintion 
        local fspec = "formspec_version[3]" .. "size[8,7;]" .. "real_coordinates[false]"

        -- background
        local bg_main = "image[0,0.5;9.78,7.5;starfield_2.png]"
        local bg_coord = "image[5,3.25;2.2,0.88;bg2.png]"
        local bg_form = bg_main  .. bg_coord

        -- get ship protector
        local shipp = ship_machine.get_protector(pos, data.size)
        if not shipp then
            return fspec .. bg_form
        end
        local ship_meta = minetest.get_meta(shipp)

        -- ship details
        local det_txt1 = minetest.colorize("#a4d0e0", "Jump Range:  " .. data.min_dist .. " - " .. data.jump_dist .. " Meters")
        local det_txt2 = minetest.colorize("#9bd1c4", "Hull Rating: " .. data.hp)
        local detail = "image[0.7,0.6;8.25,0.6;bg2.png]" .. "label[0.8,0.625;".. det_txt1 .."]" .. "label[5,0.625;".. det_txt2 .."]"

        -- combat migrations
        local combat_migration_done = meta:get_int("combat_ready") and meta:get_int("combat_ready") > 1 or false
        local combat_migration = combat_migration_done == false and "button[4,5;3,1;submit_migr;Combat Migration]" or ""

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

        -- holo toggle button
        local btn_holo = "image_button[6.05,-0.225;0.8,0.8;ctg_radar_on.png;holo;;true;false]"
        -- refresh button
        local btn_ref = "image_button[6.85,-0.225;0.8,0.8;ctg_ship_refresh_btn.png;refresh;;true;false;ctg_ship_refresh_btn_press.png]"
        -- members protect button
        local btn_prot = "button[0.7,5.7;2.0,1;prot_crew;Crew Members]"
        local btn_ally = "button[2.55,5.7;1.5,1;prot_ally;Allies]"

        -- damage warning
        local damage_warn = ""
        local d_warn_bg = "image[0.42,5.1;5.2,0.74;bg2.png]"
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
        
        -- docking button
        local btn_doc = ""
        if near_shipyard and ship_hp_prcnt >= 10 then
            btn_doc = "button[5,5.7;2.5,1;submit_dock;Station Dock]"
        elseif near_docks and #near_docks > 0 and combat_migration_done and ship_hp_prcnt >= 10 then
            local items = {}
            local index = 1
            local dock_name = meta:get_string("dock_with")
            for i, item in pairs(near_docks) do
                table.insert(items, item.name)
                if item.name == dock_name then
                    index = i
                end
            end
            local ddrop = "dropdown[5,5;2.5,1;dock_name;"..table.concat(items, ",")..";"..index..";]"
            btn_doc = ddrop .. "button[5,5.7;2.5,1;submit_dock2;Dock]"
        end

        -- deepspace
        local img_ship = "image[2.2,2;1,1;starship_icon.png]"
        local img_hole_1 = "image_button[2,1;1,1;space_wormhole1.png;btn_hole_1;;true;false;space_wormhole2.png]" -- top
        local img_hole_2 = "image_button[2,3;1,1;space_wormhole1.png;btn_hole_2;;true;false;space_wormhole2.png]" -- bottom
        local img_hole_3 = "image_button[1,2;1,1;space_wormhole1.png;btn_hole_3;;true;false;space_wormhole2.png]" -- left
        local img_hole_4 = "image_button[3,2;1,1;space_wormhole1.png;btn_hole_4;;true;false;space_wormhole2.png]" -- right
        local dest_dir = ""
        if loc == 1 then
            img_hole_1 = "image_button[2,1;1,1;space_wormhole2.png;btn_hole_1;;true;false]"
            dest_dir = "Forward"
        elseif loc == 2 then
            img_hole_2 = "image_button[2,3;1,1;space_wormhole2.png;btn_hole_2;;true;false]"
            dest_dir = "Backward"
        elseif loc == 3 then
            img_hole_3 = "image_button[1,2;1,1;space_wormhole2.png;btn_hole_3;;true;false]"
            dest_dir = "Left"
        elseif loc == 4 then
            img_hole_4 = "image_button[3,2;1,1;space_wormhole2.png;btn_hole_4;;true;false]"
            dest_dir = "Right"
        else
            dest_dir = "Nowhere"
        end
        -- coord nav
        local coord_tag = "image[0.7,1.2;4.7,0.9;bg2.png]" .. "label[0.8,1.2;Current Coordinates]"
        local coords_label = coord_tag .. "label[0.8,1.5;X: " .. pos.x .. "]label[2,1.5;Y: " .. pos.y .. "]label[3.2,1.5;Z: " .. pos.z .. "]"
        local input_field = "field[1,3.5;1.4,1;inp_x;Move X;0]field[2.3,3.5;1.4,1;inp_y;Move Y;0]field[3.6,3.5;1.4,1;inp_z;Move Z;0]"

        local busy_label = ""
        local bg_msg = "image[0.45,4.15;5.0,0.7;bg2.png]"
        -- nav submit button
        local btn_nav = "button[5,4;2,1;submit_nav;Make it so]"
        -- ready jump message
        if ready and ready > 0 then
            img_hole_1 = ""
            img_hole_2 = ""
            img_hole_3 = ""
            img_hole_4 = ""
            dest_dir = "Locked"
            btn_nav = "label[5,4;" .. minetest.colorize('#8c8c8c', "Interace Locked") .. "]"
            local msg = minetest.colorize('#ffa600', "Preparing for FTL jump...")
            busy_label = bg_msg .. "label[0.5,4.2;" .. msg .. "]"
            ship_owner = ""
            btn_doc = ""
        end
        -- dest nav label
        local nav_label = "label[5.07,3.2;Destination:]" .. "label[5.07,3.5;" .. dest_dir .. "]"

        -- messages
        if message ~= nil and message and string.len(message) > 0 then
            busy_label = bg_msg .. "label[0.5,4.2;" .. minetest.colorize('#f0ce37', message) .. "]"
        end

        -- form setup
        local form_basic = fspec .. bg_form .. "label[0,0;" .. machine_desc:format(tier) .. "]" .. detail

        if is_deepspace then
            local dspace_input = img_hole_1 .. img_hole_2 .. img_hole_3 .. img_hole_4
            formspec = form_basic .. btn_prot .. btn_ally .. img_ship .. dspace_input .. btn_nav ..
                        damage_warn .. ship_owner .. nav_label .. btn_holo .. btn_doc ..
                        hit_points .. shield_points .. busy_label .. combat_migration .. btn_ref .. message
        else
            local coords_input = coords_label .. input_field
            formspec = form_basic .. btn_prot .. btn_ally .. img_ship .. coords_input .. btn_nav ..
                        damage_warn .. ship_owner .. nav_label .. btn_holo .. btn_doc ..
                        hit_points .. shield_points .. busy_label .. combat_migration .. btn_ref .. message
        end
    end

    return formspec
end

----------------------------------------------------
----------------------------------------------------
----------------------------------------------------

function ship_machine.register_control_console(custom_data)

    local def = custom_data or {}

    def.size = custom_data.size;
    def.tier = custom_data.tier or "LV"
    def.typename = custom_data.typename or "ship_basic"
    def.modname = custom_data.modname or "ship_machine"
    def.machine_name = custom_data.machine_name or "Jumpship"
    def.machine_desc = custom_data.machine_desc or "Jumpship"
    def.do_docking = custom_data.do_docking or false
    def.jump_dist = custom_data.jump_dist or 1000
    def.min_dist = custom_data.min_dist or 15
    def.groups = custom_data.groups or {}

    local modname = def.modname
    local ltier = string.lower(def.tier)
    local machine_name = def.machine_name
    local machine_desc = def.machine_desc
    local lmachine_name = string.lower(machine_name)

    local groups = {
        cracky = 2,
        metal = 1,
        level = 1,
        starship = 1,
        jumpship = 1,
        jumpship_control = 1,
        not_in_creative_inventory = 1
    }
    for k, v in pairs(def.groups) do
        groups[k] = v
    end

    local on_receive_fields = function(pos, formname, fields, sender)
        if fields.quit then
            return
        end
        local node = minetest.get_node(pos)
        local meta = minetest.get_meta(pos)

        if fields.submit_ctl then
            if (sender and sender:is_player() and sender:get_player_name() ~= meta:get_string("owner")) then
                local new_owner = sender:get_player_name()
                local prot = ship_machine.get_protector(pos, def.size)
                if prot then
                    local meta2 = minetest.get_meta(prot)
                    meta2:set_string("owner", new_owner)
                    meta2:set_string("infotext", S("Protection (owned by @1)", new_owner))
                    ship_machine.update_ship_owner_all(pos, def.size, new_owner)
                    ship_machine.update_ship_members_clear(pos, def.size)
                    local message = "Systems Updated!"
                    local formspec = update_formspec_nav(pos, def, message)
                    meta:set_string("formspec", formspec)
                end
                return
            end
        end

        if sender and sender:is_player() and minetest.is_protected(pos, sender:get_player_name() ) then
            return
        end

        if fields.submit_migr then
            local shipp = ship_machine.get_protector(pos, def.size)
            if shipp then
                meta:set_int("combat_ready", 2)
                local ship_meta = minetest.get_meta(shipp)
                ship_meta:set_int("combat_ready", 2)
                ship_meta:set_int("hp_max", def.hp)
                ship_meta:set_int("hp", def.hp)
                ship_meta:set_int("shield_max", def.shield)
                ship_meta:set_int("shield", def.shield)
            end
            local message = "Combat Ready!"
            local formspec = update_formspec_nav(pos, def, message)
            meta:set_string("formspec", formspec)
            return
        end

        if fields.refresh then
            local formspec = update_formspec_nav(pos, def, '')
            meta:set_string("formspec", formspec)
            return
        end

        local jpos = ship_machine.get_jumpdrive(pos, def.size)

        if jpos == nil then
            local message = "Jump Drive not found..."
            local formspec = update_formspec_nav(pos, def, message)
            meta:set_string("formspec", formspec)
            return
        end

        local enabled = false
        if fields.toggle then
            if meta:get_int("enabled") == 1 then
                meta:set_int("enabled", 0)
            else
                meta:set_int("enabled", 1)
                enabled = true
            end
        end

        if fields.prot_crew then
            local prot_loc = ship_machine.get_protector(pos, def.size)
            if prot_loc then
                local prot_meta = minetest.get_meta(prot_loc)
                prot_meta:set_int("menu_level", 1)
                minetest.registered_nodes[minetest.get_node(prot_loc).name].on_rightclick(prot_loc, node, sender, nil)
            end
            return
        elseif fields.prot_ally then
            local prot_loc = ship_machine.get_protector(pos, def.size)
            if prot_loc then
                local prot_meta = minetest.get_meta(prot_loc)
                prot_meta:set_int("menu_level", 2)
                minetest.registered_nodes[minetest.get_node(prot_loc).name].on_rightclick(prot_loc, node, sender, nil)
            end
            return
        end

        if fields.holo then
            local drive_loc = ship_machine.get_jumpdrive(pos, def.size)
            local holo_pos = vector.add(pos, vector.new(0,1,0))
            local ofs = vector.subtract(holo_pos, drive_loc)
            local node = core.get_node(holo_pos)
            if node.name ~= "ship_holodisplay:display" then
                core.set_node(holo_pos, {name = "ship_holodisplay:display"})
                local meta = core.get_meta(holo_pos)
                meta:set_int("X", -(128 + ofs.x))
                meta:set_int("Y", -(129 + ofs.y))
                meta:set_int("Z", -(128 + ofs.z))
                core.get_node_timer(holo_pos):start(1)
            else
                core.set_node(holo_pos, {name = "ship_holodisplay:display_off"})
            end
            return
        end

        local jump_dis = meta:get_int("jump_dist")
        local is_deepspace = jpos and jpos.y > 22000;

        -- local pos_nav = meta:get_string("pos_nav")
        -- local nav = minetest.get_meta(pos_nav)
        -- local nav_ready = nav:get_string("jump_ready")
        local nav_ready = 1

        local changed = false
        local loc = tostring(meta:get_int("dest_dir"))
        if fields.btn_hole_1 then
            loc = "1"
            changed = true
        elseif fields.btn_hole_2 then
            loc = "2"
            changed = true
        elseif fields.btn_hole_3 then
            loc = "3"
            changed = true
        elseif fields.btn_hole_4 then
            loc = "4"
            changed = true
        end
        meta:set_int("dest_dir", tonumber(loc, 10))

        local locked = meta:get_int("travel_ready") == 1
        if locked then
            local formspec = update_formspec_nav(pos, def, "Interface lockout!\nAllocator is busy...")
            meta:set_string("formspec", formspec)
            return
        end

        local move_x = 0
        local move_y = 0
        local move_z = 0
        local isNumError = false
        if fields.inp_x then
            if isInteger(fields.inp_x) then
                move_x = tonumber(fields.inp_x, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_y then
            if isInteger(fields.inp_y) then
                move_y = tonumber(fields.inp_y, 10)
            else
                isNumError = true
            end
        end
        if fields.inp_z then
            if isInteger(fields.inp_z) then
                move_z = tonumber(fields.inp_z, 10)
            else
                isNumError = true
            end
        end

        local docked = false

        if fields.dock_name then
            meta:set_string("dock_with", fields.dock_name)
        end

        -- general docking
        if fields.submit_dock2 and def.do_docking then
            local message = ""
            local bFound = false
            local dock_name = fields.dock_name
            local ship_meta = core.get_meta(jpos)
            local ship_owner = ship_meta:get_string("owner")
            local bay_center = ship_dock.get_dock_pos(pos, def.size, ship_owner, dock_name, false)
            if bay_center then
                local bnode = core.get_node(bay_center)
                local is_jumpdrive = core.get_item_group(bnode.name, "jumpdrive") > 0
                move_x = bay_center.x - jpos.x
                move_y = bay_center.y - jpos.y
                move_z = bay_center.z - jpos.z
                if vector.distance(vector.new(move_x, move_y, move_z), jpos) <= 3 then
                    message = "You are already docked with '" .. meta:get_string("dock_with") .. "'"
                    local formspec = update_formspec_nav(pos, def, message)
                    meta:set_string("formspec", formspec)
                    return
                elseif not is_jumpdrive and bnode.name == "vacuum:vacuum" then
                    fields.submit_nav = true
                    bFound = true;
                    meta:set_int("travel_ready", 1)
                    message = "Docking port '" .. meta:get_string("dock_with") .. "' located!"
                    local formspec = update_formspec_nav(pos, def, message)
                    meta:set_string("formspec", formspec)
                end
            end
            if not bFound then
                message = "Docking port invalid..."
                local formspec = update_formspec_nav(pos, def, message)
                meta:set_string("formspec", formspec)
                return;
            end
        end

        -- shipyard dock...
        if fields.submit_dock and def.do_docking then
            local message = ""
            -- FIXME: this should be dynamic...
            local spos = {
                x = 0,
                y = 5350,
                z = 0
            }
            local s = shipyard.ship.size
            local bays = minetest.find_nodes_in_area({
                x = spos.x - s.w,
                y = spos.y - s.h,
                z = spos.z - s.l
            }, {
                x = spos.x + s.w,
                y = spos.y + s.h,
                z = spos.z + s.l
            }, {"shipyard:assembler_bay"})
            local bFound = false
            -- check if bays found
            if #bays > 0 and vector.distance(jpos, spos) <= 768 then
                for c = 1, #bays do
                    local bay = bays[c]
                    local offset = {
                        x = 0,
                        y = 2,
                        z = 1 + 2 + 14
                    }
                    local bay_center = vector.add(bay, offset);
                    if bay_center == jpos then
                        docked = true
                    end
                    -- local bmeta = minetest.get_meta(bay)
                    local bnode = minetest.get_node(bay_center)
                    if not bnode.name:match("shield_protect") and bnode.name == "vacuum:vacuum" then
                        move_x = bay_center.x - jpos.x
                        move_y = bay_center.y - jpos.y
                        move_z = bay_center.z - jpos.z
                        fields.submit_nav = true
                        bFound = true;
                        meta:set_int("travel_ready", 1)
                        message = "Docking bay found!"
                        local formspec = update_formspec_nav(pos, def, message)
                        meta:set_string("formspec", formspec)
                        break
                    end
                end
            end
            if not bFound then
                message = "Docking bay not found..."
                local formspec = update_formspec_nav(pos, def, message)
                meta:set_string("formspec", formspec)
                return;
            end
        end

        local message = ""
        local offset = {
            x = move_x,
            y = move_y,
            z = move_z
        }
        local ncount, dest = ship_machine.get_jump_dest(jpos, offset, def.size)
        local panel_dest = vector.add(pos, offset)

        if ncount == 0 and dest == nil then
            meta:set_int("travel_ready", 0)
            message = "FTL Engines not found..."
        elseif ncount > 1 then
            meta:set_int("travel_ready", 0)
            message = "FTL Engine Mismatch! Actuality Conflict..."
        elseif isNumError then
            meta:set_int("travel_ready", 0)
            message = "Must input a valid number..."
        elseif fields.submit_nav and not is_deepspace and vector.distance(pos, dest) < def.min_dist and not fields.submit_dock then
            meta:set_int("travel_ready", 0)
            message = "Jump distance below engine range..."
        elseif fields.submit_nav and not is_deepspace and docked and fields.submit_dock then
            meta:set_int("travel_ready", 0)
            message = "You are already Docked..."
        elseif fields.submit_nav and not is_deepspace and vector.distance(pos, dest) > jump_dis + 1 then
            meta:set_int("travel_ready", 0)
            message = "Jump distance beyond engine range..."
        elseif fields.submit_nav and not is_deepspace and dest.y > 22000 then
            meta:set_int("travel_ready", 0)
            message = "Jump destination beyond engine abilities..."
        elseif fields.submit_nav and not is_deepspace and dest.y < 4000 then
            meta:set_int("travel_ready", 0)
            message = "Jump destination beyond engine abilities..."
        elseif fields.submit_nav and ((is_deepspace and loc ~= "0") or (not is_deepspace)) then
            message = "Routing Jump Actuality..."
            local formspec = update_formspec_nav(pos, def, message)
            meta:set_string("formspec", formspec)

            local function jump_callback(j)
                if formspec == nil then
                    return
                end
                if j == 1 then
                    meta:set_int("travel_ready", 1)
                    meta:set_string("formspec", nil)
                    minetest.after(0.5, function()
                        local panel = core.get_node(panel_dest)
                        if core.get_item_group(panel.name, "jumpship_control") > 0 then
                            local metad = minetest.get_meta(panel_dest)
                            metad:set_int("travel_ready", 1)
                            local formspec_new = update_formspec_nav(panel_dest, def, "Folding Jump Space...")
                            metad:set_string("formspec", formspec_new)
                        end
                    end)
                    minetest.after(3, function()
                        local panel = core.get_node(panel_dest)
                        if core.get_item_group(panel.name, "jumpship_control") > 0 then
                            local metad = minetest.get_meta(panel_dest)
                            local formspec_new = update_formspec_nav(panel_dest, def, "Jump Complete!")
                            metad:set_string("formspec", formspec_new)
                            metad:set_string("dock_with", '')
                            metad:set_int("travel_ready", 0)
                            minetest.after(1.5, function()
                                if metad then
                                    local formspec_rdy = update_formspec_nav(panel_dest, def, "Ready...")
                                    metad:set_string("formspec", formspec_rdy)
                                end
                            end)
                        end
                    end)
                    return
                elseif j == 0 then
                    meta:set_int("travel_ready", 0)
                    message = "FTL Engines require more charge..."
                elseif j == -1 then
                    meta:set_int("travel_ready", 0)
                    message = "Travel obstructed at " .. "(" .. dest.x .. "," .. dest.y .. "," .. dest.z .. ")"
                elseif j == -3 then
                    meta:set_int("travel_ready", 0)
                    message = "FTL Jump Drive not found..."
                else
                    meta:set_int("travel_ready", 0)
                    message = "FTL Engines Failed to Start?"
                end

                local formspec = update_formspec_nav(pos, def, message)
                meta:set_string("formspec", formspec)
            end

            -- async jump with callback
            ship_machine.engine_do_jump(pos, def.size, jump_callback, offset)

            return
        elseif fields.submit_nav and not changed then
            message = "FTL Engines require more charge..."
            meta:set_int("travel_ready", 0)
        elseif fields.submit_nav and nav_ready ~= 1 and not changed then
            -- TODO: setup navigator thing...
            message = "Survey Navigator requires more charge..."
            meta:set_int("travel_ready", 0)
        end

        local formspec = update_formspec_nav(pos, def, message)
        meta:set_string("formspec", formspec)
    end

    minetest.register_node(modname .. ":" .. ltier .. "_" .. lmachine_name .. "", {
        description = machine_desc,
        tiles = {ltier .. "_" .. lmachine_name .. "_top.png", ltier .. "_" .. lmachine_name .. "_bottom.png",
                 ltier .. "_" .. lmachine_name .. "_side.png", ltier .. "_" .. lmachine_name .. "_side.png",
                 ltier .. "_" .. lmachine_name .. "_side.png", ltier .. "_" .. lmachine_name .. "_front.png"},
        param = "light",
        paramtype2 = "facedir",
        light_source = 3,
        drop = modname .. ":" .. ltier .. "_" .. lmachine_name,
        groups = groups,
        legacy_facedir_simple = true,
        drawtype = "mesh",
        mesh = "moreblocks_slope_half_raised.obj",
        selection_box = {
            type = "fixed",
            fixed = {{-0.5000, -0.5000, -0.5000, 0.5000, 0.5000, 0.5000}}
        },
        collision_box = {
            type = "fixed",
            fixed = {{-0.5, -0.5, -0.5, 0.5, 0.125, 0.5}, {-0.5, 0.125, -0.25, 0.5, 0.25, 0.5},
                     {-0.5, 0.25, 0, 0.5, 0.375, 0.5}, {-0.5, 0.375, 0.25, 0.5, 0.5, 0.5}}
        },
        sounds = default.node_sound_metal_defaults(),

        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Jumpship Control " .. "-" .. " " .. machine_desc)
            local holo_pos = vector.add(pos, vector.new(0,1,0))
            core.set_node(holo_pos, {name = "ship_holodisplay:display_off"})
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            local holo_pos = vector.add(pos, vector.new(0,1,0))
            local node = core.get_node(holo_pos)
            if node.name == "ship_holodisplay:display" or node.name == "ship_holodisplay:display_off" then
                core.set_node(holo_pos, {name = "air"})
            end
            return technic.machine_after_dig_node
        end,
        can_dig = technic.machine_can_dig,
        on_rotate = screwdriver.disallow,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            meta:set_int("enabled", 1)
            meta:set_int("dest_dir", 0)
            meta:set_int("jump_dist", def.jump_dist)
            meta:set_int("travel_ready", 0)
            meta:set_string("formspec", update_formspec_nav(pos, def, ''))
            local pos_drive = ship_machine.get_jumpdrive(pos, def.size)
            if pos_drive then
                local drive_offset = vector.subtract(pos, pos_drive)
                meta:set_string("drive_offset", minetest.serialize(drive_offset))
            end
        end,

        on_punch = function(pos, node, puncher)
            local drive_loc = ship_machine.get_protector(pos, def.size)
            if drive_loc then
                minetest.registered_nodes[minetest.get_node(drive_loc).name].on_punch(drive_loc, minetest.get_node(drive_loc), puncher)
            end
        end,

        on_receive_fields = on_receive_fields,
        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                action = def.digiline_effector
            }
        }
    })

end
