local CHAR = ax.character.meta

function CHAR:GetClearance()
	local inv = self:GetInventory()

	local maxClearance = -math.huge
    local maxItem = 0
	local bKeycard = inv:HasItemOfBase("keycard")

	if bKeycard then
		for k, v in pairs(inv:GetItemsByBase("keycard")) do
			if v.clearance > maxClearance then
				maxClearance = v.clearance
				maxItem = v.clearance
			end
		end
		return maxItem
	else
		return 0
	end
end
