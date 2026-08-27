--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]
if CLIENT then
    ax.option:Add("multicore", ax.type.bool, GetConVar("gmod_mcore_test"):GetInt() ~= 0, {
        description = "Enable multicore rendering optimizations (gmod_mcore_test)",
        category = "performance",
        subCategory = "general",
    })

    ax.option:Add("mapspecular", ax.type.bool, GetConVar("mat_specular"):GetInt() ~= 0, {
        description = "Toggle specular lighting on maps (mat_specular)",
        category = "performance",
        subCategory = "graphics",
    })

    ax.option:Add("mapbloomscale", ax.type.bool, GetConVar("mat_bloomscale"):GetInt() ~= 0, {
        description = "Toggle bloom scale effect (mat_bloomscale)",
        category = "performance",
        subCategory = "graphics",
    })

    ax.option:Add("drawmodeldecals", ax.type.bool, GetConVar("r_drawmodeldecals"):GetInt() ~= 0, {
        description = "Render decals on models (r_drawmodeldecals)",
        category = "performance",
        subCategory = "graphics",
    })

    ax.option:Add("mipmaptextures", ax.type.bool, GetConVar("mat_mipmaptextures"):GetInt() ~= 0, {
        description = "Enable mipmapped textures (mat_mipmaptextures)",
        category = "performance",
        subCategory = "textures",
    })

    ax.option:Add("skybox", ax.type.bool, GetConVar("r_3dsky"):GetInt() ~= 0, {
        description = "Enable 3D skybox rendering (r_3dsky)",
        category = "performance",
        subCategory = "graphics",
    })

    ax.option:Add("aiexpression", ax.type.bool, GetConVar("ai_expression_optimization"):GetInt() ~= 0, {
        description = "Optimize AI facial expressions (ai_expression_optimization)",
        category = "performance",
        subCategory = "ai",
    })

    ax.option:Add("detaildistance", ax.type.number, GetConVar("cl_detaildist"):GetInt(), {
        description = "Distance for detail props rendering (cl_detaildist)",
        category = "performance",
        subCategory = "lod",
        min = 0,
        max = 10000,
    })

    ax.option:Add("detailfade", ax.type.number, GetConVar("cl_detailfade"):GetInt(), {
        description = "Fade distance for detail props (cl_detailfade)",
        category = "performance",
        subCategory = "lod",
        min = 0,
        max = 10000,
    })

    ax.option:Add("bloom", ax.type.bool, GetConVar("pp_bloom"):GetInt() ~= 0, {
        description = "Enable bloom post-processing (pp_bloom)",
        category = "performance",
        subCategory = "postprocessing",
    })

    ax.option:Add("filterlightmaps", ax.type.bool, GetConVar("mat_filterlightmaps"):GetInt() ~= 0, {
        description = "Smooth lightmap filtering (mat_filterlightmaps)",
        category = "performance",
        subCategory = "lighting",
    })

    ax.option:Add("filtertextures", ax.type.bool, GetConVar("mat_filtertextures"):GetInt() ~= 0, {
        description = "Enable texture filtering (mat_filtertextures)",
        category = "performance",
        subCategory = "textures",
    })

    ax.option:Add("max_decals", ax.type.number, GetConVar("r_decals"):GetInt(), {
        description = "Maximum world decals (r_decals)",
        category = "performance",
        subCategory = "decals",
        min = 0,
        max = 10000,
    })

    ax.option:Add("max_modeldecals", ax.type.number, GetConVar("r_maxmodeldecal"):GetInt(), {
        description = "Maximum decals on models (r_maxmodeldecal)",
        category = "performance",
        subCategory = "decals",
        min = 0,
        max = 100,
    })

    local maxDLights = GetConVar("r_maxdlights")
    ax.option:Add("max_dynamiclights", ax.type.number, maxDLights and maxDLights:GetInt() or 32, {
        description = "Maximum dynamic lights (r_maxdlights)",
        category = "performance",
        subCategory = "lighting",
        min = 0,
        max = 100,
    })
end

ax.option:Add("performance.animations", ax.type.bool, true, {
    category = "interface",
    subCategory = "performance",
    description = "performance.animations.help",
    bNoNetworking = true
})

ax.option:Add("performance.blur", ax.type.bool, true, {
    category = "interface",
    subCategory = "performance",
    description = "performance.blur.help",
    bNoNetworking = true
})

ax.option:Add("performance.vignette.trace", ax.type.bool, true, {
    category = "interface",
    subCategory = "performance",
    description = "performance.vignette.trace.help",
    bNoNetworking = true
})

ax.option:Add("performance.voice.indicators", ax.type.bool, true, {
    category = "interface",
    subCategory = "performance",
    description = "performance.voice.indicators.help",
    bNoNetworking = true
})

ax.option:Add("inventory.categories.italic", ax.type.bool, true, {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.categories.italic.help",
    bNoNetworking = true
})

