-- Core: estado de descubrimientos, persistencia en ModData del personaje.
-- Cada personaje tiene su propio registro. Se guarda junto a la partida.

Changadex = Changadex or {}
Changadex.MODDATA_KEY = "Changadex"
Changadex.VERSION = 1

-- Devuelve la tabla de estado del jugador (creandola si no existe).
-- Estructura:
--   { version = N, found = { ["Base.Pistol"] = { t = 12345, how = "pickup" }, ... } }
function Changadex.getState(player)
    player = player or getPlayer()
    if not player then return nil end
    local md = player:getModData()
    local st = md[Changadex.MODDATA_KEY]
    if not st or type(st) ~= "table" then
        st = { version = Changadex.VERSION, found = {} }
        md[Changadex.MODDATA_KEY] = st
    end
    if not st.found then st.found = {} end
    st.version = Changadex.VERSION
    return st
end

function Changadex.isDiscovered(fullType, player)
    local st = Changadex.getState(player)
    if not st then return false end
    return st.found[fullType] ~= nil
end

-- Items que solo se descubren al consumirlos (libros/revistas al leer,
-- VHS/CDs al insertarlos en un aparato). No cuentan por pickup.
function Changadex.requiresConsumption(fullType)
    local scriptItem = getScriptManager():FindItem(fullType)
    if not scriptItem then return false end
    if scriptItem:isItemType(ItemType.LITERATURE) then return true end
    if scriptItem.getRecordedMediaCat and scriptItem:getRecordedMediaCat() then return true end
    return false
end

-- Devuelve un nombre especifico a mostrar para este InventoryItem.
-- Para revistas/periodicos, saca el titulo del modData (ej. "Sprinter: Dic 1983")
-- en lugar del generico "Magazine".
local function getSpecificName(inventoryItem)
    if not inventoryItem then return nil end
    if inventoryItem.getModData then
        local md = inventoryItem:getModData()
        if md then
            if md.literatureTitle then return md.literatureTitle end
            if md.printMedia and md.printMedia.title then
                local translated = getText(md.printMedia.title)
                if translated and translated ~= md.printMedia.title then
                    return translated
                end
                return md.printMedia.title
            end
        end
    end
    if inventoryItem.getName then
        local n = inventoryItem:getName()
        if n and n ~= "" then return n end
    end
    return nil
end
Changadex.getSpecificName = getSpecificName

-- Marca un item como descubierto.
-- how = "pickup" | "equip" | "read" | "wear" | "eat" | "watch" | "listen".
-- inventoryItem (opcional): la instancia en el mundo, para capturar titulo especifico.
-- Devuelve true si es la primera vez (para disparar notificacion).
function Changadex.discover(fullType, how, player, inventoryItem)
    if not fullType or fullType == "" then return false end
    local st = Changadex.getState(player)
    if not st then return false end

    local specificName = getSpecificName(inventoryItem)

    -- Literatura: key por titulo especifico (si lo hay) en lugar de por fullType,
    -- asi cada revista/periodico cuenta como entrada separada en el grid.
    if specificName and Changadex.requiresConsumption(fullType) then
        if st.titles and st.titles[specificName] then return false end
        st.titles = st.titles or {}
        st.titles[specificName] = {
            t = getTimestampMs and getTimestampMs() or 0,
            how = how or "pickup",
            fullType = fullType,
            name = specificName,
        }
        Changadex.onDiscover(fullType, how, player, specificName)
        return true
    end

    if st.found[fullType] then return false end

    -- Libros/VHS/CD genericos (sin titulo especifico): solo al consumirlos.
    if how == "pickup" and Changadex.requiresConsumption(fullType) then
        return false
    end

    st.found[fullType] = {
        t = getTimestampMs and getTimestampMs() or 0,
        how = how or "pickup",
        name = specificName,
    }
    Changadex.onDiscover(fullType, how, player, specificName)
    return true
end

-- Mapeo how -> clave de traduccion del verbo.
local HOW_LABEL_KEY = {
    pickup = "UI_Changadex_VerbFound",
    equip  = "UI_Changadex_VerbEquipped",
    wear   = "UI_Changadex_VerbWorn",
    read   = "UI_Changadex_VerbRead",
    eat    = "UI_Changadex_VerbEaten",
    drink  = "UI_Changadex_VerbEaten",
    watch  = "UI_Changadex_VerbWatched",
    listen = "UI_Changadex_VerbListened",
}

-- Hook de notificacion. Muestra un halo text sobre el personaje.
function Changadex.onDiscover(fullType, how, player, specificName)
    player = player or getPlayer()
    if not player then return end
    local scriptItem = getScriptManager():FindItem(fullType)
    local displayName = specificName or (scriptItem and scriptItem:getDisplayName()) or fullType

    local verbKey = HOW_LABEL_KEY[how] or HOW_LABEL_KEY.pickup
    local verb = Changadex.text(verbKey)
    local title = Changadex.text("UI_Changadex_DiscoveryTitle")
    local line = verb .. ": " .. displayName

    -- addTextWithArrow necesita un tipo especifico (no ColorInfo). Probamos
    -- con Color.new; si el juego no lo acepta, caemos a getGoodColor (verde).
    if not HaloTextHelper then return end
    local ok = false
    if HaloTextHelper.addTextWithArrow then
        local candidates = {}
        if Color and Color.new then
            table.insert(candidates, Color.new(0.35, 0.75, 1.0, 1.0))
        end
        table.insert(candidates, HaloTextHelper.getGoodColor())
        for _, c in ipairs(candidates) do
            ok = pcall(HaloTextHelper.addTextWithArrow, player, line, title, true, c)
            if ok then break end
        end
    end
    if not ok and HaloTextHelper.addGoodText then
        pcall(HaloTextHelper.addGoodText, player, line)
    end
end

-- Borra el registro (debug / reset).
function Changadex.reset(player)
    local st = Changadex.getState(player)
    if st then st.found = {} end
end
