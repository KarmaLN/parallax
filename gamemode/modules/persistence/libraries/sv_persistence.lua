ax.persistence = ax.persistence or {}
ax.persistence.stored = ax.persistence.stored or {} -- live ents
ax.persistence.data = ax.persistence.data or {}     -- saved data

-- Helper (same idea as Helix)
local function GetRealModel(ent)
    if ent:GetClass() == "prop_effect" and IsValid(ent.AttachedEntity) then
        return ent.AttachedEntity:GetModel()
    end

    return ent:GetModel()
end

-- Helper: get movable safely
local function GetMovable(ent)
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        return phys:IsMoveable()
    end
    return true
end

-- Add entity to persistence
function ax.persistence:Add(ent)
    if not IsValid(ent) then return end
    if ent:IsPlayer() or ent:IsVehicle() then return end

    -- prevent duplicates
    for uid, v in pairs(self.stored) do
        if v == ent then return end
    end

    local uid = util.CRC(ent:EntIndex() .. "_" .. CurTime() .. "_" .. math.random())

    local entry = {
        uid = uid,
        class = ent:GetClass(),
        model = GetRealModel(ent),
        pos = ent:GetPos(),
        ang = ent:GetAngles(),
        movable = GetMovable(ent),
        skin = ent:GetSkin(),
        color = ent:GetColor(),
        material = ent:GetMaterial(),
        collisionGroup = ent:GetCollisionGroup()
    }

    -- bodygroups
    local bodygroups = ent:GetBodyGroups()
    local hasBodygroups = false
    entry.bodygroups = {}

    for _, bg in ipairs(bodygroups) do
        local val = ent:GetBodygroup(bg.id)
        if val > 0 then
            entry.bodygroups[bg.id] = val
            hasBodygroups = true
        end
    end

    if not hasBodygroups then
        entry.bodygroups = nil
    end

    self.data[uid] = entry
    self.stored[uid] = ent

    ent:SetNWBool("Persistent", true)

    self:Save()
end

-- Remove entity from persistence
function ax.persistence:RemoveByUID(uid)
    local ent = self.stored[uid]

    if IsValid(ent) then
        ent:SetNWBool("Persistent", false)
        ent:Remove()
    end

    self.stored[uid] = nil
    self.data[uid] = nil

    self:Save()
end

-- Update entity (FIXED)
function ax.persistence:Update(ent)
    if not IsValid(ent) then return false end

    for uid, v in pairs(self.stored) do -- ✅ FIXED (was ipairs)
        if v == ent then
            local entry = self.data[uid]
            if not entry then return false end

            entry.class = ent:GetClass()
            entry.model = GetRealModel(ent)
            entry.pos = ent:GetPos()
            entry.ang = ent:GetAngles()
            entry.movable = GetMovable(ent)
            entry.skin = ent:GetSkin()
            entry.color = ent:GetColor()
            entry.material = ent:GetMaterial()
            entry.collisionGroup = ent:GetCollisionGroup()

            -- bodygroups
            local bodygroups = ent:GetBodyGroups()
            local hasBodygroups = false
            entry.bodygroups = {}

            for _, bg in ipairs(bodygroups) do
                local val = ent:GetBodygroup(bg.id)
                if val > 0 then
                    entry.bodygroups[bg.id] = val
                    hasBodygroups = true
                end
            end

            if not hasBodygroups then
                entry.bodygroups = nil
            end

            self:Save()
            return true
        end
    end

    return false
end

-- Save all persistent entities
function ax.persistence:Save()
    ax.data:Set("persistence", self.data, {
        scope = "map"
    })
end

-- Load and spawn all entities (FIXED FREEZE)
function ax.persistence:Load()
    print("[Persistence] Loading...")

    local data = ax.data:Get("persistence", {}, {
        scope = "map"
    })

    local count = 0
    for _ in pairs(data) do count = count + 1 end
    print("[Persistence] Loaded:", count)

    self.data = data or {}
    self.stored = {}

    for uid, v in pairs(self.data) do
        local ent = ents.Create(v.class or "prop_physics")

        if IsValid(ent) then
            ent:SetModel(v.model or "")
            ent:SetPos(v.pos or vector_origin)
            ent:SetAngles(v.ang or angle_zero)

            ent:Spawn()
            ent:Activate()

            ent:SetNWBool("Persistent", true)

            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(v.movable ~= false)

                -- ✅ FIXED: enforce freeze properly
                if v.movable == false then
                    phys:Sleep()
                else
                    phys:Wake()
                end
            end

            if v.skin ~= nil then
                ent:SetSkin(v.skin)
            end

            if istable(v.bodygroups) then
                for id, val in pairs(v.bodygroups) do
                    ent:SetBodygroup(id, val)
                end
            end

            if v.color then
                ent:SetColor(v.color)
                if v.color.a and v.color.a < 255 then
                    ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
                end
            end

            if v.material and v.material ~= "" then
                ent:SetMaterial(v.material)
            end
            
            if v.collisionGroup then
                ent:SetCollisionGroup(v.collisionGroup)
            end

            self.stored[uid] = ent
        end
    end
end

function ax.persistence:BuildPayload()
    local data = {}

    for uid, v in pairs(self.data) do
        data[#data + 1] = {
            id = uid,
            class = v.class,
            model = v.model,
            pos = v.pos,
            ang = v.ang
        }
    end

    return data
end

function ax.persistence:GetUID(ent)
    for uid, v in pairs(self.stored) do
        if v == ent then
            return uid
        end
    end
end

-- Update by UID (cleaned)
function ax.persistence:UpdateByUID(uid, ent)
    if not IsValid(ent) then return false end

    local entry = self.data[uid]
    if not entry then return false end

    entry.class = ent:GetClass()
    entry.model = GetRealModel(ent)
    entry.pos = ent:GetPos()
    entry.ang = ent:GetAngles()
    entry.movable = GetMovable(ent)
    entry.skin = ent:GetSkin()
    entry.color = ent:GetColor()
    entry.material = ent:GetMaterial()
    entry.collisionGroup = ent:GetCollisionGroup()

    -- bodygroups
    local bodygroups = ent:GetBodyGroups()
    local hasBodygroups = false
    entry.bodygroups = {}

    for _, bg in ipairs(bodygroups) do
        local val = ent:GetBodygroup(bg.id)
        if val > 0 then
            entry.bodygroups[bg.id] = val
            hasBodygroups = true
        end
    end

    if not hasBodygroups then
        entry.bodygroups = nil
    end

    self:Save()
    return true
end