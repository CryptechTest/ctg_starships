local S = minetest.get_translator(minetest.get_current_modname())

minetest.register_node("ship_parts:metal_support", {
    description = S("Stainless Steel Support"),
    tiles = {{
        name = "steel_support.png",
        backface_culling = false
    }},
    groups = {
        cracky = 1,
        metal = 1,
        level = 1
    },
    sounds = default.node_sound_metal_defaults(),
    drawtype = "glasslike_framed",
    -- climbable = true,
    sunlight_propagates = true,
    backface_culling = false,
    paramtype = "light"
})

minetest.register_node("ship_parts:aluminum_support", {
    description = S("Aluminum Support"),
    tiles = {{
        name = "aluminum_support.png",
        backface_culling = false
    }},
    groups = {
        cracky = 1,
        metal = 1,
        level = 1
    },
    sounds = default.node_sound_metal_defaults(),
    drawtype = "glasslike_framed",
    -- climbable = true,
    sunlight_propagates = true,
    paramtype = "light"
})

local function register_assembler(data)

    local machine_name = string.lower(data.name)
    local machine_desc = data.name

    local update_formspec = function(pos, data)
        local formspec = nil

        local btnName = "Launch"

        local bg = "image[0,0.5;9.78,6.5;starfield_2.png]"

        formspec =
            "formspec_version[3]" .. "size[8,10;]" .. "real_coordinates[false]" .. bg .. "label[0,0;Assembler: " ..
                machine_desc .. "]" .. "list[current_name;src;2,1;1,1;]" .. "list[current_name;dst;5,1;1,1;]" ..
                "list[current_player;main;0,6.25;8,4;]" .. "listring[current_name;dst]" ..
                "listring[current_player;main]" .. "listring[current_name;src]" .. "listring[current_player;main]" ..
                "button[3,3;4,1;launch;" .. btnName .. "]"

        return formspec
    end

    local on_receive_fields = function(pos, formname, fields, sender)
        if fields.quit then
            return
        end
        local node = minetest.get_node(pos)
        local meta = minetest.get_meta(pos)
        local enabled = false
        if fields.toggle then
            if meta:get_int("enabled") == 1 then
                meta:set_int("enabled", 0)
            else
                meta:set_int("enabled", 1)
                enabled = true
            end
        end

        local formspec = update_formspec(pos, data)
        meta:set_string("formspec", formspec)
    end

    minetest.register_node("ship_parts:assembler", {
        description = S("Starship Assembler"),
        tiles = {{
            name = "ship_deployer.png"
            -- backface_culling = false
        }},
        groups = {
            cracky = 1,
            metal = 1,
            level = 1
        },
        sounds = default.node_sound_metal_defaults(),
        -- drawtype = "glasslike_framed",
        -- climbable = true,
        -- sunlight_propagates = true,
        paramtype = "light",

        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", "Starship Assembler " .. "-" .. " " .. machine_desc)
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        can_dig = technic.machine_can_dig,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            inv:set_size("src", 1)
            inv:set_size("dst", 1)
            meta:set_int("enabled", 1)
            meta:set_string("formspec", update_formspec(pos, data))
        end
    })

end

register_assembler({
    name = "Scout"
});
