
--Global settings
local damage_multiplier =  1
local combine_velocity = false
local projectile_raycast_dist = 0.5

--[[function ship_weapons.get_spread(spread)
    return (math.random(-32768, 32768)/65536)*spread
end]]

local function damage_aoe(damage, puncher, pos, radius)
    if puncher == nil then
        return
    end
    local targs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, radius)
    for _,t in pairs(targs) do
        local dist=math.sqrt(((t:get_pos().x-pos.x)^2)+((t:get_pos().y-pos.y)^2)+((t:get_pos().z-pos.z)^2))
        local DistDamage=damage/math.max(dist, 1)
        --local player = minetest.get_player_by_name(puncher.owner)
        if t:is_player() then
            t:punch(puncher, 1.0, {
                full_punch_interval=1.0,
                damage_groups={fleshy=DistDamage},
            }, nil)
        elseif t:get_luaentity() then
            local ent = t:get_luaentity()
            if ent.type and (ent.type == "npc" or ent.type == "animal" or ent.type == "monster") then
                if puncher ~= nil then
                    t:punch(puncher, 1.0, {
                        full_punch_interval=1.0,
                        damage_groups={fleshy=DistDamage},
                    }, nil)
                end
            elseif ent.name == "__builtin:item" then
                t:remove()
            end
        end
    end
end

local function is_atmos(name)
    if name == "air" then
        return true
    elseif name == "vacuum:vacuum" then
        return true
    elseif name == "vacuum:atmos_thin" then
        return true
    elseif name == "vacuum:atmos_thick" then
        return true
    elseif name == ":asteroid:atmos" then
        return true
    end
    return false
end

