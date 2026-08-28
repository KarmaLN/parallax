ITEM.name = "Outfit"
ITEM.description = "A base outfit item."
ITEM.category = "Outfit"
ITEM.model = Model("models/props_c17/suitcase_passenger_physics.mdl")
ITEM.width = 1
ITEM.height = 1

ITEM.isOutfit = true

-- Bodygroups this outfit controls.
--
-- You can use bodygroup names:
-- ITEM.bodyGroups = {
--     ["Headgear"] = 1,
--     ["Torso"] = 2
-- }
--
-- Or bodygroup indexes:
-- ITEM.bodyGroups = {
--     [0] = 1,
--     [2] = 2
-- }
ITEM.bodyGroups = {}

-- Optional complete player model replacement.
--
-- ITEM:SetOutfitModel("models/player/example.mdl")
--
-- or simply:
-- ITEM.outfitModel = "models/player/example.mdl"
ITEM.outfitModel = nil

----------------------------------------------------------------
-- Model
----------------------------------------------------------------

function ITEM:SetOutfitModel(model)
    if not isstring(model) or model == "" then
        return
    end

    self.outfitModel = model
end


function ITEM:ApplyOutfitModel(client, character)
    if not self.outfitModel then
        return
    end

    -- Only save the original model once.
    if not character:GetData("outfitOriginalModel") then
        character:SetData(
            "outfitOriginalModel",
            client:GetModel()
        )
    end

    client:SetModel(self.outfitModel)
end


function ITEM:RestoreOutfitModel(client, character)
    local originalModel = character:GetData("outfitOriginalModel")

    if not originalModel then
        return
    end

    client:SetModel(originalModel)

    character:SetData(
        "outfitOriginalModel",
        nil
    )
end


----------------------------------------------------------------
-- Bodygroups
----------------------------------------------------------------

function ITEM:ApplyBodyGroups(client, character)
    if not istable(self.bodyGroups) then
        return
    end

    for group, value in pairs(self.bodyGroups) do
        local index = group

        -- Allow bodygroup names.
        if isstring(group) then
            index = client:FindBodygroupByName(group)
        end

        if isnumber(index) and index >= 0 then
            character:SetBodygroup(index, value)
        end
    end
end


function ITEM:ResetBodyGroups(client, character)
    if not istable(self.bodyGroups) then
        return
    end

    for group, _ in pairs(self.bodyGroups) do
        local index = group

        if isstring(group) then
            index = client:FindBodygroupByName(group)
        end

        if isnumber(index) and index >= 0 then
            character:SetBodygroup(index, 0)
        end
    end
end


----------------------------------------------------------------
-- Equip
----------------------------------------------------------------

function ITEM:AddOutfit(client)
    if not IsValid(client) then
        return false
    end

    local character = client:GetCharacter()

    if not character then
        return false
    end

    if self:GetData("equipped", false) then
        return false
    end

    ------------------------------------------------------------
    -- Apply model
    ------------------------------------------------------------

    self:ApplyOutfitModel(client, character)

    ------------------------------------------------------------
    -- Apply bodygroups
    ------------------------------------------------------------

    self:ApplyBodyGroups(client, character)

    ------------------------------------------------------------
    -- Mark equipped
    ------------------------------------------------------------

    self:SetData("equipped", true)

    if client.SetupHands then
        client:SetupHands()
    end

    self:OnEquipped(client)

    return true
end


----------------------------------------------------------------
-- Unequip
----------------------------------------------------------------

function ITEM:RemoveOutfit(client)
    if not IsValid(client) then
        return false
    end

    local character = client:GetCharacter()

    if not character then
        return false
    end

    if not self:GetData("equipped", false) then
        return false
    end

    ------------------------------------------------------------
    -- Reset this outfit's bodygroups
    ------------------------------------------------------------

    self:ResetBodyGroups(client, character)

    ------------------------------------------------------------
    -- Restore original model
    ------------------------------------------------------------

    self:RestoreOutfitModel(client, character)

    ------------------------------------------------------------
    -- Mark unequipped
    ------------------------------------------------------------

    self:SetData("equipped", false)

    if client.SetupHands then
        client:SetupHands()
    end

    self:OnUnequipped(client)

    return true
end


----------------------------------------------------------------
-- Equip action
----------------------------------------------------------------

ITEM:AddAction("equip", {
    name = "Equip",
    description = "Equip this outfit.",
    icon = "parallax/icons/check-circle.png",

    OnRun = function(action, client, item)
        if item:GetData("equipped", false) then
            return false
        end

        if not item:CanEquipOutfit(client) then
            return false
        end

        item:AddOutfit(client)

        return false
    end,

    CanUse = function(action, client, item)
        return IsValid(client)
            and not item:GetData("equipped", false)
            and item:CanEquipOutfit(client)
    end
})


----------------------------------------------------------------
-- Unequip action
----------------------------------------------------------------

ITEM:AddAction("unequip", {
    name = "Unequip",
    description = "Unequip this outfit.",
    icon = "parallax/icons/minus-circle.png",

    OnRun = function(action, client, item)
        if not item:GetData("equipped", false) then
            return false
        end

        item:RemoveOutfit(client)

        return false
    end,

    CanUse = function(action, client, item)
        return IsValid(client)
            and item:GetData("equipped", false) == true
    end
})


----------------------------------------------------------------
-- Prevent moving equipped outfits
----------------------------------------------------------------

function ITEM:CanTransfer(oldInventory, newInventory)
    if self:GetData("equipped", false) then
        return false
    end

    return true
end


----------------------------------------------------------------
-- Drop
----------------------------------------------------------------

function ITEM:OnDrop(client, position)
    if not IsValid(client) then
        return
    end

    if self:GetData("equipped", false) then
        self:RemoveOutfit(client)
    end
end


----------------------------------------------------------------
-- Callbacks
----------------------------------------------------------------

function ITEM:OnEquipped(client)
end


function ITEM:OnUnequipped(client)
end


function ITEM:CanEquipOutfit(client)
    return true
end

function ITEM:ShouldHighlightInInventory()
    return self:GetData("equipped", false)
end