--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.command:Add("CharSearch", {
    description = "Search the belongings of the tied-up player you are looking at.",
    bAllowConsole = false,
    OnRun = function(def, client)
        local restrain = ax.restrain
        if ( !istable(restrain) or !restrain:IsEnabled() ) then
            client:Notify(ax.localization:GetPhrase("restrain.item.disabled"), "error")
            return
        end

        if ( !client:Alive() ) then return end

        if ( restrain:IsRestrained(client) ) then
            client:Notify(ax.localization:GetPhrase("restrain.search.restrained"), "error")
            return
        end

        if ( istable(client:GetTable().axActionBar) ) then
            client:Notify(ax.localization:GetPhrase("restrain.item.already_busy"), "error")
            return
        end

        local target = restrain:FindRestrainTarget(client)
        if ( !ax.util:IsValidPlayer(target) ) then
            client:Notify(ax.localization:GetPhrase("restrain.item.no_target"), "error")
            return
        end

        if ( !restrain:IsRestrained(target) ) then
            client:Notify(ax.localization:GetPhrase("restrain.item.target_not_tied"), "error")
            return
        end

        local existingSearcher = restrain:GetSearcherOf(target)
        if ( existingSearcher != nil and existingSearcher != client and ax.util:IsValidPlayer(existingSearcher) ) then
            client:Notify(ax.localization:GetPhrase("restrain.search.busy"), "error")
            return
        end

        restrain:SendActionMessage(client, restrain.searchStartMessages, target)

        local duration = math.max(tonumber(ax.config:Get("restrain.action.search_time", 4)) or 4, 0.5)
        local label = ax.localization:GetPhrase("restrain.label.searching")

        client:PerformEntityAction(target, label, duration, function()
            if ( !ax.util:IsValidPlayer(client) or !ax.util:IsValidPlayer(target) ) then return end

            restrain:BeginSearch(client, target)
        end, nil, true, restrain:GetInteractDistance())
    end
})