--Utility projectile registration function
local function register_projectile(def)

    local aglow = 0
    if def.glow then
        aglow = 14
    end
    
    local texture = {def.texture}
    local texture_mod = "^ship_weapons_energy_ball.png"

    --Main projectile registration function
    minetest.register_entity(def.name, {
        initial_properties = {
            physical = false,
            is_visible = true,
            static_save = false,

            visual = "sprite",
            visual_size = {x = def.visual_size, y = def.visual_size, z = def.visual_size},
            textures = texture,
            glow = aglow,
            pointable = false,
            type = "projectile",
            max_hp = 1,
            hp = 1,
        },

        --Internal variables
        timer = 0,
        owner = "",
        node_hit = false,
        previous_pos = {},
        target_delay = 3,
        target_pos = {},
        object_target = nil,

        on_death = function(self, killer)
            local pos = self.object:get_pos()
            local radius = 1
            --Death smoke
            minetest.add_particlespawner({
                amount = 3,
                time = 0.6,
                minpos = vector.subtract(pos, radius / 4),
                maxpos = vector.add(pos, radius / 4),
                minvel = {x = -0.25, y = -0.25, z = -0.25},
                maxvel = {x = 0.25, y = 0.25, z = 0.25},
                minacc = vector.new(),
                maxacc = vector.new(),
                minexptime = 2,
                maxexptime = 5,
                minsize = radius * 10,
                maxsize = radius * 16,
                texture = {
                    name = "ctg_missile_smoke.png",
                    blend = "alpha",
                    scale = 1,
                    alpha = 1.0,
                    alpha_tween = {1, 0.5, 0},
                    scale_tween = {{
                        x = 0.75,
                        y = 0.75
                    }, {
                        x = 6,
                        y = 6
                    }}
                },
                collisiondetection = true,
                glow = 6,
            })
            --Death flash
            if def.hit_flare then
                local hit_flare = def.hit_flare
                local r = math.random(0,2)
                if r == 0 then
                    hit_flare = def.hit_flare .. "^[transformFY"
                elseif r == 1 then
                    hit_flare = def.hit_flare .. "^[transformFXR90"
                end
                minetest.add_particle({
                    pos = pos,
                    expirationtime = 0.57,
                    size = def.hit_flare_size,
                    collisiondetection = false,
                    vertical = false,
                    texture = hit_flare,
                    glow = def.hit_flare_glow,
                })
            end
            --Hit sound
            if def.hit_sound then
                minetest.sound_play(def.hit_sound, {pos=self.previous_pos, pitch=2.35, gain=def.hit_sound_gain, max_hear_distance=2*48})
            end
        end,

        --Performing checks every server step
        on_step = function(self, dtime)
            self.timer = self.timer + 1
            local pos = self.object:get_pos()

            if def.texture_anim and self.timer % 2 == 0 then
                local r = math.random(0, 3)
                if r == 0 then
                    self.object:set_texture_mod(texture_mod.. "^[colorize:#00fff7:120")
                elseif r == 1 then
                    self.object:set_texture_mod("^[colorize:#00ff11:120")
                else 
                    self.object:set_texture_mod("")
                end
            end

            --[[if self.object:get_hp() <= 5 and def.tier == 'hv' then
                local proj_def = {
                    tier = 'lv',
                    delay = 0,
                    count = 2,
                    novel = 1
                }
                ship_weapons.launch_energy_rail_projectile(proj_def, self.owner, pos, self.target_pos, self.object_target)
                if def.hit_flare then
                    minetest.add_particle({
                        pos = self.previous_pos,
                        expirationtime = 0.2,
                        size = def.hit_flare_size,
                        collisiondetection = false,
                        vertical = false,
                        texture = def.hit_flare,
                        glow = def.hit_flare_glow,
                    })
                end
                --Remove the projectile
                self.object:remove()
                return;
            end]]--

            --Trail particle spawner
            if def.trail_particle then
                --Smoke Effect
                minetest.add_particlespawner({
                    amount = 1,
                    time = 0.015,
                    minpos = {x=pos.x-0.1, y=pos.y-0.1, z=pos.z-0.1},
                    maxpos = {x=pos.x+0.1, y=pos.y+0.1, z=pos.z+0.1},
                    minvel = {x=-0.1, y=-0.1, z=-0.1},
                    maxvel = {x=0.1, y=0.1, z=0.1},
                    minacc = {x=0, y=def.trail_particle_gravity, z=0},
                    maxacc = {x=0, y=def.trail_particle_gravity, z=0},
                    minexptime = 1.425,
                    maxexptime = 2.371,
                    minsize = 1,
                    maxsize = 2.0,
                    texture = def.trail_particle_smoke,
                    glow = 2,
                })
                local dir = {x=0,y=0,z=0}
                --[[if self.target_pos and self.target_pos.x then
                    dir = vector.normalize(vector.subtract(self.target_pos, pos)) * -0.8
                    dir.y = dir.y - 0.15
                end]]
                --Sparks Effect
                minetest.add_particlespawner({
                    amount = def.trail_particle_amount,
                    time = 0.255,
                    minpos = {x=pos.x-def.trail_particle_displacement+dir.x, y=pos.y-def.trail_particle_displacement+dir.y, z=pos.z-def.trail_particle_displacement+dir.z},
                    maxpos = {x=pos.x+def.trail_particle_displacement+dir.x, y=pos.y+def.trail_particle_displacement+dir.y, z=pos.z+def.trail_particle_displacement+dir.z},
                    minvel = {x=-def.trail_particle_velocity, y=-def.trail_particle_velocity, z=-def.trail_particle_velocity},
                    maxvel = {x=def.trail_particle_velocity, y=def.trail_particle_velocity, z=def.trail_particle_velocity},
                    minacc = {x=0, y=def.trail_particle_gravity, z=0},
                    maxacc = {x=0, y=def.trail_particle_gravity, z=0},
                    minexptime = 0.25,
                    maxexptime = 0.65,
                    minsize = def.trail_particle_min_size,
                    maxsize = def.trail_particle_size,
                    texture = def.trail_particle,
                    glow = def.trail_particle_glow,
                })
            end
            
            local retarget = false
            --Target position update
            if self.object_target then
                if self.object_target:get_hp() > 0 and self.object_target:get_pos() then
                    self.target_pos = self.object_target:get_pos();
                end
            elseif retarget then
                local objs = minetest.get_objects_inside_radius(pos, 2.5)
                for _, obj in pairs(objs) do
                    local obj_pos = obj:get_pos()
                    if obj:get_luaentity() and not obj:is_player() then
                        local ent = obj:get_luaentity()
                        if ent.type and (ent.type == "npc" or ent.type == "animal" or ent.type == "monster") then
                            self.target_pos = obj_pos
                        end
                    elseif obj:is_player() then
                        self.target_pos = obj_pos
                    end
                end
            end

            --Target tracking update
            if self.target_pos and self.target_pos.x then
                local target_delta = vector.direction(pos, self.target_pos)
                local dist_delta = vector.distance(pos, self.target_pos)
                --[[if (self.timer % 2 == 0 and self.timer > self.target_delay) then
                    local velo = self.object:get_velocity()
                    local veln = {x=((target_delta.x+ship_weapons.get_spread(def.spread))*def.projectile_speed),
                                y=((target_delta.y+ship_weapons.get_spread(def.spread))*def.projectile_speed),
                                z=((target_delta.z+ship_weapons.get_spread(def.spread))*def.projectile_speed)}
                    local vel = vector.add(vector.multiply(velo, 5), veln) / 6
                    self.object:set_velocity(vel)
                end]]--
                if (dist_delta < 0.5751) then
                    self.node_hit = true 
                    if def.aoe then
                        damage_aoe(def.damage, self.object, self.previous_pos, def.aoe_radius)
                    end
                    if def.on_timeout then
                        def.on_timeout(self, self.target_pos)
                    end
                    --Remove the projectile
                    --self.object:remove()
                end
            end

            --Hit detection
            local delta = {x = pos.x-self.previous_pos.x, y = pos.y - self.previous_pos.y, z = pos.z - self.previous_pos.z}
            local ray = minetest.raycast(pos, {
                                               x = pos.x + delta.x * projectile_raycast_dist,
                                               y = pos.y + delta.y * projectile_raycast_dist,
                                               z = pos.z + delta.z * projectile_raycast_dist
                                               }, true, def.liquids_stop)
            local target = ray:next()
            if target and target.type == "node" then
                local node = minetest.get_node_or_nil(minetest.get_pointed_thing_position(target, false))
                if node and minetest.registered_nodes[node.name] and (minetest.registered_nodes[node.name].walkable and not is_atmos(node.name) or
                def.liquids_stop and minetest.registered_nodes[node.name].liquidtype ~= "none") then
                    if def.aoe then
                        damage_aoe(def.damage, self.object, target.intersection_point, def.aoe_radius)
                    end
                    if def.on_hit then
                        def.on_hit(self, target)
                    end
                    self.node_hit = true
                end
            elseif target and target.type == "object" then
                if def.aoe then
                    damage_aoe(def.damage, self.object, target.intersection_point, def.aoe_radius)
                else
                    local player = minetest.get_player_by_name(self.owner)
                    --[[if player then
                        target.ref:punch(player, 1.0, {
                        full_punch_interval=1.0,
                        damage_groups={fleshy=def.damage},
                        }, nil)
                    end]]
                end
                if def.on_hit then
                    def.on_hit(self, target)
                end
                self.node_hit = true
            end

            if self.node_hit then
                local objs = minetest.get_objects_inside_radius(pos, 1.85)
                for _, obj in pairs(objs) do
                    local obj_pos = obj:get_pos()
                    if obj:get_luaentity() and not obj:is_player() then
                        local ent = obj:get_luaentity()
                        if ent.type == "projectile" or ent.name == "ship_weapons:lv_energy_rail_projectile" then
                            --core.log("exploding nearby shells!")
                            ent.node_hit = true
                            core.after(30, function ()
                                if obj then
                                    obj:remove();
                                end
                            end)
                        end
                    end
                end                
            end

            --Spawn hit particles, execute on_hit if defined, drop an item if defined and remove the object
            if self.node_hit then
                --Little hit flares
                if def.hit_flare then
                    local hit_flare = def.hit_flare
                    local r = math.random(0,2)
                    if r == 0 then
                        hit_flare = def.hit_flare .. "^[transformFY"
                    elseif r == 1 then
                        hit_flare = def.hit_flare .. "^[transformFXR90"
                    end
                    for i = 0, 3 do
                        minetest.add_particle({
                            pos = vector.add(self.previous_pos, {x=math.random(-0.1,0.1), y=math.random(-0.1,0.1), z=math.random(-0.1,0.1)}),
                            expirationtime = 0.1 + math.random(0, 0.25),
                            size = def.hit_flare_size * (i * 1.08),
                            collisiondetection = false,
                            vertical = false,
                            texture = hit_flare,
                            glow = def.hit_flare_glow,
                        })
                    end
                    minetest.add_particle({
                        pos = self.previous_pos,
                        expirationtime = 0.175,
                        size = 37,
                        collisiondetection = false,
                        vertical = false,
                        texture = "lv_rail_cannon_ball.png^[colorize:#00ddff:200",
                        glow = def.hit_flare_glow,
                    })
                end
                --Hit particles
                if def.hit_particle then
                    minetest.add_particlespawner({
                        amount = def.hit_particle_amount,
                        time = 0.075,
                        minpos = self.previous_pos,
                        maxpos = self.previous_pos,
                        minvel = {x=-def.hit_particle_velocity, y=-def.hit_particle_velocity, z=-def.hit_particle_velocity},
                        maxvel = {x=def.hit_particle_velocity, y=def.hit_particle_velocity+2, z=def.hit_particle_velocity},
                        minacc = {x=0, y=def.hit_particle_gravity, z=0},
                        maxacc = {x=0, y=def.hit_particle_gravity, z=0},
                        minexptime = 3,
                        maxexptime = 7,
                        minsize = def.hit_particle_min_size,
                        maxsize = def.hit_particle_size,
                        collisiondetection = false,
                        collision_removal = false,
                        object_collision = false,
                        vertical = false,
                        texture = def.hit_particle,
                        glow = def.hit_particle_glow,
                    })
                end
                --Hit sparks
                if def.hit_spark then
                    local hit_vel = 5.25
                    local dir = vector.normalize(vector.subtract(self.previous_pos, pos))
                    local h_pos = self.previous_pos or pos
                    local hit_spark = {
                        name = "lv_rail_cannon_energy_spark_anim.png^[colorize:#00fff7:200",
                        blend = "alpha",
                        scale = 1,
                        alpha = 1.0,
                        alpha_tween = {1, 1, 0.01},
                        scale_tween = {{
                            x = 1.45,
                            y = 1.45
                        }, {
                            x = 0.05,
                            y = 0.05
                        }}
                    }
                    local spark_animation = {
                        type = "vertical_frames",
                        aspect_w = 16,
                        aspect_h = 16,
                        length = 0.7 + 0.01
                    }
                    minetest.add_particlespawner({
                        amount = 64,
                        time = 0.075,
                        minpos = {x=h_pos.x-dir.x, y=h_pos.y-dir.y, z=h_pos.z-dir.z},
                        maxpos = {x=h_pos.x+dir.x, y=h_pos.y+dir.y, z=h_pos.z+dir.z},
                        minvel = {x=(hit_vel*dir.x)-2, y=hit_vel*dir.y*0.5, z=(hit_vel*dir.z)-2},
                        maxvel = {x=(hit_vel*dir.x)+2, y=(hit_vel*dir.y*1.75)+5, z=(hit_vel*dir.z)+2},
                        minacc = {x=-0.42, y=(1.2125 * dir.y * 0.4) - 5, z=-0.42},
                        maxacc = {x=0.42, y=(1.351 * dir.y) - 1, z=0.42},
                        minexptime = 1,
                        maxexptime = 3,
                        minsize = 1,
                        maxsize = 2.25,
                        collisiondetection = true,
                        collision_removal = false,
                        object_collision = false,
                        vertical = false,
                        texture = hit_spark,
                        animation = spark_animation,
                        glow = 12,
                    })
                end
                --Hit sound
                if def.hit_sound then
                    minetest.sound_play(def.hit_sound, {pos=self.previous_pos, pitch=7.51, gain=def.hit_sound_gain, max_hear_distance=2*64})
                end
                --Drop a drop item, if defined
                if def.drop then
                    if math.random() < def.drop_chance then
                        minetest.add_item(self.previous_pos, def.drop)
                    end
                end
                --Remove the projectile
                self.object:remove()
            end

            --Spawn a hit flare and remove the projectile if it timeouts
            if self.timer > def.timeout then
                if def.flare then
                    minetest.add_particle({
                        pos = self.previous_pos,
                        expirationtime = 0.25,
                        size = math.floor(def.flare_size/2),
                        collisiondetection = false,
                        vertical = false,
                        texture = def.flare,
                        glow = def.flare_glow,
                    })
                end
                if def.on_timeout then def.on_timeout(self) end
                self.object:remove()
            end

            self.previous_pos = pos

        end,
    })
