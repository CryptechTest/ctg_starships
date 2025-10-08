-- Ammo registration function
local function register_ammo(def)

    local amount = def.amount or 1

    minetest.register_craftitem(def.name, {
        description = def.description,
        inventory_image = def.texture,
        wield_image = def.texture,
        stack_max = 16,
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
    name = "ship_weapons:lv_missile",
    description = "Light Missile",
    texture = "ctg_lv_missile.png",
    recipe = {{{'technic:carbon_plate', 'ship_parts:circuit_standard', 'technic:carbon_plate'},
               {'tnt:gunpowder', 'default:mese_crystal', 'tnt:gunpowder'},
               {'ctg_world:aluminum_ingot', 'group:coolant_water', 'ctg_world:aluminum_ingot'}}},
    amount = 8
})

register_ammo({
    name = "ship_weapons:mv_missile",
    description = "Medium Missile",
    texture = "ctg_mv_missile.png",
    recipe = {{{'technic:carbon_plate', 'ship_parts:circuit_standard', 'technic:carbon_plate'},
               {'tnt:gunpowder', 'ship_weapons:lv_missile', 'tnt:gunpowder'},
               {'ctg_world:aluminum_ingot', 'group:coolant_water', 'ctg_world:aluminum_ingot'}}},
    amount = 6
})

register_ammo({
    name = "ship_weapons:hv_missile",
    description = "Heavy Missile",
    texture = "ctg_hv_missile.png",
    recipe = {{{'technic:carbon_plate', 'ship_parts:circuit_advanced', 'technic:carbon_plate'},
               {'tnt:gunpowder', 'ship_weapons:mv_missile', 'tnt:gunpowder'},
               {'ctg_world:titanium_ingot', 'group:coolant_water', 'ctg_world:titanium_ingot'}}},
    amount = 4
})
