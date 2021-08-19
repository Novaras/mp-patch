-- Proto for any ships which are captured by salcaps via latching and waiting instead of dragging the ship.

---@class AlternateCapturableProto : Ship
mpp_map_entity_proto = {};

--- Sets the ship's inherent vis to Full, also makes the ship alternate-capturable for salvettes (latch and wait ala marines).
function mpp_map_entity_proto:init()
	if (self._init == nil) then
		self:visibility(VisFull);

		self._init = 1;
	end
end

function mpp_map_entity_proto:update()
	self:init();
end

modkit.compose:addShipProto("mpp_dreadnaught", mpp_map_entity_proto);