ax.net:Hook("ax.persistence_sync", function(payload)
    if IsValid(ax.gui.persistence) then
        ax.gui.persistence:Remove()
    end

    ax.gui.persistence = vgui.Create("axMenuPersistence")
    ax.gui.persistence:Populate(payload)
end)

ax.persistence = ax.persistence or {}

ax.net:Hook("ax.persistence.highlight", function(ent)
    if not IsValid(ent) then return end

    ax.persistence.highlightEnt = ent
    ax.persistence.highlightExpire = CurTime() + 5
end)