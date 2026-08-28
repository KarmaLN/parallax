local MODULE = MODULE

MODULE.Name = "NPC Corpse Cleanup"
MODULE.Description = "A simple timer that deletes NPC Corpses"
MODULE.Author = "KarmaLN"

ax.localization:Register("en", {
    ["config.corpseCleanupTime"] = "Corpse Cleanup Time",
    ["category.modules"] = "Modules",
    ["subcategory.cleanup"] = "Cleanup",
})

ax.config:Add("corpseCleanupTime", ax.type.number, 180, {
    category = "modules",
    subCategory = "cleanup",
    description = "Sets the Cooldown on NPC Corpse Cleanup",
    min = 30,
    max = 3600,
    decimals = 0,
})

local function CleanUp()
	if SERVER then    
    	for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
        	if ent:GetNWBool("IsPlayerRagdoll") then continue end
            ent:Remove()
    	end
	end   
    RunConsoleCommand("g_ragdoll_maxcount", "0")
    
    timer.Simple(2, function()
    	RunConsoleCommand("g_ragdoll_maxcount", "15")
    end)
    
    ax.util:Print(Color(0, 255, 0),"Completed NPC Corpse Cleanup")
end

local function CleanUpTimer()
    if !timer.Exists("cleanup_Corpses") then
        timer.Create("cleanup_Corpses", ax.config:Get("corpseCleanupTime"), 0, function()
            CleanUp()
        end)
    end
end

function MODULE:OnPlayerRagdollCreated(client, ragdoll)
    ragdoll:SetNWBool("IsPlayerRagdoll", true)
end

function MODULE:OnSchemaLoaded()
	CleanUpTimer()
end
