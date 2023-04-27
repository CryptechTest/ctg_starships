minetest.register_craft({
    output = "ship_parts:metal_support 3",
    recipe = {{"technic:stainless_steel_ingot", "", "technic:stainless_steel_ingot"},
              {"", "technic:stainless_steel_ingot", ""},
              {"technic:stainless_steel_ingot", "", "technic:stainless_steel_ingot"}}
})

minetest.register_craft({
    output = "ship_parts:aluminum_support 3",
    recipe = {{"ctg_world:aluminum_ingot", "", "ctg_world:aluminum_ingot"}, {"", "ctg_world:aluminum_ingot", ""},
              {"ctg_world:aluminum_ingot", "", "ctg_world:aluminum_ingot"}}
})
