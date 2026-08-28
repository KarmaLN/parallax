--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

local function getPlayerDebugLabel(client)
    if ( !ax.util:IsValidPlayer(client) ) then
        return tostring(client)
    end

    return string.format("%s [%s]", client:Nick(), client:SteamID64())
end

local function getCharacterInventory(client)
    if ( !ax.util:IsValidPlayer(client) ) then return nil end

    local character = client:GetCharacter()
    if ( !istable(character) ) then return nil end

    local inventory = character:GetInventory()
    if ( isnumber(inventory) ) then
        inventory = ax.inventory.instances[inventory]
    end

    if ( !istable(inventory) ) then return nil end

    return inventory
end

-- Captures the target's engine weapons/clips/ammo plus their equipped weapon items, unequips the items, and strips the loadout.
local function snapshotAndStripWeapons(target)
    if ( !ax.util:IsValidPlayer(target) ) then return nil end

    local snapshot = {
        weapons = {},
        ammo = {},
        equippedItems = {},
        itemWeaponClasses = {},
        activeWeaponClass = nil,
    }

    local activeWeapon = target:GetActiveWeapon()
    if ( IsValid(activeWeapon) ) then
        snapshot.activeWeaponClass = activeWeapon:GetClass()
    end

    for _, weapon in ipairs(target:GetWeapons() or {}) do
        if ( !IsValid(weapon) ) then continue end

        local weaponClass = weapon:GetClass()
        if ( !isstring(weaponClass) or weaponClass == "" ) then continue end

        snapshot.weapons[#snapshot.weapons + 1] = {
            class = weaponClass,
            clip1 = math.max(tonumber(weapon:Clip1()) or 0, 0),
            clip2 = math.max(tonumber(weapon:Clip2()) or 0, 0),
        }

        local primaryAmmoType = tonumber(weapon:GetPrimaryAmmoType()) or -1
        if ( primaryAmmoType >= 0 and snapshot.ammo[primaryAmmoType] == nil ) then
            snapshot.ammo[primaryAmmoType] = math.max(tonumber(target:GetAmmoCount(primaryAmmoType)) or 0, 0)
        end

        local secondaryAmmoType = tonumber(weapon:GetSecondaryAmmoType()) or -1
        if ( secondaryAmmoType >= 0 and snapshot.ammo[secondaryAmmoType] == nil ) then
            snapshot.ammo[secondaryAmmoType] = math.max(tonumber(target:GetAmmoCount(secondaryAmmoType)) or 0, 0)
        end
    end

    local inventory = getCharacterInventory(target)
    if ( istable(inventory) ) then
        for _, item in pairs(inventory:GetItems() or {}) do
            if ( !istable(item) or !isfunction(item.GetData) ) then continue end
            if ( item.isWeapon != true ) then continue end
            if ( item:GetData("equipped", false) != true ) then continue end

            snapshot.equippedItems[#snapshot.equippedItems + 1] = {
                id = item.id,
                class = item.weaponClass,
            }

            if ( isstring(item.weaponClass) and item.weaponClass != "" ) then
                snapshot.itemWeaponClasses[item.weaponClass] = true
            end

            item:SetData("equipped", false)
        end
    end

    target:StripWeapons()
    target:StripAmmo()

    if ( #snapshot.weapons <= 0 and #snapshot.equippedItems <= 0 ) then
        return nil
    end

    return snapshot
end

-- Restores a weapon snapshot; item-backed weapons are only re-given when the item instance still sits in the target's own inventory, so confiscated weapons stay gone.
local function restoreWeaponSnapshot(target, snapshot)
    if ( !ax.util:IsValidPlayer(target) ) then return end
    if ( !istable(snapshot) or !istable(snapshot.weapons) ) then return end

    local inventory = getCharacterInventory(target)
    local inventoryID = istable(inventory) and inventory.id or nil

    local restorableItemClasses = {}
    for _, entry in ipairs(snapshot.equippedItems or {}) do
        if ( !istable(entry) ) then continue end

        local item = ax.item.instances[entry.id]
        if ( !istable(item) or !isfunction(item.GetInventoryID) ) then continue end
        if ( item:GetInventoryID() != inventoryID ) then continue end

        item:SetData("equipped", true)

        if ( isstring(entry.class) and entry.class != "" ) then
            restorableItemClasses[entry.class] = true
        end
    end

    local restoredWeaponClasses = {}
    local itemWeaponClasses = istable(snapshot.itemWeaponClasses) and snapshot.itemWeaponClasses or {}

    for _, weaponData in ipairs(snapshot.weapons) do
        if ( !istable(weaponData) ) then continue end

        local weaponClass = weaponData.class
        if ( !isstring(weaponClass) or weaponClass == "" ) then continue end
        if ( restoredWeaponClasses[weaponClass] == true ) then continue end

        -- Skip weapons that came from an equipped item which is no longer in the target's inventory.
        if ( itemWeaponClasses[weaponClass] == true and restorableItemClasses[weaponClass] != true ) then continue end

        local weapon = target:Give(weaponClass, true)
        weapon = IsValid(weapon) and weapon or target:GetWeapon(weaponClass)
        if ( !IsValid(weapon) ) then continue end

        restoredWeaponClasses[weaponClass] = true

        if ( weapon:GetMaxClip1() != -1 ) then
            weapon:SetClip1(math.max(tonumber(weaponData.clip1) or 0, 0))
        end

        if ( weapon:GetMaxClip2() != -1 ) then
            weapon:SetClip2(math.max(tonumber(weaponData.clip2) or 0, 0))
        end
    end

    for ammoType, amount in pairs(snapshot.ammo or {}) do
        ammoType = tonumber(ammoType) or -1
        amount = math.max(tonumber(amount) or 0, 0)

        if ( ammoType >= 0 ) then
            target:SetAmmo(amount, ammoType)
        end
    end

    if ( isstring(snapshot.activeWeaponClass) and snapshot.activeWeaponClass != "" and target:HasWeapon(snapshot.activeWeaponClass) ) then
        target:SelectWeapon(snapshot.activeWeaponClass)
    end
end

--- Syncs a player's restrain relay state to all connected clients; called after every state mutation.
---@realm server
---@param client Player The player whose state is synced.
function MODULE:SyncClient(client)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    client:SetRelay("restrain.tied", self:GetRuntime(client).bTied == true)
end

--- Resets a player's restrain state and ends any search session they are part of; called on spawn, character load, death, and disconnect.
---@realm server
---@param client Player The player to reset.
function MODULE:ResetPlayerState(client)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    self:EndSearch(client, "reset")
    self:EndSearch(self:GetSearcherOf(client), "reset")

    local runtime = self:GetRuntime(client)
    runtime.bTied = false
    runtime.tiedBy = nil
    runtime.weaponSnapshot = nil

    self:SyncClient(client)
end

--- Ties a player up: snapshots and strips their weapons, marks them restrained, and notifies both parties.
---@realm server
---@param actor Player The player applying the zip-tie.
---@param target Player The player being tied up.
---@return boolean success Whether the target was tied up.
function MODULE:RestrainPlayer(actor, target)
    if ( !ax.util:IsValidPlayer(actor) ) then return false end
    if ( !ax.util:IsValidPlayer(target) ) then return false end
    if ( !target:Alive() ) then return false end
    if ( self:IsRestrained(target) ) then return false end

    local runtime = self:GetRuntime(target)
    runtime.bTied = true
    runtime.tiedBy = actor:SteamID64()
    runtime.weaponSnapshot = snapshotAndStripWeapons(target)

    self:SendActionMessage(actor, self.tieMessages, target)
    self:SyncClient(target)

    target:Notify(ax.localization:GetPhrase("restrain.notify.tied"), "warning")

    ax.util:PrintDebug(string.format(
        "[RESTRAIN] '%s' tied up '%s'",
        getPlayerDebugLabel(actor),
        getPlayerDebugLabel(target)
    ))

    return true
end

--- Frees a tied-up player: ends any active search on them, restores their weapons, and notifies both parties.
---@realm server
---@param actor Player The player removing the restraints.
---@param target Player The player being freed.
---@return boolean success Whether the target was freed.
function MODULE:UnrestrainPlayer(actor, target)
    if ( !ax.util:IsValidPlayer(actor) ) then return false end
    if ( !ax.util:IsValidPlayer(target) ) then return false end
    if ( !self:IsRestrained(target) ) then return false end

    self:EndSearch(self:GetSearcherOf(target), "untied")

    local runtime = self:GetRuntime(target)
    runtime.bTied = false
    runtime.tiedBy = nil

    restoreWeaponSnapshot(target, runtime.weaponSnapshot)
    runtime.weaponSnapshot = nil

    self:SendActionMessage(actor, self.untieMessages, target)
    self:SyncClient(target)

    target:Notify(ax.localization:GetPhrase("restrain.notify.released"), "info")

    ax.util:PrintDebug(string.format(
        "[RESTRAIN] '%s' freed '%s'",
        getPlayerDebugLabel(actor),
        getPlayerDebugLabel(target)
    ))

    return true
end

--- Starts a timed untie action bar on the actor; used by both the bare-hands USE flow and cutting-tool items.
---@realm server
---@param actor Player The player performing the untie.
---@param target Player The tied-up player being freed.
---@param duration number The action bar duration in seconds.
---@param label string The localized action bar label.
function MODULE:StartUntieAction(actor, target, duration, label)
    if ( !ax.util:IsValidPlayer(actor) ) then return end
    if ( !ax.util:IsValidPlayer(target) ) then return end

    self:SendActionMessage(actor, self.untieStartMessages, target)

    actor:PerformEntityAction(target, label, duration, function()
        if ( !ax.util:IsValidPlayer(actor) or !ax.util:IsValidPlayer(target) ) then return end
        if ( !self:IsEnabled() ) then return end

        self:UnrestrainPlayer(actor, target)
    end, nil, true, self:GetInteractDistance())
end

--- Returns the player currently searching the given target, or nil.
---@realm server
---@param target Player The tied-up player.
---@return Player|nil searcher The active searcher, if any.
function MODULE:GetSearcherOf(target)
    if ( !IsValid(target) ) then return nil end

    for searcher, session in pairs(self.sessions) do
        if ( istable(session) and session.target == target ) then
            return searcher
        end
    end

    return nil
end

--- Opens the target's inventory for the actor in the container UI and records the search session.
---@realm server
---@param actor Player The player performing the search.
---@param target Player The tied-up player being searched.
---@return boolean success Whether the search was opened.
function MODULE:BeginSearch(actor, target)
    if ( !ax.util:IsValidPlayer(actor) ) then return false end
    if ( !ax.util:IsValidPlayer(target) ) then return false end
    if ( !actor:Alive() or !target:Alive() ) then return false end
    if ( self:IsRestrained(actor) ) then return false end
    if ( !self:IsRestrained(target) ) then return false end

    local existingSearcher = self:GetSearcherOf(target)
    if ( existingSearcher != nil and existingSearcher != actor ) then
        if ( ax.util:IsValidPlayer(existingSearcher) ) then
            actor:Notify(ax.localization:GetPhrase("restrain.search.busy"), "error")
            return false
        end

        self:EndSearch(existingSearcher, "invalid")
    end

    local inventory = getCharacterInventory(target)
    if ( !istable(inventory) ) then
        actor:Notify(ax.localization:GetPhrase("restrain.search.no_inventory"), "error")
        return false
    end

    self:SendActionMessage(actor, self.searchMessages, target)

    if ( istable(ax.container) and istable(ax.container.module) and isfunction(ax.container.module.CloseContainerForClient) ) then
        ax.container.module:CloseContainerForClient(actor)
    end

    inventory:AddReceiver(actor)
    ax.inventory:Sync(inventory)

    actor.axOpenContainerInventory = inventory.id
    self.sessions[actor] = {
        target = target,
        inventoryID = inventory.id,
    }

    local maxWeight = isfunction(inventory.GetMaxWeight) and (tonumber(inventory:GetMaxWeight()) or 30) or 30

    -- The entity slot is false, not nil: a nil first vararg punches a hole in the encoded argument table and the client would unpack nothing. IsValid(false) is safe and flags the panel as a virtual container.
    ax.net:Start(actor, "container.open", false, inventory.id, target:Nick(), 0, 0, maxWeight)

    ax.util:PrintDebug(string.format(
        "[RESTRAIN] '%s' is searching '%s' (inventory %d)",
        getPlayerDebugLabel(actor),
        getPlayerDebugLabel(target),
        inventory.id
    ))

    return true
end

--- Ends a searcher's active session, revoking inventory access and force-closing their panel if it is still open.
---@realm server
---@param searcher Player|nil The searching player whose session ends; nil is a no-op.
---@param reason? string Debug-only reason tag.
function MODULE:EndSearch(searcher, reason)
    if ( searcher == nil ) then return end

    local session = self.sessions[searcher]
    if ( !istable(session) ) then return end

    self.sessions[searcher] = nil

    if ( !ax.util:IsValidPlayer(searcher) ) then return end

    -- Always revoke receiver access directly; the containers module's own close path skips temporary (negative-ID) inventories such as bot characters.
    local inventory = ax.inventory.instances[session.inventoryID]
    if ( istable(inventory) and isfunction(inventory.IsReceiver) and inventory:IsReceiver(searcher) ) then
        inventory:RemoveReceiver(searcher)
    end

    if ( tonumber(searcher.axOpenContainerInventory) == session.inventoryID ) then
        searcher.axOpenContainer = nil
        searcher.axOpenContainerInventory = nil

        ax.net:Start(searcher, "restrain.search.close")
    end

    ax.util:PrintDebug(string.format(
        "[RESTRAIN] Search by '%s' ended (%s)",
        getPlayerDebugLabel(searcher),
        tostring(reason)
    ))
end

--- Ends every search session whose participants died, disconnected, separated too far, or are no longer tied.
---@realm server
function MODULE:ValidateSearchSessions()
    local maxDistance = math.max(tonumber(ax.config:Get("restrain.search.max_distance", 128)) or 128, 64)
    local maxDistanceSqr = maxDistance * maxDistance

    for searcher, session in pairs(self.sessions) do
        if ( !istable(session) or !ax.util:IsValidPlayer(searcher) ) then
            self.sessions[searcher] = nil
            continue
        end

        local target = session.target

        if ( !ax.util:IsValidPlayer(target) or !searcher:Alive() or !target:Alive() or !self:IsRestrained(target) ) then
            self:EndSearch(searcher, "invalid")
            continue
        end

        if ( searcher:GetPos():DistToSqr(target:GetPos()) > maxDistanceSqr ) then
            self:EndSearch(searcher, "distance")
            continue
        end

        if ( tonumber(searcher.axOpenContainerInventory) != session.inventoryID ) then
            self:EndSearch(searcher, "closed")
        end
    end
end
