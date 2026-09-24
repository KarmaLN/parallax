ax.persistence = ax.persistence or {}
ax.persistence.stored = ax.persistence.stored or {} -- live ents
ax.persistence.data = ax.persistence.data or {}     -- saved data

-- NWVar type name -> Entity setter/getter suffix
local NWVAR_ACCESSORS = {
    Bool = "Bool",
    Int = "Int",
    Float = "Float",
    String = "String",
    Vector = "Vector",
    Angle = "Angle"
}

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

-- Captures every networked variable (SetNWBool/Int/Float/String/Vector/Angle) set on the entity
-- NWEntity values are intentionally skipped, since they can only be restored if they still point
-- at another entity that also survives a map reload.
local function CaptureNWVars(ent)
    local nwTable = ent:GetNWVarTable()
    if not istable(nwTable) or table.IsEmpty(nwTable) then return nil end

    local result = {}
    local hasAny = false

    for nwType, suffix in pairs(NWVAR_ACCESSORS) do
        local bucket = nwTable[nwType]

        if istable(bucket) and not table.IsEmpty(bucket) then
            result[suffix] = table.Copy(bucket)
            hasAny = true
        end
    end

    return hasAny and result or nil
end

-- Restores NWVars captured by CaptureNWVars
local function RestoreNWVars(ent, nwvars)
    if not istable(nwvars) then return end

    for suffix, bucket in pairs(nwvars) do
        local setter = ent["SetNW" .. suffix]
        if isfunction(setter) then
            for key, value in pairs(bucket) do
                setter(ent, key, value)
            end
        end
    end
end

-- Builds a persistable snapshot of an entity's state
local function BuildEntry(ent, uid)
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
        collisionGroup = ent:GetCollisionGroup(),
        nwvars = CaptureNWVars(ent)
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

    return entry
end

-- Applies a persisted entry's cosmetic/state data onto a freshly created entity
local function ApplyEntry(ent, entry)
    if istable(entry.bodygroups) then
        for id, val in pairs(entry.bodygroups) do
            ent:SetBodygroup(id, val)
        end
    end

    if entry.skin ~= nil then
        ent:SetSkin(entry.skin)
    end

    if entry.color then
        ent:SetColor(entry.color)
        if entry.color.a and entry.color.a < 255 then
            ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
        end
    end

    if entry.material and entry.material ~= "" then
        ent:SetMaterial(entry.material)
    end

    if entry.collisionGroup then
        ent:SetCollisionGroup(entry.collisionGroup)
    end

    RestoreNWVars(ent, entry.nwvars)
end

-- Spawns a live entity from a persisted entry
local function SpawnFromEntry(entry)
    local ent = ents.Create(entry.class or "prop_physics")
    if not IsValid(ent) then return nil end

    ent:SetModel(entry.model or "")
    ent:SetPos(entry.pos or vector_origin)
    ent:SetAngles(entry.ang or angle_zero)

    ent:Spawn()
    ent:Activate()

    ent:SetNWBool("Persistent", true)

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(entry.movable ~= false)

        if entry.movable == false then
            phys:Sleep()
        else
            phys:Wake()
        end
    end

    ApplyEntry(ent, entry)

    return ent
end

-- Queues a debounced save so bulk operations (e.g. mass-adding props) don't hit disk repeatedly
function ax.persistence:QueueSave()
    if self.saveQueued then return end

    self.saveQueued = true

    timer.Simple(1, function()
        self.saveQueued = false
        self:Save()
    end)
end

-- Tracks an entity as persistent and links its uid both ways
function ax.persistence:Track(uid, ent)
    self.stored[uid] = ent
    ent.axPersistUID = uid

    ent:CallOnRemove("ax.persistence", function(removedEnt)
        if self.stored[removedEnt.axPersistUID] == removedEnt then
            self.stored[removedEnt.axPersistUID] = nil
        end
    end)
end

-- Add entity to persistence
function ax.persistence:Add(ent)
    if not IsValid(ent) then return end
    if ent:IsPlayer() or ent:IsVehicle() then return end
    if ent.axPersistUID and self.stored[ent.axPersistUID] == ent then return end -- already persistent

    local uid = util.CRC(ent:EntIndex() .. "_" .. CurTime() .. "_" .. math.random())

    self.data[uid] = BuildEntry(ent, uid)

    ent:SetNWBool("Persistent", true)

    self:Track(uid, ent)
    self:QueueSave()
end

-- Remove entity from persistence
function ax.persistence:RemoveByUID(uid)
    local ent = self.stored[uid]

    if IsValid(ent) then
        ent:SetNWBool("Persistent", false)
        ent.axPersistUID = nil
        ent:Remove()
    end

    self.stored[uid] = nil
    self.data[uid] = nil

    self:QueueSave()
end

-- Stops tracking an entity without deleting it, e.g. when an admin toggles persistence off
function ax.persistence:Untrack(uid)
    local ent = self.stored[uid]

    if IsValid(ent) then
        ent:SetNWBool("Persistent", false)
        ent:RemoveCallOnRemove("ax.persistence")
        ent.axPersistUID = nil
    end

    self.stored[uid] = nil
    self.data[uid] = nil

    self:QueueSave()
end

-- Update entity's saved state from its current live state
function ax.persistence:UpdateByUID(uid, ent)
    if not IsValid(ent) then return false end
    if not self.data[uid] then return false end

    self.data[uid] = BuildEntry(ent, uid)

    self:QueueSave()
    return true
end

-- Update entity (looked up by live reference)
function ax.persistence:Update(ent)
    if not IsValid(ent) then return false end

    local uid = ent.axPersistUID
    if not uid or self.stored[uid] ~= ent then return false end

    return self:UpdateByUID(uid, ent)
end

-- Save all persistent entities
function ax.persistence:Save()
    ax.data:Set("persistence", self.data, {
        scope = "map"
    })
end

-- Load and spawn all entities
function ax.persistence:Load()
    local data = ax.data:Get("persistence", {}, {
        scope = "map"
    })

    self.data = data or {}
    self.stored = {}

    local count = 0

    for uid, entry in pairs(self.data) do
        local ent = SpawnFromEntry(entry)

        if IsValid(ent) then
            self:Track(uid, ent)
            count = count + 1
        end
    end

    ax.util:PrintDebug("[Persistence] Loaded " .. count .. " entities.")
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
    if not IsValid(ent) then return nil end

    return ent.axPersistUID
end

-- Respawns a single persisted entity in-place, useful after admin edits or entity corruption
function ax.persistence:RespawnByUID(uid)
    local entry = self.data[uid]
    if not entry then return nil end

    local oldEnt = self.stored[uid]
    if IsValid(oldEnt) then
        oldEnt.axPersistUID = nil
        oldEnt:Remove()
    end

    local ent = SpawnFromEntry(entry)
    if not IsValid(ent) then return nil end

    self:Track(uid, ent)

    return ent
end