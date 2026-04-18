-- Agrega una linea al menu contextual (clic derecho) sobre items, indicando
-- el estado en el Changadex: si ya fue descubierto (y como) o si todavia falta
-- descubrirlo con la accion correspondiente (leer, comer, mirar, etc.).

Changadex = Changadex or {}

local VERB_BY_HOW = {
    pickup = "UI_Changadex_VerbFound",
    equip  = "UI_Changadex_VerbEquipped",
    wear   = "UI_Changadex_VerbWorn",
    read   = "UI_Changadex_VerbRead",
    eat    = "UI_Changadex_VerbEaten",
    watch  = "UI_Changadex_VerbWatched",
    listen = "UI_Changadex_VerbListened",
}

local ACTION_LABEL = {
    read   = "UI_Changadex_ActionRead",
    watch  = "UI_Changadex_ActionWatch",
    listen = "UI_Changadex_ActionListen",
    eat    = "UI_Changadex_ActionEat",
    wear   = "UI_Changadex_ActionWear",
    equip  = "UI_Changadex_ActionEquip",
}

-- Devuelve la accion requerida para un scriptItem, o nil si alcanza con pickup.
local function requiredAction(scriptItem)
    if not scriptItem then return nil end
    if scriptItem:isItemType(ItemType.LITERATURE) then return "read" end
    if scriptItem.getRecordedMediaCat and scriptItem:getRecordedMediaCat() then
        if scriptItem.getMediaType and scriptItem:getMediaType() == 0 then
            return "listen"
        end
        return "watch"
    end
    if scriptItem:isItemType(ItemType.FOOD) then return "eat" end
    if scriptItem:isItemType(ItemType.CLOTHING) then return "wear" end
    if scriptItem:isItemType(ItemType.WEAPON) then return "equip" end
    return nil
end

-- Busca el record de descubrimiento: primero por titulo (literatura),
-- despues por fullType.
local function findRecord(inventoryItem, fullType, st)
    if not st then return nil end
    local specificName = Changadex.getSpecificName and Changadex.getSpecificName(inventoryItem)
    if specificName and st.titles and st.titles[specificName] then
        return st.titles[specificName]
    end
    if st.found and st.found[fullType] then
        return st.found[fullType]
    end
    return nil
end

local function resolveItem(entry)
    if entry and entry.getFullType then return entry end
    if entry and entry.items and entry.items[1] then return entry.items[1] end
    return nil
end

local function onFillContextMenu(player, context, items)
    if not items or #items == 0 then return end
    local item = resolveItem(items[1])
    if not item or not item.getFullType then return end

    local fullType = item:getFullType()
    local scriptItem = item.getScriptItem and item:getScriptItem() or nil
    local st = Changadex.getState()
    local rec = findRecord(item, fullType, st)

    local prefix = Changadex.text("UI_Changadex_Title") .. ": "
    local optionText
    local greyed = false

    if rec then
        -- Ya descubierto: mostramos el verbo con un tilde adelante.
        local verb = Changadex.text(VERB_BY_HOW[rec.how] or "UI_Changadex_VerbFound")
        optionText = prefix .. Changadex.text("UI_Changadex_CtxDone", verb)
    else
        -- Pendiente: si requiere una accion especifica, la mostramos.
        local action = requiredAction(scriptItem)
        if action then
            local actionTxt = Changadex.text(ACTION_LABEL[action])
            optionText = prefix .. Changadex.text("UI_Changadex_CtxPendingAction", actionTxt)
        else
            optionText = prefix .. Changadex.text("UI_Changadex_CtxPending")
        end
        greyed = true
    end

    local opt = context:addOption(optionText, nil, nil)
    if opt then
        -- Texto informativo — no clickeable.
        opt.notAvailable = greyed
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillContextMenu)
