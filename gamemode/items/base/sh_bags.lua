ITEM.name = "Bag"
ITEM.description = "A base bag item."
ITEM.category = "Bags"
ITEM.model = Model("models/props_c17/suitcase_passenger_physics.mdl")
ITEM.weight = 1
ITEM.isBag = true

-- Extra inventory weight capacity granted while this bag is equipped.
ITEM.capacityBonus = 10

-- Exclusivity group for this bag. Equipping a bag unequips any other equipped
-- bag sharing the same category (e.g. only one "backpack" at a time).
-- Leave nil to allow this bag to be equipped alongside anything.
ITEM.bagCategory = "bag"

----------------------------------------------------------------
-- Capacity
----------------------------------------------------------------

function ITEM:GetTargetInventory(client)
    local character = IsValid(client) and client:GetCharacter()

    return character and character:GetInventory() or nil
end


-- Persists a changed max weight to the inventory's database row.
function ITEM:SaveInventoryCapacity(inventory)
    if not SERVER then
        return
    end

    if not isnumber(inventory.id) or inventory.id < 1 then
        return
    end

    local query = mysql:Update("ax_inventories")
        query:Update("max_weight", inventory.maxWeight)
        query:Where("id", inventory.id)
    query:Execute()
end


function ITEM:AddCapacity(client)
    local inventory = self:GetTargetInventory(client)

    if not inventory then
        return false
    end

    inventory.maxWeight = (inventory.maxWeight or 0) + self.capacityBonus

    self:SaveInventoryCapacity(inventory)
    ax.inventory:Sync(inventory)

    return true
end


function ITEM:RemoveCapacity(client)
    local inventory = self:GetTargetInventory(client)

    if not inventory then
        return false
    end

    inventory.maxWeight = math.max((inventory.maxWeight or 0) - self.capacityBonus, 0)

    self:SaveInventoryCapacity(inventory)
    ax.inventory:Sync(inventory)

    return true
end


----------------------------------------------------------------
-- Category exclusivity
----------------------------------------------------------------

function ITEM:UnequipConflictingBags(client)
    if not self.bagCategory then
        return
    end

    local inventory = self:GetTargetInventory(client)

    if not inventory then
        return
    end

    for _, invItem in pairs(inventory:GetItems()) do
        if invItem ~= self and invItem.isBag and invItem.bagCategory == self.bagCategory
            and invItem:GetData("equipped", false) then
            invItem:UnequipBag(client)
        end
    end
end


----------------------------------------------------------------
-- Equip
----------------------------------------------------------------

function ITEM:EquipBag(client)
    if not IsValid(client) then
        return false
    end

    if self:GetData("equipped", false) then
        return false
    end

    if not self:CanEquipBag(client) then
        return false
    end

    self:UnequipConflictingBags(client)

    if not self:AddCapacity(client) then
        return false
    end

    self:SetData("equipped", true)
    self:OnEquipped(client)

    return true
end


----------------------------------------------------------------
-- Unequip
----------------------------------------------------------------

function ITEM:UnequipBag(client)
    if not IsValid(client) then
        return false
    end

    if not self:GetData("equipped", false) then
        return false
    end

    self:RemoveCapacity(client)
    self:SetData("equipped", false)
    self:OnUnequipped(client)

    return true
end


----------------------------------------------------------------
-- Equip action
----------------------------------------------------------------

ITEM:AddAction("equip", {
    name = "Equip",
    description = "Equip this bag.",
    icon = "parallax/icons/check-circle.png",

    OnRun = function(action, client, item)
        item:EquipBag(client)

        return false
    end,

    CanUse = function(action, client, item)
        return IsValid(client)
            and not item:GetData("equipped", false)
            and item:CanEquipBag(client)
    end
})


----------------------------------------------------------------
-- Unequip action
----------------------------------------------------------------

ITEM:AddAction("unequip", {
    name = "Unequip",
    description = "Unequip this bag.",
    icon = "parallax/icons/minus-circle.png",

    OnRun = function(action, client, item)
        item:UnequipBag(client)

        return false
    end,

    CanUse = function(action, client, item)
        if not IsValid(client) or not item:GetData("equipped", false) then
            return false
        end

        -- Block unequipping if losing the capacity would overflow the inventory.
        local inventory = item:GetTargetInventory(client)

        if inventory and inventory:GetWeight() > (inventory:GetMaxWeight() - item.capacityBonus) then
            return false, "You are carrying too much to remove this bag."
        end

        return true
    end
})


----------------------------------------------------------------
-- Prevent moving equipped bags
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
        self:UnequipBag(client)
    end
end


----------------------------------------------------------------
-- Removed
----------------------------------------------------------------

function ITEM:OnRemoved()
    if not SERVER or not self:GetData("equipped", false) then
        return
    end

    local inventory = ax.inventory.instances[self:GetInventoryID()]
    local character = inventory and inventory:GetOwner()
    local client = istable(character) and character.GetOwner and character:GetOwner() or nil

    if IsValid(client) then
        self:RemoveCapacity(client)
    end
end


----------------------------------------------------------------
-- Callbacks
----------------------------------------------------------------

function ITEM:OnEquipped(client)
end


function ITEM:OnUnequipped(client)
end


function ITEM:CanEquipBag(client)
    return true
end


function ITEM:ShouldHighlightInInventory()
    return self:GetData("equipped", false)
end
