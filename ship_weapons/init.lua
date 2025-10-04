local S = minetest.get_translator(minetest.get_current_modname())

ship_weapons = {}

-- load files
local default_path = minetest.get_modpath("ship_weapons")

dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "crafts.lua")
dofile(default_path .. DIR_DELIM .. "compat.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "beam_emitter.lua")
dofile(default_path .. DIR_DELIM .. "missile_ammo.lua")
dofile(default_path .. DIR_DELIM .. "missile_explode.lua")
dofile(default_path .. DIR_DELIM .. "missile_emitter.lua")
dofile(default_path .. DIR_DELIM .. "missile_projectile.lua")
dofile(default_path .. DIR_DELIM .. "targeting_computer.lua")
dofile(default_path .. DIR_DELIM .. "targeting_computer_adv.lua")
dofile(default_path .. DIR_DELIM .. "targeting_dish.lua")
dofile(default_path .. DIR_DELIM .. "plasma_ammo.lua")
dofile(default_path .. DIR_DELIM .. "plasma_explode.lua")
dofile(default_path .. DIR_DELIM .. "plasma_cannon_projectile.lua")
dofile(default_path .. DIR_DELIM .. "plasma_cannon.lua")
--dofile(default_path .. DIR_DELIM .. "plasma_cannon_heavy.lua") -- TODO: finish this?
dofile(default_path .. DIR_DELIM .. "rail_cannon_projectile.lua")
dofile(default_path .. DIR_DELIM .. "rail_cannon.lua")
-- disable till done..
--dofile(default_path .. DIR_DELIM .. "laser_cannon.lua")