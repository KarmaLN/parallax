--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

local tiedColor = Color(255, 160, 160)

--- Adds a tied status line beneath target descriptions.
---@realm client
function MODULE:GetTargetIDLines(entity)
    if ( !ax.util:IsValidPlayer(entity) ) then return end
    if ( !self:IsEnabled() ) then return end
    if ( !self:IsRestrained(entity) ) then return end

    return {
        {
            text = ax.localization:GetPhrase("restrain.state.tied"),
            color = tiedColor,
        },
    }
end

function MODULE:PlayerPostThink(client)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    client:SetHandsBehindBack(self:IsEnabled() and self:IsRestrained(client))
end
