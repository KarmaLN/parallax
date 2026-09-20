
local PANEL = {}

local function L(key, ...)
	if ( ax and ax.localization and isfunction(ax.localization.GetPhrase) ) then
		return ax.localization:GetPhrase(key, ...)
	end

	return tostring(key)
end

AccessorFunc(PANEL, "bReadOnly", "ReadOnly", FORCE_BOOL)

function PANEL:Init()
	local paddingX = ax.util:ScreenScale(8)
	local paddingY = ax.util:ScreenScaleH(6)

	self:SetSize(
		math.Clamp(ScrW() * 0.62, ax.util:ScreenScale(380), ScrW() - paddingX * 2),
		math.Clamp(ScrH() * 0.64, ax.util:ScreenScaleH(280), ScrH() - paddingY * 2)
	)
	self:SetTitle("")
	self:MakePopup()
	self:Center()

	local header = self:Add("EditablePanel")
	header:SetTall(ax.util:ScreenScaleH(24))
	header:Dock(TOP)
	header.Paint = function(this, width, height)
		local glass = ax.theme:GetGlass()
		surface.SetDrawColor(ColorAlpha(glass.panelBorder, 110))
		surface.DrawRect(0, height - 1, width, 1)
	end

	self.vendorName = header:Add("ax.text")
	self.vendorName:Dock(LEFT)
	self.vendorName:SetWide(self:GetWide() * 0.5 - 7)
	self.vendorName:SetText("John Doe", true, true)
	self.vendorName:SetTextInset(paddingX / 2, 0)
	self.vendorName:SetTextColor(color_white)
	self.vendorName:SetFont("ax.small")

	self.ourName = header:Add("ax.text")
	self.ourName:Dock(RIGHT)
	self.ourName:SetWide(self:GetWide() * 0.5 - 7)
	self.ourName:SetText(L"you".." ("..ax.currencies:Format(LocalPlayer():GetCharacter():GetMoney(), "default")..")", true, true)
	self.ourName:SetTextInset(0, 0)
	self.ourName:SetTextColor(color_white)
	self.ourName:SetFont("ax.small")

	local footer = self:Add("EditablePanel")
	footer:SetTall(ax.util:ScreenScaleH(34))
	footer:Dock(BOTTOM)
	footer:DockPadding(paddingX / 2, paddingY / 2, paddingX / 2, paddingY / 2)
	footer.Paint = function(this, width, height)
		local glass = ax.theme:GetGlass()
		surface.SetDrawColor(ColorAlpha(glass.panelBorder, 110))
		surface.DrawRect(0, 0, width, 1)
	end


	self.vendorSell = footer:Add("ax.button")
	self.vendorSell:SetFont("ax.small")
	self.vendorSell:Dock(LEFT)
	self.vendorSell:SetWide(self:GetWide() * 0.5 - paddingX)
	self.vendorSell:DockMargin(0, 0, paddingX / 2, 0)
	self.vendorSell:SetContentAlignment(5)
	self.vendorSell:SetUpdateSizeOnHover(false)
	-- The text says purchase but the vendor is selling it to us.
	self.vendorSell:SetText(L"vendorPurchase", true, true)
	self.vendorSell:SetTextColor(color_white)

	self.vendorSell.DoClick = function(this)
		if (IsValid(self.activeSell)) then
			net.Start("axVendorTrade")
				net.WriteString(self.activeSell.item)
				net.WriteBool(false)
			net.SendToServer()
		end
	end

	self.vendorBuy = footer:Add("ax.button")
	self.vendorBuy:SetFont("ax.small")
	self.vendorBuy:Dock(RIGHT)
	self.vendorBuy:SetWide(self:GetWide() * 0.5 - paddingX)
	self.vendorBuy:DockMargin(paddingX / 2, 0, 0, 0)
	self.vendorBuy:SetContentAlignment(5)
	self.vendorBuy:SetUpdateSizeOnHover(false)
	self.vendorBuy:SetText(L"vendorSellItem", true, true)
	self.vendorBuy:SetTextColor(color_white)
	self.vendorBuy:SetEnabled(false)
	self.vendorBuy.DoClick = function(this)
		if (IsValid(self.activeBuy)) then
			net.Start("axVendorTrade")
				net.WriteString(self.activeBuy.item)
				net.WriteBool(true)
			net.SendToServer()
		end
	end

	self.selling = self:Add("ax.scroller.vertical")
	self.selling:SetWide(self:GetWide() * 0.5 - 7)
	self.selling:Dock(LEFT)
	self.selling:DockMargin(0, paddingY, paddingX / 2, paddingY)

	self.sellingItems = self.selling:Add("DListLayout")
	self.sellingItems:SetSize(self.selling:GetSize())
	self.sellingItems:DockPadding(0, 0, 0, paddingY)
	self.selling.Paint = function(this, width, height)
		local glass = ax.theme:GetGlass()
		surface.SetDrawColor(ColorAlpha(glass.panel, 90))
		surface.DrawRect(0, 0, width, height)
	end

	self.buying = self:Add("ax.scroller.vertical")
	self.buying:SetWide(self:GetWide() * 0.5 - 7)
	self.buying:Dock(RIGHT)
	self.buying:DockMargin(paddingX / 2, paddingY, 0, paddingY)

	self.buyingItems = self.buying:Add("DListLayout")
	self.buyingItems:SetSize(self.buying:GetSize())
	self.buyingItems:DockPadding(0, 0, 0, paddingY)
	self.buying.Paint = function(this, width, height)
		local glass = ax.theme:GetGlass()
		surface.SetDrawColor(ColorAlpha(glass.panel, 90))
		surface.DrawRect(0, 0, width, height)
	end

	self.sellingList = {}
	self.buyingList = {}
