
-- luacheck: globals VENDOR_BUY VENDOR_SELL VENDOR_BOTH VENDOR_WELCOME VENDOR_LEAVE VENDOR_NOTRADE VENDOR_PRICE
-- luacheck: globals VENDOR_STOCK VENDOR_MODE VENDOR_MAXSTOCK VENDOR_SELLANDBUY VENDOR_SELLONLY VENDOR_BUYONLY VENDOR_TEXT

local MODULE = MODULE

MODULE.name = "Vendors"
MODULE.author = "KarmaLN"
MODULE.description = "Adds vendors that can be placed on the map."

CAMI.RegisterPrivilege({
	Name = "Parallax - Manage Vendors",
	MinAccess = "admin"
})

VENDOR_BUY = 1
VENDOR_SELL = 2
VENDOR_BOTH = 3

-- Keys for vendor messages.
VENDOR_WELCOME = 1
VENDOR_LEAVE = 2
VENDOR_NOTRADE = 3

-- Keys for item information.
VENDOR_PRICE = 1
VENDOR_STOCK = 2
VENDOR_MODE = 3
VENDOR_MAXSTOCK = 4

-- Sell and buy the item.
VENDOR_SELLANDBUY = 1
-- Only sell the item to the player.
VENDOR_SELLONLY = 2
-- Only buy the item from the player.
VENDOR_BUYONLY = 3

if (SERVER) then
	function MODULE:SaveData()
		local data = {}

		for _, entity in ipairs(ents.FindByClass("ax_vendor")) do
			local bodygroups = {}

			for _, v in ipairs(entity:GetBodyGroups() or {}) do
				bodygroups[v.id] = entity:GetBodygroup(v.id)
			end

			data[#data + 1] = {
				name = entity:GetDisplayName(),
				description = entity:GetDescription(),
				pos = entity:GetPos(),
				angles = entity:GetAngles(),
				model = entity:GetModel(),
				skin = entity:GetSkin(),
				bodygroups = bodygroups,
				bubble = entity:GetNoBubble(),
				items = entity.items,
				factions = entity.factions,
				classes = entity.classes,
				money = entity.money,
				scale = entity.scale
			}
		end

		self:SetData(data)
	end

	function MODULE:LoadData()
		for _, v in ipairs(self:GetData() or {}) do
			local entity = ents.Create("ax_vendor")
			entity:SetPos(v.pos)
			entity:SetAngles(v.angles)
			entity:Spawn()

			entity:SetModel(v.model)
			entity:SetSkin(v.skin or 0)
			entity:InitPhysObj()

			entity:SetNoBubble(v.bubble)
			entity:SetDisplayName(v.name)
			entity:SetDescription(v.description)

			for id, bodygroup in pairs(v.bodygroups or {}) do
				entity:SetBodygroup(id, bodygroup)
			end

			local items = {}

			for uniqueID, data in pairs(v.items) do
				items[tostring(uniqueID)] = data
			end

			entity.items = items
			entity.factions = v.factions or {}
			entity.classes = v.classes or {}
			entity.money = v.money
			entity.scale = v.scale or 0.5
		end
	end

	function MODULE:CanVendorSellItem(client, vendor, itemID)
		local tradeData = vendor.items[itemID]
		local char = client:GetCharacter()

		if (!tradeData or !char) then
			return false
		end

		if (!char:HasMoney(tradeData[1] or 0)) then
			return false
		end

		return true
	end

	ax.log.AddType("vendorUse", function(client, ...)
		local arg = {...}
		return string.format("%s used the '%s' vendor.", client:Name(), arg[1])
	end)

	ax.log.AddType("vendorBuy", function(client, ...)
		local arg = {...}

		return string.format("%s purchased a '%s' from the '%s' vendor for %s.", client:Name(), arg[1], arg[2], arg[3])
	end)

	ax.log.AddType("vendorSell", function(client, ...)
		local arg = {...}

		return string.format("%s sold a '%s' to the '%s' vendor for %s.", client:Name(), arg[1], arg[2], arg[3])
	end)
else
end

properties.Add("vendor_edit", {
	MenuLabel = "Edit Vendor",
	Order = 999,
	MenuIcon = "icon16/user_edit.png",

	Filter = function(self, entity, client)
		if (!IsValid(entity)) then return false end
		if (entity:GetClass() != "ax_vendor") then return false end
		if (!gamemode.Call( "CanProperty", client, "vendor_edit", entity)) then return false end

		return CAMI.PlayerHasAccess(client, "Parallax - Manage Vendors", nil)
	end,

	Action = function(self, entity)
		self:MsgStart()
			net.WriteEntity(entity)
		self:MsgEnd()
	end,

	Receive = function(self, length, client)
		local entity = net.ReadEntity()

		if (!IsValid(entity)) then return end
		if (!self:Filter(entity, client)) then return end

		entity.receivers[#entity.receivers + 1] = client

		local itemsTable = {}

		for k, v in pairs(entity.items) do
			if (!table.IsEmpty(v)) then
				itemsTable[k] = v
			end
		end

		client.axVendor = entity

		net.Start("axVendorEditor")
			net.WriteEntity(entity)
			net.WriteUInt(entity.money or 0, 16)
			net.WriteTable(itemsTable)
			net.WriteFloat(entity.scale or 0.5)
			net.WriteTable(entity.messages)
			net.WriteTable(entity.factions)
			net.WriteTable(entity.classes)
		net.Send(client)
	end
})
