local disallowed_targets = {
    "__builtin:item",
    "wield3d:wield_entity",
	"3d_armor_stand:armor_entity",
	"ctg_jetpack:jetpack_copper_entity",
	"ctg_jetpack:jetpack_bronze_entity",
	"ctg_jetpack:jetpack_iron_entity",
	"ctg_jetpack:jetpack_titanium_entity",
	"digilines_lcd:text",
	"digistuff:controller_entity",
	"digiterms:screen",
	"display_api:dummy_entity",
	"itemshelf:item",
	"lwcomputers:digiscreenimage",
	"lwcomputers:monitorimage",
	"minecart:marker_cube",
	"minecart:marker",
	"pipeworks:tubed_item",
	"pipeworks:color_entity",
	"dryplants:reedmace_water_entity",
	"prefab:boat",
	"protector:display",
	"streets:pedcountdown",
	"schemlib:pos1",
	"schemlib:pos2",
	"schemlib:cuboid",
	"ship_weapons:lv_tower_display",
	"ship_weapons:lv_missile_tower_display",
    "ship_weapons:mv_tower_display",
    "ship_weapons:mv_missile_tower_display",
    "ship_weapons:hv_tower_display",
    "ship_weapons:hv_missile_tower_display",
	"ship_raider:display",
	"signs_lib:text",
	"smartshop:quad_upright_sprite",
	"smartshop:item",
	"smartshop:single_sprite",
	"smartshop:single_upright_sprite",
	"smartshop:single_wielditem",
	"testcoin:item",
	"tubelib2:marker_cube",
	'x_farming:stove_food',
	"ship_holodisplay:entity",
    "ship_holodisplay:ship",
    "ship_holodisplay:scanner",
}

local update_entities = function(pos)
	local ominp = {x = (pos.x - 0.5) + 0.001953125, y = pos.y - 0.5, z = (pos.z - 0.5) + 0.001953125}
	local meta = core.get_meta(pos)
	local scanpos = {x = pos.x + meta:get_int("X"), y = pos.y + meta:get_int("Y"), z = pos.z + meta:get_int("Z")}
	local min = {x = scanpos.x - 1, y = scanpos.y, z = scanpos.z - 1}
	local max = {x = scanpos.x + 255, y = scanpos.y + 256, z = scanpos.z + 255}
	local objs = core.objects_in_area(min, max)
	for obj in objs do
		-- check if obj is a player, if not make sure it's not in the disallowed_targets list
		if obj:is_player() then
			local p = vector.round(vector.add(obj:get_pos(), {x = 0, y = 0.5, z = 0}))
			local spos = {x = ominp.x + ((p.x - scanpos.x) * 0.00390625), y = ominp.y + ((p.y - scanpos.y) * 0.00390625), z= ominp.z + ((p.z - scanpos.z) * 0.00390625)}
			core.add_entity(spos, "ship_holodisplay:entity", obj:get_player_name() .. ";" .. core.pos_to_string(p) .. ";player")
		else
			local name = obj:get_luaentity().name
			local disallowed = false
			for _, target in ipairs(disallowed_targets) do
				if name == target then
					disallowed = true
					break
				end
			end
			if not disallowed then
				local relation = "neutral"
				if name == "space_raider:raider" then
					relation = "hostile"
				-- check if it starts with ship_weapons:
				elseif string.find(name, "ship_weapons:") then
					relation = "hostile"
					name = "ship_weapons:projectile"
				end
				local is_mobs = mobs.spawning_mobs[name]
				-- get 2nd part of name split by ":" 
				name = string.split(name, ":")[2]
				-- make it uppercase first letter
				name = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
				--replace "_" and everything after "_" with " "
				name = string.gsub(name, "_.*", "")
				local nametag  = obj:get_properties().nametag
				if nametag ~= "" and nametag ~= nil then
					name = nametag
				end
				
				
				if is_mobs then
					local entity = obj:get_luaentity()
					if entity.type == "monster" then
						relation = "hostile"
					elseif entity.type == "npc" or entity.type == "animal" then
						if not entity.passive then
							relation = "neutral"
						else
							relation = "friendly"
						end							
					end
				end
				
				local p = vector.round(vector.add(obj:get_pos(), {x = 0, y = 0.5, z = 0}))
				local spos = {x = ominp.x + ((p.x - scanpos.x) * 0.00390625), y = ominp.y + ((p.y - scanpos.y) * 0.00390625), z= ominp.z + ((p.z - scanpos.z) * 0.00390625)}
				core.add_entity(spos, "ship_holodisplay:entity", name .. ";" .. core.pos_to_string(p) .. ";" .. relation)
			end
		end
	end
end

