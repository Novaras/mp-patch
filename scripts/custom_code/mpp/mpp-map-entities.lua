-- Proto for any ships which are captured by salcaps via latching and waiting instead of dragging the ship.

---@class DreadnaughtProto : Ship
---@field unclaimed_tumble_target table<integer, Position>
mpp_dreadnaught_proto = {
	unclaimed_tumble_target = {0.01, 0.03, 0.02}
};

function mpp_dreadnaught_proto:ensureVisible()
	if (self:visibility() ~= VisFull) then
		self:visibility(VisFull);
	end
end

function mpp_dreadnaught_proto:ownerSpecificBehavior()
	if (self.player.id == -1) then 				-- owned by env
		self:canDoAbility(AB_Targeting, 0);
		self:canDoAbility(AB_Attack, 0);
		self:canDoAbility(AB_Move, 0);
		self:canDoAbility(AB_Steering, 0);

		-- ---@type table<integer, Position>
		-- --- we need to keep 'nudging' the tumble a little if it falls too low
		-- local extra_tumble = {};
		-- for i, v in self:tumble() do
		-- 	extra_tumble[i] = min(0.1, mpp_dreadnaught_proto.unclaimed_tumble_target[i] - v); -- min(1, target - current) = boost
		-- end
		-- self:tumble(extra_tumble);

		if (self:tumble()[1] == 0) then
			self:print("tumbling");
			self:tumble(mpp_dreadnaught_proto.unclaimed_tumble_target);
		end
	else 										-- owned by a player
		if (self:tumble()[1] ~= 0) then
			self:tumble(0);
		end
		self:canDoAbility(AB_Targeting, 1);
		self:canDoAbility(AB_Attack, 1);
		self:canDoAbility(AB_Move, 1);
		self:canDoAbility(AB_Steering, 1);
	end
end

function mpp_dreadnaught_proto:stunAndRepairIfCritical()
	self:print("check dmg...");
	if (self:HP() < 0.2) then
		self:invulnerable(1);
		self:stunned(1);
		self:tumble({0.1, 0.1, 0.1});
		self.healing = 1;
	end

	if (self.healing == 1) then
		self:playEffect("speed_burst_flash", 10);
		self:HP(self:HP() + 0.01);
		if (self:HP() > 0.8) then
			self:invulnerable(0);
			self:stunned(0);
			self:tumble(0);
			self:print("done, stop healing");
		end
	end
end

function mpp_dreadnaught_proto:update()
	self:print("update " .. self:tick() .. " begin");
	-- ensure visible to all
	if (self:tick() == 1) then
		SobGroup_SetCaptureState(self.own_group, 0);
		self:ensureVisible();

		-- modkit.table.printTbl(GLOBAL_SHIPS:all(), "global ships report");
	end
	-- behavior for owners:
	self:ownerSpecificBehavior();
	self:stunAndRepairIfCritical();
	self:print("update " .. self:tick() .. " finish");
end

modkit.compose:addShipProto("mpp_dreadnaught", mpp_dreadnaught_proto);


--- ====

---@class MoverProto : Ship
---@field dreadnaught DreadnaughtProto
mpp_mover_proto = {};

function mpp_mover_proto:update()
	if (self:tick() > 5) then
		self:ghost(0);
	end
end

function mpp_mover_proto:start()
	self:print("hi");

	self.dreadnaught = self.dreadnaught or GLOBAL_SHIPS:find(function (ship)
		return ship.type_group == "mpp_dreadnaught";
	end);


	self.dreadnaught:capturableModifier(1);
	self:canDoAbility(AB_Capture, 1);
	self:capture(self.dreadnaught);
	self:canDoAbility(AB_Capture, 0);
	self.dreadnaught:capturableModifier(0);
end

modkit.compose:addShipProto("mpp_mover", mpp_mover_proto);

-- =====

---@class MoverSpawnerProto : Ship
mpp_mover_spawner_proto = {
	max_movers = 10
};

function mpp_mover_spawner_proto:spawnNewMover()
	self:print("spawn mover call");
	local new_mover_group = self:spawnShip("mpp_mover", self:position());
	SobGroup_SetGhost(new_mover_group, 1); -- the mover must unghost itself
	local move_to = self:position();
	for i, _ in move_to do
		if (i ~= 2) then
			move_to[i] = move_to[i] + 700;
		else
			move_to[i] = move_to[i] - 200;
		end
	end
	self:print("issue move...");
	SobGroup_Move(self.player.id, new_mover_group, Volume_Fresh("mover-vol-" .. self.id .. "-" .. self:tick(), move_to));
	self:print("spawn call finished");
end

function mpp_mover_spawner_proto:update()
	self:print("tick: " .. self:tick() .. ",\tplayer (modkit): " .. self.player.id .. "\tplayer (engine): " .. SobGroup_GetPlayerOwner(self.own_group));
	if (self.player.id == -1 and self:tick() > 2) then
		if (MAP_METADATA == nil) then
			dofilepath("data:leveldata/multiplayer/deathmatch_xeno/Remnant.level");
		end

		self:print("do player swap stuff");

		local spawner_map_data = modkit.table.find(MAP_METADATA.spawners, function (spawner_data)
			return %self:distanceTo(spawner_data.spawn_pos) < 500;
		end);

		modkit.table.printTbl(spawner_map_data, self.own_group .. " metadata");

		---@type Ship
		local target_player_builder = modkit.table.find(GLOBAL_SHIPS:all(), function (ship)
			print("check ship " .. ship.id);
			print("dist: " .. ship:distanceTo(%spawner_map_data.target_player_spawn_pos));
			return ship:alive() and ship:distanceTo(%spawner_map_data.target_player_spawn_pos) < 500;
		end);

		local target_player = target_player_builder.player;

		self:print("tpi: " .. target_player.id);
		if (target_player and target_player.id ~= -1) then
			self:print("switch owner to " .. target_player.id .. " from " .. self.player.id .. "!");
			self:print("player: " .. SobGroup_GetPlayerOwner(self.own_group));
			SobGroup_SwitchOwner(self.own_group, target_player.id);
			self:print("player: " .. SobGroup_GetPlayerOwner(self.own_group));
		end
	end

	if (self:tick() >= 120) then -- grace period
		if (self.player.id ~= -1) then
			self:visibility(VisFull);
			if (mod(self:tick(), 30) == 0) then
				self:print("spawning start");
				local our_movers = GLOBAL_SHIPS:corvettes(function (ship)
					%self:print(ship.own_group .. "is mover?");
					if (ship.type_group == "mpp_mover" and %self.player.id == ship.player.id) then
						%self:print("i think " .. ship.own_group .. " belongs to us and is a mover?");
					end
					return ship.type_group == "mpp_mover" and %self.player.id == ship.player.id;
				end);
				self:print("found " .. modkit.table.length(our_movers) .. " movers");
				if (modkit.table.length(our_movers) < mpp_mover_spawner_proto.max_movers) then
					self:spawnNewMover();
				end
				self:print("spawning end");
			end
		end
	end
end

modkit.compose:addShipProto("mpp_mover_spawner", mpp_mover_spawner_proto);