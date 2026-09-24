ITEM.name = "Outfit"
ITEM.description = "A base outfit item."
ITEM.category = "Outfits"
ITEM.model = Model("models/props_c17/suitcase_passenger_physics.mdl")
ITEM.weight = 1
ITEM.isOutfit = true

-- Exclusivity group for this outfit. Equipping an outfit unequips any other
-- equipped outfit sharing the same category (e.g. "head", "torso").
-- Leave nil to allow this outfit to be equipped alongside anything.
ITEM.outfitCategory = nil

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

-- Optional model substring replacement(s), applied to the player's current
-- model instead of a full replacement. Accepts a single pair:
-- ITEM.replacements = {"male", "female"}
-- or multiple pairs:
-- ITEM.replacements = {
--     {"male", "female"},
--     {"group01", "group02"}
-- }
ITEM.replacements = nil

-- Optional skin index applied while this outfit is equipped.
ITEM.newSkin = nil

----------------------------------------------------------------
-- Model
----------------------------------------------------------------

-- Suffixes per-item data keys with the outfit category so outfits in
-- different categories don't clobber each other's saved state.
function ITEM:GetOutfitDataKey(key)
    return key .. (self.outfitCategory or "")
end


function ITEM:SetOutfitModel(model)
    if not isstring(model) or model == "" then
        return
    end

    self.outfitModel = model
end


-- Resolves the model to apply for this outfit. Override this to compute a
-- replacement model dynamically instead of using `outfitModel`/`replacements`.
function ITEM:GetReplacementModel(client)
    if self.outfitModel then
        return self.outfitModel
    end

    if not self.replacements then
        return nil
    end

    local currentModel = client:GetModel()

    if istable(self.replacements) then
        -- Single pair: {"from", "to"}
        if isstring(self.replacements[1]) and isstring(self.replacements[2]) then
            return currentModel:gsub(self.replacements[1], self.replacements[2])
        end

        -- Multiple pairs: {{"from", "to"}, {"from", "to"}}
        local result = currentModel

        for _, pair in ipairs(self.replacements) do
            result = result:gsub(pair[1], pair[2])
        end

        return result
    elseif isstring(self.replacements) then
        return self.replacements
    end

    return nil
end


function ITEM:ApplyOutfitModel(client, character)
    local replacement = self:GetReplacementModel(client)

    if not replacement then
        return
    end

    local dataKey = self:GetOutfitDataKey("outfitOriginalModel")

    -- Only save the original model once.
    if not character:GetData(dataKey) then
        character:SetData(
            dataKey,
            client:GetModel()
        )
    end

    client:SetModel(replacement)
end


function ITEM:RestoreOutfitModel(client, character)
    local dataKey = self:GetOutfitDataKey("outfitOriginalModel")
    local originalModel = character:GetData(dataKey)

    if not originalModel then
        return
    end

    client:SetModel(originalModel)

    character:SetData(
        dataKey,
        nil
    )
end


----------------------------------------------------------------
-- Skin
----------------------------------------------------------------

function ITEM:ApplyOutfitSkin(client, character)
    if not isnumber(self.newSkin) then
        return
    end

    local dataKey = self:GetOutfitDataKey("outfitOriginalSkin")

    if not character:GetData(dataKey) then
        character:SetData(dataKey, client:GetSkin())
    end

    client:SetSkin(self.newSkin)
end


function ITEM:RestoreOutfitSkin(client, character)
    if not isnumber(self.newSkin) then
        return
    end

    local dataKey = self:GetOutfitDataKey("outfitOriginalSkin")
    local originalSkin = character:GetData(dataKey)

    client:SetSkin(originalSkin or 0)
    character:SetData(dataKey, nil)
end


----------------------------------------------------------------
-- Sub-materials
----------------------------------------------------------------

function ITEM:ApplyOutfitSubMaterials(client, character)
    local materials = self:GetData("submaterials")

    if not istable(materials) then
        return
    end

    for index, material in pairs(materials) do
        client:SetSubMaterial(index - 1, material)
    end
end


function ITEM:ResetOutfitSubMaterials(client, character)
    local materials = {}

    for index = 1, #client:GetMaterials() do
        if client:GetSubMaterial(index - 1) ~= "" then
            materials[index] = client:GetSubMaterial(index - 1)
            client:SetSubMaterial(index - 1, "")
        end
    end

    if not table.IsEmpty(materials) then
        self:SetData("submaterials", materials)
    end
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
    -- Unequip conflicting outfits in the same category
    ------------------------------------------------------------

    self:UnequipConflictingOutfits(client)

    ------------------------------------------------------------
    -- Apply model
    ------------------------------------------------------------

    self:ApplyOutfitModel(client, character)

    ------------------------------------------------------------
    -- Apply skin
    ------------------------------------------------------------

    self:ApplyOutfitSkin(client, character)

    ------------------------------------------------------------
    -- Apply bodygroups
    ------------------------------------------------------------

    self:ApplyBodyGroups(client, character)

    ------------------------------------------------------------
    -- Apply saved sub-materials
    ------------------------------------------------------------

    self:ApplyOutfitSubMaterials(client, character)

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
    -- Save and reset this outfit's sub-materials
    ------------------------------------------------------------

    self:ResetOutfitSubMaterials(client, character)

    ------------------------------------------------------------
    -- Reset this outfit's bodygroups
    ------------------------------------------------------------

    self:ResetBodyGroups(client, character)

    ------------------------------------------------------------
    -- Restore original skin
    ------------------------------------------------------------

    self:RestoreOutfitSkin(client, character)

    ------------------------------------------------------------
    -- Restore original model
    ------------------------------------------------------------

    self:RestoreOutfitModel(client, character)

    ------------------------------------------------------------
    -- Unequip any outfits attached to this one
    ------------------------------------------------------------

    for id in pairs(self:GetData("outfitAttachments", {})) do
        self:RemoveAttachment(id, client)
    end

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
-- Category exclusivity
----------------------------------------------------------------

-- Unequips any other equipped outfit sharing this outfit's category.
function ITEM:UnequipConflictingOutfits(client)
    if not self.outfitCategory then
        return
    end

    local character = client:GetCharacter()
    local inventory = character and character:GetInventory()

    if not inventory then
        return
    end

    for _, invItem in pairs(inventory:GetItems()) do
        if invItem ~= self and invItem.isOutfit and invItem.outfitCategory == self.outfitCategory
            and invItem:GetData("equipped", false) then
            invItem:RemoveOutfit(client)
        end
    end
end


----------------------------------------------------------------
-- Attachments
----------------------------------------------------------------

-- Marks another outfit item as dependent on this one - it is automatically
-- unequipped when this outfit is unequipped or dropped.
function ITEM:AddAttachment(itemID)
    local attachments = self:GetData("outfitAttachments", {})
    attachments[itemID] = true

    self:SetData("outfitAttachments", attachments)
end


function ITEM:RemoveAttachment(itemID, client)
    local attachments = self:GetData("outfitAttachments", {})
    local attachedItem = ax.item.instances[itemID]

    if attachedItem and attachedItem:GetData("equipped", false) then
        attachedItem:RemoveOutfit(client)
    end

    attachments[itemID] = nil
    self:SetData("outfitAttachments", attachments)
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