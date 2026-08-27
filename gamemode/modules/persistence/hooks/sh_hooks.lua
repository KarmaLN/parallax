function MODULE:PhysgunPickup(ply, ent)
    local banned = {
        ["func_door"] = true,
        ["prop_door_rotating"] = true,
        ["func_breakable_surf"] = true
    }
    
    if not IsValid(ent) then return end
    
  	if banned[ent:GetClass()] then return false end
    --if ent:GetNWBool("Persistent", false) then return false end
end