minetest.register_node("ship_machine:coolant_source", {
    description = S("Coolant Source"),
    drawtype = "liquid",
    waving = 3,
    light_source = 9,
    tiles = {{
        name = "ctg_machines_coolant_source_animated.png",
        backface_culling = false,
        animation = {
            type = "vertical_frames",
            aspect_w = 16,
            aspect_h = 16,
            length = 2.0
        }
    }, {
        name = "ctg_machines_coolant_source_animated.png",
        backface_culling = true,
        animation = {
            type = "vertical_frames",
            aspect_w = 16,
            aspect_h = 16,
            length = 2.0
        }
    }},
    use_texture_alpha = "blend",
    paramtype = "light",
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    is_ground_content = false,
    drop = "",
    drowning = 1,
    liquidtype = "source",
    liquid_alternative_flowing = "ship_machine:coolant_flowing",
    liquid_alternative_source = "ship_machine:coolant_source",
	liquid_renewable = false,
    liquid_viscosity = 3,
	liquid_range = 1,
    post_effect_color = {
        a = 103,
        r = 254,
        g = 57,
        b = 153
    },
    groups = {
        coolant = 1,
        water = 3,
        liquid = 3,
        cools_lava = 1
    },
    sounds = default.node_sound_water_defaults()
})

minetest.register_node("ship_machine:coolant_flowing", {
    description = S("Flowing Coolant"),
    drawtype = "flowingliquid",
    waving = 3,
    light_source = 7,
    tiles = {"ctg_machines_coolant_source_animated.png"},
    special_tiles = {{
        name = "ctg_machines_coolant_flowing_animated.png",
        backface_culling = false,
        animation = {
            type = "vertical_frames",
            aspect_w = 16,
            aspect_h = 16,
            length = 0.5
        }
    }, {
        name = "ctg_machines_coolant_flowing_animated.png",
        backface_culling = true,
        animation = {
            type = "vertical_frames",
            aspect_w = 16,
            aspect_h = 16,
            length = 0.5
        }
    }},
    use_texture_alpha = "blend",
    paramtype = "light",
    paramtype2 = "flowingliquid",
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    is_ground_content = false,
    drop = "",
    drowning = 1,
    liquidtype = "flowing",
    liquid_alternative_flowing = "ship_machine:coolant_flowing",
    liquid_alternative_source = "ship_machine:coolant_source",
	liquid_renewable = false,
    liquid_viscosity = 3,
	liquid_range = 1,
    post_effect_color = {
        a = 103,
        r = 254,
        g = 57,
        b = 153
    },
    groups = {
        coolant = 1,
        water = 3,
        liquid = 3,
        not_in_creative_inventory = 1,
        cools_lava = 1
    },
    sounds = default.node_sound_water_defaults()
})

if minetest.get_modpath("radiant_damage") then
    local on_radiation_damage = function(player, damage, pos)
        if player:get_hp() <= 0 or damage == 0 then
            return
        end
        local armor_groups = player.get_armor_groups and player:get_armor_groups()
        local old_damage = damage;
        local has_prot = false
        if armor_groups then
            local radiation_multiplier = armor_groups.radiation
            if radiation_multiplier ~= nil then
                damage = damage * (radiation_multiplier / 100)
                if (damage > 0) then
                    has_prot = true;
                end
            elseif radiation_multiplier == nil and damage > 0 then
                damage = 0
                has_prot = true;
            else
                damage = 0
            end
        end
        if has_prot then
            -- damage armor..
            local _, armor_inv = armor.get_valid_player(armor, player, "[radiant_damage]")
            local armor_list = armor_inv:get_list("armor")
            for i, stack in pairs(armor_list) do
                if not stack:is_empty() then
                    local name = stack:get_name()
                    if name:match('lead') or name:match('gold') or name:match('mithril') then
                        local use = minetest.get_item_group(name, "armor_use") * old_damage * 0.1
                        armor:damage(player, i, stack, use)
                    end
                end
            end
        end
        damage = math.floor(damage)
        if damage > 0 then
            minetest.log("action",
                player:get_player_name() .. " takes " .. tostring(damage) .. " damage from mese radiation damage at " ..
                    minetest.pos_to_string(pos))
            player:set_hp(player:get_hp() - damage)
        end
        if damage > 0 or has_prot then
            if has_prot then
                old_damage = old_damage * 0.5
            end
            minetest.sound_play({
                name = "radiant_damage_geiger",
                gain = math.min(1, math.max(0.6, old_damage) / 10)
            }, {
                to_player = player:get_player_name()
            })
        end
    end

    radiant_damage.register_radiant_damage("coolant", {
        interval = 2,
        inverse_square_falloff = true,
        emitted_by = {
            ["ship_machine:coolant_source"] = 1,
            ["ship_machine:coolant_flowing"] = 1
        },
        attenuated_by = {
            ["group:stone"] = 0.5,
            ["group:mese_radiation_shield"] = 0.1,
            ["group:mese_radiation_amplifier"] = 4,
            ["group:metal"] = 0.2
        },
        default_attenuation = 0.6,
        on_damage = on_radiation_damage
    })
