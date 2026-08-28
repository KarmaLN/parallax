--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local player = ax.player.meta or FindMetaTable("Player")

--- Returns whether this player is currently tied up.
---@realm shared
---@return boolean tied Whether the player is tied up.
function player:IsRestrained()
    local restrain = ax.restrain
    if ( !istable(restrain) ) then return false end

    return restrain:IsRestrained(self)
end

local zeroAngle = Angle(0, 0, 0)

local function isFemaleModel(client)
    local model = string.lower(tostring(client:GetModel() or ""))

    return string.find(model, "female", 1, true) != nil
end

--- Sets whether this player's hands should be posed behind their back via bone manipulation.
---@realm shared
---@param bState boolean Whether the pose should be applied.
function player:SetHandsBehindBack(bState)
    local leftUpperArm = self:LookupBone("ValveBiped.Bip01_L_UpperArm")
    local rightUpperArm = self:LookupBone("ValveBiped.Bip01_R_UpperArm")
    local leftForearm = self:LookupBone("ValveBiped.Bip01_L_Forearm")
    local rightForearm = self:LookupBone("ValveBiped.Bip01_R_Forearm")
    local leftHand = self:LookupBone("ValveBiped.Bip01_L_Hand")
    local rightHand = self:LookupBone("ValveBiped.Bip01_R_Hand")

    if ( !leftUpperArm or !rightUpperArm or !leftForearm or !rightForearm or !leftHand or !rightHand ) then
        return
    end

    if ( bState ) then
        local bFemale = isFemaleModel(self)

        self:ManipulateBoneAngles(leftUpperArm, Angle(5, 5, 0))
        self:ManipulateBoneAngles(rightUpperArm, Angle(-5, 10, 0))
        self:ManipulateBoneAngles(leftForearm, bFemale and Angle(16, 5, 0) or Angle(25, 5, 0))
        self:ManipulateBoneAngles(rightForearm, bFemale and Angle(-16, 5, 0) or Angle(-25, 5, 0))
        self:ManipulateBoneAngles(leftHand, Angle(-25, -10, 0))
        self:ManipulateBoneAngles(rightHand, Angle(25, -10, 0))
    else
        self:ManipulateBoneAngles(leftUpperArm, zeroAngle)
        self:ManipulateBoneAngles(rightUpperArm, zeroAngle)
        self:ManipulateBoneAngles(leftForearm, zeroAngle)
        self:ManipulateBoneAngles(rightForearm, zeroAngle)
        self:ManipulateBoneAngles(leftHand, zeroAngle)
        self:ManipulateBoneAngles(rightHand, zeroAngle)
    end
end
