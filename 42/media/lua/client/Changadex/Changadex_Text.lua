-- Wrapper de getText con fallback: si la traduccion no esta cargada,
-- devuelve un texto hardcodeado en vez del key crudo. Asi la UI nunca
-- muestra "UI_Changadex_Title" aunque el JSON no cargue.
--
-- Ademas detecta el idioma del juego (via getCore():getOptionLanguage())
-- para elegir entre ES/EN en el fallback.

Changadex = Changadex or {}

local DEFAULTS_EN = {
    UI_Changadex_Title           = "Changadex",
    UI_Changadex_Open            = "Open Changadex",
    UI_Changadex_Progress        = "Progress",
    UI_Changadex_Unknown         = "???",
    UI_Changadex_Found           = "Discovered",
    UI_Changadex_NotFound        = "Undiscovered",
    UI_Changadex_All             = "All",
    UI_Changadex_ShowOnlyFound   = "Only discovered",
    UI_Changadex_ShowOnlyMissing = "Only missing",
    UI_Changadex_ShowAll         = "Show all",
    UI_Changadex_Search          = "Search...",
    UI_Changadex_CtxDiscover     = "Discover",
    UI_Changadex_CtxViewInfo     = "View info",
    UI_Changadex_InfoTitle       = "Item info",
    UI_Changadex_InfoClose       = "Close",
    UI_Changadex_DiscoveryTitle  = "New for Changadex",
    UI_Changadex_TooltipLabel    = "Discovered:",
    UI_Changadex_Yes             = "Yes",
    UI_Changadex_No              = "No",
    UI_Changadex_Desc_Weapon       = "A weapon. Useful for defending yourself from zombies.",
    UI_Changadex_Desc_Ammo         = "Ammunition for a ranged weapon.",
    UI_Changadex_Desc_Firearm      = "A firearm.",
    UI_Changadex_Desc_RangedWeapons= "A ranged weapon.",
    UI_Changadex_Desc_Food         = "Something edible. Eating keeps hunger away.",
    UI_Changadex_Desc_Water        = "Something drinkable.",
    UI_Changadex_Desc_Medical      = "Medical supplies for treating wounds or illness.",
    UI_Changadex_Desc_FirstAid     = "First aid supplies.",
    UI_Changadex_Desc_Clothing     = "A garment. Protects from cold and zombie bites.",
    UI_Changadex_Desc_Accessory    = "An accessory you can wear.",
    UI_Changadex_Desc_Jewelry      = "Jewelry. Not very useful in a zombie apocalypse.",
    UI_Changadex_Desc_Literature   = "Reading material. Can teach you things.",
    UI_Changadex_Desc_SkillBook    = "A skill book to level up.",
    UI_Changadex_Desc_Recipe       = "A cooking recipe.",
    UI_Changadex_Desc_Map          = "A map of an area.",
    UI_Changadex_Desc_Tool         = "A useful tool.",
    UI_Changadex_Desc_Material     = "A building or crafting material.",
    UI_Changadex_Desc_Container    = "A container for storing things.",
    UI_Changadex_Desc_Electronics  = "An electronic device.",
    UI_Changadex_Desc_Appliance    = "A household appliance.",
    UI_Changadex_Desc_Entertainment= "Something to pass the time.",
    UI_Changadex_Desc_Junk         = "Junk. Barely useful.",
    UI_Changadex_Desc_Trapping     = "Trapping equipment.",
    UI_Changadex_Desc_Gardening    = "Gardening-related.",
    UI_Changadex_Desc_Fishing      = "Fishing equipment.",
    UI_Changadex_Desc_Animal       = "An animal.",
    UI_Changadex_Desc_Other        = "An object.",
}

local DEFAULTS_ES = {
    UI_Changadex_Title           = "Changadex",
    UI_Changadex_Open            = "Abrir Changadex",
    UI_Changadex_Progress        = "Progreso",
    UI_Changadex_Unknown         = "???",
    UI_Changadex_Found           = "Descubierto",
    UI_Changadex_NotFound        = "No descubierto",
    UI_Changadex_All             = "Todo",
    UI_Changadex_ShowOnlyFound   = "Solo descubiertos",
    UI_Changadex_ShowOnlyMissing = "Solo faltantes",
    UI_Changadex_ShowAll         = "Mostrar todo",
    UI_Changadex_Search          = "Buscar...",
    UI_Changadex_CtxDiscover     = "Descubrir",
    UI_Changadex_CtxViewInfo     = "Ver informacion",
    UI_Changadex_InfoTitle       = "Informacion del item",
    UI_Changadex_InfoClose       = "Cerrar",
    UI_Changadex_DiscoveryTitle  = "Nuevo en Changadex",
    UI_Changadex_TooltipLabel    = "Descubierto:",
    UI_Changadex_Yes             = "Si",
    UI_Changadex_No              = "No",
    UI_Changadex_Desc_Weapon       = "Un arma. Util para defenderte de los zombis.",
    UI_Changadex_Desc_Ammo         = "Municion para un arma a distancia.",
    UI_Changadex_Desc_Firearm      = "Un arma de fuego.",
    UI_Changadex_Desc_RangedWeapons= "Un arma a distancia.",
    UI_Changadex_Desc_Food         = "Algo comestible. Comer te mantiene con hambre a raya.",
    UI_Changadex_Desc_Water        = "Algo que se puede beber.",
    UI_Changadex_Desc_Medical      = "Equipo medico para curar heridas o enfermedades.",
    UI_Changadex_Desc_FirstAid     = "Equipo de primeros auxilios.",
    UI_Changadex_Desc_Clothing     = "Una prenda. Te protege del frio y de las mordidas de zombis.",
    UI_Changadex_Desc_Accessory    = "Un accesorio para llevar encima.",
    UI_Changadex_Desc_Jewelry      = "Joyeria. Poco util en un apocalipsis zombi.",
    UI_Changadex_Desc_Literature   = "Material de lectura. Puede ensenarte cosas.",
    UI_Changadex_Desc_SkillBook    = "Un libro de habilidades para subir de nivel.",
    UI_Changadex_Desc_Recipe       = "Una receta de cocina.",
    UI_Changadex_Desc_Map          = "Un mapa de una zona.",
    UI_Changadex_Desc_Tool         = "Una herramienta util.",
    UI_Changadex_Desc_Material     = "Un material de construccion o artesania.",
    UI_Changadex_Desc_Container    = "Un recipiente para guardar cosas.",
    UI_Changadex_Desc_Electronics  = "Un dispositivo electronico.",
    UI_Changadex_Desc_Appliance    = "Un electrodomestico.",
    UI_Changadex_Desc_Entertainment= "Algo de entretenimiento para pasar el rato.",
    UI_Changadex_Desc_Junk         = "Basura. Sirve de poco.",
    UI_Changadex_Desc_Trapping     = "Equipo de trampas.",
    UI_Changadex_Desc_Gardening    = "Algo relacionado con la jardineria.",
    UI_Changadex_Desc_Fishing      = "Equipo de pesca.",
    UI_Changadex_Desc_Animal       = "Un animal.",
    UI_Changadex_Desc_Other        = "Un objeto.",
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
