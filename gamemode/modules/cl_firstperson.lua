local MODULE = MODULE
MODULE.name = "Bodycam"
MODULE.author = "KarmaLN"
MODULE.description = "First-person bodycam system using Parallax viewstack."

-- =========================
-- Options
-- =========================
ax.localization:Register("en", {
    ["option.bodycam"] = "Bodycam",
    ["subcategory.firstperson"] = "First Person",
})

ax.option:Add("bodycam", ax.type.bool, true, {
    description = "Enable/Disable Bodycam",
    category = "camera",
    subCategory = "firstperson",
})

if SERVER then return end

-- =========================
-- Settings
-- =========================
local DISABLE_ON_ADS = true
local REALISM = false
local SMOOTHING = 15

-- =========================
-- Locals
-- =========================
local LocalPlayer = LocalPlayer

local camWeight = 0
local smoothAng = nil

local lastModel = nil
local headBone = nil

local vecZero = Vector(0, 0, 0)
local vecOne  = Vector(1, 1, 1)

-- =========================
-- Weapon blacklist
-- =========================
local blackList = {
    ["gmod_camera"] = true,
    ["gmod_tool"] = true,
    ["weapon_physgun"] = true,
    ["weapon_physcannon"] = true,
    ["weapon_pa_fists"] = true,
}

-- =========================
-- GUI CHECK (NEW)
-- =========================
local guiBlacklist = {
    ["ax.gui.chatbox"] = true, -- default chatbox
}
local function IsGUIOpen()
    if not ax.gui then return false end

    for k, v in pairs(ax.gui) do
        if not v or type(v) ~= "Panel" and type(v) ~= "table" then
            ax.gui[k] = nil
            continue
        end

        if IsValid(v) then
            if guiBlacklist[v] then continue end

            if v:IsVisible() and v:GetAlpha() > 0 then
                return true
            end
        else
            ax.gui[k] = nil
        end
    end

    return false
end

-- =========================
-- Head bone cache
-- =========================
local function GetHeadBone(ply)
    local mdl = ply:GetModel()
    if mdl ~= lastModel then
        lastModel = mdl

        headBone = ply:LookupBone("ValveBiped.Bip01_Head1")
            or ply:LookupBone("Head")
            or ply:LookupBone("head")
    end

    return headBone
end

-- =========================
-- Head hide
-- =========================
local function SetHeadHidden(ply, hide)
    if not IsValid(ply) then return end

    if ply._HeadHidden == hide then return end
    ply._HeadHidden = hide

    local bone = GetHeadBone(ply)
    if bone then
        ply:ManipulateBoneScale(bone, hide and vecZero or vecOne)
        ply:InvalidateBoneCache()
    end
end

-- =========================
-- Should enable bodycam
-- =========================
local blacklistedWeapons = {
    ["weapon_construction"] = true,
    ["ax_hands"] = true,
}

local function ShouldImmerse(client)
    if not client:Alive() or client:InVehicle() then return false end
    if ax.option:Get("thirdperson") then return false end
    if not ax.option:Get("bodycam", true) then return false end
    if client:GetViewEntity() ~= client then return false end
    if client:InVehicle() then return false end
    
    local wep = client:GetActiveWeapon()
    if not IsValid(wep) or blackList[wep:GetClass()] then return false end
	if not IsValid(wep) then return false end
    if DISABLE_ON_ADS and client:KeyDown(IN_ATTACK2) and !blacklistedWeapons[wep:GetClass()] then
        return false
    end

    return true
end

-- =========================
-- CAMERA MODIFIER (MAIN)
-- =========================
ax.viewstack:RegisterModifier("camera", function(client, patch)
    if client ~= LocalPlayer() then return end

    local target = ShouldImmerse(client) and 1 or 0
    camWeight = math.Approach(camWeight, target, FrameTime() * 8)

    local shouldHideHead = camWeight > 0.05 and not IsGUIOpen()
    SetHeadHidden(client, shouldHideHead)

    if camWeight < 0.01 then return end

    local attID = client:LookupAttachment("eyes")
    local att = attID > 0 and client:GetAttachment(attID)

    local eyePos = att and att.Pos or client:EyePos()
    local targetAng = client:EyeAngles()

    if REALISM and att then
        targetAng = att.Ang
        targetAng:RotateAroundAxis(targetAng:Right(), -90)
        targetAng:RotateAroundAxis(targetAng:Up(), 90)
    end

    smoothAng = smoothAng or targetAng
    smoothAng = LerpAngle(FrameTime() * SMOOTHING, smoothAng, targetAng)

    local finalPos = eyePos

    if camWeight > 0.1 then
        local tr = util.TraceLine({
            start = client:EyePos(),
            endpos = eyePos + targetAng:Forward() * 2,
            filter = client
        })
        finalPos = tr.HitPos
    end

    local breath = math.sin(CurTime() * 2) * 0.3 * camWeight
    finalPos = finalPos + Vector(0, 0, breath)

    local shake = math.sin(CurTime() * 6) * 0.2 * camWeight

    return {
        origin = LerpVector(camWeight, patch.origin, finalPos),
        angles = LerpAngle(camWeight, patch.angles, smoothAng + Angle(shake, 0, 0)),
        fov = patch.fov,
        drawviewer = true
    }
end, 100)

-- =========================
-- VIEWMODEL MODIFIER
-- =========================
ax.viewstack:RegisterModifier("viewmodel", function(client, patch)
    if client ~= LocalPlayer() then return end

    if camWeight > 0.25 then
        return nil
    end
end, 100)

-- =========================
-- Think Fix (UPDATED)
-- =========================
hook.Add("Think", "Bodycam_ForceHeadHide", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if camWeight > 0.05 and not IsGUIOpen() then
        local bone = GetHeadBone(ply)
        if bone then
            ply:ManipulateBoneScale(bone, vecZero)
        end
    end
end)

-- =========================
-- Hide default crosshair
-- =========================
hook.Add("HUDShouldDraw", "Bodycam_HideCrosshair", function(name)
    if camWeight > 0.25 and name == "CHudCrosshair" then
        return false
    end
end)

-- =========================
-- Custom crosshair
-- =========================
hook.Add("HUDPaint", "Bodycam_DrawCrosshair", function()
    if camWeight < 0.25 then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * 8000,
        filter = ply
    })

    local scr = tr.HitPos:ToScreen()
    local alpha = 180 * camWeight

    draw.RoundedBox(6, scr.x - 3, scr.y - 3, 6, 6, Color(0, 0, 0, alpha * 0.6))
    draw.RoundedBox(4, scr.x - 2, scr.y - 2, 4, 4, Color(255, 255, 255, alpha))
    draw.RoundedBox(2, scr.x - 1, scr.y - 1, 2, 2, Color(255, 255, 255, alpha * 0.8))
end)

-- =========================
-- Reset head on weapon switch
-- =========================
hook.Add("PlayerSwitchWeapon", "Bodycam_ResetHead", function(ply)
    SetHeadHidden(ply, false)
end)