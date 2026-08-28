--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Returns whether the restrain system is enabled.
---@realm shared
---@return boolean enabled Whether the system is enabled.
function MODULE:IsEnabled()
    return ax.config:Get("restrain.enabled", true) == true
end

--- Returns the maximum distance in Hammer units for tie, untie, and search interactions.
---@realm shared
---@return number distance The configured interaction distance.
function MODULE:GetInteractDistance()
    return math.max(tonumber(ax.config:Get("restrain.max_distance", 96)) or 96, 32)
end

--- Returns (and lazily initializes) the server-side runtime state table for a player.
---@realm server
---@param client Player The player to fetch runtime state for.
---@return table runtime The runtime state table.
function MODULE:GetRuntime(client)
    if ( !self.runtime[client] ) then
        self.runtime[client] = {
            bTied = false,
            tiedBy = nil,
            weaponSnapshot = nil,
        }
    end

    return self.runtime[client]
end

--- Returns whether a player is currently tied up; reads the runtime table on the server and the relay on the client.
---@realm shared
---@param client Player The player to check.
---@return boolean tied Whether the player is tied up.
function MODULE:IsRestrained(client)
    if ( !ax.util:IsValidPlayer(client) ) then return false end

    if ( SERVER ) then
        return self:GetRuntime(client).bTied == true
    end

    return client:GetRelay("restrain.tied", false) == true
end

--- Returns the living player the client is aiming at within interaction distance, or nil.
---@realm shared
---@param client Player The player whose eye trace is used.
---@return Player|nil target The valid restrain target, if any.
function MODULE:FindRestrainTarget(client)
    if ( !ax.util:IsValidPlayer(client) ) then return nil end

    local trace = client:GetEyeTrace()
    local target = trace and trace.Entity or nil
    if ( !ax.util:IsValidPlayer(target) ) then return nil end
    if ( target == client ) then return nil end
    if ( !target:Alive() ) then return nil end

    local maxDistance = self:GetInteractDistance()
    if ( client:GetPos():DistToSqr(target:GetPos()) > (maxDistance * maxDistance) ) then return nil end

    return target
end

--- Sends a random /me line from a message bank, formatted with the target's name; server only.
---@realm shared
---@param client Player The player performing the action.
---@param bank table Array of /me message formats with one %s for the target name.
---@param target Player The player the action is performed on.
function MODULE:SendActionMessage(client, bank, target)
    if ( !SERVER ) then return end
    if ( !ax.util:IsValidPlayer(client) or !ax.util:IsValidPlayer(target) ) then return end
    if ( !istable(bank) or #bank == 0 ) then return end

    ax.chat:Send(client, "me", string.format(bank[math.random(#bank)], target:Nick()))
end

--- Stamps the `cut_restraints` action onto an item class table; idempotent across refreshes.
---@realm shared
---@param itemTable table The stored item definition table to attach the action to.
function MODULE:AttachCutAction(itemTable)
    if ( !istable(itemTable) or !isfunction(itemTable.AddAction) ) then return end
    if ( !isstring(itemTable.class) or itemTable.class == "" ) then return end

    local actions = istable(ax.item.actions) and ax.item.actions[itemTable.class] or nil
    if ( istable(actions) and istable(actions.cut_restraints) ) then return end

    itemTable:AddAction("cut_restraints", {
        name = "Cut Restraints",
        description = "Cut the restraints off the tied-up individual you are looking at.",
        icon = "parallax/icons/lock-open.png",

        CanUse = function(action, client, item)
            local restrain = ax.restrain
            if ( !istable(restrain) or !restrain:IsEnabled() ) then
                return false, ax.localization:GetPhrase("restrain.item.disabled")
            end

            if ( istable(client:GetTable().axActionBar) ) then
                return false, ax.localization:GetPhrase("restrain.item.already_busy")
            end

            local target = restrain:FindRestrainTarget(client)
            if ( !ax.util:IsValidPlayer(target) ) then
                return false, ax.localization:GetPhrase("restrain.item.no_target")
            end

            if ( !restrain:IsRestrained(target) ) then
                return false, ax.localization:GetPhrase("restrain.item.target_not_tied")
            end
        end,

        OnRun = function(action, client, item)
            local restrain = ax.restrain
            if ( !istable(restrain) or !restrain:IsEnabled() ) then return false end
            if ( restrain:IsRestrained(client) ) then return false end

            local target = restrain:FindRestrainTarget(client)
            if ( !ax.util:IsValidPlayer(target) ) then return false end
            if ( !restrain:IsRestrained(target) ) then return false end

            local duration = math.max(tonumber(ax.config:Get("restrain.action.cut_time", 3)) or 3, 0.5)
            restrain:StartUntieAction(client, target, duration, ax.localization:GetPhrase("restrain.label.cutting"))

            return false
        end,
    })
end

--- Attaches the cut action to every registered item class flagged with `canCutRestraints`; runs once everything (framework, schema, and module items) is registered.
---@realm shared
function MODULE:OnSchemaLoaded()
    for _, itemTable in pairs(ax.item.stored) do
        if ( istable(itemTable) and itemTable.canCutRestraints == true ) then
            self:AttachCutAction(itemTable)
        end
    end
end
