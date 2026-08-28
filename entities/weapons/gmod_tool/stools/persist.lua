TOOL.Category = "Parallax"
TOOL.Name = "#tool.persist.name"

if CLIENT then
    language.Add("tool.persist.name", "Persist Tool")
    language.Add("tool.persist.desc", "Save and remove persistent props")
    language.Add("tool.persist.0", "Left click: Save | Right click: Remove | Reload: Open menu")
end

local banned = {
    ["func_door"] = true,
    ["prop_door_rotating"] = true,
    ["func_breakable_surf"] = true
}

local function CanUse(ply)
    return IsValid(ply) and ply:IsAdmin()
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not CanUse(ply) then return false end

    local ent = trace.Entity
    if not IsValid(ent) then return false end

    local class = string.lower(ent:GetClass() or "")
    if banned[class] then return false end

    if ent:IsPlayer() then return false end
	if ent:GetNWBool("Persistent", false) then return false end
    
    ax.persistence:Add(ent)
    ply:Notify("Persistent prop added!")

    return true
end

function TOOL:RightClick(trace)
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not CanUse(ply) then return false end

    local ent = trace.Entity
    if not IsValid(ent) then return false end
    if ent:IsPlayer() then return false end
    if not ent:GetNWBool("Persistent", false) then ply:Notify("Prop already persisted!") return false end

    local uid = ax.persistence:GetUID(ent)
    if not uid then return false end

    ax.persistence:RemoveByUID(uid)

    ply:Notify("Persistent prop removed!")

    return true
end

local lastReload = 0

function TOOL:Reload(trace)
    local ply = self:GetOwner()

    -- CLIENT: open menu if not aiming at persistent prop
    if CLIENT then
        local ent = trace.Entity

        if not (IsValid(ent) and ent:GetNWBool("Persistent", false)) then
            ax.net:Start("ax.persistence_openMenu")
        end

        return true
    end

    -- SERVER: update prop
    if not IsValid(ply) or not ply:IsAdmin() then return false end

    local ent = trace.Entity

    if IsValid(ent) and ent:GetNWBool("Persistent", false) then
        local uid = ax.persistence:GetUID(ent)
        if not uid then return false end

        local updated = ax.persistence:UpdateByUID(uid, ent)

        if updated then
            ply:Notify("Updated persisted prop!")
        else
            ply:Notify("Failed to update prop!")
        end
    end

    return true
end