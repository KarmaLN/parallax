-- Context menu entry that lets admins toggle persistence on any prop/entity they're looking at
properties.Add("ax_persistence_toggle", {
    MenuLabel = "Toggle Persistence",
    Order = 9999,
    MenuIcon = "icon16/lock.png",

    Filter = function(self, ent, client)
        if not IsValid(ent) or not IsValid(client) then return false end
        if not client:IsAdmin() then return false end
        if ent:IsPlayer() or ent:IsVehicle() or ent:IsWorld() then return false end

        return true
    end,

    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,

    Receive = function(self, length, client)
        local ent = net.ReadEntity()

        if not properties.CanBeTargeted(ent, client) then return end
        if not self:Filter(ent, client) then return end

        if ent.axPersistUID then
            ax.persistence:Untrack(ent.axPersistUID)
            client:Notify("Entity is no longer persistent.")
        else
            ax.persistence:Add(ent)
            client:Notify("Entity is now persistent.")
        end
    end
})
