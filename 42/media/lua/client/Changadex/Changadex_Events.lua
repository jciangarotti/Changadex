-- Hooks de descubrimiento:
--   * OnPlayerUpdate: escanea el inventario del jugador cada 500ms y marca
--     los items nuevos. Cubre TODAS las formas en que un item puede llegar
--     al inventario (drag-and-drop, context menu, pickup, loot all, etc.)
--     — OnContainerUpdate no dispara en transferencias normales, solo en
--     foraging / vehiculos / moveables, por eso lo cambiamos.
--   * OnGameStart: construye el catalogo y hace un escaneo inicial
--     SILENCIOSO (sin halo text) para no spamear con todo lo que ya
--     tenias encima al cargar la partida.

Changadex = Changadex or {}

-- Escanea un InventoryContainer y todos sus bolsos anidados, marcando
-- cada fullType que aparezca.
local function scanContainer(container, player, seen, silent)
    if not container then return end
    local items = container:getItems()
    if not items then return end
    for i = 0, items:size() - 1 do
        local inv = items:get(i)
        local fullType = inv and inv:getFullType()
        if fullType and not seen[fullType] then
            seen[fullType] = true
            Changadex.discover(fullType, player, silent)
        end
        if inv and inv.getInventory then
            local nested = inv:getInventory()
            if nested then scanContainer(nested, player, seen, silent) end
        end
    end
end

function Changadex.scanPlayerInventory(player, silent)
    player = player or getPlayer()
    if not player then return end
    local inv = player:getInventory()
    if not inv then return end
    local seen = {}
    scanContainer(inv, player, seen, silent)
end

-- Throttle: OnPlayerUpdate fira por frame (60Hz). Escaneamos a lo sumo
-- cada 500ms para mantener el costo bajo.
local lastScanMs = 0
local SCAN_COOLDOWN_MS = 500

local function onPlayerUpdate(player)
    if not player or player ~= getPlayer() then return end
    local now = getTimestampMs and getTimestampMs() or 0
    if now - lastScanMs < SCAN_COOLDOWN_MS then return end
    lastScanMs = now
    Changadex.scanPlayerInventory(player, false)
end

local function onGameStart()
    Changadex.buildCatalog()
    local player = getPlayer()
    if player then
        -- Escaneo inicial silencioso: evita el spam de halo text con todo
        -- lo que ya tenias en el inventario al cargar la partida.
        Changadex.scanPlayerInventory(player, true)
        -- Marcamos el timestamp para que el primer tick no re-escanee.
        lastScanMs = getTimestampMs and getTimestampMs() or 0
    end
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)
Events.OnGameStart.Add(onGameStart)
