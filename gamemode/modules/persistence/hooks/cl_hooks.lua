hook.Add("PreDrawHalos", "ax.persistence.halo", function()
    local ent = ax.persistence.highlightEnt
    if not IsValid(ent) then return end

    if CurTime() > (ax.persistence.highlightExpire or 0) then
        ax.persistence.highlightEnt = nil
        return
    end
    
    halo.Add({ent}, Color(255, 0, 0), 5, 5, 2, true, true)
end)