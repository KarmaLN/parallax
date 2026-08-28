--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.localization:Register("en", {
    ["category.restrain"] = "Restrain",
    ["subcategory.restrain.general"] = "General",
    ["subcategory.restrain.timing"] = "Timing",

    -- Item action names and descriptions
    ["restrain.item.action.tie"] = "Tie Up",
    ["restrain.item.action.tie.desc"] = "Restrain the individual you are looking at.",
    ["restrain.item.action.cut"] = "Cut Restraints",
    ["restrain.item.action.cut.desc"] = "Cut the restraints off the tied-up individual you are looking at.",

    -- Action bar labels
    ["restrain.label.tying"] = "Applying Zip-Tie...",
    ["restrain.label.untying"] = "Untying...",
    ["restrain.label.cutting"] = "Cutting Restraints...",
    ["restrain.label.searching"] = "Searching...",

    -- CanUse / command error messages
    ["restrain.item.disabled"] = "The restrain system is not enabled on this server.",
    ["restrain.item.already_busy"] = "You are already busy.",
    ["restrain.item.no_target"] = "You are not looking at a valid player.",
    ["restrain.item.target_already_tied"] = "That individual is already tied up.",
    ["restrain.item.target_not_tied"] = "That individual is not tied up.",
    ["restrain.item.inventory_blocked"] = "You cannot use inventory actions while tied up.",

    -- Notifications
    ["restrain.notify.tied"] = "You have been tied up. Someone will have to free you.",
    ["restrain.notify.released"] = "You have been freed from your restraints.",

    -- Search
    ["restrain.search.busy"] = "Someone is already searching that individual.",
    ["restrain.search.restrained"] = "You cannot search anyone while tied up.",
    ["restrain.search.no_inventory"] = "That individual has no accessible inventory.",

    -- Target status display
    ["restrain.state.tied"] = "This person is zip-tied.",

    -- Config display names
    ["config.restrain.enabled"] = "Enable Restrain",
    ["config.restrain.max_distance"] = "Max Interaction Distance",
    ["config.restrain.search.max_distance"] = "Max Search Distance",
    ["config.restrain.speed.tied"] = "Tied Player Speed",
    ["config.restrain.action.tie_time"] = "Tie Action Duration",
    ["config.restrain.action.untie_time"] = "Bare-Hands Untie Duration",
    ["config.restrain.action.cut_time"] = "Cutting Tool Untie Duration",
    ["config.restrain.action.search_time"] = "Search Action Duration",

    -- Config help strings
    ["config.restrain.enabled.help"] = "Enable or disable the restrain system.",
    ["config.restrain.max_distance.help"] = "Distance in Hammer units within which tie, untie, and search actions can be started.",
    ["config.restrain.search.max_distance.help"] = "Distance in Hammer units at which an open search is automatically closed.",
    ["config.restrain.speed.tied.help"] = "Maximum movement speed (HU/s) for a tied-up player.",
    ["config.restrain.action.tie_time.help"] = "Duration in seconds of the zip-tie action bar.",
    ["config.restrain.action.untie_time.help"] = "Duration in seconds of the bare-hands untie action bar (hold USE on a tied player).",
    ["config.restrain.action.cut_time.help"] = "Duration in seconds of the untie action bar when using a cutting tool.",
    ["config.restrain.action.search_time.help"] = "Duration in seconds of the search action bar.",
})
