local function register_lv_drive(data)
    data.modname = "ship_machine"
    -- data.charge_max = 8
    -- data.speed = 3
    data.tier = "LV"
    data.typename = "gravity_drive"
    ship_machine.register_engine(data)
end

register_lv_drive({
    machine_name = "gravity_drive_lite",
    machine_desc = "Gravity Generator Lite",
    demand = {1500},
    charge_max = 6,
    gravity = 0.6,
    speed = 4,
    digiline_effector = ship_machine.gravity_drive_digiline_effector
})

register_lv_drive({
    machine_name = "gravity_drive",
    machine_desc = "Gravity Generator",
    demand = {2500},
    charge_max = 8,
    gravity = 0.95,
    speed = 5,
    digiline_effector = ship_machine.gravity_drive_lite_digiline_effector
})

register_lv_drive({
    machine_name = "gravity_drive_admin",
    machine_desc = "Gravity Generator Admin",
    demand = {0},
    charge_max = 0,
    gravity = 0.96,
    speed = 5,
    digiline_effector = ship_machine.gravity_drive_digiline_effector
})

ship_machine.register_jumpship({
    machine_name = "jump_drive",
    machine_desc = "Jump Drive Allocator",
    typename = "jump_drive"
})

ship_machine.register_jumpship({
    machine_name = "jump_drive_spawn",
    machine_desc = "Jump Drive - Orbital Station",
    typename = "jump_drive_spawn"
})
