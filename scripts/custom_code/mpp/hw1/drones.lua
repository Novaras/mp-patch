-- By: Fear
-- Readable stock code.
-- We only use drone0, since we control the parade positions using vertexes of a pre-computed icosahedron (`parade_positions`).
-- These drones are actually capable of firing since the script only issues soft move commands to reposition the drones,
-- unlike the stock code which issues parade commands (which interrupt anything the drone is doing such as orienting, tracking, attcking, etc...)

---@class DroneFrigAttribs
---@field live_drones drone_proto[]
---@field _init integer
---@field new_drones drone_proto[]
---@field targets_group string

---@class drones_proto : Ship, DroneFrigAttribs
local drones_proto = {
	drone_kill_distance = 950,
	---@type Vec3[]
	parade_positions = { -- note that the number of drones is set by the positions in this table, add more for more drones
		{210, 0, 0+10},
		{-210, 0, 0+10},
		{0, 210, 0+10},
		{0, -210, 0+10},
		{0, 0, 210+10},
		{0, 0, -210+10},
		{120, 120, 120+10},
		{-120, 120, 120+10},
		{120, -120, 120+10},
		{-120, -120, 120+10},
		{120, 120, -120+10},
		{-120, 120, -120+10},
		{120, -120, -120+10},
		{-120, -120, -120+10},
	},
	attribs = function (g, p, s)
		return {
			live_drones = {},
			_init = 0,
			new_drones = {},
			targets_group = SobGroup_Fresh("drone-frig-targets-" .. s),
		};
	end
};

--- === helpers ===

function drones_proto:killDrones()
	for _, drone in self.live_drones do
		drone:HP(0);
	end
end

function drones_proto:pruneDeadDrones()
	for i, drone in self.live_drones do
		if (drone:HP() <= 0 or drone:alive() == nil) then
			self.live_drones[i] = nil;
		end
	end
end

--- Returns `nil` if the frigate is not 'ready', meaning it is not capable of fighting with drones.
---
---@return '1'|'nil'
function drones_proto:frigateReady()
	return self:isDoingAbility(AB_Hyperspace) == 0
		and self:allInRealSpace() == 1
		and self:beingCaptured() == 0
		and self:isDoingAnyAbilities({
			AB_Hyperspace,
			AB_HyperspaceViaGate,
			AB_Dock,
			AB_Retire
		}) == 0;
end

--- Returns a drone's 'type index' (i.e drone0 -> 0, drone11 -> 11)
---
---@param drone Ship
---@return string
function drones_proto:droneTypeIndex(drone)
	return strsub(drone.type_group, 10);
end

--- Returns the correct `Position` for the given drone.
---
---@param drone Ship
---@return Position
function drones_proto:droneParadePos(drone)
	local parade_pos = {};
	for i, value in self:position() do
		parade_pos[i] = (value + self.parade_positions[tonumber(self:droneTypeIndex(drone)) + 1][i]); -- drone x, y, z pos is frigate pos + offsets in table
	end
	return parade_pos;
end

-- === actions ===

--- If we don't have our full retinue of drones, repopulates them.
--- Drone count is synced with the table of positions in `self.parade_positions`.
function drones_proto:produceMissingDrones()
	-- modkit.table.printTbl(modkit.table.map(self.live_drones, function (drone)
	-- 	return {
	-- 		own_group = drone.own_group,
	-- 		hp = drone:HP()
	-- 	};
	-- end), "live drones")
	-- print("[" .. Universe_GameTime() .. "] produce missing drones call for " .. self.own_group);
	if (modkit.table.length(self.new_drones) == 0 and modkit.table.length(self.live_drones) < modkit.table.length(self.parade_positions)) then
		self.new_drones = {};
		-- print("[" .. Universe_GameTime() .. "] frigate " .. self.own_group .. " has no drones! (tick: " .. self:tick() .. ")");
		for i = 1, modkit.table.length(self.parade_positions) do
			if (self.live_drones[i] == nil) then
				self:produceShip("kus_drone" .. i - 1);
				self.new_drones[modkit.table.length(self.new_drones) + 1] = tostring(i - 1);
			end
		end
	end
	-- print("production done!");
end

--- Adds any drones (produced by `self:produceMissingDrones`) to `self.live_drones`.
function drones_proto:addProducedDronesToList()
	-- print("[" .. Universe_GameTime() .. "] hi from drone collation run for " .. self.own_group);

	-- print("new_drones? " .. modkit.table.length(self.new_drones));

	if (modkit.table.length(self.new_drones) > 0) then
		local our_docked_drones = GLOBAL_SHIPS:drones(function (ship)
			return ship:docked(%self);
		end);
		-- print("begin assigning new drones...");
		for i, drone_type_index in self.new_drones do
			-- print("drone " .. i);
			self.live_drones[drone_type_index] = modkit.table.find(our_docked_drones, function (drone)
				return %self:droneTypeIndex(drone) == %drone_type_index;
			end) or self.live_drones[drone_type_index];

			local drone = self.live_drones[drone_type_index];
			if (drone) then
				-- print("drone link phase for drone " .. drone.own_group);
				self.new_drones[i] = nil;
				drone:link(self);
			else
				-- print("no drone to assign");
			end
		end
	end
	-- print("collection done!");
end

--- Launches any drones currently docked.
function drones_proto:launchDrones()
	for _, drone in self.live_drones do
		self:launch(drone);
	end
