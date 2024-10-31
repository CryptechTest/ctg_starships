
--Global settings
local damage_multiplier =  1
local combine_velocity = false
local projectile_raycast_dist = 0.5

function ship_weapons.get_spread(spread)
    return (math.random(-32768, 32768)/65536)*spread
end

function ship_weapons.damage_aoe(damage, puncher, pos, radius)
    local targs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, radius)
    for _,t in pairs(targs) do
        local dist=math.sqrt(((t:get_pos().x-pos.x)^2)+((t:get_pos().y-pos.y)^2)+((t:get_pos().z-pos.z)^2))
        local DistDamage=damage/math.max(dist, 1)
        t:punch(puncher, 1.0, {
            full_punch_interval=1.0,
            damage_groups={fleshy=DistDamage},
        }, nil)
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

    --Main projectile registration function
    minetest.register_entity(def.name, {
        physical = false,
        is_visible = true,
        static_save = false,

        visual = "sprite",
        visual_size = {x = def.visual_size, y = def.visual_size, z = def.visual_size},
        textures = {def.texture},
        glow = aglow,
        pointable = false,

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
                amount = 16,
                time = 0.5,
                minpos = vector.subtract(pos, radius / 4),
                maxpos = vector.add(pos, radius / 4),
                minvel = {x = -0.5, y = -0.5, z = -0.5},
                maxvel = {x = 0.5, y = 0.5, z = 0.5},
                minacc = vector.new(),
                maxacc = vector.new(),
                minexptime = 2,
                maxexptime = 6,
                minsize = radius * 3,
                maxsize = radius * 5,
                texture = {
                    name = "ctg_missile_smoke.png",
                    blend = "alpha",
                    scale = 1,
                    alpha = 1.0,
                    alpha_tween = {1, 0},
                    scale_tween = {{
                        x = 0.25,
                        y = 0.25
                    }, {
                        x = 6,
                        y = 6
                    }}
                },
                collisiondetection = true,
                glow = 5,
            })
            --Death flash
            if def.hit_flare then
                minetest.add_particle({
                    pos = pos,
                    expirationtime = 0.3,
                    size = def.hit_flare_size,
                    collisiondetection = false,
                    vertical = false,
                    texture = def.hit_flare,
                    glow = def.hit_flare_glow,
                })
            end
            --Hit sound
            if def.hit_sound then
                minetest.sound_play(def.hit_sound, {pos=self.previous_pos, gain=def.hit_sound_gain, max_hear_distance=2*48})
            end
        end,

        --Performing checks every server step
        on_step = function(self, dtime)
            self.timer = self.timer + 1
            local pos = self.object:get_pos()
            --Trail particle spawner
            if def.trail_particle then
                --Smoke Effect
                minetest.add_particlespawner({
                    amount = 2,
                    time = 0.1,
                    minpos = {x=pos.x-0.1, y=pos.y-0.1, z=pos.z-0.1},
                    maxpos = {x=pos.x+0.1, y=pos.y+0.1, z=pos.z+0.1},
                    minvel = {x=-0.1, y=-0.1, z=-0.1},
                    maxvel = {x=0.1, y=0.1, z=0.1},
                    minacc = {x=0, y=def.trail_particle_gravity, z=0},
                    maxacc = {x=0, y=def.trail_particle_gravity, z=0},
                    minexptime = 4,
                    maxexptime = 6,
                    minsize = 2,
                    maxsize = 3,
                    texture = def.trail_particle_smoke,
                    glow = 3,
                })
                --Sparks Effect
                minetest.add_particlespawner({
                    amount = def.trail_particle_amount,
                    time = 0.05,
                    minpos = {x=pos.x-def.trail_particle_displacement, y=pos.y-def.trail_particle_displacement, z=pos.z-def.trail_particle_displacement},
                    maxpos = {x=pos.x+def.trail_particle_displacement, y=pos.y+def.trail_particle_displacement, z=pos.z+def.trail_particle_displacement},
                    minvel = {x=-def.trail_particle_velocity, y=-def.trail_particle_velocity, z=-def.trail_particle_velocity},
                    maxvel = {x=def.trail_particle_velocity, y=def.trail_particle_velocity, z=def.trail_particle_velocity},
                    minacc = {x=0, y=def.trail_particle_gravity, z=0},
                    maxacc = {x=0, y=def.trail_particle_gravity, z=0},
                    minexptime = 1,
                    maxexptime = 4,
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
            if self.target_pos then
                local target_delta = vector.direction(pos, self.target_pos)
                local dist_delta = vector.distance(pos, self.target_pos)
                if (self.timer % 2 == 0 and self.timer > self.target_delay) then
                    local velo = self.object:get_velocity()
                    local veln = {x=((target_delta.x+ship_weapons.get_spread(def.spread))*def.projectile_speed),
                                y=((target_delta.y+ship_weapons.get_spread(def.spread))*def.projectile_speed),
                                z=((target_delta.z+ship_weapons.get_spread(def.spread))*def.projectile_speed)}
                    local vel = vector.add(vector.multiply(velo, 5), veln) / 6
                    self.object:setvelocity(vel)
                end
                if (dist_delta < 1.8) then
                    --self.node_hit = true 
                    if def.on_timeout then
                        def.on_timeout(self, self.target_pos)
                    end
                    --Remove the projectile
                    self.object:remove()
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
                        ship_weapons.damage_aoe(def.damage, self.owner, target.intersection_point, def.aoe_radius)
                    end
                    if def.on_hit then
                        def.on_hit(self, target)
                    end
                    self.node_hit = true
                end
            elseif target and target.type == "object" then
                if def.aoe then
                    ship_weapons.damage_aoe(def.damage, self.owner, target.intersection_point, def.aoe_radius)
                else
                    target.ref:punch(self.owner, 1.0, {
                    full_punch_interval=1.0,
                    damage_groups={fleshy=def.damage},
                    }, nil)
                end
                if def.on_hit then
                    def.on_hit(self, target)
                end
                self.node_hit = true
            end

            --Spawn hit particles, execute on_hit if defined, drop an item if defined and remove the object
            if self.node_hit then
                --Little hit flares
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
                --Hit particles
                if def.hit_particle then
                    minetest.add_particlespawner({
                        amount = def.hit_particle_amount,
                        time = 0.05,
                        minpos = self.previous_pos,
                        maxpos = self.previous_pos,
                        minvel = {x=-def.hit_particle_velocity, y=-def.hit_particle_velocity, z=-def.hit_particle_velocity},
                        maxvel = {x=def.hit_particle_velocity, y=def.hit_particle_velocity+1, z=def.hit_particle_velocity},
                        minacc = {x=0, y=def.hit_particle_gravity, z=0},
                        maxacc = {x=0, y=def.hit_particle_gravity, z=0},
                        minexptime = 2,
                        maxexptime = 4,
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
                --Hit sound
                if def.hit_sound then
                    minetest.sound_play(def.hit_sound, {pos=self.previous_pos, gain=def.hit_sound_gain, max_hear_distance=2*64})
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
                        expirationtime = 0.2,
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
        name = "ctg_missile_vapor.png",
        blend = "alpha",
        scale = 1,
        alpha = 1.0,
        alpha_tween = {1, 0},
        scale_tween = {{
            x = 0.5,
            y = 0.5
        }, {
            x = 2.5,
            y = 2.2
        }}
    }
    local spark_texture = {
        name = "ctg_spark.png",
        blend = "alpha",
        scale = 1,
        alpha = 1.0,
        alpha_tween = {1, 0.5},
        scale_tween = {{
            x = 0.5,
            y = 0.5
        }, {
            x = 0,
            y = 0
        }}
    }
    local radius = 1.5
    local spread = 1
    if tier == 'mv' then
        radius = 2.6
        spread = 0.5 
    elseif tier == 'hv' then
        radius = 4
        spread = 0.25
    end
    local def = { 
        name = modname .. ':' .. tier .. '_ship_missile',
        spread = spread,
        cooldown = 1,
        flare = "tnt_boom.png",
        flare_size = 10,
        flare_glow = 14,
        hit_flare = "tnt_boom.png",
        hit_flare_size = 8,
        hit_flare_glow = 14,
        trail_particle = spark_texture,
        trail_particle_smoke = smoke_texture,
        trail_particle_velocity = 0.1,
        trail_particle_gravity = 0.015,
        trail_particle_size = 0.8,
        trail_particle_amount = 4,
        trail_particle_displacement = 0.008,
        trail_particle_glow = 14,
        reload_sound = "bweapons_hitech_pack_missile_launcher_reload",
        reload_sound_gain = 0.25,
        projectile_speed = 9,
        projectile_gravity = 0,
        projectile_timeout = 1600,
        projectile_texture = "ctg_"..tier.."_missile_entity.png",
        projectile_glow = 12,
        projectile_visual_size = 0.5,
        on_hit = function(self, target)
            if not minetest.is_protected(target.intersection_point, "") then
                ship_weapons.boom(target.intersection_point, { radius = radius, ignore_protection = false })
            else
                ship_weapons.safe_boom(target.intersection_point, { radius = radius, ignore_protection = false })
            end
        end,
        on_timeout = function(self)
            if not minetest.is_protected(self.previous_pos, "") then
                ship_weapons.boom(self.previous_pos, { radius = radius, ignore_protection = false })
            else
                ship_weapons.safe_boom(self.previous_pos, { radius = radius, ignore_protection = false })
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
    local hit_particle_velocity = def.hit_particle_velocity or 2
    local hit_particle_gravity = def.hit_particle_gravity or -10
    local hit_particle_size = def.hit_particle_size or 3
    local hit_particle_min_size = math.floor(hit_particle_size/2)
    local hit_particle_amount = def.hit_particle_amount or 32
    local hit_particle_glow = 0
    local drop_chance = def.drop_chance or 0.9
    local fire_sound_gain = def.fire_sound_gain or 1
    local hit_sound_gain = def.hit_sound_gain or 0.25
    local reload_sound_gain = def.reload_sound_gain or 0.25
    local trail_particle_distance = def.hitscan_particle_distance or 0.5
    local trail_particle_velocity = def.trail_particle_velocity or 1
    local trail_particle_gravity = def.trail_particle_gravity or 0
    local trail_particle_size = def.trail_particle_size or 1
    local trail_particle_min_size = math.floor(trail_particle_size/2)
    local trail_particle_amount = def.trail_particle_amount or 4
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
    local projectile_texture = def.projectile_texture or "bweapons_api_missing_texture.png"
    local projectile_glow = def.projectile_glow or false
    local projectile_visual_size = def.projectile_visual_size or 1

    --Make a projectile definition and register projectile
    local projectiledef = {
        name=def.name.."_projectile",
        damage=damage,
        timeout=projectile_timeout,
        projectile_speed=projectile_speed,
        projectile_gravity=projectile_gravity,
        spread=spread,
        aoe=aoe,
        aoe_radius=aoe_radius,
        visual_size=projectile_visual_size,
        texture=projectile_texture,
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

function ship_weapons.launch_projectile(custom_def, operator, origin, target, object_target)

    local tier = custom_def.tier or "lv"
    local def = {
        fire_sound = "bweapons_hitech_pack_missile_launcher_fire",
        fire_sound_gain = 1.5,
        flare = "tnt_boom.png",
        flare_size = 8,
        flare_glow = 14,
        delay = custom_def.delay or 3
    }
    local spark_texture = {
        name = "ctg_spark.png",
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

    local proj_name = 'ship_weapons:'..tier..'_ship_missile'    
    local projectile_speed = custom_def.projectile_speed or 2
    local projectile_gravity = 0
    local spread = 0.25

    local shot_amount = custom_def.count or 1;
    local spawndist = 1.1
    
    local originpos = origin
    --Get port position to use based on facing
    local dir = ship_weapons.get_port_direction(origin)
    local vel = vector.multiply(dir, 16)
    --Set projectile port origin position
    local pos = {x=originpos.x+dir.x*spawndist, y=originpos.y+dir.y*spawndist, z=originpos.z+dir.z*spawndist}

    --Projectile creation
    for i = 0,shot_amount-1,1
    do
        local obj = minetest.add_entity(pos, proj_name.."_projectile")
        if not obj then return end
        --Set projectile owner/operator
        obj:get_luaentity().owner = operator
        --Set previous pos when just spawned
        obj:get_luaentity().previous_pos = pos
        --Set the target pos when just spawned
        obj:get_luaentity().target_pos = target
        obj:get_luaentity().target_delay = def.delay
        obj:get_luaentity().object_target = object_target
        --Combine velocity with launch velocity
        obj:setvelocity({x=((dir.x+ship_weapons.get_spread(spread))*projectile_speed)+vel.x,
                        y=((dir.y+ship_weapons.get_spread(spread))*projectile_speed)+vel.y,
                        z=((dir.z+ship_weapons.get_spread(spread))*projectile_speed)+vel.z})
        obj:setacceleration({x=0, y=projectile_gravity, z=0})
    end
        
    --Fire flash
    minetest.add_particle({
        pos = pos,
        expirationtime = 0.1,
        size = def.flare_size,
        collisiondetection = false,
        vertical = false,
        texture = def.flare,
        glow = def.flare_glow,
    })
    
    local r = 0.25
    local s_vel = vector.multiply(dir, 6)
    local s_vel_min = vector.subtract(s_vel, {x=math.random(-r,r), y=math.random(-r,r), z=math.random(-r,r)})
    local s_vel_max = vector.add(s_vel, {x=math.random(-r,r), y=math.random(-r,r), z=math.random(-r,r)})
    local s_pos = {x=originpos.x+dir.x*0.7, y=originpos.y+dir.y*0.7, z=originpos.z+dir.z*0.7}
    minetest.add_particlespawner({
        amount = 32,
        time = 0.175,
        minpos = {x=s_pos.x-0.01, y=s_pos.y-0.01, z=s_pos.z-0.01},
        maxpos = {x=s_pos.x+0.01, y=s_pos.y+0.01, z=s_pos.z+0.01},
        minvel = s_vel_min,
        maxvel = s_vel_max,
        minacc = {x=-0.25, y=-0.28, z=-0.25},
        maxacc = {x=0.25, y=0.28, z=0.25},
        minexptime = 0.3,
        maxexptime = 1.2,
        minsize = 0.7,
        maxsize = 1,
        texture = spark_texture,
        glow = 14,
    })

    --Fire sound
    if def.fire_sound then minetest.sound_play(def.fire_sound, {pos=originpos, gain=def.fire_sound_gain, max_hear_distance=2*48}) end

end

setup_projectile_register('lv')
setup_projectile_register('mv')
setup_projectile_register('hv')