local update_ships = function (pos)
	local ominp = {x = (pos.x - 0.5) + 0.001953125, y = pos.y - 0.5, z = (pos.z - 0.5) + 0.001953125}
	local meta = core.get_meta(pos)
	local scanpos = {x = pos.x + meta:get_int("X"), y = pos.y + meta:get_int("Y"), z = pos.z + meta:get_int("Z")}
	local min = {x = scanpos.x - 1, y = scanpos.y, z = scanpos.z - 1}
	local max = {x = scanpos.x + 128, y = scanpos.y + 128, z = scanpos.z + 128}
	-- Area volume for 'core.find_nodes_in_area' is limited to 4,096,000 nodes so we need to scan in chunks of 128x128x128
	for x = min.x, max.x, 128 do
		for y = min.y, max.y, 128 do
			for z = min.z, max.z, 128 do
				local min2 = {x = x, y = y, z = z}
				local max2 = {x = x + 127, y = y + 127, z = z + 127}
				local nodes = core.find_nodes_in_area(min2, max2, {"group:jumpdrive"})
				for _, node in ipairs(nodes) do
                    local ship_name = "Unknown Ship"
                    local drive = core.get_node(node)
                    -- the name will look something like this and we just want the final part discarding the mod and the "jump_drive_" part "ship_raider:jump_drive_raider" -> "Raider"
                    ship_name = string.split(drive.name, ":")[2]
                    ship_name = string.sub(ship_name, 12)
                    ship_name = string.upper(string.sub(ship_name, 1, 1)) .. string.sub(ship_name, 2)

					-- get node 2 blocks above the jumpdrive, check if it's a protector
					local prot_pos = {x = node.x, y = node.y + 2, z = node.z}
					local protector = core.get_node(prot_pos)
					local is_protector = core.get_item_group(protector.name, "ship_protector")
					
					if is_protector > 0 then
						local prot_meta = core.get_meta(prot_pos)
						local length = prot_meta:get_int("p_length")
						local width = prot_meta:get_int("p_width")
						local height = prot_meta:get_int("p_height")
						local size  = {x = width, y = height, z = length}
						local spos = {x = ominp.x + ((node.x - scanpos.x) * 0.00390625), y = ominp.y + ((node.y - scanpos.y) * 0.00390625), z= ominp.z + ((node.z - scanpos.z) * 0.00390625)}
						local type = "unknown"
						local offset = {x = 128, y = 129, z = 128}
                        
						if node == vector.add(offset, scanpos) then
                            
							type = "self"
                        else 
                            local pitch = 2
                            local delay = 0.5
                            local vol = length * width * height
                            if vol > 100000 then
                                pitch = 1
                                delay = 1.5
                            elseif vol > 10000 then
                                pitch = 1.5
                                delay = 1
                            end
                            core.after(delay, function()
                                core.sound_play("ship_holodisplay_scanner", {pos = spos, max_hear_distance = 5, gain = 0.025, pitch = pitch})
                            end)
						end
						core.add_entity(spos, "ship_holodisplay:ship", ship_name .. ";" .. core.pos_to_string(node) .. ";" .. core.pos_to_string(size) .. ";" .. type)
					end
					
				end
			end
		end
	end

end

core.register_node("ship_holodisplay:display", {
	description = "Holographic Display",
	-- Textures of node; +Y, -Y, +X, -X, +Z, -Z
	tiles = {"ship_holodisplay_display_top.png^[opacity:0", "ship_holodisplay_display_top.png^[opacity:0"},
	groups = {oddly_breakable_by_hand = 2, not_in_creative_inventory = 1},
	paramtype = "light",
	light_source = 12,
	use_texture_alpha = "blend",
	backface_culling = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	selection_box = {
		type = "fixed",
		fixed = {0, 0, 0, 0, 0, 0},
	},
	walkable = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.5, 0.5},
	},
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = core.get_meta(pos)
		meta:set_int("X", 0)
		meta:set_int("Y", 0)
		meta:set_int("Z", 0)
		core.get_node_timer(pos):start(2)
	end,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local meta = core.get_meta(pos)
		local formspec = "size[5,5]" ..
			"label[0.5,0.5;Scan Pos:]" ..
			"field[1,2;1,1;x;X:;".. meta:get_int("X") .."]" ..
			"field[2,2;1,1;y;Y:;".. meta:get_int("Y")  .."]" ..
			"field[3,2;1,1;z;Z:;".. meta:get_int("Z")  .."]" ..
			"button[1,3;3,1;show;Toggle Highlight]"..
			"button_exit[1,4.5;3,1;submit;Submit]"
		clicker:get_meta():set_string("holonode", core.serialize(pos))
		core.show_formspec(clicker:get_player_name(), "ship_holodisplay", formspec)
	end,
	on_timer = function(pos, elapsed)
        core.add_entity(vector.add(pos, {x = 0, y = -0.5, z =0}), "ship_holodisplay:scanner")
		update_ships(pos)
		update_entities(pos)
		core.get_node_timer(pos):start(2)
	end,
	on_blast = function()
		-- TODO: handle destroy...
	end,
})