end

--- Syncs the ROE of all alive drones to the frigate's ROE
---
---@param ROE ROE
function drones_proto:syncDroneROEs(ROE)
	for _, drone in self.live_drones do
		drone:ROE(ROE or self:ROE());
	end
end

--- Syncs the Stance of all alive drones to the frigate's Stance
function drones_proto:syncDroneStances()
	for _, drone in self.live_drones do
		drone:stance(self:stance());
	end
end

--- If the frigate has an attack target (it was told to attack by its player), the drones will focus on these targets.
--- Otherwise, drones are free to act according to the frigates ROE.
function drones_proto:manageDroneTargets()
	if (self:attacking()) then -- if frig has targets, target them also
		-- operations where we need to fetch a collection of ships from the global list are generally slow
		-- in this case `manageDroneTargets` was producing a bottleneck, so we use direct sobgroups for performance here
		SobGroup_Clear(self.targets_group);
		SobGroup_GetCommandTargets(self.targets_group, self.own_group, COMMAND_Attack);
		for _, drone in self.live_drones do
			drone:attack(self.targets_group);
		end
	end
end

--- Issues each drone a soft move command to its matching parade position. This allows the drones to move while firing.
function drones_proto:positionLaunchedDrones()
	local position_index = 1;
	for _, drone in self.live_drones do
		if (drone:docked(self) == nil) then
			local pos = self:droneParadePos(drone);
			if (drone:attacking()) then
				if (drone:distanceTo(pos) > 100) then
					drone:move(pos);
				end
			else
				drone:parade(self);
			end
			position_index = position_index + 1;
		end
	end
end

-- === lifetime ===

--- Need to init on first `update` instead of `create` - `create` provides no group or ship id!
--- Disables the frigate's auto-launching, and initialises the drone rebuilding code to run on a fast schedule
function drones_proto:init()
	if (self._init == 0) then
		self:autoLaunch(ShipHoldStayDockedAlways);

		-- the drones are not picked up until the second run (as their data is not available on `create`, only `update`)
		-- so it would take two cycles MINIMUM for a drone to respawn and be controllable, at worst nearly 3 (i.e if a drone dies
		-- just after a cycle, it will be rebuilt next cycle, and only the cycle _after that_ would it be useable)
		-- hence, we run this restocking process at a faster rate, meaning our drone list will accurate unless a drone dies closer
		-- than `base_rate - fast_rate` seconds ago (i.e `1 - 0.5` makes us accurate to a half-second)
		if (self.collate_event_id == nil) then
			self.collate_event_id = modkit.scheduler:every(
				10,
				function ()
					-- print("[" .. Universe_GameTime() .. "] begin fast run")
					if (%self:frigateReady()) then
						%self:pruneDeadDrones();
						%self:addProducedDronesToList();
						%self:launchDrones();
					else
						%self:killDrones();
					end
					-- print("fast run end");
				end
			);
		end
		if (self.repopulate_event_id == nil) then
			self.repopulate_event_id = modkit.scheduler:every(
				20, -- seconds = this number * modkit_scheduler.seconds_per_tick
				function ()
					-- print("[" .. Universe_GameTime() .. "] begin slow run")
					if (%self:frigateReady()) then
						%self:produceMissingDrones();
					end
					-- print("slow run end");
				end
			);
		end

		self._init = 1;
	end
end

-- === hooks ===

function drones_proto:update()
	print(self.own_group .. ":update begin");
	if (self:tick() >= 3) then -- some time to undock
		self:init();

		--print("main run start: " .. Universe_GameTime());
		if (self:frigateReady()) then
			self:syncDroneStances();
			self:syncDroneROEs();
			self:manageDroneTargets();
			self:positionLaunchedDrones();
		end
		--print("main run end: " .. Universe_GameTime());
	end
	print(self.own_group .. ":update end");
end

function drones_proto:destroy()
	print(self.own_group .. ":destroy begin");
	modkit.scheduler:clear(self.repopulate_event_id);
	modkit.scheduler:clear(self.collate_event_id);

	for _, drone in self.live_drones do
		drone:HP(0);
	end
	print(self.own_group .. ":destroy end");
end

-- function drones_proto:start()
-- end

-- function drones_proto:go()
	
-- end

-- function drones_proto:finish()
-- end

modkit.compose:addShipProto("kus_dronefrigate", drones_proto);

-- === drones themselves ===

-- drones which are unlinked for 2s die (anomalous spawn condition)

---@class DroneAttribs
---@field frigate Ship|nil

---@class drone_proto : Ship, DroneAttribs
drone_proto = {
	attribs = function ()
		return {
			frigate = nil,
		};
	end
};

--- Links this drone with a frigate.
---
---@param frigate drones_proto
function drone_proto:link(frigate)
	self.frigate = frigate;
end

function drone_proto:update()
	if (self:tick() > 2) then
		if (self.frigate == nil or self.frigate:alive() == nil) then
			self:spawn(0);
			self:die();
		else
			local distance_to_position = self:distanceTo(self.frigate:droneParadePos(self));
			if (distance_to_position > 750) then
				self:speed(1.3);
			elseif (distance_to_position > 1500) then -- things look bad, just teleport into position
				self:position(self.frigate:droneParadePos(self));
			else -- close
				self:speed(1);
			end
		end
	end
end

for i = 0, 14 do
	modkit.compose:addShipProto("kus_drone" .. i, drone_proto);
end