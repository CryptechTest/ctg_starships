local S = core.get_translator(core.get_current_modname())

orbital_battery = {}

local ship_weapon_battery = {
    size = {
        w = 8,
        h = 8,
        l = 8
    },
    name = "Orbital Weapon Battery",
    hp = 750,
    shield = 3000
}

-- load files
local default_path = core.get_modpath("orbital_battery")
dofile(default_path .. "/digilines.lua")

local function on_blast_hit(pos, intensity)
    local pos_above = vector.add(pos, {x=0,y=2,z=0})
    local ship_meta = core.get_meta(pos_above)
    local hp = ship_meta:get_int("hp")
    if hp <= 0 then
        return false
    end

    local shield = ship_meta:get_int("shield")
    if shield > 0 then
        shield = shield - intensity * 5
        ship_meta:set_int("shield", shield)
    else
        hp = hp - intensity * 5
        ship_meta:set_int("hp", hp)
    end

    intensity = intensity or 1
    intensity = math.min(intensity, 3)
    ship_weapons.safe_boom(pos, {radius = intensity * 0.5})

    return true
end

local function on_destroy(pos)
    local pos_above = vector.add(pos, {x=0,y=2,z=0})
    local ship_meta = core.get_meta(pos_above)
    local hp = ship_meta:get_int("hp")
    if hp > 0 then
        return false
    end

    local size = ship_weapon_battery.size
    local pos1 = vector.subtract(pos, {x=size.w,y=size.h,z=size.l})
    local pos2 = vector.add(pos, {x=size.w,y=size.h,z=size.l})
    local chests = core.find_nodes_in_area(pos1, pos2, { "technic:gold_chest" })
    for _, chest in pairs(chests) do
        local count = 0
        local meta = core.get_meta(chest)
        local inv = meta:get_inventory()
        local list = inv:get_list("main")
        if list then
            for _, item in pairs(list) do
                if item then
                    count = count + item:get_count()
                    inv:remove_item("main", item)
                end
            end
        end
    end

    local node_above = core.get_node(pos_above)
    local group_above = core.get_item_group(node_above.name, "ship_protector")
    if group_above > 0 then
        -- remove protection node
        core.remove_node(pos_above)
    end
    -- remove jumpdrive node
    core.remove_node(pos)

    -- create explosion...
    ship_weapons.boom(pos, {radius = 3})

    core.log("action","Destroyed JumpShip '" .. ship_weapon_battery.name .. "' at " .. core.serialize(pos))

    return true
end

-- register control console
ship_machine.register_control_console({
    typename = "orbital_battery",
    modname = "orbital_battery",
    machine_name = "platform_1",
    tier = "MV",
    jump_dist = 250,
    min_dist = 15,
    size = ship_weapon_battery.size,
    hp = ship_weapon_battery.hp,
    shield = ship_weapon_battery.shield,
    machine_desc = ship_weapon_battery.name,
    digiline_effector = orbital_battery.digiline_effector,
    do_docking = true,
    groups = {
        orbital_battery = 1
    }
});

-- register jumpship
ship_machine.register_jumpship({
    modname = "orbital_battery",
    machine_name = "jump_drive_platform_1",
    machine_desc = "Jump Drive Allocator",
    typename = "jump_drive",
    tier = "MV",
    do_protect = true,
    ship_name = ship_weapon_battery.name,
    size = ship_weapon_battery.size,
    hp = ship_weapon_battery.hp,
    shield = ship_weapon_battery.shield,
    on_blast_hit = on_blast_hit,
    on_destroy = on_destroy
});
