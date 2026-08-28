--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Force-closes the container panel when the server ends a search session (target untied, died, left, or moved away).
ax.net:Hook("restrain.search.close", function()
    local panel = istable(ax.container) and ax.container.panel or nil
    if ( !IsValid(panel) ) then return end

    panel.bSkipServerClose = true
    panel:Remove()
end)