end

local function setup_projectile_register(tier)
    local modname = "ship_weapons"    
    local smoke_texture = {
        name = "ctg_missile_vapor.png^[colorize:#00fff7:20",
        blend = "alpha",
        scale = 1,
        alpha = 1.0,
        alpha_tween = {1, 0.4, 0},
        scale_tween = {{
            x = 0.5,
            y = 0.5
        }, {
            x = 7.5,
            y = 7.5
        }}
    }
    local spark_texture = {
        name = "ctg_spark.png^[colorize:#00fff7:210",
        blend = "alpha",
        scale = 1,
        alpha = 1.0,
        alpha_tween = {1, 0.1},
        scale_tween = {{
            x = 0.55,
            y = 0.55
        }, {
            x = 2,
            y = 2
        }}
    }
    local spark_texture_2 = {
        name = "lv_rail_cannon_spark.png^[colorize:#00fff7:110",
        blend = "alpha",
        scale = 1,
        alpha = 1.0,
        alpha_tween = {1, 1, 0.01},
        scale_tween = {{
            x = 0.55,
            y = 0.55
        }, {
            x = 2,
            y = 2
        }}
    }
    local damage = 10
    local radius = 0.5 + math.random(0.01, 0.45)
    local spread = 2
    local speed = 20
    if tier == 'mv' then
        damage = 11
        radius = 0.975
        spread = 1.5
        speed  = 21
    end
    if tier == 'hv' then
        damage = 13
        radius = 1.751
        spread = 1.25
        speed = 22
    end
    local def = { 
        name = modname .. ':' .. tier .. '_energy_rail',
        tier = tier,
        spread = spread,
        damage = damage,
        cooldown = 1,
        ammo_per_shot = 1,
        aoe = true,
        aoe_radius = 2 + (radius * 2),
        flare = "tnt_boom.png^[colorize:#00fff7:120",
        flare_size = 5,
        flare_glow = 14,
        hit_flare = "tnt_boom.png^[colorize:#00fff7:130",
        hit_flare_size = 10,
        hit_flare_glow = 13,
        --hit_particle = "lv_rail_cannon_spark.png^[colorize:#00fff7:130",
        hit_spark_particle = spark_texture_2,
        trail_particle = spark_texture,
        trail_particle_smoke = smoke_texture,
        trail_particle_velocity = 0.07571,
        trail_particle_gravity = 0.0225,
        trail_particle_size = 0.542,
        trail_particle_amount = 10,
        trail_particle_displacement = 0.0375,
        trail_particle_glow = 12,
        reload_sound = "bweapons_hitech_pack_missile_launcher_reload",
        reload_sound_gain = 0.25,
        projectile_speed = speed,
        projectile_gravity = -1,
        projectile_timeout = 360,
        --projectile_texture = "ctg_"..tier.."_missile_entity.png",
        projectile_texture = "lv_rail_cannon_ball.png",
        projectile_texture_anim = true,
        projectile_glow = 13,
        projectile_visual_size = 0.648,
        on_hit = function(self, target)
            if not minetest.is_protected(target.intersection_point, "") then
                ship_weapons.boom(target.intersection_point, { radius = radius, ignore_protection = false, fire = true })
            else
                ship_weapons.safe_boom(target.intersection_point, { radius = radius, ignore_protection = false, fire = true })
            end
        end,
        on_timeout = function(self)
            if not minetest.is_protected(self.previous_pos, "") then
                ship_weapons.boom(self.previous_pos, { radius = radius, ignore_protection = false, fire = true })
            else
                ship_weapons.safe_boom(self.previous_pos, { radius = radius, ignore_protection = false, fire = true })
            end
        end,
    }

    --Setting defaults if fields are not defined in definition
    local damage = def.damage or 1
    local spawndist = def.spawn_distance or 1
    local shot_amount = def.shot_amount or 1
    local spread = def.spread or 0
    local cooldown = def.cooldown or 0
    local liquids_stop = def.liquids_stop or false
    local distance = def.distance or 10
    local penetration = def.penetration or 1
    local aoe = def.aoe or false
    local aoe_radius = def.aoe_radius or 5
    local flare_size = def.flare_size or 10
    local flare_glow = 0
    local hit_flare_size = def.hit_flare_size or 0.5
    local hit_flare_glow = 0
    local ammo_per_shot = def.ammo_per_shot or 1
    local repair_uses = def.repair_uses or 8
    local hit_particle_velocity = def.hit_particle_velocity or 3
    local hit_particle_gravity = def.hit_particle_gravity or -10
    local hit_particle_size = def.hit_particle_size or 2
    local hit_particle_min_size = math.floor(hit_particle_size/2)
    local hit_particle_amount = def.hit_particle_amount or 16
    local hit_particle_glow = 0
    local drop_chance = def.drop_chance or 0.9
    local fire_sound_gain = def.fire_sound_gain or 1
    local hit_sound_gain = def.hit_sound_gain or 0.35
    local reload_sound_gain = def.reload_sound_gain or 0.25
    local trail_particle_distance = def.hitscan_particle_distance or 0.5
    local trail_particle_velocity = def.trail_particle_velocity or 1
    local trail_particle_gravity = def.trail_particle_gravity or 0
    local trail_particle_size = def.trail_particle_size or 1
    local trail_particle_min_size = math.floor(trail_particle_size/2)
    local trail_particle_amount = def.trail_particle_amount or 2
    local trail_particle_displacement = def.trail_particle_displacement or 0.5
    local trail_particle_glow = 0

    if def.flare_glow then
        flare_glow = 14
    end
    if def.hit_particle_glow then
        hit_particle_glow = 14
    end
    if def.hit_flare_glow then
        hit_flare_glow = 14
    end
    if def.trail_particle_glow then
        trail_particle_glow = 14
    end

    damage = damage * damage_multiplier

    local projectile_speed = def.projectile_speed or 15
    local projectile_gravity = def.projectile_gravity or 0
    local projectile_timeout = def.projectile_timeout or 250
    local projectile_texture = def.projectile_texture or "lv_rail_cannon_ball.png"
    local projectile_texture_anim = def.projectile_texture_anim or false
    local projectile_glow = def.projectile_glow or false
    local projectile_visual_size = def.projectile_visual_size or 1

    --Make a projectile definition and register projectile
    local projectiledef = {
        name=def.name.."_projectile",
        tier=def.tier,
        damage=damage,
        timeout=projectile_timeout,
        projectile_speed=projectile_speed,
        projectile_gravity=projectile_gravity,
        spread=spread,
        aoe=aoe,
        aoe_radius=aoe_radius,
        visual_size=projectile_visual_size,
        texture=projectile_texture,
        texture_anim=projectile_texture_anim,
        glow=projectile_glow,
        trail_particle=def.trail_particle,
        trail_particle_smoke=def.trail_particle_smoke,
        trail_particle_velocity=trail_particle_velocity,
        trail_particle_gravity=trail_particle_gravity,
        trail_particle_glow=trail_particle_glow,
        trail_particle_size=trail_particle_size,
        trail_particle_min_size=trail_particle_min_size,
        trail_particle_amount=trail_particle_amount,
        trail_particle_displacement=trail_particle_displacement,
        flare=def.flare,
        flare_size=flare_size,
        flare_glow=flare_glow,
        hit_spark=def.hit_spark_particle,
        hit_flare=def.hit_flare,
        hit_flare_size=hit_flare_size,
        hit_flare_glow=hit_flare_glow,
        hit_particle=def.hit_particle,
        hit_particle_glow=hit_particle_glow,
        hit_particle_velocity=hit_particle_velocity,
        hit_particle_size=hit_particle_size,
        hit_particle_gravity=hit_particle_gravity,
        hit_particle_min_size=hit_particle_min_size,
        hit_particle_amount=hit_particle_amount,
        hit_sound=def.hit_sound,
        hit_sound_gain=hit_sound_gain,
        drop=def.drop,
        drop_chance=drop_chance,
        on_hit=def.on_hit,
        on_timeout=def.on_timeout,
        liquids_stop=liquids_stop,
        }
    register_projectile(projectiledef)
