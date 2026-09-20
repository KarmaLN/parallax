local PANEL = {}

local function L(key, ...)
	if (ax and ax.localization and isfunction(ax.localization.GetPhrase)) then
		return ax.localization:GetPhrase(key, ...)
	end

	return tostring(key)
end

function PANEL:Init()
	self.entity = self.entity or (ax.gui.vendor and ax.gui.vendor.entity)

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
	self.ranks = {}

	for factionID, faction in pairs(ax.faction:GetAll() or {}) do
		if (!istable(faction)) then
			continue
		end

		local factionKey = faction.id or factionID

		local panel = self.scroll:Add("EditablePanel")
		panel:Dock(TOP)
		panel:DockPadding(
			paddingX / 2,
			paddingY / 2,
			paddingX / 2,
			paddingY / 2
		)
		panel:DockMargin(0, 0, 0, paddingY / 2)

		local factionCheck = panel:Add("DCheckBoxLabel")
		factionCheck:Dock(TOP)
		factionCheck:SetText(L(faction.name or faction.Name or factionKey))
		factionCheck:DockMargin(0, 0, 0, paddingY / 2)

		factionCheck.OnChange = function(this, state)
			self:updateVendor("faction", factionKey)
		end

		self.factions[factionKey] = factionCheck

		local rankRow = panel:Add("EditablePanel")
		rankRow:Dock(TOP)
		rankRow:SetTall(ax.util:ScreenScaleH(24))
		rankRow:DockMargin(
			ax.util:ScreenScale(16),
			0,
			0,
			paddingY / 2
		)

		local rankLabel = rankRow:Add("ax.text")
		rankLabel:Dock(LEFT)
		rankLabel:SetWide(ax.util:ScreenScale(112))
		rankLabel:SetText(L"vendorMinimumRank", true, true)
		rankLabel:SetContentAlignment(4)

		local rank = rankRow:Add("ax.text.entry")
		rank:Dock(FILL)
		rank:SetPlaceholderText(L"vendorRankOrder")
		rank:SetNumeric(true)
		rank:SetText("", true, true)

		rank.OnEnter = function(this)
			self:updateVendor("rank", {
				factionKey,
				this:GetValue()
			})
		end

		self.ranks[factionKey] = rank

		panel:SizeToChildren(false, true)
	end
end

function PANEL:Setup()
	for factionID, value in pairs(self.entity.factions or {}) do
		if (IsValid(self.factions[factionID])) then
			self.factions[factionID].noSend = true
			self.factions[factionID]:SetChecked(true)
		end

		if (IsValid(self.ranks[factionID])) then
			local minimumRank = isnumber(value) and value or ""

			self.ranks[factionID].noSend = true
			self.ranks[factionID]:SetText(
				minimumRank,
				true,
				true
			)
		end
	end
end

vgui.Register("axVendorFactionEditor", PANEL, "ax.frame")