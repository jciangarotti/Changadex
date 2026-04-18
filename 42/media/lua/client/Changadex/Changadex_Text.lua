-- Wrapper de getText con fallback: si la traduccion no esta cargada,
-- devuelve un texto hardcodeado en vez del key crudo. Asi la UI nunca
-- muestra "UI_Changadex_Title" aunque el JSON no cargue.
--
-- Ademas detecta el idioma del juego (via getCore():getOptionLanguage())
-- para elegir entre ES/EN en el fallback.

Changadex = Changadex or {}

local DEFAULTS_EN = {
    UI_Changadex_Title         = "Changadex",
    UI_Changadex_Open          = "Open Changadex",
    UI_Changadex_Progress      = "Progress",
    UI_Changadex_Unknown       = "???",
    UI_Changadex_Found         = "Discovered",
    UI_Changadex_NotFound      = "Undiscovered",
    UI_Changadex_All           = "All",
    UI_Changadex_FoundOn       = "Discovered: %1",
    UI_Changadex_ShowOnlyFound = "Only discovered",
    UI_Changadex_ShowOnlyMissing = "Only missing",
    UI_Changadex_ShowAll       = "Show all",
    UI_Changadex_Search        = "Search...",
    UI_Changadex_DiscoveryTitle = "New for Changadex",
    UI_Changadex_VerbFound     = "Found",
    UI_Changadex_VerbEquipped  = "Equipped",
    UI_Changadex_VerbWorn      = "Worn",
    UI_Changadex_VerbRead      = "Read",
    UI_Changadex_VerbEaten     = "Eaten",
    UI_Changadex_VerbWatched   = "Watched",
    UI_Changadex_VerbListened  = "Listened",
    UI_Changadex_ActionRead    = "read it",
    UI_Changadex_ActionWatch   = "watch it",
    UI_Changadex_ActionListen  = "listen to it",
    UI_Changadex_ActionEat     = "eat it",
    UI_Changadex_ActionWear    = "wear it",
    UI_Changadex_ActionEquip   = "equip it",
    UI_Changadex_CtxDone       = "%1",
    UI_Changadex_CtxPending    = "pending",
    UI_Changadex_CtxPendingAction = "missing — %1",
}

local DEFAULTS_ES = {
    UI_Changadex_Title         = "Changadex",
    UI_Changadex_Open          = "Abrir Changadex",
    UI_Changadex_Progress      = "Progreso",
    UI_Changadex_Unknown       = "???",
    UI_Changadex_Found         = "Descubierto",
    UI_Changadex_NotFound      = "No descubierto",
    UI_Changadex_All           = "Todo",
    UI_Changadex_FoundOn       = "Descubierto: %1",
    UI_Changadex_ShowOnlyFound = "Solo descubiertos",
    UI_Changadex_ShowOnlyMissing = "Solo faltantes",
    UI_Changadex_ShowAll       = "Mostrar todo",
    UI_Changadex_Search        = "Buscar...",
    UI_Changadex_DiscoveryTitle = "Nuevo en Changadex",
    UI_Changadex_VerbFound     = "Encontrado",
    UI_Changadex_VerbEquipped  = "Equipado",
    UI_Changadex_VerbWorn      = "Puesto",
    UI_Changadex_VerbRead      = "Leido",
    UI_Changadex_VerbEaten     = "Comido",
    UI_Changadex_VerbWatched   = "Visto",
    UI_Changadex_VerbListened  = "Escuchado",
    UI_Changadex_ActionRead    = "leerlo",
    UI_Changadex_ActionWatch   = "verlo",
    UI_Changadex_ActionListen  = "escucharlo",
    UI_Changadex_ActionEat     = "comerlo",
    UI_Changadex_ActionWear    = "ponertelo",
    UI_Changadex_ActionEquip   = "equiparlo",
    UI_Changadex_CtxDone       = "%1",
    UI_Changadex_CtxPending    = "pendiente",
    UI_Changadex_CtxPendingAction = "falta %1",
}

local function pickFallback()
    local lang = "EN"
    local ok, result = pcall(function() return getCore():getOptionLanguage() end)
    if ok and result then
        lang = tostring(result)
    end
    if lang == "ES" or lang == "AR" then return DEFAULTS_ES end
    return DEFAULTS_EN
end

local fallback = nil

-- getText con fallback. Admite parametros variables como getText original.
function Changadex.text(key, ...)
    local translated = getText(key, ...)
    -- Si el juego devuelve el key tal cual, uso el fallback hardcodeado.
    if translated == key then
        if not fallback then fallback = pickFallback() end
        local def = fallback[key]
        if def then
            -- Reemplazo %1, %2, ... con los argumentos dados.
            local args = {...}
            def = string.gsub(def, "%%(%d+)", function(n)
                return tostring(args[tonumber(n)] or "")
            end)
            return def
        end
    end
    return translated
end