end

function PANEL:addItem(uniqueID, listID)
	local entity = self.entity
	local items = entity.items
	local data = items[uniqueID]

	if ((!listID or listID == "selling") and !IsValid(self.sellingList[uniqueID])
	and ax.item.stored[uniqueID]) then
		if (data and data[VENDOR_MODE] and data[VENDOR_MODE] != VENDOR_BUYONLY) then
			local item = self.sellingItems:Add("axVendorItem")
			item:Setup(uniqueID)

			self.sellingList[uniqueID] = item
			self.sellingItems:InvalidateLayout()
		end
	end

	if ((!listID or listID == "buying") and !IsValid(self.buyingList[uniqueID])
	and LocalPlayer():GetCharacter():GetInventory():HasItem(uniqueID)) then
		if (data and data[VENDOR_MODE] and data[VENDOR_MODE] != VENDOR_SELLONLY) then
			local item = self.buyingItems:Add("axVendorItem")
			item:Setup(uniqueID)
			item.isLocal = true

			self.buyingList[uniqueID] = item
			self.buyingItems:InvalidateLayout()
		end
	end
end

function PANEL:removeItem(uniqueID, listID)
	if (!listID or listID == "selling") then
		if (IsValid(self.sellingList[uniqueID])) then
			self.sellingList[uniqueID]:Remove()
			self.sellingItems:InvalidateLayout()
		end
	end

	if (!listID or listID == "buying") then
		if (IsValid(self.buyingList[uniqueID])) then
			self.buyingList[uniqueID]:Remove()
			self.buyingItems:InvalidateLayout()
		end
	end
end

function PANEL:Setup(entity)
	self.entity = entity
	self:SetTitle("")
	self.vendorName:SetText(entity:GetDisplayName()..(entity.money and " ("..entity.money..")" or ""), true, true)

	self.vendorBuy:SetEnabled(!self:GetReadOnly())
	self.vendorSell:SetEnabled(!self:GetReadOnly())
	self.vendorBuy:SetEnabled(false)
	self.vendorSell:SetEnabled(false)

	for k, _ in SortedPairs(entity.items) do
		self:addItem(k, "selling")
	end

	for _, v in SortedPairs(LocalPlayer():GetCharacter():GetInventory():GetItems()) do
		self:addItem(v.class, "buying")
	end
end

function PANEL:OnRemove()
	net.Start("axVendorClose")
	net.SendToServer()

	if (IsValid(ax.gui.vendorEditor)) then
		ax.gui.vendorEditor:Remove()
	end
end

function PANEL:Think()
	local entity = self.entity

	if (!IsValid(entity)) then
		self:Remove()

		return
	end

	if ((self.nextUpdate or 0) < CurTime()) then
		self:SetTitle("")
		self.vendorName:SetText(entity:GetDisplayName()..(entity.money and " ("..ax.currencies:Format(entity.money, "default")..")" or ""), true, true)
		self.ourName:SetText(L"you".." ("..ax.currencies:Format(LocalPlayer():GetCharacter():GetMoney(), "default")..")", true, true)

		self.nextUpdate = CurTime() + 0.25
	end
end

function PANEL:OnItemSelected(panel)
	local price = self.entity:GetPrice(panel.item, panel.isLocal)
	local previous = panel.isLocal and self.activeBuy or self.activeSell

	if (IsValid(previous) and previous != panel) then
		previous:SetSelected(false)
	end

	panel:SetSelected(true)

	if (panel.isLocal) then
		self.vendorBuy:SetEnabled(!self:GetReadOnly())
		self.vendorBuy:SetText(L"vendorSellItem".." ("..ax.currencies:Format(price, "default")..")", true, true)
	else
		self.vendorSell:SetEnabled(!self:GetReadOnly())
		self.vendorSell:SetText(L"vendorPurchase".." ("..ax.currencies:Format(price, "default")..")", true, true)
	end
end

vgui.Register("axVendor", PANEL, "ax.frame")

PANEL = {}

