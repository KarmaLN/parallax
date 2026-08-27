-- Open persistence menu
ax.net:Hook("ax.persistence_openMenu", function(client)
    if not IsValid(client) or not client:Alive() then return end

    local payload = ax.persistence:BuildPayload()
    ax.net:Start(client, "ax.persistence_sync", payload)
end)

-- Highlight entity
ax.net:Hook("ax.persistence.highlight", function(client, uid)
    if not IsValid(client) or not client:IsAdmin() then return end

    local ent = ax.persistence.stored[uid]
    if not IsValid(ent) then return end

    ax.net:Start(client, "ax.persistence.highlight", ent)
end)

-- Remove entity
ax.net:Hook("ax.persistence.remove", function(client, uid)
    if not IsValid(client) or not client:IsAdmin() then return end
    if not uid then return end

    ax.persistence:RemoveByUID(uid)
end)

-- Teleport to entity
ax.net:Hook("ax.persistence.teleport", function(client, uid)
    if not IsValid(client) or not client:IsAdmin() then return end

    local data = ax.persistence.data[uid]
    if not data then return end

    client:SetPos(data.pos + Vector(0,0,50))
end)

-- Respawn single entity
ax.net:Hook("ax.persistence.respawn", function(client, uid)
    if not IsValid(client) or not client:IsAdmin() then return end

    local data = ax.persistence.data[uid]
    if not data then return end

    local oldEnt = ax.persistence.stored[uid]
    if IsValid(oldEnt) then
        oldEnt:Remove()
    end

    local ent = ents.Create(data.class or "prop_physics")
    if not IsValid(ent) then return end

    ent:SetModel(data.model or "")
    ent:SetPos(data.pos or vector_origin)
    ent:SetAngles(data.ang or angle_zero)

    ent:Spawn()
    ent:Activate()

    ent:SetNWBool("Persistent", true)

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(data.movable ~= false)

        if data.movable == false then
            phys:Sleep()
        else
            phys:Wake()
        end
    end

    ax.persistence.stored[uid] = ent
end)