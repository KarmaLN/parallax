--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.config:Add("restrain.enabled", ax.type.bool, true, {
    description = "config.restrain.enabled.help",
    category = "restrain",
    subCategory = "general"
})

ax.config:Add("restrain.max_distance", ax.type.number, 96, {
    description = "config.restrain.max_distance.help",
    min = 32,
    max = 256,
    decimals = 0,
    category = "restrain",
    subCategory = "general"
})

ax.config:Add("restrain.search.max_distance", ax.type.number, 128, {
    description = "config.restrain.search.max_distance.help",
    min = 64,
    max = 512,
    decimals = 0,
    category = "restrain",
    subCategory = "general"
})

ax.config:Add("restrain.speed.tied", ax.type.number, 80, {
    description = "config.restrain.speed.tied.help",
    min = 1,
    max = 300,
    decimals = 0,
    category = "restrain",
    subCategory = "general"
})

ax.config:Add("restrain.action.tie_time", ax.type.number, 5, {
    description = "config.restrain.action.tie_time.help",
    min = 0.5,
    max = 30,
    decimals = 1,
    category = "restrain",
    subCategory = "timing"
})

ax.config:Add("restrain.action.untie_time", ax.type.number, 15, {
    description = "config.restrain.action.untie_time.help",
    min = 1,
    max = 60,
    decimals = 1,
    category = "restrain",
    subCategory = "timing"
})

ax.config:Add("restrain.action.cut_time", ax.type.number, 3, {
    description = "config.restrain.action.cut_time.help",
    min = 0.5,
    max = 15,
    decimals = 1,
    category = "restrain",
    subCategory = "timing"
})

ax.config:Add("restrain.action.search_time", ax.type.number, 4, {
    description = "config.restrain.action.search_time.help",
    min = 0.5,
    max = 30,
    decimals = 1,
    category = "restrain",
    subCategory = "timing"
})
