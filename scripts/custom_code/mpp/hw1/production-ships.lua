local generic_proto = {};

function generic_proto:showProductionSubsystems()
	local tech_subs = {
		DefenderSubSystems = "FighterProduction",
		CorvetteDrive = "CorvetteProduction",
		CapitalShipDrive = "FrigateProduction",
		SuperCapitalShipDrive = "CapShipProduction"
	};
	for tech, subsystem in tech_subs do
		if (self.player():hasResearch(tech) == 1) then
			if (tech == "SuperCapitalShipDrive") then -- only add capship to motherships
				if (self:isMothership()) then
					SobGroup_CreateSubSystem(self.own_group, subsystem);
				end
			else
				SobGroup_CreateSubSystem(self.own_group, subsystem);
			end
		end
	end
end

function generic_proto:ensureSingleResShipQueued()
	-- predicate function
	local isOurBuilder = function (ship)
		return (ship:player().id == %self.player().id) and ship:canBuild() and ship.id ~= %self.id;
	end
	local our_builders = GLOBAL_SHIPS:filter(isOurBuilder); -- all our build capable ships
	for i = 0, 5, 1 do
		res_ship_name = self:race() .. "_researchship"; -- kus_researchship, tai_researchship
		if (i > 0) then
			res_ship_name = res_ship_name .. "_" .. i;
		end
		-- if we are building this res ship, other ships should be restricted from building it:
		for _, ship in our_builders do
			if (self:isBuilding(res_ship_name) == 1) then -- always passes???
				SobGroup_RestrictBuildOption(ship.own_group, res_ship_name);
			else
				SobGroup_UnRestrictBuildOption(ship.own_group, res_ship_name);
			end
		end
	end
end

-- ===

local motherships_proto = {};
for k, v in generic_proto do
	motherships_proto[k] = v;
end


function motherships_proto:create()
	if self.player().id == Universe_CurrentPlayer() then
		UI_SetElementVisible("NewResearchMenu", "Platform", 0);
		UI_SetElementVisible("NewResearchMenu", "Utility", 0);
	end
end

function motherships_proto:update()
	self:ensureSingleResShipQueued();
	self:showProductionSubsystems();

	-- SP stock code
	if Player_GetNumberOfSquadronsOfTypeAwakeOrSleeping(-1, "Special_Splitter" ) == 0 then		
		SobGroup_AbilityActivate(self.own_group, AB_Move, 0);
		SobGroup_AbilityActivate(self.own_group, AB_Dock, 0);
		--btn hyperspace
		if UI_IsNamedElementVisible("NewTaskbar", "btnHW1SPHyperspace") == 1 then		
			--SobGroup_AbilityActivate("Player_Ships0", AB_Hyperspace, 1)
		else
			SobGroup_AbilityActivate("Player_Ships0", AB_Hyperspace, 0)
		end
	else
		SobGroup_AbilityActivate(self.own_group, AB_Move, 1);
		SobGroup_AbilityActivate(self.own_group, AB_Dock, 1);
	end
end

modkit.compose:addShipProto("kus_mothership", motherships_proto);
modkit.compose:addShipProto("tai_mothership", motherships_proto);

-- ===

local carriers_proto = {};
for k, v in generic_proto do
	carriers_proto[k] = v;
end

function carriers_proto:create()
	if self.player().id == Universe_CurrentPlayer() then
		UI_SetElementVisible("NewResearchMenu", "Platform", 0);
		UI_SetElementVisible("NewResearchMenu", "Utility", 0);
	end
end

function carriers_proto:update()
	self:ensureSingleResShipQueued();
	self:showProductionSubsystems();

	-- SP stock code (tai cc only)
	if (self:isAnyTypeOf({"tai_carrier"})) then
		if Player_GetNumberOfSquadronsOfTypeAwakeOrSleeping(-1, "Special_Splitter" ) == 1 then
			SobGroup_AbilityActivate(self.own_group, AB_Hyperspace, 1);
		else
			SobGroup_AbilityActivate(self.own_group, AB_Hyperspace, 0);
		end
	end
end

modkit.compose:addShipProto("kus_carrier", carriers_proto);
modkit.compose:addShipProto("tai_carrier", carriers_proto);