function PANEL:Init()
	local padding = ax.util:ScreenScale(1)
	local iconInset = ax.util:ScreenScale(1.5)
	local rowHeight = ax.util:ScreenScaleH(28)

	self:SetTall(rowHeight)
	self:DockMargin(ax.util:ScreenScale(4), ax.util:ScreenScaleH(4), ax.util:ScreenScale(4), 0)

	self.icon = self:Add("EditablePanel")
	self.icon:Dock(LEFT)
	self.icon:SetMouseInputEnabled(false)
	self.icon:DockMargin(0, padding, ax.util:ScreenScale(6), padding)
	self.icon:SetWide(rowHeight)

	self.iconImage = self.icon:Add("DModelPanel")
	self.iconImage:Dock(FILL)
	self.iconImage:DockMargin(iconInset, iconInset, iconInset, iconInset)
	self.iconImage:SetMouseInputEnabled(false)
	self.iconImage:SetFOV(35)
	self.iconImage.Paint = function(this, width, height)
		if (!IsValid(this.Entity)) then
			return
		end

		local x, y = this:LocalToScreen(0, 0)
		local cameraPosition = this:GetCamPos()
		local lookAt = this:GetLookAt()

		cam.Start3D(cameraPosition, (lookAt - cameraPosition):Angle(), this:GetFOV(), x, y, width, height, 5, 4096)
			cam.IgnoreZ(true)
		this:DrawModel()
			cam.IgnoreZ(false)
		cam.End3D()

		this:LayoutEntity(this.Entity)
	end

	self.count = self:Add("ax.text")
	self.count:Dock(RIGHT)
	self.count:SetWide(ax.util:ScreenScale(32))
	self.count:SetFont("ax.small")
	self.count:SetTextColor(color_white)
	self.count:SetContentAlignment(5)
	self.count:SetText("", true, true)
	self.count:SetMouseInputEnabled(false)

	self.name = self:Add("ax.text")
	self.name:Dock(FILL)
	self.name:DockMargin(0, 0, padding, 0)
	self.name:SetFont("ax.small")
	self.name:SetTextColor(color_white)
	self.name:SetExpensiveShadow(1, Color(0, 0, 0, 200))
	self.name:SetMouseInputEnabled(false)

	self.selected = false
	self.Paint = function(this, width, height)
		if (!IsValid(this.click) or (!this.selected and !this.click:IsHovered())) then
			return
		end

		local glass = ax.theme:GetGlass()
		local fill = this.selected and glass.buttonActive or glass.buttonHover
		surface.SetDrawColor(ColorAlpha(fill, this.selected and 190 or 100))
		surface.DrawRect(0, 0, width, height)
	end

	self.click = self:Add("ax.button")
	self.click:Dock(FILL)
	self.click:SetText("")
	self.click.Paint = function() end
	self.click.DoClick = function(this)
		local previous = self.isLocal and ax.gui.vendor.activeBuy or ax.gui.vendor.activeSell
		if (IsValid(previous) and previous != self) then
			previous:SetSelected(false)
		end

		if (self.isLocal) then
			ax.gui.vendor.activeBuy = self
		else
			ax.gui.vendor.activeSell = self
		end

		ax.gui.vendor:OnItemSelected(self)
	end
end

function PANEL:SetSelected(selected)
	self.selected = selected == true
	self:InvalidateLayout(true)
end

function PANEL:SetCallback(callback)
	self.click.DoClick = function(this)
		callback()
		self.selected = true
	end
end

function PANEL:Setup(uniqueID)
	local item = ax.item.stored[uniqueID]

	if (item) then
		self.item = uniqueID
		self.iconImage:SetModel(item:GetModel())
		self.iconImage.Entity:SetSkin(item:GetSkin())

		local mins, maxs = self.iconImage.Entity:GetRenderBounds()
		local center = (mins + maxs) * 0.5
		local distance = math.max((maxs - mins):Length() * 0.8, 10)

		self.iconImage:SetLookAt(center)
		self.iconImage:SetCamPos(center + Vector(distance, distance, distance * 0.5))
		self.name:SetText(item:GetName())
		self.itemName = item:GetName()
	end
end

function PANEL:UpdateCount()
	local entity = ax.gui.vendor and ax.gui.vendor.entity

	if (!IsValid(entity) or !self.item) then
		return
	end

	if (!self.isLocal) then
		local current, max = entity:GetStock(self.item)
		self.count:SetText(max and (current .. "/" .. max) or L"vendorUnlimited", true, true)

		return current
	end

	local character = LocalPlayer():GetCharacter()

	if (!character) then
		return
	end

	local count = character:GetInventory():GetItemCount(self.item)
	self.count:SetText("x" .. count, true, true)

	return count
end

function PANEL:Think()
	if ((self.nextUpdate or 0) < CurTime()) then
		local entity = ax.gui.vendor.entity

		if (IsValid(entity)) then
			local count = self:UpdateCount()

			if (self.isLocal and count == 0) then
				self:Remove()
			end
		end

		self.nextUpdate = CurTime() + 0.1
	end
end


vgui.Register("axVendorItem", PANEL, "EditablePanel")
