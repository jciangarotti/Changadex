-- Opciones del menu contextual (clic derecho) sobre items:
--   * Si NO esta descubierto: "Descubrir" — lo marca como descubierto y abre
--     la ventana de informacion.
--   * Si YA esta descubierto: "Ver informacion" — solo abre la ventana.

Changadex = Changadex or {}

local function resolveItem(entry)
    if entry and entry.getFullType then return entry end
    if entry and entry.items and entry.items[1] then return entry.items[1] end
    return nil
end

local function onDiscoverClick(player, fullType, scriptItem)
    Changadex.discover(fullType, player)
    if Changadex.showInfo then
        Changadex.showInfo(scriptItem, fullType)
    end
end

local function onViewInfoClick(player, fullType, scriptItem)
    if Changadex.showInfo then
        Changadex.showInfo(scriptItem, fullType)
    end
end

local function onFillContextMenu(player, context, items)
    if not items or #items == 0 then return end
    local item = resolveItem(items[1])
    if not item or not item.getFullType then return end

    local fullType = item:getFullType()
    local scriptItem = item.getScriptItem and item:getScriptItem() or nil
    if not scriptItem then return end

    local playerObj = getSpecificPlayer(player) or getPlayer()
    local prefix = Changadex.text("UI_Changadex_Title") .. ": "
    local isDiscovered = Changadex.isDiscovered(fullType, playerObj)

    if isDiscovered then
        context:addOption(
            prefix .. Changadex.text("UI_Changadex_CtxViewInfo"),
            nil,
            function() onViewInfoClick(playerObj, fullType, scriptItem) end
        )
    else
        context:addOption(
            prefix .. Changadex.text("UI_Changadex_CtxDiscover"),
            nil,
            function() onDiscoverClick(playerObj, fullType, scriptItem) end
        )
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillContextMenu)
