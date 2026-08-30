local function L(key, ...)
	if ( ax and ax.localization and isfunction(ax.localization.GetPhrase) ) then
		return ax.localization:GetPhrase(key, ...)
	end

	return tostring(key)
end

VENDOR_TEXT = {}
	VENDOR_TEXT[VENDOR_SELLANDBUY] = "vendorBoth"
	VENDOR_TEXT[VENDOR_BUYONLY] = "vendorBuy"
	VENDOR_TEXT[VENDOR_SELLONLY] = "vendorSell"

	net.Receive("axVendorOpen", function()
		local entity = net.ReadEntity()

		if (!IsValid(entity)) then
			return
		end

		entity.money = net.ReadUInt(16)
		entity.items = net.ReadTable()
		entity.scale = net.ReadFloat()

		ax.gui.vendor = vgui.Create("axVendor")
		ax.gui.vendor:SetReadOnly(false)
		ax.gui.vendor:Setup(entity)
	end)

	net.Receive("axVendorEditor", function()
		local entity = net.ReadEntity()

		if (!IsValid(entity) or !CAMI.PlayerHasAccess(LocalPlayer(), "Parallax - Manage Vendors", nil)) then
			return
		end

		entity.money = net.ReadUInt(16)
		entity.items = net.ReadTable()
		entity.scale = net.ReadFloat()
		entity.messages = net.ReadTable()
		entity.factions = net.ReadTable()
		entity.classes = net.ReadTable()

		ax.gui.vendor = vgui.Create("axVendor")
		ax.gui.vendor:SetReadOnly(true)
		ax.gui.vendor:Setup(entity)
		ax.gui.vendorEditor = vgui.Create("axVendorEditor")
	end)

	net.Receive("axVendorEdit", function()
		local panel = ax.gui.vendor

		if (!IsValid(panel)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		local key = net.ReadString()
		local data = net.ReadType()

		if (key == "mode") then
			entity.items[data[1]] = entity.items[data[1]] or {}
			entity.items[data[1]][VENDOR_MODE] = data[2]

			if (!data[2]) then
				panel:removeItem(data[1])
			elseif (data[2] == VENDOR_SELLANDBUY) then
				panel:addItem(data[1])
			else
				panel:addItem(data[1], data[2] == VENDOR_SELLONLY and "selling" or "buying")
				panel:removeItem(data[1], data[2] == VENDOR_SELLONLY and "buying" or "selling")
			end
		elseif (key == "price") then
			local uniqueID = data[1]

			entity.items[uniqueID] = entity.items[uniqueID] or {}
			entity.items[uniqueID][VENDOR_PRICE] = tonumber(data[2])
		elseif (key == "stockDisable") then
			if (entity.items[data]) then
				entity.items[data][VENDOR_MAXSTOCK] = nil
			end
		elseif (key == "stockMax") then
			local uniqueID = data[1]
			local value = data[2]
			local current = data[3]

			entity.items[uniqueID] = entity.items[uniqueID] or {}
			entity.items[uniqueID][VENDOR_MAXSTOCK] = value
			entity.items[uniqueID][VENDOR_STOCK] = current
		elseif (key == "stock") then
			local uniqueID = data[1]
			local value = data[2]

			entity.items[uniqueID] = entity.items[uniqueID] or {}

			if (!entity.items[uniqueID][VENDOR_MAXSTOCK]) then
				entity.items[uniqueID][VENDOR_MAXSTOCK] = value
			end

			entity.items[uniqueID][VENDOR_STOCK] = value
		elseif (key == "scale") then
			entity.scale = data
		end
	end)

	net.Receive("axVendorEditFinish", function()
		local panel = ax.gui.vendor
		local editor = ax.gui.vendorEditor

		if (!IsValid(panel) or !IsValid(editor)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		local key = net.ReadString()
		local data = net.ReadType()

		if (key == "name") then
			editor.name:SetText(data)
		elseif (key == "description") then
			editor.description:SetText(data)
		elseif (key == "bubble") then
			editor.bubble.noSend = true
			editor.bubble:SetValue(data and 1 or 0)
		elseif (key == "mode") then
			if (data[2] == nil) then
				editor.lines[data[1]]:SetValue(3, L"none")
			else
				editor.lines[data[1]]:SetValue(3, L(VENDOR_TEXT[data[2]]))
			end
		elseif (key == "price") then
			editor.lines[data]:SetValue(4, entity:GetPrice(data))
		elseif (key == "stockDisable") then
			editor.lines[data]:SetValue(5, "-")
		elseif (key == "stockMax" or key == "stock") then
			local current, max = entity:GetStock(data)

			editor.lines[data]:SetValue(5, current.."/"..max)
		elseif (key == "faction") then
			local uniqueID = data[1]
			local state = data[2]
			local editPanel = ax.gui.editorFaction

			entity.factions[uniqueID] = state

			if (IsValid(editPanel) and IsValid(editPanel.factions[uniqueID])) then
				editPanel.factions[uniqueID]:SetChecked(state == true)
			end
		elseif (key == "class") then
			local uniqueID = data[1]
			local state = data[2]
			local editPanel = ax.gui.editorFaction

			entity.classes[uniqueID] = state

			if (IsValid(editPanel) and IsValid(editPanel.classes[uniqueID])) then
				editPanel.classes[uniqueID]:SetChecked(state == true)
			end
		elseif (key == "model") then
			editor.model:SetText(entity:GetModel())
		elseif (key == "scale") then
			editor.sellScale.noSend = true
			editor.sellScale:SetValue(data)
		end

		surface.PlaySound("buttons/button14.wav")
	end)

	net.Receive("axVendorMoney", function()
		local panel = ax.gui.vendor

		if (!IsValid(panel)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		local value = net.ReadUInt(16)
		value = value != -1 and value or nil

		entity.money = value

		local editor = ax.gui.vendorEditor

		if (IsValid(editor)) then
			local useMoney = tonumber(value) != nil

			editor.money:SetDisabled(!useMoney)
			editor.money:SetEnabled(useMoney)
			editor.money:SetText(useMoney and value or "∞")
		end
	end)

	net.Receive("axVendorStock", function()
		local panel = ax.gui.vendor

		if (!IsValid(panel)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		local uniqueID = net.ReadString()
		local amount = net.ReadUInt(16)

		entity.items[uniqueID] = entity.items[uniqueID] or {}
		entity.items[uniqueID][VENDOR_STOCK] = amount

		local editor = ax.gui.vendorEditor

		if (IsValid(editor)) then
			local _, max = entity:GetStock(uniqueID)

			editor.lines[uniqueID]:SetValue(5, amount .. "/" .. max)
		end
	end)

	net.Receive("axVendorAddItem", function()
		local uniqueID = net.ReadString()

		if (IsValid(ax.gui.vendor)) then
			ax.gui.vendor:addItem(uniqueID, "buying")
		end
	end)