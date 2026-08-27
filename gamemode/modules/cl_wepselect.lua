
MODULE.index = 1
MODULE.displayIndex = 1
MODULE.alpha = 0
MODULE.fadeTime = 0

function MODULE:HUDShouldDraw(name)
	if (name == "CHudWeaponSelection") then
		return false
	end
end

function MODULE:Think()
    local client = LocalPlayer()
	if (!IsValid(client) or !client:Alive()) then
		self.alpha = 0
		return
	end

	local weapons = client:GetWeapons()
	if (#weapons == 0) then return end

	self.displayIndex = Lerp(FrameTime() * 12, self.displayIndex, self.index)

	if (self.fadeTime < CurTime()) then
		self.alpha = Lerp(FrameTime() * 5, self.alpha, 0)
	else
		self.alpha = Lerp(FrameTime() * 10, self.alpha, 1)
	end
end

function MODULE:Open()
    self.fadeTime = CurTime() + 3

	local weapon = LocalPlayer():GetWeapons()[self.index]
	if (IsValid(weapon)) then
	    LocalPlayer():EmitSound("common/talk.wav", 50, 180)
	end
end

function MODULE:HUDPaint()
	if (self.alpha <= 0.01) then return end

	local client = LocalPlayer()
	local weapons = client:GetWeapons()
	if (#weapons == 0) then return end

	local x = ScrW() * 0.75
	local y = ScrH() * 0.5

	local spacing = 50

	for i = 1, #weapons do
		local offset = (i - self.displayIndex) * spacing

			-- only draw nearby items (perf + clean look)
		if (math.abs(offset) > 200) then continue end

		local weapon = weapons[i]
		local name = language.GetPhrase(weapon:GetPrintName())

		local selected = (i == self.index)
		local alpha = self.alpha * (255 - math.abs(offset) * 1.2)

		local scale = selected and 1.2 or 1

		surface.SetFont("ax.small")
		local tw, th = surface.GetTextSize(name)

		if (selected) then
            draw.SimpleText(
                name,
                "ax.large",
                x,
                y + offset,
                ax.theme:GetGlass().inputBorder,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
		    )
        else
            draw.SimpleText(
                name,
                "ax.medium",
                x,
                y + offset,
                Color(255,255,255,255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
		    )
		end
	end
end

function MODULE:PlayerBindPress(client, bind, pressed)
    if (client:KeyDown(IN_ATTACK) or client:KeyDown(IN_ATTACK2)) then
        return
    end
    
    if client:InVehicle() then return end
    
	bind = bind:lower()

	if (!pressed) then return end

	local weapons = client:GetWeapons()
	if (#weapons == 0) then return end
    
	local slot = bind:match("slot(%d)")
    if (slot) then
        slot = tonumber(slot)

        if (weapons[slot]) then
            self.index = slot
            self:Open()
        end

        return true
    end
    
	if (bind:find("invnext")) then
		self.index = math.min(self.index + 1, #weapons)
		self:Open()
		return true
	elseif (bind:find("invprev")) then
		self.index = math.max(self.index - 1, 1)
		self:Open()
		return true
	elseif (bind == "+attack2" and self.alpha > 0) then
		client:EmitSound("common/wpn_denyselect.wav")

		self.alpha = 0
		self.fadeTime = 0

		return true
	elseif (bind == "+attack" and self.alpha > 0) then
		local weapon = weapons[self.index]

		if (IsValid(weapon)) then
			input.SelectWeapon(weapon)
			client:EmitSound("HL2Player.Use")
			
			self.alpha = 0
			self.fadeTime = 0
		end
		return true
	end
end
