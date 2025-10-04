local function register_lv_drive(data)
    data.modname = "ship_machine"
    data.tier = "LV"
    data.typename = "gravity_drive"
    ship_machine.register_engine(data)
end

local function register_mv_drive(data)
    data.modname = "ship_machine"
    data.tier = "MV"
    data.typename = "gravity_drive"
    data.upgrade = 1
    ship_machine.register_engine(data)
end

local function register_hv_drive(data)
    data.modname = "ship_machine"
    data.tier = "HV"
    data.typename = "gravity_drive"
    data.upgrade = 2
    ship_machine.register_engine(data)
end

-------------------------------------------------------------------------

-- low voltage (lite)
register_lv_drive({
    machine_name = "gravity_drive_lite",
    machine_desc = "Gravity Generator Lite",
    demand = {4600},
    charge_max = 10,
    gravity = 0.713,
    speed = 4,
    digiline_effector = ship_machine.gravity_drive_lite_digiline_effector
})

-- medium voltage
register_mv_drive({
    machine_name = "gravity_generator",
    machine_desc = S("Gravity Generator"),
    demand = {6000, 5600, 5000},
    charge_max = 8,
    gravity = 0.876,
    speed = 5,
    digiline_effector = ship_machine.gravity_drive_lite_digiline_effector
})

-- high voltage
register_hv_drive({
    machine_name = "gravity_generator",
    machine_desc = S("Gravity Generator"),
    demand = {8000, 7400, 7000},
    charge_max = 7,
    gravity = 0.957,
    speed = 6,
    digiline_effector = ship_machine.gravity_drive_lite_digiline_effector
})

-- low voltage for ship
register_lv_drive({
    machine_name = "gravity_drive",
    machine_desc = "Gravity Generator",
    demand = {5000},
    charge_max = 8,
    gravity = 0.792,
    speed = 5,
    digiline_effector = ship_machine.gravity_drive_lite_digiline_effector
})

-- admin
register_lv_drive({
    machine_name = "gravity_drive_admin",
    machine_desc = "Gravity Generator Admin",
    demand = {0},
    charge_max = 0,
    gravity = 0.96,
    speed = 5,
    digiline_effector = ship_machine.gravity_drive_digiline_effector
})

--------------------------------------------------

-- proto_scout jumpdrive
ship_machine.register_jumpship({
    modname = "ship_machine",
    machine_name = "jump_drive",
    machine_desc = "Jump Drive Allocator",
    typename = "jump_drive",
    do_protect = false,
    size = {
        w = 12,
        h = 12,
        l = 15
    },
    ship_name = "Jumpship",
    jump_dist = 1500,
    hp = 1000,
    shield = 1000,
})

-- admin
ship_machine.register_jumpship({
    modname = "ship_machine",
    machine_name = "jump_drive_spawn",
    machine_desc = "Jump Drive - Orbital Station",
    typename = "jump_drive_spawn",
    do_protect = false,
    size = {
        w = 171,
        h = 56,
        l = 219
    },
    ship_name = "Orbital Station",
    hp = 1000000,
    shield = 500000,
})