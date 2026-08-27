local MODULE = MODULE or {}

MODULE.name = "Persistence"
MODULE.description = ""
MODULE.author = "KarmaLN"

ax.persistence = ax.persistence or {}

function MODULE:InitPostEntity()
    if SERVER then
        ax.persistence:Load()
    end
    
    local TOOL = weapons.GetStored("gmod_tool")
    TOOL = TOOL.Tool

    for toolName, toolData in pairs(TOOL) do
        if (toolName == "paint") then continue end -- Hardcode, sorry

        local oldLeftClickFunc = toolData.LeftClick
        local oldRightClickFunc = toolData.RightClick

        TOOL[toolName].LeftClick = function(this, trace)
            oldLeftClickFunc(this, trace)

            return false
        end

        TOOL[toolName].RightClick = function(this, trace)
            oldRightClickFunc(this, trace)

            return false
        end
    end
end

function MODULE:ShutDown()
    if SERVER then
        ax.persistence:Save()
    end
end