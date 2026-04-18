-- Hooks de descubrimiento:
--   * OnContainerUpdate: escanea el inventario del jugador y marca items nuevos.
--   * OnEquipPrimary/Secondary: marca lo que se pone en mano.
--   * OnClothingUpdated: marca la ropa equipada.
--   * ISReadABook:perform (patch): marca revistas/libros al terminar de leer.
--   * ISEatFoodAction:complete (patch): marca comida al terminar de comerla.

require "TimedActions/ISReadABook"
require "TimedActions/ISEatFoodAction"
require "TimedActions/ISDeviceMediaAction"

Changadex = Changadex or {}

-- Escanea un InventoryContainer (ItemContainer) y sus bolsos anidados,
-- marcando cada fullType que aparezca.
local function scanContainer(container, player, seen)
    if not container then return end
    local items = container:getItems()
    if not items then return end
    for i = 0, items:size() - 1 do
        local inv = items:get(i)
        local scriptItem = inv.getScriptItem and inv:getScriptItem() or nil
        local fullType = inv:getFullType()
        if fullType and not seen[fullType] then
            seen[fullType] = true
            Changadex.discover(fullType, "pickup", player, inv)
        end
        if inv.getInventory then
            local nested = inv:getInventory()
            if nested then scanContainer(nested, player, seen) end
        end
    end
end

-- Hace el escaneo completo del inventario del jugador + todas las bolsas.
function Changadex.scanPlayerInventory(player)
    player = player or getPlayer()
    if not player then return end
    local inv = player:getInventory()
    if not inv then return end
    local seen = {}
    scanContainer(inv, player, seen)
end

-- Throttle: OnContainerUpdate puede dispararse mucho. Solo escaneamos si paso
-- un tiempo minimo desde el ultimo scan.
local lastScanMs = 0
local SCAN_COOLDOWN_MS = 250

local function onContainerUpdate()
    local player = getPlayer()
    if not player then return end
    local now = getTimestampMs and getTimestampMs() or 0
    if now - lastScanMs < SCAN_COOLDOWN_MS then return end
    lastScanMs = now
    Changadex.scanPlayerInventory(player)
end

local function onEquip(character, item)
    if character ~= getPlayer() then return end
    if not item then return end
    Changadex.discover(item:getFullType(), "equip", character, item)
end

local function onClothingUpdated(character)
    if character ~= getPlayer() then return end
    local worn = character:getWornItems()
    if not worn then return end
    for i = 0, worn:size() - 1 do
        local wi = worn:get(i)
        local item = wi and wi:getItem() or nil
        if item then
            Changadex.discover(item:getFullType(), "wear", character, item)
        end
    end
end

-- Patch de ISReadABook:perform — cuando se termina de leer, marcamos el item
-- como descubierto con how="read". Si ya estaba descubierto por pickup,
-- actualizamos el "how" para registrar que encima lo leimos.
local origReadPerform = ISReadABook.perform
function ISReadABook:perform()
    local result = origReadPerform(self)
    local player = self.character
    if player and self.item then
        local fullType = self.item:getFullType()
        Changadex.discover(fullType, "read", player, self.item)
    end
    return result
end

-- Patch de ISEatFoodAction:complete — al terminar de comer/beber algo.
-- Si ya estaba descubierto por pickup, actualizamos el "how" a "eat" asi
-- queda registrado que ademas lo comiste.
local origEatComplete = ISEatFoodAction.complete
function ISEatFoodAction:complete()
    local result = origEatComplete(self)
    local player = self.character
    if player and self.item then
        local fullType = self.item:getFullType()
        local st = Changadex.getState(player)
        if st and st.found[fullType] then
            st.found[fullType].how = "eat"
        else
            Changadex.discover(fullType, "eat", player, self.item)
        end
    end
    return result
end

-- Patch de ISDeviceMediaAction:complete — al meter un VHS o CD en un
-- aparato (VCR, radio, TV). Consideramos eso como "ver" / "escuchar".
local origMediaComplete = ISDeviceMediaAction.complete
function ISDeviceMediaAction:complete()
    local result = origMediaComplete(self)
    local player = self.character
    if player and (not self.isRemove) and self.secondaryItem then
        local fullType = self.secondaryItem:getFullType()
        local scriptItem = self.secondaryItem:getScriptItem()
        local how = "watch"
        if scriptItem and scriptItem.getMediaType then
            -- mediaType: 0 = CD/audio, 1 = VHS/video
            if scriptItem:getMediaType() == 0 then how = "listen" end
        end
        local st = Changadex.getState(player)
        if st and st.found[fullType] then
            st.found[fullType].how = how
        else
            Changadex.discover(fullType, how, player, self.secondaryItem)
        end
    end
    return result
end

-- Escaneo inicial al cargar la partida, para marcar todo lo que el jugador
-- ya tenia encima antes de instalar el mod.
local function onGameStart()
    local player = getPlayer()
    if not player then return end
    Changadex.buildCatalog()
    Changadex.scanPlayerInventory(player)
end

Events.OnContainerUpdate.Add(onContainerUpdate)
Events.OnEquipPrimary.Add(onEquip)
Events.OnEquipSecondary.Add(onEquip)
Events.OnClothingUpdated.Add(onClothingUpdated)
Events.OnGameStart.Add(onGameStart)
