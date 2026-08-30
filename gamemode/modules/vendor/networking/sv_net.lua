util.AddNetworkString("axVendorOpen")
util.AddNetworkString("axVendorClose")
util.AddNetworkString("axVendorTrade")

util.AddNetworkString("axVendorEdit")
util.AddNetworkString("axVendorEditFinish")
util.AddNetworkString("axVendorEditor")
util.AddNetworkString("axVendorMoney")
util.AddNetworkString("axVendorStock")
util.AddNetworkString("axVendorAddItem")

net.Receive("axVendorClose", function(length, client)
		local entity = client.axVendor

		if (IsValid(entity)) then
			for k, v in ipairs(entity.receivers) do
				if (v == client) then
					table.remove(entity.receivers, k)

					break
				end
			end

			client.axVendor = nil
		end
	end)

local function UpdateEditReceivers(receivers, key, value)
    net.Start("axVendorEdit")
		net.WriteString(key)
		net.WriteType(value)
	net.Send(receivers)
end

net.Receive("axVendorEdit", function(length, client)
	if (!CAMI.PlayerHasAccess(client, "Parallax - Manage Vendors", nil)) then
		return
	end

	local entity = client.axVendor

	if (!IsValid(entity)) then
		return
	end

	local key = net.ReadString()
	local data = net.ReadType()
	local feedback = true

	if (key == "name") then
		entity:SetDisplayName(data)
	elseif (key == "description") then
		entity:SetDescription(data)
	elseif (key == "bubble") then
			entity:SetNoBubble(data)
	elseif (key == "mode") then
	        local uniqueID = data[1]
	        entity.items[uniqueID] = entity.items[uniqueID] or {}
	        entity.items[uniqueID][VENDOR_MODE] = data[2]

			UpdateEditReceivers(entity.receivers, key, data)
		elseif (key == "price") then
			local uniqueID = data[1]
			data[2] = tonumber(data[2])

			if (data[2]) then
				data[2] = math.Round(data[2])
			end

			entity.items[uniqueID] = entity.items[uniqueID] or {}
			entity.items[uniqueID][VENDOR_PRICE] = data[2]

			UpdateEditReceivers(entity.receivers, key, data)

			data = uniqueID
		elseif (key == "stockDisable") then
			local uniqueID = data

			entity.items[uniqueID] = entity.items[uniqueID] or {}
			entity.items[uniqueID][VENDOR_MAXSTOCK] = nil

			UpdateEditReceivers(entity.receivers, key, uniqueID)

			data = uniqueID
		elseif (key == "stockMax") then
			local uniqueID = data[1]
			data[2] = math.max(math.Round(tonumber(data[2]) or 1), 1)

			entity.items[uniqueID] = entity.items[uniqueID] or {}
			entity.items[uniqueID][VENDOR_MAXSTOCK] = data[2]
			entity.items[uniqueID][VENDOR_STOCK] = math.Clamp(entity.items[uniqueID][VENDOR_STOCK] or data[2], 1, data[2])

			data[3] = entity.items[uniqueID][VENDOR_STOCK]

			UpdateEditReceivers(entity.receivers, key, data)

			data = uniqueID
		elseif (key == "stock") then
			local uniqueID = data[1]

			entity.items[uniqueID] = entity.items[uniqueID] or {}

			if (!entity.items[uniqueID][VENDOR_MAXSTOCK]) then
				data[2] = math.max(math.Round(tonumber(data[2]) or 0), 0)
				entity.items[uniqueID][VENDOR_MAXSTOCK] = data[2]
			end

			data[2] = math.Clamp(math.Round(tonumber(data[2]) or 0), 0, entity.items[uniqueID][VENDOR_MAXSTOCK])
			entity.items[uniqueID][VENDOR_STOCK] = data[2]

			UpdateEditReceivers(entity.receivers, key, data)

			data = uniqueID
		elseif (key == "faction") then
			local faction = ax.faction.teams[data]

			if (faction) then
				entity.factions[data] = !entity.factions[data]

				if (!entity.factions[data]) then
					entity.factions[data] = nil
				end
			end

			local uniqueID = data
			data = {uniqueID, entity.factions[uniqueID]}
		elseif (key == "class") then
			local class

			for _, v in ipairs(ax.class.list) do
				if (v.uniqueID == data) then
					class = v

					break
				end
			end

			if (class) then
				entity.classes[data] = !entity.classes[data]

				if (!entity.classes[data]) then
					entity.classes[data] = nil
				end
			end

			local uniqueID = data
			data = {uniqueID, entity.classes[uniqueID]}
		elseif (key == "model") then
			entity:SetModel(data)
			entity:InitPhysObj()
			entity:SetAnim()
		elseif (key == "useMoney") then
			if (entity.money) then
				entity:SetMoney()
			else
				entity:SetMoney(0)
			end
		elseif (key == "money") then
			data = math.Round(math.abs(tonumber(data) or 0))

			entity:SetMoney(data)
			feedback = false
		elseif (key == "scale") then
			data = tonumber(data) or 0.5

			entity.scale = data

			UpdateEditReceivers(entity.receivers, key, data)
		end

		MODULE:SaveData()

		if (feedback) then
			local receivers = {}

			for _, v in ipairs(entity.receivers) do
				if (CAMI.PlayerHasAccess(v, "Parallax - Manage Vendors", nil)) then
					receivers[#receivers + 1] = v
				end
			end

			net.Start("axVendorEditFinish")
				net.WriteString(key)
				net.WriteType(data)
			net.Send(receivers)
		end
end)

net.Receive("axVendorTrade", function(length, client)
		if ((client.axVendorTry or 0) < CurTime()) then
			client.axVendorTry = CurTime() + 0.33
		else
			return
		end

		local entity = client.axVendor

		if (!IsValid(entity) or client:GetPos():Distance(entity:GetPos()) > 192) then
			return
		end

		if (!entity:CanAccess(client)) then
			return
		end

		local uniqueID = net.ReadString()
		local isSellingToVendor = net.ReadBool()

		if (entity.items[uniqueID] and
			hook.Run("CanPlayerTradeWithVendor", client, entity, uniqueID, isSellingToVendor) != false) then
			local price = entity:GetPrice(uniqueID, isSellingToVendor)

			if (isSellingToVendor) then
				local found = false
				local name

				if (!entity:HasMoney(price)) then
					return client:NotifyLocalized("vendorNoMoney")
				end

				local stock, max = entity:GetStock(uniqueID)

				if (stock and stock >= max) then
					return client:NotifyLocalized("vendorMaxStock")
				end

				local invOkay = true

				for _, item in pairs(client:GetCharacter():GetInventory():GetItems()) do
					if (item.class == uniqueID and item:GetID() != 0 and ax.item.instances[item:GetID()] and item:GetData("equip", false) == false) then
						invOkay = item:Remove()
						found = true
						name = L(item.name, client)

						break
					end
				end

				if (!found) then
					return
				end

				if (!invOkay) then
					client:GetCharacter():GetInventory():Sync(client, true)
					return client:NotifyLocalized("tellAdmin", "trd!iid")
				end

				client:GetCharacter():GiveMoney(price, price == 0)
				client:NotifyLocalized("businessSell", name, ax.currencies:Format(price, "default"))
				entity:TakeMoney(price)
				entity:AddStock(uniqueID)

				if ( ax.log and isfunction(ax.log.Add) ) then
					ax.log:Add(client, "vendorSell", name, entity:GetDisplayName(), ax.currencies:Format(price, "default"))
				end
			else
				local stock = entity:GetStock(uniqueID)

				if (stock and stock < 1) then
					return client:NotifyLocalized("vendorNoStock")
				end

				if (!client:GetCharacter():HasMoney(price)) then
					return client:NotifyLocalized("canNotAfford")
				end

				if ( !entity:CanSellToPlayer(client, uniqueID) ) then
					return false
				end

				local name = L(ax.item.stored[uniqueID].name, client)

				client:GetCharacter():TakeMoney(price, price == 0)
				client:NotifyLocalized("businessPurchase", name, ax.currencies:Format(price, "default"))

				entity:GiveMoney(price)

				if (!client:GetCharacter():GetInventory():Add(uniqueID)) then
					ax.item:Spawn(uniqueID, client:GetPos() + Vector(0, 0, 8), Angle(0, 0, 0))
				else
					net.Start("axVendorAddItem")
						net.WriteString(uniqueID)
					net.Send(client)
				end

				entity:TakeStock(uniqueID)

				if ( ax.log and isfunction(ax.log.Add) ) then
					ax.log:Add(client, "vendorBuy", name, entity:GetDisplayName(), ax.currencies:Format(price, "default"))
				end
			end

			MODULE:SaveData()
			hook.Run("CharacterVendorTraded", client, entity, uniqueID, isSellingToVendor)
		else
			client:NotifyLocalized("vendorNoTrade")
		end
	end)