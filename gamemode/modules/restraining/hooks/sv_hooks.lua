--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:Think()
    if ( (self.nextSessionCheck or 0) > CurTime() ) then return end
    self.nextSessionCheck = CurTime() + 0.25

    self:ValidateSearchSessions()
end

function MODULE:PlayerSpawn(client)
    self:ResetPlayerState(client)
end

function MODULE:PlayerLoadedCharacter(client, character, lastCharacter)
    self:ResetPlayerState(client)
end

function MODULE:DoPlayerDeath(client)
    self:ResetPlayerState(client)
end

function MODULE:PlayerDisconnected(client)
    self:ResetPlayerState(client)

    self.runtime[client] = nil
    self.sessions[client] = nil
end

--- Blocks all +USE interaction for tied players and starts the bare-hands untie when a free player uses a tied one.
---@realm server
function MODULE:PlayerUse(client, entity)
    if ( !self:IsEnabled() ) then return end
    if ( !ax.util:IsValidPlayer(client) ) then return end

    if ( self:IsRestrained(client) ) then
        return false
    end

    if ( !ax.util:IsValidPlayer(entity) ) then return end
    if ( !self:IsRestrained(entity) ) then return end
    if ( !client:Alive() or !entity:Alive() ) then return end
    if ( istable(client:GetTable().axActionBar) ) then return end
    if ( !client:RateLimit("restrain.untie", 0.5) ) then return end

    local duration = math.max(tonumber(ax.config:Get("restrain.action.untie_time", 15)) or 15, 1)
    self:StartUntieAction(client, entity, duration, ax.localization:GetPhrase("restrain.label.untying"))
end

function MODULE:CanPlayerInteractItem(client, item, action, context)
    if ( !self:IsEnabled() ) then return end
    if ( !ax.util:IsValidPlayer(client) ) then return end
    if ( !self:IsRestrained(client) ) then return end

    return false, ax.localization:GetPhrase("restrain.item.inventory_blocked")
end

function MODULE:CanTransferItem(client, item, fromInventory, toInventory, placement)
    if ( !self:IsEnabled() ) then return end
    if ( !ax.util:IsValidPlayer(client) ) then return end
    if ( !self:IsRestrained(client) ) then return end

    -- The reason is a phrase key; the transfer networking resolves it via ax.localization:GetPhrase before notifying.
    return false, "restrain.item.inventory_blocked"
end

--- Grants a searcher modify access to the searched inventory while their session is active; consumed by `ax.inventory:CanAccess`.
---@realm server
function MODULE:CanPlayerAccessInventory(client, inventory)
    local session = self.sessions[client]
    if ( !istable(session) or !istable(inventory) ) then return end
    if ( session.inventoryID != inventory.id ) then return end

    return true
end

function MODULE:SetupMove(client, moveData)
    if ( !self:IsEnabled() ) then return end
    if ( !ax.util:IsValidPlayer(client) or !client:Alive() ) then return end
    if ( !self:IsRestrained(client) ) then return end

    local limit = math.max(tonumber(ax.config:Get("restrain.speed.tied", 80)) or 80, 1)
    moveData:SetMaxClientSpeed(math.min(moveData:GetMaxClientSpeed(), limit))
    moveData:SetMaxSpeed(math.min(moveData:GetMaxSpeed(), limit))
end

function MODULE:PlayerPostThink(client)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    client:SetHandsBehindBack(self:IsEnabled() and self:IsRestrained(client))
end
