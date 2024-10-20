-- backwards compat to old version

local data = {
    hp = 8
}
local ltier = 'lv'
local tmachine_name = 'beam_tower'

-- display entity shown for tower hit effect
minetest.register_entity("ship_weapons:tower_display", {
    physical = false,
    collisionbox = {-0.75, -0.75, -0.75, 0.75, 0.75, 0.75},
    visual = "wielditem",
    -- wielditem seems to be scaled to 1.5 times original node size
    visual_size = {
        x = 0.67,
        y = 0.67
    },
    hp_max = 10,
    textures = {"ship_weapons:" .. ltier .. "_tower_display_node"},
    glow = 3,

    infotext = "HP: " .. data.hp .. "/" .. data.hp .. "",

    on_death = function(self, killer)
        technic.swap_node(self.pos, "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_broken")
        minetest.get_node_timer(self.pos):start(30)
        local meta = minetest.get_meta(self.pos)
        meta:set_int("broken", 1)
        meta:set_int("hp", 0)
    end,

    on_rightclick = function(self, clicker)
        local pos = self.object:get_pos();
        if pos then
            -- self.object:remove()
            self.object:set_properties({
                is_visible = false
            })
            minetest.get_node_timer(pos):start(3)
        end
    end,

    on_punch = function(puncher, time_from_last_punch, tool_capabilities, direction, damage)

        local function on_hit(self, target)

            local node = minetest.get_node(target)
            local meta = minetest.get_meta(target)
            -- minetest.log("hit " .. node.name)

            if node.name == "ship_weapons:" .. ltier .. "_" .. tmachine_name or 
                node.name == "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_active" or
                node.name == "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_idle" then

                -- and self.object:get_player_name() == meta:get_string("owner") 

                technic.swap_node(target, "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "")
                -- spawn_particle2(target, tier)

                local hp = meta:get_int("hp") or 1
                meta:set_int("hp", hp - 1)
                meta:set_int("last_hit", 1)

                self.object:set_properties({
                    infotext = "HP: " .. meta:get_int("hp") .. "/" .. data.hp .. ""
                })

                if hp - 1 <= 0 then
                    technic.swap_node(target, "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_broken")
                    meta:set_int("broken", 1)
                    self.object:remove()
                    minetest.get_node_timer(target):start(math.random(data.repair_length, data.repair_length + 30))
                    minetest.sound_play("ctg_zap", {
                        pos = target,
                        gain = 0.8,
                        pitch = randFloat(2.2, 2.25)
                    })
                end

                return true
            elseif node.name == "ship_weapons:" .. ltier .. "_" .. tmachine_name .. "_broken" then
                local meta = minetest.get_meta(target)
                if meta:get_int("broken") == 1 then
                    self.object:remove()
                end
            end
            return false
        end

        if puncher and puncher.object then
            local pos = puncher.object:get_pos();
            on_hit(puncher, pos)
            return 0;
        end

        return damage;
    end
})