ax.option:Add("interface.theme", ax.type.array, "dark", {
    category = "interface",
    subCategory = "appearance",
    description = "interface.theme.help",
    choices = {
        ["dark"] = "theme.dark",
        ["light"] = "theme.light",
        ["blue"] = "theme.blue",
        ["purple"] = "theme.purple",
        ["green"] = "theme.green",
        ["red"] = "theme.red",
        ["orange"] = "theme.orange"
    },
    bNoNetworking = true,
    OnChanged = function(self, oldValue, value)
        if ( IsValid(ax.gui.main) ) then
            ax.gui.main:Remove()
            vgui.Create("ax.main")

            -- just notify the user that the main menu has been rebuilt to apply the new theme
            Derma_Message("The main menu has been rebuilt to apply the new theme.", "Theme Changed", "OK")
        end
    end
})

ax.option:Add("interface.glass.roundness", ax.type.number, 8, {
    category = "interface",
    subCategory = "appearance",
    description = "interface.glass.roundness.help",
    min = 0,
    max = 24,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("interface.glass.blur", ax.type.number, 1.0, {
    category = "interface",
    subCategory = "appearance",
    description = "interface.glass.blur.help",
    min = 0,
    max = 2.0,
    decimals = 2,
    bNoNetworking = true
})

ax.option:Add("interface.glass.opacity", ax.type.number, 1.0, {
    category = "interface",
    subCategory = "appearance",
    description = "interface.glass.opacity.help",
    min = 0.2,
    max = 1.5,
    decimals = 2,
    bNoNetworking = true
})

ax.option:Add("interface.glass.borderOpacity", ax.type.number, 1.0, {
    category = "interface",
    subCategory = "appearance",
    description = "interface.glass.borderOpacity.help",
    min = 0.2,
    max = 1.5,
    decimals = 2,
    bNoNetworking = true
})

ax.option:Add("interface.glass.gradientOpacity", ax.type.number, 1.0, {
    category = "interface",
    subCategory = "appearance",
    description = "interface.glass.gradientOpacity.help",
    min = 0.0,
    max = 1.5,
    decimals = 2,
    bNoNetworking = true
})

-- UI scaling and layout options
ax.option:Add("interface.scale", ax.type.number, 1.0, {
    min = 0.5,
    max = 2.0,
    decimals = 1,
    category = "interface",
    subCategory = "layout",
    description = "UI element scaling factor (affects notifications, panels, etc.)",
    bNoNetworking = true
})

ax.option:Add("inventory.columns", ax.type.number, 3, {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.columns.help",
    min = 2,
    max = 8,
    decimals = 0,
    bNoNetworking = true,
    OnChanged = function(self, oldValue, value)
        if ( CLIENT and IsValid(ax.gui.inventory) ) then
            ax.gui.inventory:PopulateItems()
        end
    end
})

ax.option:Add("store.columns", ax.type.number, 3, {
    category = "interface",
    subCategory = "inventory",
    description = "store.columns.help",
    min = 1,
    max = 8,
    decimals = 0,
    bNoNetworking = true,
    OnChanged = function(self, oldValue, value)
        if ( CLIENT and IsValid(ax.gui.settings) ) then
            ax.gui.settings:Remove()
            ax.command:Run("settings")
        end
    end
})

ax.option:Add("inventory.sort.categories", ax.type.array, "alphabetical", {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.sort.categories.help",
    choices = {
        ["alphabetical"] = "inventory.sort.alphabetical",
        ["manual"] = "inventory.sort.manual"
    },
    bNoNetworking = true
})

ax.option:Add("inventory.sort.items", ax.type.array, "alphabetical", {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.sort.items.help",
    choices = {
        ["alphabetical"] = "inventory.sort.alphabetical",
        ["weight"] = "inventory.sort.weight",
        ["class"] = "inventory.sort.class"
    },
    bNoNetworking = true
})

ax.option:Add("inventory.search.live", ax.type.bool, true, {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.search.live.help",
    bNoNetworking = true
})

ax.option:Add("inventory.categories.collapsible", ax.type.bool, false, {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.categories.collapsible.help",
    bNoNetworking = true
})

ax.option:Add("inventory.pagination.page_size", ax.type.number, 24, {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.pagination.page_size.help",
    min = 1,
    max = 128,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("inventory.actions.confirm_bulk_drop", ax.type.bool, true, {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.actions.confirm_bulk_drop.help",
    bNoNetworking = true
})

ax.option:Add("button.delay.click", ax.type.number, 0.1, {
    category = "interface",
    subCategory = "interaction",
    description = "button.delay.click.help",
    min = 0,
    max = 1,
    decimals = 2,
    bNoNetworking = true
})

-- Visual preference options

ax.option:Add("hud.bar.health.show", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "hud.bar.health.show.help",
    bNoNetworking = true
})

ax.option:Add("hud.bar.armor.show", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "hud.bar.armor.show.help",
    bNoNetworking = true
})

ax.option:Add("hud.elements.enabled", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "hud.elements.enabled.help",
    bNoNetworking = true
})

ax.option:Add("hud.targetid.enabled", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.enabled.help",
    bNoNetworking = true
})

