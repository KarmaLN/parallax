--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ITEM.name = "Zip-Tie"
ITEM.description = "A tough plastic strip that locks around wrists and only comes off with a cutting tool."
ITEM.model = Model("models/items/crossbowrounds.mdl")
ITEM.category = "Tools"
ITEM.weight = 0.1
ITEM.price = 10
ITEM.shouldStack = true
ITEM.maxStack = 5

ITEM.canCutRestraints = true

ITEM:AddAction("tie", {
    name = "Tie Up",
    description = "Restrain the individual you are looking at.",
    icon = "parallax/icons/lock.png",

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

        if ( restrain:IsRestrained(target) ) then
            return false, ax.localization:GetPhrase("restrain.item.target_already_tied")
        end
    end,

    OnRun = function(action, client, item)
        local restrain = ax.restrain
        if ( !istable(restrain) or !restrain:IsEnabled() ) then return false end
        if ( restrain:IsRestrained(client) ) then return false end

        local target = restrain:FindRestrainTarget(client)
        if ( !ax.util:IsValidPlayer(target) ) then return false end
        if ( restrain:IsRestrained(target) ) then return false end

        restrain:SendActionMessage(client, restrain.tieStartMessages, target)

        local duration = math.max(tonumber(ax.config:Get("restrain.action.tie_time", 5)) or 5, 0.5)
        local label = ax.localization:GetPhrase("restrain.label.tying")

        client:PerformEntityAction(target, label, duration, function()
            if ( !ax.util:IsValidPlayer(client) or !ax.util:IsValidPlayer(target) ) then return end
            if ( !restrain:IsEnabled() ) then return end

            -- Consume the zip-tie only when the tie actually succeeded.
            restrain:RestrainPlayer(client, target)
 
                
        end, nil, true, restrain:GetInteractDistance())

        return false
    end,
})


