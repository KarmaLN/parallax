local MODULE = MODULE

local function GetClientClearance(client)
	local character = client:GetCharacter()
	if ( !character or !character:GetInventory() ) then return 0 end

	return character:GetClearance()
end

function MODULE:PlayerUse(client, entity)
	local keycardLevel = entity:GetRelay("keycardLevel", 0)
	local bHasKeycard = keycardLevel > 0 and GetClientClearance(client) >= keycardLevel

	-- Non-door entities (rotating props, buttons, etc.) are only gated through use
	if ( !entity:IsDoor() ) then
		if ( keycardLevel > 0 and !bHasKeycard ) then
			if ( !client.axNextKeycardNotify or client.axNextKeycardNotify < CurTime() ) then
				client.axNextKeycardNotify = CurTime() + 1
				client:Notify("You need a level " .. keycardLevel .. " keycard to use this.", ax.notification.enums.TYPE_ERROR)
			end

			return false
		end

		return
	end

	if ( client:KeyDown(IN_WALK) ) then
		local isLocked = entity:IsLocked()
		local permsNeeded = isLocked and MODULE.Permissions.UNLOCK or MODULE.Permissions.LOCK

		if ( bHasKeycard or client:HasDoorAccess(entity, permsNeeded) ) then
			client:PerformEntityAction(entity, isLocked and "Unlock" or "Lock", 0.5, function()
				entity:ToggleDoorLock()
			end, nil)
		end

		return false
	end
end

function MODULE:PlayerReady(client)
	ax.net:Start(client, "ax.doors.permissions_sync", MODULE.AccessGroup_Permissions)
end

function MODULE:InitPostEntity()
	local bInitialized = ax.data:Get("doors_initialized", false, {
		scope = "map",
		force = true,
	})

	if ( !bInitialized ) then
		local unownableData = {}

		for _, ent in ents.Iterator() do
			if ( ent:IsDoor() ) then
				ent:SetRelay("ownable", false)
				unownableData[ent:MapCreationID()] = true
			end
		end

		ax.data:Set("doors_unownable", unownableData, { scope = "map" })
		ax.data:Set("doors_initialized", true, { scope = "map" })
	else
		local unownableDoors = ax.data:Get("doors_unownable", {}, {
			scope = "map",
			force = true,
		})

		for doorID, isUnownable in pairs(unownableDoors) do
			local door = ents.GetMapCreatedEntity(doorID)
			if ( IsValid(door) and door:IsDoor() ) then
				door:SetRelay("ownable", !isUnownable)
			end
		end
	end

	local keycardData = ax.data:Get("doors_keycards", {}, {
		scope = "map",
		force = true,
	})

	for doorID, level in pairs(keycardData) do
		local door = ents.GetMapCreatedEntity(doorID)
		if ( IsValid(door) ) then
			door:SetRelay("keycardLevel", level)
		end
	end

	for _, ent in ents.Iterator() do
		if ( ent:IsDoor() ) then
			ent:SetRelay("locked", ent:IsLocked())
		end
	end
end