ax.option:Add("hud.targetid.distance", ax.type.number, 96, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.distance.help",
    min = 32,
    max = 512,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.fade_speed_in", ax.type.number, 10, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.fade_speed_in.help",
    min = 1,
    max = 30,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.fade_speed_out", ax.type.number, 10, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.fade_speed_out.help",
    min = 1,
    max = 30,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.position_speed", ax.type.number, 20, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.position_speed.help",
    min = 1,
    max = 40,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.max_width", ax.type.number, 128, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.max_width.help",
    min = 64,
    max = 384,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.line_spacing", ax.type.number, 6, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.line_spacing.help",
    min = 4,
    max = 16,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.visible_delay", ax.type.number, 0.1, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.visible_delay.help",
    min = 0,
    max = 1,
    decimals = 2,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.player_offset", ax.type.number, 16, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.player_offset.help",
    min = 0,
    max = 64,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.flash_speed", ax.type.number, 0.75, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.flash_speed.help",
    min = 0.1,
    max = 5,
    decimals = 2,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.show_descriptions", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.show_descriptions.help",
    bNoNetworking = true
})

ax.option:Add("hud.targetid.show_extras", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.show_extras.help",
    bNoNetworking = true
})

-- Chat preferences
ax.option:Add("chat.timestamps", ax.type.bool, false, {
    category = "chat",
    subCategory = "formatting",
    description = "chat.timestamps.help",
    bNoNetworking = true
})

-- whether or not to use 0-24 hours or the PM/AM system
ax.option:Add("chat.timestamps.24hour", ax.type.bool, false, {
    category = "chat",
    subCategory = "formatting",
    description = "chat.timestamps.24hour.help",
    bNoNetworking = true
})

ax.option:Add("chat.sounds", ax.type.bool, true, {
    category = "chat",
    subCategory = "behavior",
    description = "chat.sounds.help",
    bNoNetworking = true
})

ax.option:Add("chat.randomized.verbs", ax.type.bool, true, {
    category = "chat",
    subCategory = "behavior",
    description = "chat.randomized.verbs.help",
    bNoNetworking = true
})

-- Notification customization
ax.option:Add("notification.enabled", ax.type.bool, true, {
    category = "interface",
    subCategory = "notifications",
    description = "notification.enabled.help",
    bNoNetworking = true
})

ax.option:Add("notification.length.default", ax.type.number, 5, {
    min = 1,
    max = 20,
    decimals = 0,
    category = "interface",
    subCategory = "notifications",
    description = "notification.length.default.help",
    bNoNetworking = true
})

ax.option:Add("notification.sounds", ax.type.bool, true, {
    category = "interface",
    subCategory = "notifications",
    description = "notification.sounds.help",
    bNoNetworking = true
})

ax.option:Add("notification.position", ax.type.array, "bottomcenter", {
    category = "interface",
    subCategory = "notifications",
    description = "notification.position.help",
    choices = {
        ["topright"] = "Top Right", ["topleft"] = "Top Left", ["topcenter"] = "Top Center",
        ["bottomright"] = "Bottom Right", ["bottomleft"] = "Bottom Left", ["bottomcenter"] = "Bottom Center"
    },
    bNoNetworking = true
})

ax.option:Add("notification.scale", ax.type.number, 1.0, {
    min = 0.5,
    max = 2.0,
    decimals = 1,
    category = "interface",
    subCategory = "notifications",
    description = "notification.scale.help",
    bNoNetworking = true
})

ax.option:Add("fontScaleGeneral", ax.type.number, 1, {
    category = "interface",
    subCategory = "typography",
    description = "fontScaleGeneral.help",
    min = 0.5,
    max = 2,
    decimals = 2,
    deferredUpdate = true,
    bNoNetworking = true,
    OnChanged = function(self, oldValue, value)
        ax.font:Load()

        Derma_Message("Font scale changed. You may need to rejoin the server for all changes to take effect.", "Font Scale Changed", "OK")
    end
})

ax.option:Add("fontScaleSmall", ax.type.number, 1, {
    category = "interface",
    subCategory = "typography",
    description = "fontScaleSmall.help",
    min = 0.5,
    max = 2,
    decimals = 2,
    deferredUpdate = true,
    bNoNetworking = true,
    OnChanged = function(self, oldValue, value)
        ax.font:Load()

        Derma_Message("Font scale changed. You may need to rejoin the server for all changes to take effect.", "Font Scale Changed", "OK")
    end
})

ax.option:Add("fontScaleBig", ax.type.number, 1, {
    category = "interface",
    subCategory = "typography",
    description = "fontScaleBig.help",
    min = 0.5,
    max = 2,
    decimals = 2,
    deferredUpdate = true,
    bNoNetworking = true,
    OnChanged = function(self, oldValue, value)
        ax.font:Load()

        Derma_Message("Font scale changed. You may need to rejoin the server for all changes to take effect.", "Font Scale Changed", "OK")
    end
})