core.register_node("ship_holodisplay:display_off", {
	description = "Holographic Display Off",
	-- Textures of node; +Y, -Y, +X, -X, +Z, -Z
	tiles = {"ship_holodisplay_display_top.png", "ship_holodisplay_display_top.png"},
	groups = {oddly_breakable_by_hand = 2, not_in_creative_inventory = 1},
	use_texture_alpha = "blend",
	backface_culling = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	selection_box = {
		type = "fixed",
		fixed = {0, 0, 0, 0, 0, 0},
	},
	walkable = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.0, -0.0, -0.0, 0.0, -0.0, 0.0},
	},
	on_blast = function()
		-- TODO: handle destroy...
	end,
})

core.register_entity("ship_holodisplay:entity", {
	initial_properties = {
		physical = false,
		visual = "cube",
		visual_size = {x = 0.00390625, y = 0.00390625, z = 0.00390625},
		collisionbox = {-0.001953125, -0.001953125, -0.001953125, 0.001953125, 0.001953125, 0.001953125},
		collide_with_objects = false,
		textures = {},
		glow = 14,
        use_texture_alpha = true,
	},
	_player = "",
	_player_pos = {x = 0, y = 0, z = 0},
	_type = "neutral",
	on_punch = function(self, puncher)
		return true
	end,
	on_step = function(self, dtime)
		self._lifetime = (self._lifetime or 2.1) - dtime
		if self._lifetime and self._lifetime <= 0 then
			self.object:remove()
		end
	end,
	on_activate = function(self, staticdata)
		if staticdata == nil or staticdata == "" then
			self.object:remove()
		else
			local data = string.split(staticdata, ";")
			if #data ~= 3 then
				self.object:remove()
			end
            self._lifetime = 2.1
			self._player = data[1]
			self._player_pos = core.string_to_pos(data[2])
			self._type = data[3]
			
		end
        local textures = self.object:get_properties().textures
		if self._type == "hostile" then
			textures = {
                "ship_holodisplay_entity_hostile.png",
                "ship_holodisplay_entity_hostile.png",
                "ship_holodisplay_entity_hostile.png",
                "ship_holodisplay_entity_hostile.png",
                "ship_holodisplay_entity_hostile.png",
                "ship_holodisplay_entity_hostile.png"
            }
		elseif self._type == "friendly" then
			textures = {
                "ship_holodisplay_entity_friendly.png",
                "ship_holodisplay_entity_friendly.png",
                "ship_holodisplay_entity_friendly.png",
                "ship_holodisplay_entity_friendly.png",
                "ship_holodisplay_entity_friendly.png",
                "ship_holodisplay_entity_friendly.png"
            }
		elseif self._type == "player" then
			textures = {
                "ship_holodisplay_entity_player.png",
                "ship_holodisplay_entity_player.png",
                "ship_holodisplay_entity_player.png",
                "ship_holodisplay_entity_player.png",
                "ship_holodisplay_entity_player.png",
                "ship_holodisplay_entity_player.png"
            }
		else
			textures = {
                "ship_holodisplay_entity_neutral.png",
                "ship_holodisplay_entity_neutral.png",
                "ship_holodisplay_entity_neutral.png",
                "ship_holodisplay_entity_neutral.png",
                "ship_holodisplay_entity_neutral.png",
                "ship_holodisplay_entity_neutral.png"
            }
		end
        self.object:set_properties({infotext = self._player .. " " ..  core.pos_to_string(self._player_pos), textures = textures})
	end,
	get_staticdata = function(self)
		if self._player ~= "" then
			return self._player .. ";" .. core.pos_to_string(self._player_pos) .. ";" .. self._type
		end
		return ""
	end
})

