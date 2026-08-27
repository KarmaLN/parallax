local PANEL = {}

function PANEL:Init()
    local user = LocalPlayer()
    local char = user:GetCharacter()
    if not char then return end

    self:SetSize(ScrW() * 0.4, ScrH() * 0.8)
    self:Center()
    self:MakePopup()
    self:SetTitle("Persistence")
    self:SetDraggable(false)
    self:SetSizable(false)
    self:ShowCloseButton(true)

    -- Search bar
    self.searchBar = self:Add("ax.text.entry")
    self.searchBar:Dock(TOP)
    self.searchBar:SetPlaceholderText("Search props...")

    -- Scroll list
    self.scroll = self:Add("ax.scroller.vertical")
    self.scroll:Dock(FILL)
    self.scroll:DockMargin(0, 15, 0, 15)

    self.entries = {}
    
    self.currentPage = 1
    self.perPage = 50
    self.filteredList = {}

    -- Bottom bar
    self.footer = self:Add("EditablePanel")
    self.footer:Dock(BOTTOM)
    self.footer:SetTall(40)

    self.prevBtn = self.footer:Add("ax.button")
    self.prevBtn:Dock(LEFT)
    self.prevBtn:SetText("Previous")
    
    self.nextBtn = self.footer:Add("ax.button")
    self.nextBtn:Dock(RIGHT)
    self.nextBtn:SetText("Next")

    self.pageLabel = self.footer:Add("ax.text")
    self.pageLabel:Dock(FILL)
    self.pageLabel:SetContentAlignment(5)
end

function PANEL:Populate(propList)
    if not istable(propList) then return end

    self.propList = propList

    self.searchBar.OnChange = function(entry)
        self.currentPage = 1
        self:RefreshList(entry:GetValue())
    end

    self.prevBtn.DoClick = function()
        if self.currentPage > 1 then
            self.currentPage = self.currentPage - 1
            self:RenderPage()
        end
    end

    self.nextBtn.DoClick = function()
        local maxPages = math.ceil(#self.filteredList / self.perPage)
        if self.currentPage < maxPages then
            self.currentPage = self.currentPage + 1
            self:RenderPage()
        end
    end

    self:RefreshList()
    
    self:SetTitle("Persistence" .. " | Total: " .. #propList)
end

function PANEL:RefreshList(filter)
    filter = string.lower(filter or "")
    self.filteredList = {}

    for _, data in ipairs(self.propList) do
        local name = string.lower(data.model or "")

        if filter == "" or string.find(name, filter, 1, true) then
            self.filteredList[#self.filteredList + 1] = data
        end
    end

    self.currentPage = 1
    self:RenderPage()
end

function PANEL:RenderPage()
    self.scroll:Clear()
    self.entries = {}

    local startIndex = (self.currentPage - 1) * self.perPage + 1
    local endIndex = math.min(startIndex + self.perPage - 1, #self.filteredList)

    for i = startIndex, endIndex do
        local data = self.filteredList[i]
        if not data then continue end

        local prop = self.scroll:Add("ax.button")
        prop:Dock(TOP)
        prop:SetTall(120)
        prop:DockMargin(0, 0, 0, 8)
        prop:SetText((data.class or "unknown") .. " | " .. (data.model or "unknown"))

        -- Model preview
        local modelPanel = prop:Add("SpawnIcon")
        modelPanel:Dock(LEFT)
        modelPanel:SetWide(100)
        modelPanel:SetVisible(false)

        timer.Simple(0, function()
            if IsValid(modelPanel) then
                modelPanel:SetModel(data.model or "models/error.mdl")
                modelPanel:SetVisible(true)
            end
        end)

        -- Menu
        prop.DoClick = function(self)
            local menu = vgui.Create("ax.dmenu")

            menu:AddOption("Remove", function()
                ax.net:Start("ax.persistence.remove", data.id)
                self:Remove()
            end)

            menu:AddOption("Teleport to", function()
                ax.net:Start("ax.persistence.teleport", data.id)
            end)

            menu:AddOption("Highlight", function()
                ax.net:Start("ax.persistence.highlight", data.id)
            end)

            menu:AddOption("Respawn", function()
                ax.net:Start("ax.persistence.respawn", data.id)
            end)

            menu:Open()
        end

        self.entries[#self.entries + 1] = prop
    end

    -- Page info
    local maxPages = math.max(1, math.ceil(#self.filteredList / self.perPage))
    self.pageLabel:SetText("Page " .. self.currentPage .. " / " .. maxPages)
end

vgui.Register("axMenuPersistence", PANEL, "ax.frame")