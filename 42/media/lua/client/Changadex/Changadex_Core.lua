-- Core: estado de descubrimientos, persistencia en ModData del personaje.
-- Cada personaje tiene su propio registro. Se guarda junto a la partida.

Changadex = Changadex or {}
Changadex.MODDATA_KEY = "Changadex"
Changadex.VERSION = 2

-- Devuelve la tabla de estado del jugador (creandola si no existe).
-- Estructura:
--   { version = N, found = { ["Base.Pistol"] = { t = 12345 }, ... } }
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
    -- Migracion desde v1: descarta el subtable `titles` y cualquier campo
    -- `how` / `name` por fullType (no hay forma de descubrir por accion).
    if st.version ~= Changadex.VERSION then
        st.titles = nil
        for k, v in pairs(st.found) do
            if type(v) == "table" then
                st.found[k] = { t = v.t or 0 }
            end
        end
        st.version = Changadex.VERSION
    end
    return st
end

function Changadex.isDiscovered(fullType, player)
    local st = Changadex.getState(player)
    if not st then return false end
    return st.found[fullType] ~= nil
end

-- Halo text sobre la cabeza del personaje cuando descubris algo nuevo.
-- addTextWithArrow pide un Color (0-1), no un ColorInfo. Si falla caemos
-- a addGoodText para que un bug de binding no rompa la accion que disparo
-- el descubrimiento.
function Changadex.notifyDiscovery(fullType, player)
    player = player or getPlayer()
    if not player or not HaloTextHelper then return end
    local scriptItem = getScriptManager():FindItem(fullType)
    local displayName = (scriptItem and scriptItem:getDisplayName()) or fullType
    local title = Changadex.text("UI_Changadex_DiscoveryTitle")

    local ok = false
    if HaloTextHelper.addTextWithArrow then
        local candidates = {}
        if Color and Color.new then
            table.insert(candidates, Color.new(0.35, 0.75, 1.0, 1.0))
        end
        table.insert(candidates, HaloTextHelper.getGoodColor())
        for _, c in ipairs(candidates) do
            ok = pcall(HaloTextHelper.addTextWithArrow, player, displayName, title, true, c)
            if ok then break end
        end
    end
    if not ok and HaloTextHelper.addGoodText then
        pcall(HaloTextHelper.addGoodText, player, displayName)
    end
end

-- Marca un item como descubierto. Devuelve true si es la primera vez.
-- `silent` = true evita la notificacion (usado en el escaneo inicial).
function Changadex.discover(fullType, player, silent)
    if not fullType or fullType == "" then return false end
    local st = Changadex.getState(player)
    if not st then return false end
    if st.found[fullType] then return false end
    st.found[fullType] = {
        t = getTimestampMs and getTimestampMs() or 0,
    }
    if not silent then
        Changadex.notifyDiscovery(fullType, player)
    end
    return true
end

-- Borra el registro (debug / reset).
function Changadex.reset(player)
    local st = Changadex.getState(player)
    if st then st.found = {} end
end
