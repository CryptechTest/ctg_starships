local S = minetest.get_translator(minetest.get_current_modname())

local time_scl = 50

local function round(v)
    return math.floor(v + 0.5)
end

local function needs_charge(pos)
    local meta = minetest.get_meta(pos)
    local charge = meta:get_int("charge")
    local charge_max = meta:get_int("charge_max")
    return charge < charge_max
end
