
local PANEL = {}

local function L(key, ...)
	if ( ax and ax.localization and isfunction(ax.localization.GetPhrase) ) then
		return ax.localization:GetPhrase(key, ...)
	end

	return tostring(key)
end

function PANEL:Init()
	local paddingX = ax.util:ScreenScale(8)
	local paddingY = ax.util:ScreenScaleH(6)

	self:SetSize(
		math.Clamp(ScrW() * 0.22, ax.util:ScreenScale(200), ax.util:ScreenScale(280)),
		math.Clamp(ScrH() * 0.5, ax.util:ScreenScaleH(240), ScrH() - paddingY * 2)
	)
	self:Center()
	self:MakePopup()
	self:SetTitle(L"vendorFaction")
	self.scroll = self:Add("ax.scroller.vertical")
	self.scroll:Dock(FILL)
	self.scroll:DockPadding(0, 0, 0, paddingY)

	self.factions = {}
	self.classes = {}

	for k, v in pairs(ax.faction:GetAll()) do
		local panel = self.scroll:Add("EditablePanel")
		panel:Dock(TOP)
		panel:DockPadding(paddingX / 2, paddingY / 2, paddingX / 2, paddingY / 2)
		panel:DockMargin(0, 0, 0, paddingY / 2)

		local faction = panel:Add("DCheckBoxLabel")
		faction:Dock(TOP)
		faction:SetText(L(v.name))
		faction:DockMargin(0, 0, 0, 4)
		faction.OnChange = function(this, state)
			self:updateVendor("faction", v.id)
		end

		self.factions[v.id] = faction

		for _, v2 in ipairs(ax.class:GetAll()) do
			if (v2.faction == k) then
				local class = panel:Add("DCheckBoxLabel")
				class:Dock(TOP)
				class:DockMargin(ax.util:ScreenScale(16), 0, 0, paddingY / 2)
				class:SetText(L(v2.name))
				class.OnChange = function(this, state)
					self:updateVendor("class", v2.id)
				end

				self.classes[v2.id] = class

			end
		end

		panel:SizeToChildren(false, true)
	end
end

function PANEL:Setup()
	for k, _ in pairs(self.entity.factions or {}) do
		if (IsValid(self.factions[k])) then
			self.factions[k]:SetChecked(true)
		end
	end

	for k, _ in pairs(self.entity.classes or {}) do
		if (IsValid(self.classes[k])) then
			self.classes[k]:SetChecked(true)
		end
	end
end

vgui.Register("axVendorFactionEditor", PANEL, "ax.frame")
