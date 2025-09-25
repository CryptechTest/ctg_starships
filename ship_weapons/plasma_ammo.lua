-- Ammo registration function
local function register_ammo(def)

    local amount = def.amount or 1

    minetest.register_craftitem(def.name, {
        description = def.description,
        inventory_image = def.texture,
        wield_image = def.texture,
        stack_max = 16,
	    groups = {not_in_creative_inventory = 1},
    })

    if def.recipe then
        for _, v in pairs(def.recipe) do
            minetest.register_craft({
                type = "shaped",
                output = def.name .. " " .. amount,
                recipe = v
            })
        end
    end

end

register_ammo({
    name = "ship_weapons:lv_plasma_energy_shell",
    description = "Light Plasma Shell",
    texture = "ship_weapons_energy_ball_2.png",
    --[[recipe = {{{'', 'basic_materials:energy_crystal_simple', ''},
               {'tnt:gunpowder', 'default:mese_crystal', 'tnt:gunpowder'},
               {'', 'basic_materials:energy_crystal_simple', ''}}},]]
    amount = 10
})

register_ammo({
    name = "ship_weapons:mv_plasma_energy_shell",
    description = "Medium Plasma Shell",
    texture = "ship_weapons_energy_ball_2.png",
    --[[recipe = {{{'', 'basic_materials:energy_crystal_simple', ''},
               {'tnt:gunpowder', 'ship_weapons:lv_plasma_energy_shell', 'tnt:gunpowder'},
               {'', 'basic_materials:energy_crystal_simple', ''}}},]]
    amount = 7
})

register_ammo({
    name = "ship_weapons:hv_plasma_energy_shell",
    description = "Heavy Plasma Shell",
    texture = "ship_weapons_energy_ball_2.png",
    --[[recipe = {{{'', 'basic_materials:energy_crystal_simple', ''},
               {'tnt:gunpowder', 'ship_weapons:mv_plasma_energy_shell', 'tnt:gunpowder'},
               {'', 'basic_materials:energy_crystal_simple', ''}}},]]
    amount = 5
})