core.register_entity("ship_holodisplay:scanner", {
	initial_properties = {
		physical = false,
		visual = "cube",
		visual_size = {x = 1, y = 0, z = 1},
		collisionbox = { 0, 0, 0, 0, 0, 0},
		collide_with_objects = false,
		glow = 14,
        use_texture_alpha = true,
		textures = {"ship_holodisplay_display_top.png^[opacity:191", "ship_holodisplay_display_top.png^[opacity:191"},
	},
    _lifetime = nil,
    _start_pos = nil,
    on_activate = function(self, staticdata)
        self._lifetime = 4
        self._start_pos = self.object:get_pos()
        self.object:set_velocity({x = 0, y = 0.5, z = 0})
    end,
	on_step = function(self, dtime)
		if self._lifetime and self._lifetime <= 0 then
			self.object:remove()
		else
			self._lifetime = (self._lifetime or 2) - dtime
		end
        local pos = self.object:get_pos()
        if pos then
            if pos.y >= self._start_pos.y + 1 then
                self.object:set_velocity({x = 0, y = -0.5, z = 0})
            elseif pos.y <= self._start_pos.y then
                self.object:set_velocity({x = 0, y = 0.5, z = 0})
            end
        end
	end,
    on_punch = function(self, puncher)
        return true
    end,

})


core.register_entity("ship_holodisplay:ship", {
	initial_properties = {
		physical = false,
		visual = "cube",
		visual_size = {x = 0.00390625, y = 0.00390625, z = 0.00390625},
		collisionbox = {-0.001953125, -0.001953125, -0.001953125, 0.001953125, 0.001953125, 0.001953125},
		collide_with_objects = false,
		glow = 14,
        use_texture_alpha = true,
		textures = {},
	},
	_name = "",
	_pos = {x = 0, y = 0, z = 0},
	_size = {x = 0, y = 0, z = 0},
	_type = "unknown",
	on_punch = function(self, puncher)
		return true
	end,
	on_step = function(self, dtime)
		if self._lifetime and self._lifetime <= 0 then
			self.object:remove()
		else
			self._lifetime = (self._lifetime or 2.1) - dtime
		end
	end,
	on_activate = function(self, staticdata)
		if staticdata == nil or staticdata == "" then
			self.object:remove()
		else
            self._lifetime = 2.1
			local data = string.split(staticdata, ";")
			if #data ~= 4 then
				self.object:remove()
			end
			self._name = data[1]
			self._pos = core.string_to_pos(data[2])
			self._size = core.string_to_pos(data[3])
			self._type = data[4]
		end
		local min = {x = self._pos.x - self._size.x, y = self._pos.y - self._size.y, z = self._pos.z - self._size.z}
		local max = {x = self._pos.x + self._size.x, y = self._pos.y + self._size.y, z = self._pos.z + self._size.z}
		local size = vector.multiply(vector.subtract(max, min), 0.00390625)
		local textures = {
            "ship_holodisplay_ship_unknown.png",
            "ship_holodisplay_ship_unknown.png",
            "ship_holodisplay_ship_unknown.png",
            "ship_holodisplay_ship_unknown.png",
            "ship_holodisplay_ship_unknown.png",
            "ship_holodisplay_ship_unknown.png"
        }
		if self._type == "self" then
			textures = {
                "ship_holodisplay_ship_self.png",
                "ship_holodisplay_ship_self.png",
                "ship_holodisplay_ship_self.png",
                "ship_holodisplay_ship_self.png",
                "ship_holodisplay_ship_self.png",
                "ship_holodisplay_ship_self.png"
            }
		elseif self._type == "hostile" then
			textures = {
                "ship_holodisplay_ship_hostile.png",
                "ship_holodisplay_ship_hostile.png",
                "ship_holodisplay_ship_hostile.png",
                "ship_holodisplay_ship_hostile.png",
                "ship_holodisplay_ship_hostile.png",
                "ship_holodisplay_ship_hostile.png"
            }
		elseif self._type == "friendly" then
			textures = {
                "ship_holodisplay_ship_friendly.png",
                "ship_holodisplay_ship_friendly.png",
                "ship_holodisplay_ship_friendly.png",
                "ship_holodisplay_ship_friendly.png",
                "ship_holodisplay_ship_friendly.png",
                "ship_holodisplay_ship_friendly.png"
            }
		end

		self.object:set_properties({infotext = self._name .. " " .. core.pos_to_string(self._pos), visual_size = size, textures = textures})
	end,
	get_staticdata = function(self)
		return self._name .. ";" .. core.pos_to_string(self._pos) .. ";" .. core.pos_to_string(self._size) .. ";" .. self._type
	end
})

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "ship_holodisplay" then
		if fields["submit"] then
			local pos = core.deserialize(player:get_meta():get_string("holonode"))
			local meta = core.get_meta(pos)
			meta:set_int("X", tonumber(fields["x"]))
			meta:set_int("Y", tonumber(fields["y"]))
			meta:set_int("Z", tonumber(fields["z"]))
		elseif fields["show"] then
			local pos = core.deserialize(player:get_meta():get_string("holonode"))
			local meta = core.get_meta(pos)
			meta:set_int("show", (meta:get_int("show") > 0) and 0 or 1)
		end
	end
end)
