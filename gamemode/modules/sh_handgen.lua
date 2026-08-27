local MODULE = MODULE

MODULE.Name = "C_Hands Generator"
MODULE.Description = "Generates custom hands for players."
MODULE.Author = "Khall"

if CLIENT then 
    local playerMeta = FindMetaTable("Player")
    local entMeta = FindMetaTable("Entity")
    
    local CGEN_mode = 3
    local CGEN_long = 0
    local cl_playermodel = GetConVar("cl_playermodel")

    local handsRootLong = {
        ['ValveBiped.Bip01_R_Clavicle'] = true,
        ['ValveBiped.Bip01_L_Clavicle'] = true,
    }

    local handsRoot = {
        ['ValveBiped.Bip01_R_UpperArm'] = true,
        ['ValveBiped.Bip01_L_UpperArm'] = true,
    }

    local CGEN_CurHandsModel = ""
    local CGEN_CurHandsSkin = 0
    local CGEN_CurHandsBGs = {}
    local CGEN_CurTime = CurTime()
    local CGEN_BoneDraw = false
    local CGEN_ForceReload = false
    local CGEN_RootBones = {}
    local CGEN_HandBones = {}

    function entMeta:GetAllChildBones(rootBone)
        local bones = {}

        local function AddChildren(parent)
            local children = self:GetChildBones(parent)

            if not children then return end

            for _, child in ipairs(children) do
                bones[self:GetBoneName(child)] = true
                AddChildren(child)
            end
        end

        bones[self:GetBoneName(rootBone)] = true
        AddChildren(rootBone)

        return bones
    end

    function playerMeta:CGENGetDefaultHands()
        local playerModel = self:GetModel()
        local playerModelName = player_manager.TranslateToPlayerModelName(playerModel)
        local data = player_manager.TranslatePlayerHands(playerModelName)

        data.model = tostring(data.model)
        data.skin = tonumber(data.skin)
        data.body = tostring(data.body)

        return data
    end

    function MODULE:OutfitApply(ply, model, download_info)
        ply.m_sCGENForcedModel = model != "" and model or nil

        if model == "" then 
            ply:SetModel(ply.original_model or player_manager.TranslatePlayerModel(cl_playermodel:GetString())) 
        end 
    end

    local function CGEN_HandsDraw(self)
        local ply = LocalPlayer()

        if CGEN_CurTime != CurTime() then 
            self:SetModel(self:GetModel()) 
        end
        
        local plySkin = ply:GetSkin()
        local skinChanged = (CGEN_CurHandsSkin != plySkin)
        local bgChanged = false
        
        for i = 0, ply:GetNumBodyGroups() - 1 do
            local currentBG = ply:GetBodygroup(i)
            if CGEN_CurHandsBGs[i] != currentBG then
                bgChanged = true
                break
            end
        end
        
        if CGEN_ForceReload or (CGEN_CurHandsModel and CGEN_CurHandsModel != self:GetModel()) or skinChanged or bgChanged then
            CGEN_ForceReload = false
            CGEN_BoneDraw = false

            local data = ply:CGENGetDefaultHands()
            local plyModel = ply:GetModel()

            if CGEN_mode == 3 or not data or data.model == plyModel then 
                CGEN_RootBones = (CGEN_long == 1) and handsRootLong or handsRoot
                CGEN_HandBones = {}

                self:SetModel(ply:GetModel())
                self:SetSkin(ply:GetSkin())
                self:SetColor(ply:GetPlayerColor():ToColor())

                for i = 0, ply:GetNumBodyGroups() - 1 do
                    if self:GetBodygroupCount(i) > 0 then
                        self:SetBodygroup(i, ply:GetBodygroup(i)) 
                    end
                end

                local hasHandsRoot = false
                for i = 0, self:GetBoneCount() - 1 do
                    local bName = self:GetBoneName(i)
                    if CGEN_RootBones[bName] then
                        hasHandsRoot = true
                        break
                    end
                end

                if not hasHandsRoot then
                    local defaultData = ply:CGENGetDefaultHands()
                    if defaultData and defaultData.model then
                        self:SetModel(defaultData.model)
                        self:SetSkin(defaultData.skin)
                        self:SetBodyGroups(defaultData.body)
                        CGEN_BoneDraw = false
                    else
                        CGEN_BoneDraw = true
                    end
                else
                    for i = 0, self:GetBoneCount() - 1 do
                        local bName = self:GetBoneName(i)
                        
                        if CGEN_RootBones[bName] then
                            CGEN_HandBones[bName] = true
                            table.Merge(CGEN_HandBones, self:GetAllChildBones(i))
                        end
                    end

                    CGEN_BoneDraw = true
                end
            else
                self:SetModel(data.model)
                self:SetSkin(data.skin)
                self:SetBodyGroups(data.body)
            end

            CGEN_CurHandsModel = self:GetModel()
            CGEN_CurHandsSkin = plySkin
            
            for i = 0, ply:GetNumBodyGroups() - 1 do
                CGEN_CurHandsBGs[i] = ply:GetBodygroup(i)
            end
        end

        if CGEN_BoneDraw then
            local hidden = Vector(0.0001, 0.0001, 0.0001)
            local shown = Vector(1,1,1)

            for i = 0, self:GetBoneCount() - 1 do
                local bName = self:GetBoneName(i)

                if CGEN_HandBones[bName] then
                    self:ManipulateBoneScale(i, shown)
                else
                    self:ManipulateBoneScale(i, hidden)
                end
            end

            self:DrawModel()
            
            CGEN_CurTime = CurTime()
        else 
            self:DrawModel() 
        end
    end

    function MODULE:PostDrawPlayerHands(ent, vm, ply, wep)
        if CurTime() - CGEN_CurTime >= 0.1 then
            ent.Draw = function() 
                CGEN_HandsDraw(ent)
            end
        end
    end
end