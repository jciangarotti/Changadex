-- UI del Changadex: ventana con sidebar de categorias + grilla de items.
-- Items descubiertos salen con su icono e imagen; los no descubiertos aparecen
-- como silueta gris con "???" en lugar del nombre.

require "ISUI/ISCollapsableWindow"
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"

Changadex = Changadex or {}

local FONT_SMALL = UIFont.Small
local FONT_MED = UIFont.Medium
local FH_SMALL = getTextManager():getFontHeight(FONT_SMALL)
local FH_MED = getTextManager():getFontHeight(FONT_MED)
local PAD = 8

-------------------------------------------------
-- Categorias (sidebar izquierdo)
-------------------------------------------------
ChangadexCategoryList = ISScrollingListBox:derive("ChangadexCategoryList")

-- Reserva espacio a la derecha para que el scrollbar del ISScrollingListBox
-- no tape el contador "X/Y".
local SCROLLBAR_PAD = 18

function ChangadexCategoryList:doDrawItem(y, item, alt)
    local a = 0.9
    local w = self:getWidth() - SCROLLBAR_PAD
    if self.selected == item.index then
        self:drawRect(0, y, w, item.height - 1, 0.3, 0.7, 0.35, 0.15)
    end
    self:drawRectBorder(0, y, w, item.height, 0.5, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    local catKey = item.item
    local label = Changadex.getCategoryLabel(catKey)
    local found, total = Changadex.getProgressForCategory(catKey)
    local pct = total > 0 and (found / total) or 0

    self:drawText(label, 6, y + 4, 1, 1, 1, a, FONT_SMALL)

    local countText = string.format("%d/%d", found, total)
    local tw = getTextManager():MeasureStringX(FONT_SMALL, countText)
    self:drawText(countText, w - tw - 6, y + 4, 0.8, 0.9, 0.8, a, FONT_SMALL)

    -- Barrita de progreso
    local barX = 6
    local barY = y + item.height - 6
    local barW = w - 12
    self:drawRect(barX, barY, barW, 3, 0.6, 0.15, 0.15, 0.15)
    if pct > 0 then
        local r, g, b = 0.25, 0.75, 0.35
        if pct >= 1 then r, g, b = 1, 0.85, 0.2 end
        self:drawRect(barX, barY, math.floor(barW * pct), 3, 1, r, g, b)
    end

    return y + item.height
end

-------------------------------------------------
-- Grilla de items (panel derecho)
-------------------------------------------------
ChangadexItemGrid = ISPanel:derive("ChangadexItemGrid")

function ChangadexItemGrid:new(x, y, w, h)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.6 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.items = {}
    o.scroll = 0
    o.cellW = 180
    o.cellH = 54
    o.iconSize = 40
    o.filterMode = "found" -- "all" | "found" | "missing" — default: solo descubiertos
    o.search = ""
    o.hoverIndex = -1
    return o
end

function ChangadexItemGrid:setCategory(catKey)
    self.category = catKey
    self.scroll = 0
    self:rebuild()
end

function ChangadexItemGrid:setFilter(mode)
    self.filterMode = mode
    self.scroll = 0
    self:rebuild()
end

function ChangadexItemGrid:setSearch(text)
    self.search = string.lower(text or "")
    self.scroll = 0
    self:rebuild()
end

function ChangadexItemGrid:rebuild()
    self.items = {}
    if not self.category then return end
    local catalog = Changadex.buildCatalog()
    local list = catalog.byCategory[self.category] or {}
    local st = Changadex.getState()

    -- Script items "normales" (no literatura con titulo propio)
    for _, scriptItem in ipairs(list) do
        local fullType = scriptItem:getFullName()
        local rec = st and st.found[fullType]
        local found = rec ~= nil
        local include = true
        if self.filterMode == "found" and not found then include = false end
        if self.filterMode == "missing" and found then include = false end
        local displayName = (rec and rec.name) or scriptItem:getDisplayName() or fullType
        if include and self.search ~= "" then
            if not string.find(string.lower(displayName), self.search, 1, true) then include = false end
        end
        if include then
            table.insert(self.items, {
                scriptItem = scriptItem,
                fullType = fullType,
                found = found,
                name = displayName,
                rec = rec,
            })
        end
    end

    -- Entradas por titulo especifico (revistas, periodicos, print media).
    -- Cada titulo descubierto es una fila propia, asi se distingue de los demas.
    if self.category == "Literature" and st and st.titles then
        for title, rec in pairs(st.titles) do
            local include = (self.filterMode ~= "missing")
            if include and self.search ~= "" then
                if not string.find(string.lower(title), self.search, 1, true) then include = false end
            end
            if include then
                local scriptItem = getScriptManager():FindItem(rec.fullType)
                table.insert(self.items, {
                    scriptItem = scriptItem,
                    fullType = rec.fullType,
                    found = true,
                    name = title,
                    rec = rec,
                })
            end
        end
    end

    -- Orden alfabetico por nombre mostrado.
    table.sort(self.items, function(a, b)
        return string.lower(a.name or "") < string.lower(b.name or "")
    end)
end

function ChangadexItemGrid:cellsPerRow()
    return math.max(1, math.floor(self.width / self.cellW))
end

function ChangadexItemGrid:totalRows()
    return math.ceil(#self.items / self:cellsPerRow())
end

function ChangadexItemGrid:maxScroll()
    local rows = self:totalRows()
    local visibleRows = math.floor(self.height / self.cellH)
    return math.max(0, rows - visibleRows) * self.cellH
end

function ChangadexItemGrid:onMouseWheel(del)
    self.scroll = self.scroll + del * 30
    if self.scroll < 0 then self.scroll = 0 end
    local ms = self:maxScroll()
    if self.scroll > ms then self.scroll = ms end
    return true
end

function ChangadexItemGrid:prerender()
    ISPanel.prerender(self)
    self:setStencilRect(0, 0, self.width, self.height)
end

function ChangadexItemGrid:render()
    local perRow = self:cellsPerRow()
    local mouseX, mouseY = self:getMouseX(), self:getMouseY()
    self.hoverIndex = -1

    for i, entry in ipairs(self.items) do
        local idx = i - 1
        local col = idx % perRow
        local row = math.floor(idx / perRow)
        local x = col * self.cellW
        local y = row * self.cellH - self.scroll
        if y + self.cellH >= 0 and y <= self.height then
            local hovered = (mouseX >= x and mouseX < x + self.cellW and mouseY >= y and mouseY < y + self.cellH)
            if hovered then self.hoverIndex = i end
            self:drawCell(entry, x, y, hovered)
        end
    end

    self:clearStencilRect()

    -- Scrollbar simple
    local ms = self:maxScroll()
    if ms > 0 then
        local trackX = self.width - 4
        local trackY = 0
        local trackH = self.height
        self:drawRect(trackX, trackY, 3, trackH, 0.4, 0.2, 0.2, 0.2)
        local thumbH = math.max(20, trackH * (trackH / (trackH + ms)))
        local thumbY = (self.scroll / ms) * (trackH - thumbH)
        self:drawRect(trackX, thumbY, 3, thumbH, 0.9, 0.7, 0.7, 0.7)
    end
end

function ChangadexItemGrid:drawCell(entry, x, y, hovered)
    local pad = 4
    local iconX = x + pad
    local iconY = y + (self.cellH - self.iconSize) / 2

    if hovered then
        self:drawRect(x + 1, y + 1, self.cellW - 2, self.cellH - 2, 0.25, 1, 1, 1)
    end
    self:drawRectBorder(x, y, self.cellW, self.cellH, 0.3, 0.5, 0.5, 0.5)

    -- Icono
    local scriptItem = entry.scriptItem
    local texture = nil
    local iconName = scriptItem:getIcon()
    if scriptItem:getIconsForTexture() and not scriptItem:getIconsForTexture():isEmpty() then
        iconName = scriptItem:getIconsForTexture():get(0)
    end
    if iconName then
        texture = tryGetTexture("Item_" .. iconName)
    end

    if entry.found then
        if texture then
            self:drawTextureScaledAspect2(texture, iconX, iconY, self.iconSize, self.iconSize, 1, 1, 1, 1)
        end
        local name = entry.name or (scriptItem and scriptItem:getDisplayName()) or entry.fullType
        self:drawText(name, iconX + self.iconSize + pad, y + pad, 1, 1, 1, 1, FONT_SMALL)
        local rec = entry.rec
        if rec then
            local howKeys = {
                pickup = "UI_Changadex_VerbFound",
                equip  = "UI_Changadex_VerbEquipped",
                wear   = "UI_Changadex_VerbWorn",
                read   = "UI_Changadex_VerbRead",
                eat    = "UI_Changadex_VerbEaten",
                drink  = "UI_Changadex_VerbEaten",
                watch  = "UI_Changadex_VerbWatched",
                listen = "UI_Changadex_VerbListened",
            }
            local howText = Changadex.text(howKeys[rec.how] or "UI_Changadex_VerbFound")
            self:drawText(howText, iconX + self.iconSize + pad, y + pad + FH_SMALL + 2, 0.6, 0.85, 0.6, 1, FONT_SMALL)
        end
    else
        -- Silueta: dibuja el mismo icono pero tintado negro/gris.
        if texture then
            self:drawTextureScaledAspect2(texture, iconX, iconY, self.iconSize, self.iconSize, 0.85, 0.05, 0.05, 0.05)
        else
            self:drawRect(iconX, iconY, self.iconSize, self.iconSize, 0.8, 0.1, 0.1, 0.1)
        end
        self:drawText(Changadex.text("UI_Changadex_Unknown"), iconX + self.iconSize + pad, y + pad, 0.7, 0.7, 0.7, 1, FONT_SMALL)
    end
end

-------------------------------------------------
-- Ventana principal
-------------------------------------------------
ChangadexWindow = ISCollapsableWindow:derive("ChangadexWindow")
ChangadexWindow.instance = nil

function ChangadexWindow:new(x, y, w, h)
    local o = ISCollapsableWindow:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.title = Changadex.text("UI_Changadex_Title")
    o.resizable = true
    o.minimumWidth = 640
    o.minimumHeight = 420
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.85 }
    return o
end

function ChangadexWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local th = self:titleBarHeight()
    local topY = th + PAD
    local headerH = FH_MED + 6

    -- Barra superior: progreso global + filtros
    self.searchEntry = ISTextEntryBox:new("", PAD, topY, 200, FH_SMALL + 8)
    self.searchEntry:initialise()
    self.searchEntry:instantiate()
    self.searchEntry:setText("")
    self.searchEntry.onCommandEntered = function() end
    self:addChild(self.searchEntry)

    local btnW = 130
    local btnH = FH_SMALL + 8
    -- Orden: descubiertos (default) | todos | faltantes
    self.btnFound = ISButton:new(self.searchEntry:getRight() + PAD, topY, btnW, btnH, Changadex.text("UI_Changadex_ShowOnlyFound"), self, ChangadexWindow.onFilter)
    self.btnFound.internal = "found"
    self.btnFound:initialise()
    self:addChild(self.btnFound)

    self.btnAll = ISButton:new(self.btnFound:getRight() + 4, topY, btnW, btnH, Changadex.text("UI_Changadex_ShowAll"), self, ChangadexWindow.onFilter)
    self.btnAll.internal = "all"
    self.btnAll:initialise()
    self:addChild(self.btnAll)

    self.btnMissing = ISButton:new(self.btnAll:getRight() + 4, topY, btnW, btnH, Changadex.text("UI_Changadex_ShowOnlyMissing"), self, ChangadexWindow.onFilter)
    self.btnMissing.internal = "missing"
    self.btnMissing:initialise()
    self:addChild(self.btnMissing)

    local bodyY = self.searchEntry:getBottom() + PAD + headerH
    local bodyH = self.height - bodyY - PAD - 4
    local sidebarW = 220

    -- Lista de categorias
    self.catList = ChangadexCategoryList:new(PAD, bodyY, sidebarW, bodyH)
    self.catList:initialise()
    self.catList:instantiate()
    self.catList.itemheight = 32
    self.catList.drawBorder = true
    self.catList:setOnMouseDownFunction(self, function(target, catKey)
        target:onSelectCategory(catKey)
    end)
    self:addChild(self.catList)

    -- Grilla
    local gridX = self.catList:getRight() + PAD
    self.grid = ChangadexItemGrid:new(gridX, bodyY, self.width - gridX - PAD, bodyH)
    self.grid:initialise()
    self:addChild(self.grid)

    self:populateCategories()
    self:updateFilterButtonStyles()
end

function ChangadexWindow:populateCategories()
    local catalog = Changadex.buildCatalog()
    self.catList:clear()
    for _, catKey in ipairs(catalog.categories) do
        self.catList:addItem(Changadex.getCategoryLabel(catKey), catKey)
    end
    if #catalog.categories > 0 then
        self.catList.selected = 1
        self:onSelectCategory(catalog.categories[1])
    end
end

function ChangadexWindow:onSelectCategory(catKey)
    self.selectedCategory = catKey
    self.grid:setCategory(catKey)
end

function ChangadexWindow:onFilter(button)
    if button and button.internal then
        self.grid:setFilter(button.internal)
        self:updateFilterButtonStyles()
    end
end

function ChangadexWindow:updateFilterButtonStyles()
    local active = { r = 0.25, g = 0.55, b = 0.25, a = 1 }
    local inactive = { r = 0.2, g = 0.2, b = 0.2, a = 1 }
    local buttons = { self.btnFound, self.btnAll, self.btnMissing }
    for _, btn in ipairs(buttons) do
        local isActive = (btn.internal == self.grid.filterMode)
        local c = isActive and active or inactive
        btn.backgroundColor = { r = c.r, g = c.g, b = c.b, a = c.a }
    end
end

function ChangadexWindow:prerender()
    ISCollapsableWindow.prerender(self)

    -- Sync search entry -> grid (poor-man tick, sin eventos)
    if self.searchEntry then
        local t = self.searchEntry:getText() or ""
        if t ~= (self.grid.search_display or "") then
            self.grid.search_display = t
            self.grid:setSearch(t)
        end
    end

    -- Header de progreso global
    local th = self:titleBarHeight()
    local headerY = (self.searchEntry and self.searchEntry:getBottom() or (th + PAD)) + PAD
    local found, total = Changadex.getOverallProgress()
    local pct = total > 0 and (found / total) or 0
    local label = string.format("%s: %d / %d  (%d%%)", Changadex.text("UI_Changadex_Progress"), found, total, math.floor(pct * 100 + 0.5))

    local barX = PAD
    local barW = self.width - PAD * 2
    local barH = FH_MED + 4
    self:drawRect(barX, headerY, barW, barH, 0.7, 0.1, 0.1, 0.1)
    if pct > 0 then
        local r, g, b = 0.25, 0.75, 0.35
        if pct >= 1 then r, g, b = 1, 0.85, 0.2 end
        self:drawRect(barX, headerY, math.floor(barW * pct), barH, 0.8, r, g, b)
    end
    self:drawRectBorder(barX, headerY, barW, barH, 0.9, 0.6, 0.6, 0.6)
    self:drawText(label, barX + 8, headerY + 2, 1, 1, 1, 1, FONT_MED)
end

function ChangadexWindow:onResize()
    ISCollapsableWindow.onResize(self)
    if self.catList and self.grid and self.searchEntry then
        local th = self:titleBarHeight()
        local bodyY = self.searchEntry:getBottom() + PAD + FH_MED + 6
        local bodyH = self.height - bodyY - PAD - 4
        self.catList:setY(bodyY); self.catList:setHeight(bodyH)
        self.grid:setY(bodyY); self.grid:setHeight(bodyH)
        self.grid:setWidth(self.width - self.grid.x - PAD)
    end
end

function ChangadexWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    ChangadexWindow.instance = nil
end

function Changadex.toggleUI()
    if ChangadexWindow.instance then
        ChangadexWindow.instance:close()
        return
    end
    local w, h = 900, 560
    local x = (getCore():getScreenWidth() - w) / 2
    local y = (getCore():getScreenHeight() - h) / 2
    local win = ChangadexWindow:new(x, y, w, h)
    win:initialise()
    win:addToUIManager()
    ChangadexWindow.instance = win
end
