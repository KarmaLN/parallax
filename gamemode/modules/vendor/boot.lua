local MODULE = MODULE

MODULE.name = "Vendors"
MODULE.author = "KarmaLN"
MODULE.description = "Adds vendors that can be placed on the map."

ax.util:Include("parallax/gamemode/modules/vendor/localization/sh_english.lua", "shared")

CAMI.RegisterPrivilege({
    Name = "Parallax - Manage Vendors",
    MinAccess = "admin"
})

VENDOR_BUY = 1
VENDOR_SELL = 2
VENDOR_BOTH = 3

VENDOR_WELCOME = 1
VENDOR_LEAVE = 2
VENDOR_NOTRADE = 3

VENDOR_PRICE = 1
VENDOR_STOCK = 2
VENDOR_MODE = 3
VENDOR_MAXSTOCK = 4

VENDOR_SELLANDBUY = 1
VENDOR_SELLONLY = 2
VENDOR_BUYONLY = 3

local DATA_OPTIONS = {
    scope = "map",
    human = true
}

local function GetVendorDataKey()
    return "module_vendor"
end

if (SERVER) then
    function MODULE:Notify(client, phrase, notificationType, ...)
        local language = client:GetLanguage()
        local translations = ax.localization.langs[language]

        if (!istable(translations) and isstring(language)) then
            translations = ax.localization.langs[string.Explode("-", language)[1]]
        end

        translations = istable(translations) and translations or ax.localization.langs.en or {}

        local message = translations[phrase] or phrase
        local arguments = {...}

        if (#arguments > 0) then
            message = string.format(message, unpack(arguments))
        end

        client:Notify(message, notificationType)
    end

    function MODULE:GetData()
        local data = ax.data:Get(GetVendorDataKey(), {}, DATA_OPTIONS)
        return istable(data) and data or {}
    end

    function MODULE:SetData(data)
        return ax.data:Set(GetVendorDataKey(), istable(data) and data or {}, DATA_OPTIONS)
    end

    function MODULE:SaveData()
        local data = {}

        for _, entity in ipairs(ents.FindByClass("ax_vendor")) do
            local bodygroups = {}

            for _, value in ipairs(entity:GetBodyGroups() or {}) do
                bodygroups[value.id] = entity:GetBodygroup(value.id)
            end

            data[#data + 1] = {
                name = entity:GetDisplayName(),
                description = entity:GetDescription(),
                pos = entity:GetPos(),
                angles = entity:GetAngles(),
                model = entity:GetModel(),
                skin = entity:GetSkin(),
                bodygroups = bodygroups,
                bubble = entity:GetNoBubble(),
                items = entity.items,
                factions = entity.factions,
                money = entity.money,
                scale = entity.scale
            }
        end

        self:SetData(data)
    end

    function MODULE:LoadData()
        for _, value in ipairs(self:GetData() or {}) do
            local entity = ents.Create("ax_vendor")

            if (!IsValid(entity)) then
                continue
            end

            entity:SetPos(value.pos)
            entity:SetAngles(value.angles)
            entity:Spawn()

            if (value.model) then
                entity:SetModel(value.model)
            end

            entity:SetSkin(value.skin or 0)
            entity:InitPhysObj()
            entity:SetNoBubble(value.bubble)
            entity:SetDisplayName(value.name or "")
            entity:SetDescription(value.description or "")

            for id, bodygroup in pairs(value.bodygroups or {}) do
                entity:SetBodygroup(tonumber(id) or id, bodygroup)
            end

            local items = {}
            for uniqueID, itemData in pairs(value.items or {}) do
                items[tostring(uniqueID)] = itemData
            end

            entity.items = items
            entity.factions = value.factions or {}
            entity.money = value.money
            entity.scale = value.scale or 0.5
        end
    end

    function MODULE:OnLoaded()
        self:LoadData()
    end

    function MODULE:CanVendorSellItem(client, vendor, itemID)
        local tradeData = vendor.items[itemID]
        local char = client:GetCharacter()

        if (!tradeData or !char or !char:HasMoney(tradeData[1] or 0)) then
            return false
        end

        return true
    end

    if (ax.log and isfunction(ax.log.AddType)) then
        ax.log.AddType("vendorUse", function(client, ...)
            local arg = {...}
            return string.format("%s used the '%s' vendor.", client:Name(), arg[1])
        end)

        ax.log.AddType("vendorBuy", function(client, ...)
            local arg = {...}
            return string.format("%s purchased a '%s' from the '%s' vendor for %s.", client:Name(), arg[1], arg[2], arg[3])
        end)

        ax.log.AddType("vendorSell", function(client, ...)
            local arg = {...}
            return string.format("%s sold a '%s' to the '%s' vendor for %s.", client:Name(), arg[1], arg[2], arg[3])
        end)
    end
end

properties.Add("vendor_edit", {
    MenuLabel = "Edit Vendor",
    Order = 999,
    MenuIcon = "icon16/user_edit.png",

    Filter = function(self, entity, client)
        if (!IsValid(entity)) then
            return false
        end

        return CAMI.PlayerHasAccess(client, "Parallax - Manage Vendors", nil)
    end,

    Action = function(self, entity)
        self:MsgStart()
            net.WriteEntity(entity)
        self:MsgEnd()
    end,

    Receive = function(self, length, client)
        local entity = net.ReadEntity()

        if (!IsValid(entity) or !self:Filter(entity, client)) then
            return
        end

        entity.receivers = entity.receivers or {}
        entity.receivers[#entity.receivers + 1] = client

        local itemsTable = {}
        for uniqueID, itemData in pairs(entity.items or {}) do
            if (!table.IsEmpty(itemData)) then
                itemsTable[tostring(uniqueID)] = itemData
            end
        end

        client.axVendor = entity

        net.Start("axVendorEditor")
            net.WriteEntity(entity)
            local hasMoney = entity.money != nil
            net.WriteBool(hasMoney)

            if (hasMoney) then
                net.WriteUInt(math.Clamp(tonumber(entity.money) or 0, 0, 65535), 16)
            end

            net.WriteTable(itemsTable)
            net.WriteFloat(entity.scale or 0.5)
            net.WriteTable(entity.messages or {})
            net.WriteTable(entity.factions or {})
        net.Send(client)
    end
})