end

if minetest.get_modpath("bucket") then
    bucket.register_liquid("ship_machine:coolant_source", "ship_machine:coolant_flowing", "ship_machine:bucket_coolant",
        "ctg_bucket_coolant.png", S("Coolant Bucket"), {
            tool = 1,
            coolant_bucket = 1
        })
end

if minetest.get_modpath("bottles") then

    local function spawn_particle(pos)
        local grav = 1;
        if (pos.y > 4000) then
            grav = 0.4;
        end
        local def = {
            amount = 15,
            time = 0.7,
            collisiondetection = true,
            collision_removal = false,
            object_collision = false,
            vertical = false,

            animation = {
                type = "vertical_frames",
                aspect_w = 32,
                aspect_h = 32,
                length = 1
            },
            texture = {
                name = "ctg_coolant_bubble_anim.png",
                alpha_tween = {1, 0},
                scale_tween = {{
                    x = 0.5,
                    y = 0.5
                }, {
                    x = 3,
                    y = 3
                }},
                blend = "alpha"
            },
            glow = 6,

            minpos = {
                x = pos.x + -0.17,
                y = pos.y + 0,
                z = pos.z + -0.17
            },
            maxpos = {
                x = pos.x + 0.17,
                y = pos.y + 0.65,
                z = pos.z + 0.17
            },
            minvel = {
                x = 0,
                y = 0.05,
                z = 0
            },
            maxvel = {
                x = 0,
                y = 0.8 * grav,
                z = 0
            },
            minacc = {
                x = -0.5,
                y = -1.25 * grav,
                z = -0.5
            },
            maxacc = {
                x = 0.5,
                y = -2.85 * grav,
                z = 0.5
            },
            minexptime = 0.7,
            maxexptime = 1.1,
            minsize = 0.35,
            maxsize = 1.0
        }

        minetest.add_particlespawner(def);
    end

    -- Register new coolant bottle node
    --[[minetest.register_node(":ship_machine:bottle_of_coolant", {
        description = ("Bottle of Coolant"),
        drawtype = "plantlike",
        paramtype = "light",
        is_ground_content = false,
        walkable = false,
        selection_box = {
            type = "fixed",
            fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
        }
    })]] --
    bottles.register_filled_bottle({
        target = "ship_machine:coolant_source",
        sound = "default_water_footstep",
        modname = "ship_machine",
        name = "bottle_of_coolant",
        description = "Bottle of Coolant",
        groups = {
            vessel = 1,
            dig_immediate = 3,
            attached_node = 1,
            coolant_water = 1
        }
    })

    local old_spill = bottles.spill;
    -- OVerride a spilled bottle
    local register_spilled_bottle = function(itemstack, placer)
        if placer:is_player() then
            local name = itemstack:get_name()
            if (name:match("bottle_of_coolant")) then
                -- Play contents sound
                bottles.play_bottle_sound(placer:get_pos(),
                    bottles.registered_filled_bottles[itemstack:get_name()].sound)

                spawn_particle(placer:get_pos())

                -- Subtract from stack of filled bottles and set return value
                local count = itemstack:get_count()
                local retval = nil
                if count == 1 then
                    itemstack:clear()
                    retval = ItemStack("vessels:glass_bottle")
                else
                    itemstack:set_count(count - 1)
                    retval = itemstack
                    local leftover = placer:get_inventory():add_item("main", ItemStack("vessels:glass_bottle"))
                    if not leftover:is_empty() then
                        minetest.add_item(placer:get_pos(), leftover)
                    end
                end

                -- Return value
                return retval
            end

            return old_spill(itemstack, placer);
        else
            return itemstack
        end
    end

    local contents_node = minetest.registered_nodes['ship_machine:bottle_of_coolant']
    if contents_node then
        contents_node.on_use = register_spilled_bottle;
    end

    local function do_particle_effect(pos, amount)
        local grav = 1;
        if (pos.y > 4000) then
            grav = 0.3;
        end
        local prt = {
            animation = {
                type = "vertical_frames",
                aspect_w = 32,
                aspect_h = 32,
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
            time = 1.8,
            size = 0.8,
            glow = 6,
            cols = true
        }
        local rx = math.random(-0.064, 0.064) * 0.88
        local rz = math.random(-0.064, 0.064) * 0.88
        local texture = prt.texture
        if (math.random() >= 0.52) then
            texture = prt.texture_r180
        end

        minetest.add_particlespawner({
            amount = amount,
            time = prt.time + math.random(-0.3, 1.2),
            minpos = {
                x = pos.x - 0.25,
                y = pos.y - 0.17,
                z = pos.z - 0.25
            },
            maxpos = {
                x = pos.x + 0.25,
                y = pos.y + 0.96,
                z = pos.z + 0.25
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
                x = -0.2,
                y = -0.15,
                z = -0.2
            },
            maxacc = {
                x = 0.2,
                y = 0.23 * grav,
                z = 0.2
            },
            minexptime = prt.time * 0.30,
            maxexptime = prt.time * 0.96,
            minsize = prt.size * 0.5,
            maxsize = prt.size * 1.2,
            collisiondetection = prt.cols,
            collision_removal = true,
            object_collision = false,
            vertical = false,
            animation = prt.animation,
            texture = texture,
            glow = prt.glow
        })
    end

    minetest.register_abm({
        label = "coolant effects - bubbles source",
        nodenames = {"ship_machine:coolant_source"},
        neighbors = {"air", "vacuum:vacuum", "vacuum:atmos_thin"},
        interval = 3,
        chance = 5,
        action = function(pos)
            do_particle_effect(pos, math.random(3, 10))
        end
    })
    minetest.register_abm({
        label = "coolant effects - bubbles flowing",
        nodenames = {"ship_machine:coolant_flowing"},
        neighbors = {"air", "vacuum:vacuum", "vacuum:atmos_thin"},
        interval = 4,
        chance = 6,
        action = function(pos)
            do_particle_effect(pos, math.random(2, 5))
        end
    })

end

--local coolant_image = "ctg_machines_coolant_source_animated.png"
--ship_machine.coolant_bottle_image = "[combine:16x16:0,0=" .. coolant_image .. "^vessels_glass_bottle_mask.png^[makealpha:0,254,0"

if minetest.get_modpath("unified_inventory") then
    unified_inventory.register_craft_type("chemicals", {
        description = "Chemical Processing",
        icon = "ctg_hv_chem_lab_front_active.png",
        width = 2,
        height = 2
    })
    unified_inventory.register_craft({
        type = "chemicals",
        output = "ship_machine:bottle_of_coolant",
        items = {"livingcaves:bucket_cavewater", "technic:sulfur_dust", "group:salt", "group:glow_shroom"}
    })
end
