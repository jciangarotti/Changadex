-- Clasificador: recorre todos los items del juego y los agrupa por categoria.
-- Se arma una sola vez por sesion (lazy) y se cachea.

Changadex = Changadex or {}

-- Claves de categoria que usamos internamente. La UI las traduce con
-- getText("IGUI_ItemCat_" .. key) si existe (son localizaciones del juego
-- base) o con el texto literal como fallback.
Changadex.CATEGORY_ORDER = {
    "Weapon", "Ammo", "Firearm", "RangedWeapons",
    "Food", "Water", "Medical", "FirstAid",
    "Clothing", "Accessory", "Jewelry",
    "Literature", "SkillBook", "Recipe", "Map",
    "Tool", "Material", "Container",
    "Electronics", "Appliance",
    "Entertainment",
    "Junk", "Trapping", "Gardening", "Fishing",
    "Animal",
    "Other",
}

-- Mapeo override: si item:getDisplayCategory() cae en algo no listado,
-- cae a "Other".
local VALID_KEY = {}
for _,k in ipairs(Changadex.CATEGORY_ORDER) do VALID_KEY[k] = true end

-- Fallback para items sin DisplayCategory: clasifica por ItemType + tags.
local function classifyFallback(scriptItem)
    if scriptItem:isItemType(ItemType.LITERATURE) then return "Literature" end
    if scriptItem:isItemType(ItemType.WEAPON) then return "Weapon" end
    if scriptItem:isItemType(ItemType.FOOD) then return "Food" end
    if scriptItem:isItemType(ItemType.CLOTHING) then return "Clothing" end
    if scriptItem:isItemType(ItemType.DRAINABLE) then return "Tool" end
    if scriptItem:isItemType(ItemType.CONTAINER) then return "Container" end
    if scriptItem:isItemType(ItemType.KEY) or scriptItem:isItemType(ItemType.KEY_RING) then return "Other" end
    if scriptItem:isItemType(ItemType.MAP) then return "Map" end
    if scriptItem:isItemType(ItemType.RADIO) then return "Electronics" end
    return "Other"
end

local function categoryFor(scriptItem)
    -- Overrides por ItemType (tienen prioridad sobre DisplayCategory):
    -- PZ etiqueta flyers/fotos como "Junk" pero son leibles, asi que
    -- los forzamos a Literature. Idem VHS/CD a Entertainment.
    if scriptItem:isItemType(ItemType.LITERATURE) then return "Literature" end
    if scriptItem.getRecordedMediaCat and scriptItem:getRecordedMediaCat() then
        return "Entertainment"
    end
    local cat = scriptItem:getDisplayCategory()
    if not cat or cat == "" or not VALID_KEY[cat] then
        cat = classifyFallback(scriptItem)
    end
    return cat
end
Changadex.getCategoryForItem = categoryFor

local function shouldInclude(scriptItem)
    if scriptItem:getObsolete() then return false end
    if scriptItem:isHidden() then return false end
    local moduleName = scriptItem:getModuleName()
    if moduleName == "Moveables" then return false end
    local name = scriptItem:getDisplayName()
    if not name or name == "" then return false end
    return true
end

-- Construye y cachea el catalogo completo.
-- Estructura:
--   Changadex.Catalog = {
--     byCategory = { [catKey] = { scriptItem1, scriptItem2, ... } },
--     categories = { catKey1, catKey2, ... },     -- ordenadas
--     itemCategory = { [fullName] = catKey },     -- lookup inverso
--     total = N,
--     totalByCategory = { [catKey] = N },
--   }
function Changadex.buildCatalog(force)
    if Changadex.Catalog and not force then return Changadex.Catalog end

    local byCategory = {}
    local totalByCategory = {}
    local itemCategory = {}
    local total = 0

    local allItems = getScriptManager():getAllItems()
    local size = allItems:size()
    for i = 0, size - 1 do
        local scriptItem = allItems:get(i)
        if shouldInclude(scriptItem) then
            local cat = categoryFor(scriptItem)
            if not byCategory[cat] then byCategory[cat] = {} end
            table.insert(byCategory[cat], scriptItem)
            itemCategory[scriptItem:getFullName()] = cat
            totalByCategory[cat] = (totalByCategory[cat] or 0) + 1
            total = total + 1
        end
    end

    -- Orden alfabetico por displayName dentro de cada categoria.
    for _, list in pairs(byCategory) do
        table.sort(list, function(a, b)
            return string.lower(a:getDisplayName()) < string.lower(b:getDisplayName())
        end)
    end

    -- Solo devolvemos las categorias que tienen al menos 1 item.
    local categories = {}
    for _, k in ipairs(Changadex.CATEGORY_ORDER) do
        if byCategory[k] and #byCategory[k] > 0 then
            table.insert(categories, k)
        end
    end
    -- Agrega categorias extra que aparecieron y no estaban en el orden base.
    for k, _ in pairs(byCategory) do
        local inList = false
        for _, ck in ipairs(categories) do
            if ck == k then inList = true; break end
        end
        if not inList then table.insert(categories, k) end
    end

    Changadex.Catalog = {
        byCategory = byCategory,
        categories = categories,
        itemCategory = itemCategory,
        total = total,
        totalByCategory = totalByCategory,
    }
    return Changadex.Catalog
end

-- Texto localizado de una categoria.
function Changadex.getCategoryLabel(catKey)
    local key = "IGUI_ItemCat_" .. catKey
    local tr = getText(key)
    if tr and tr ~= key then return tr end
    return catKey
end

-- Descripcion de flavor derivada de la categoria del item.
function Changadex.getCategoryDescription(catKey)
    if not catKey then catKey = "Other" end
    local key = "UI_Changadex_Desc_" .. catKey
    local tr = Changadex.text(key)
    if tr and tr ~= key then return tr end
    return Changadex.text("UI_Changadex_Desc_Other")
end

-- Conteo de items descubiertos por categoria.
function Changadex.getProgressForCategory(catKey, player)
    local catalog = Changadex.buildCatalog()
    local list = catalog.byCategory[catKey] or {}
    local st = Changadex.getState(player)
    local foundCount = 0
    local total = #list
    if st then
        for _, scriptItem in ipairs(list) do
            if st.found[scriptItem:getFullName()] then
                foundCount = foundCount + 1
            end
        end
    end
    return foundCount, total
end

function Changadex.getOverallProgress(player)
    local catalog = Changadex.buildCatalog()
    local st = Changadex.getState(player)
    local foundCount = 0
    local total = catalog.total
    if st then
        for _, list in pairs(catalog.byCategory) do
            for _, scriptItem in ipairs(list) do
                if st.found[scriptItem:getFullName()] then
                    foundCount = foundCount + 1
                end
            end
        end
    end
    return foundCount, total
end