end

local function calculatePitch(vector1, vector2)
    -- Calculate the difference vector
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    -- Calculate the pitch angle
    local pitch = -math.atan2(dy, math.sqrt(dx * dx + dz * dz))
    -- Optional: Convert pitch from radians to degrees
    --local pitch_degrees = pitch * 180 / math.pi
    local pitch_degrees = math.deg(pitch)
    return pitch, pitch_degrees
end

local function calculateYaw(vector1, vector2)
    -- Calculate yaw for each vector
    --local yaw = math.atan2(vector2.x - vector1.x, vector2.z - vector1.z)
    local yaw = -math.atan2(vector1.x - vector2.x, vector1.z - vector2.z)
    -- Optional: Convert to degrees
    --local yaw_degrees = yaw * 180 / math.pi
    local yaw_degrees = math.deg(yaw) + 0
    return math.rad(yaw_degrees), yaw_degrees
end

function ship_weapons.launch_energy_rail_projectile(custom_def, operator, origin, target, object_target)

    local mount_dir = custom_def.mount_dir or "bottom"
    local tier = custom_def.tier or "lv"
    local def = {
        fire_sound = "ctg_rail_cannon_fire",
        fire_sound_gain = 0.1,
        flare = "tnt_boom.png^[colorize:#00fff7:160",
        flare_size = 4,
        flare_glow = 14,
        delay = custom_def.delay or 3
    }
    local spark_texture = {
        name = "ctg_spark.png^[colorize:#00fff7:160",
        blend = "alpha",
        scale = 1,
        alpha = 1.0,
        alpha_tween = {1, 0.2},
        scale_tween = {{
            x = 0.75,
            y = 0.75
        }, {
            x = 0,
            y = 0
        }}
    }

    local proj_name = 'ship_weapons:'..tier..'_energy_rail'
    local projectile_speed = (custom_def.projectile_speed or 1) + math.random(0.1, 0.2)
    local projectile_gravity = -1.567
    local spread = 0.8

    if origin.y > 10000 then
        projectile_speed = projectile_speed * 1.1
        projectile_gravity = -0.71
    elseif origin.y > 4000 then
        projectile_speed = projectile_speed * 1.05
        projectile_gravity = -1.05
    end

    local shot_amount = custom_def.count or 2;
    local spawndist = 1.55
    
    local originpos = origin
    local dist = vector.distance(origin, target)
    local n_dist = dist * 0.01
    --Get port position to use based on facing
    local dir = vector.normalize(target - origin);
    local vel = vector.multiply(dir, 50)
    vel.y = vel.y + (n_dist * (0 + math.abs(projectile_gravity)))
    local pitch, pitch_deg = calculatePitch(origin, target)
    local yaw, yaw_deg = calculateYaw(origin, target)
    --Set projectile port origin position
    local function get_port_pos()
        local port_a = {x = 0, y = 0.225 + (dir.y * 1), z = -0.25}
        port_a = vector.add(originpos, vector.rotate_around_axis(port_a, {x = 0, y = 1, z = 0}, yaw))
        return port_a
    end
    local _port_a = get_port_pos()
    local port_a = {x=_port_a.x+dir.x*spawndist, y=_port_a.y+dir.y*spawndist, z=_port_a.z+dir.z*spawndist}

    local function spawn_proj(_pos)
        local obj = minetest.add_entity(_pos, proj_name.."_projectile")
        if not obj then return end
        if not obj:get_luaentity() then return end
        --core.log('cannon spawn_proj(_pos)')
        --Set projectile owner/operator
        obj:get_luaentity().owner = operator
        --Set previous pos when just spawned
        obj:get_luaentity().previous_pos = _pos
        --Set the target pos when just spawned
        obj:get_luaentity().target_pos = target
        obj:get_luaentity().target_delay = def.delay
        obj:get_luaentity().object_target = object_target
        if custom_def.novel == nil then
            --Combine velocity with launch velocity
            obj:set_velocity({x=((dir.x+ship_weapons.get_spread(spread))*projectile_speed)+vel.x,
                            y=((dir.y+ship_weapons.get_spread(spread))*projectile_speed)+vel.y,
                            z=((dir.z+ship_weapons.get_spread(spread))*projectile_speed)+vel.z})
        else
            obj:set_velocity({x=((ship_weapons.get_spread(1))*projectile_speed),
                            y=((ship_weapons.get_spread(1))*projectile_speed),
                            z=((ship_weapons.get_spread(1))*projectile_speed)})
        end
        obj:set_acceleration({x=0, y=projectile_gravity, z=0})
        
        --Fire flash
        minetest.add_particle({
            pos = _pos,
            expirationtime = 0.1,
            size = def.flare_size,
            collisiondetection = false,
            vertical = false,
            texture = def.flare,
            glow = def.flare_glow,
        })
        
        local r = 2.5
        local s_vel = vector.multiply(vel, 0.1)
        local s_vel_min = vector.subtract(s_vel, {x=r, y=r, z=r})
        local s_vel_max = vector.add(s_vel, {x=r, y=r, z=r})
        minetest.add_particlespawner({
            amount = 30,
            time = 0.075,
            minpos = {x=_pos.x-0.01, y=_pos.y-0.01, z=_pos.z-0.01},
            maxpos = {x=_pos.x+0.01, y=_pos.y+0.01, z=_pos.z+0.01},
            minvel = s_vel_min,
            maxvel = s_vel_max,
            minacc = {x=-0.25, y=-0.28, z=-0.25},
            maxacc = {x=0.25, y=0.28, z=0.25},
            minexptime = 0.2,
            maxexptime = 0.65,
            minsize = 0.77,
            maxsize = 1.1,
            texture = spark_texture,
            glow = 14,
        })
        --Fire sound
        if def.fire_sound then minetest.sound_play(def.fire_sound, {pos=_pos, pitch=math.random(0.85,0.875), gain=def.fire_sound_gain, max_hear_distance=2*28}) end
    end

    --Projectile creation
    spawn_proj(port_a)

end

setup_projectile_register('lv')
--setup_projectile_register('mv')
--setup_projectile_register('hv')