--- Opens the target's inventory for the actor in the container UI and records the search session.
---@realm server
---@param actor Player The player performing the search.
---@param target Player The tied-up player being searched.
---@return boolean success Whether the search was opened.
function MODULE:BeginSearch(actor, target)
    if ( !ax.util:IsValidPlayer(actor) ) then return false end
    if ( !ax.util:IsValidPlayer(target) ) then return false end
    if ( !actor:Alive() or !target:Alive() ) then return false end

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

        if ( !ax.util:IsValidPlayer(target) or !searcher:Alive() or !target:Alive()) then
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