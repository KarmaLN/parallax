local MODULE = MODULE
MODULE.name = "HUD"
MODULE.author = "KarmaLN"
MODULE.description = ""

ax.hud = ax.hud or {}
ax.hud.bars = ax.hud.bars or {}

-- Register a new HUD bar
function ax.hud:RegisterBar(id, data)
    if not id or not istable(data) then return end

    data.priority  = data.priority or 0
    data.iconColor = data.iconColor or Color(255, 255, 255)

    ax.hud.bars[id] = data
end

function ax.hud:GetBars()
    return ax.hud.bars
end

local function DrawBar(id, x, y, w, h, targetValue, maxValue, color, icon, iconColor)
    local client = ax.client or LocalPlayer()

    targetValue = math.Clamp(targetValue or 0, 0, maxValue or 1)

    client._bars = client._bars or {}
    client._bars[id] = client._bars[id] or targetValue

    -- Smooth interpolation
    client._bars[id] = ax.ease:Lerp(
        "Linear",
        math.Clamp(FrameTime() * 10, 0, 1),
        client._bars[id],
        targetValue
    )

    local currentValue = client._bars[id]
    local frac = maxValue > 0 and (currentValue / maxValue) or 0

    -- Draw icon
    if icon then
        ax.render.DrawMaterial(
            0,
            x,
            y - h / 2,
            h * 2,
            h * 2,
            iconColor or color,
            icon
        )

        x = x + h * 2 + ax.util:ScreenScale(4)
    end

    -- Background
    ax.render.Draw(0, x, y, w, h, Color(0, 0, 0, 150))

    -- Fill
    local fillW = math.max(0, w * frac)

    if fillW > 0 then
        ax.render.Draw(0, x, y, fillW, h, color)
    end
end

-- =========================
-- HUD DRAWING
-- =========================
if CLIENT then
    function MODULE:HUDPaintCurvy()
        local client = LocalPlayer()

        if (not ax.util:IsValidPlayer(client) or not client:Alive()) then return end
        if not client:GetCharacter() then return end
        if IsValid(ax.gui.tab) then return end

        local barWidth  = ax.util:ScreenScale(100)
        local barHeight = ax.util:ScreenScaleH(4)

        local x = ax.util:ScreenScale(0) + barHeight * 2 + 20
        local yBase = ax.util:ScreenScaleH(8)
        local spacing = 40

        local i = 0

        for id, bar in SortedPairsByMemberValue(ax.hud:GetBars(), "priority") do
            -- Safety checks
            if not bar.getValue or not bar.getMax then continue end

            -- Optional visibility check
            if bar.shouldDraw and not bar.shouldDraw(client) then continue end

            local value = bar.getValue(client) or 0
            local max   = bar.getMax(client) or 0

            if max <= 0 then continue end

            -- Support dynamic colors
            local color = isfunction(bar.color) and bar.color(client) or bar.color

            i = i + 1
            local y = yBase + (i * spacing)

            DrawBar(
                id,
                x,
                y,
                barWidth,
                barHeight,
                value,
                max,
                color or Color(255,255,255),
                bar.icon,
                bar.iconColor
            )
        end
    end
end

-- =========================
-- DEFAULT BARS
-- =========================

ax.hud:RegisterBar("health", {
    priority = 1,

    getValue = function(client)
        return client:Health()
    end,

    getMax = function(client)
        return client:GetMaxHealth()
    end,

    color = function(client)
        local hp = client:Health()
        if hp < 25 then
            return Color(255, 50, 50)
        end
        return Color(255, 100, 100, 200)
    end,

    icon = ax.util:GetMaterial("parallax/icons/heart.png", "smooth mips"),
})

ax.hud:RegisterBar("armor", {
    priority = 2,

    getValue = function(client)
        return client:Armor()
    end,

    getMax = function(client)
        return client:GetMaxArmor()
    end,

    color = Color(100, 100, 255, 200),
    icon = ax.util:GetMaterial("parallax/icons/shield.png", "smooth mips"),

    shouldDraw = function(client)
        return client:Armor() > 0
    end
})