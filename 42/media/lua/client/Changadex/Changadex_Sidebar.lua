-- Agrega un boton "Changadex" al final de la barra lateral izquierda
-- (ISEquippedItem). Al hacer click abre/cierra la ventana principal,
-- equivalente a apretar la tecla configurada.
--
-- Triple via para garantizar que aparezca en cualquier orden de carga:
--   1) Patch de ISEquippedItem:initialise — si el panel se construye despues
--      de cargarse este archivo, el boton se agrega en la creacion.
--   2) Pasada en OnGameStart — si el panel ya existe antes.
--   3) Reintento por frame via OnPlayerUpdate hasta que quede agregado
--      (cubre sidebar size changes / split screen / corner cases).
-- Todas las vias son idempotentes: addChangadexButton hace early-return
-- si el panel ya tiene changadexBtn.

require "ISUI/ISEquippedItem"
require "ISUI/ISButton"

Changadex = Changadex or {}

local INTERNAL = "CHANGADEX"
local TEXTURE_PATH = "media/ui/Changadex_Sidebar.png"

local function loadTexture()
    local ok, tex = pcall(getTexture, TEXTURE_PATH)
    if ok and tex then return tex end
    if tryGetTexture then
        local ok2, tex2 = pcall(tryGetTexture, TEXTURE_PATH)
        if ok2 and tex2 then return tex2 end
    end
    return nil
end

-- Busca el boton mas abajo en el panel iterando todos los hijos — asi
-- no nos importan los nombres (invBtn, mapBtn, zoneBtn, etc., algunos
-- condicionales segun admin / multiplayer / debug / worldmap). Coincide
-- con el criterio que usa PZ en ISEquippedItem:shrinkWrap.
local function findAnchorButton(panel)
    if not panel or not panel.getChildren then return nil end
    local children = panel:getChildren()
    if not children then return nil end
    local anchor
    local maxBottom = -1
    for _, child in pairs(children) do
        if child and child.Type == "ISButton" and child.getBottom then
            if child.internal ~= INTERNAL then
                local b = child:getBottom()
                if b > maxBottom then
                    maxBottom = b
                    anchor = child
                end
            end
        end
    end
    return anchor
end

local function addChangadexButton(panel)
    if not panel or panel.changadexBtn then return end

    local anchor = findAnchorButton(panel)
    if not anchor then return end

    local tw = anchor:getWidth()
    local th = anchor:getHeight()
    local y = anchor:getBottom() + 5

    local btn = ISButton:new(0, y, tw, th, "", panel, ISEquippedItem.onOptionMouseDown)
    local tex = loadTexture()
    if tex then btn:setImage(tex) end
    btn.internal = INTERNAL
    btn:initialise()
    btn:instantiate()
    btn:setDisplayBackground(false)
    btn:ignoreWidthChange()
    btn:ignoreHeightChange()
    panel:addChild(btn)
    panel.changadexBtn = btn

    local tooltip = Changadex.text and Changadex.text("UI_Changadex_Open") or "Changadex"
    if panel.addMouseOverToolTipItem then
        panel:addMouseOverToolTipItem(btn, tooltip)
    end

    -- initialise termina con shrinkWrap() — volvemos a ajustar el alto del
    -- panel para que nuestro boton quede dentro del area renderizada.
    if panel.shrinkWrap then
        panel:shrinkWrap()
    else
        panel:setHeight(math.max(panel.height or 0, btn:getBottom()))
    end
end

-- Patch: intercepta :initialise para agregar el boton cuando el panel se crea.
local origInit = ISEquippedItem.initialise
function ISEquippedItem:initialise()
    origInit(self)
    addChangadexButton(self)
end

-- Patch: intercepta el click antes del handler original.
local origClick = ISEquippedItem.onOptionMouseDown
function ISEquippedItem:onOptionMouseDown(button, x, y)
    if button and button.internal == INTERNAL then
        if Changadex.toggleUI then
            Changadex.toggleUI()
        end
        return
    end
    return origClick(self, button, x, y)
end

-- Fallback: si el panel fue creado antes de aplicarse nuestro patch
-- (orden de carga), recorremos los paneles activos y agregamos el boton
-- a cada uno. Tanto OnGameStart como OnPlayerUpdate son idempotentes
-- gracias al early-return por panel.changadexBtn.
local function applyToExistingPanels()
    for i = 0, 3 do
        local pd = getPlayerData and getPlayerData(i) or nil
        if pd and pd.equipped then
            addChangadexButton(pd.equipped)
        end
    end
end

local applied = false
local function applyOnTick()
    if applied then return end
    for i = 0, 3 do
        local pd = getPlayerData and getPlayerData(i) or nil
        if pd and pd.equipped and pd.equipped.changadexBtn then
            applied = true
            return
        end
        if pd and pd.equipped then
            addChangadexButton(pd.equipped)
            applied = pd.equipped.changadexBtn ~= nil
        end
    end
end

Events.OnGameStart.Add(applyToExistingPanels)
Events.OnPlayerUpdate.Add(applyOnTick)
