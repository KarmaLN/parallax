ITEM.name = "Keycard Base"
ITEM.model = Model("models/props_lab/clipboard.mdl")
ITEM.description = "a small, flat card—usually made of plastic—that is used to unlock doors or access secured areas electronically. It contains embedded technology such as a magnetic stripe, RFID chip, or NFC chip, which communicates with a reader to grant or deny access."

ITEM.category = "Keycard"
ITEM.clearance = 1
ITEM.weight = 0.2

ITEM.isBase = true


function ITEM:GetDescription()
    return "Clearance: " .. self.clearance
end