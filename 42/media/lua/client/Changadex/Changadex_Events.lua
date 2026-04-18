-- Hooks de descubrimiento:
--   * OnContainerUpdate: escanea el inventario del jugador y marca items
--     nuevos. Es el unico hook automatico; el resto de la descubierta va
--     por el menu contextual (clic derecho).
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

-- Throttle: OnContainerUpdate puede dispararse mucho. Solo escaneamos si
-- paso un tiempo minimo desde el ultimo scan.
local lastScanMs = 0
local SCAN_COOLDOWN_MS = 250

local function onContainerUpdate()
    local player = getPlayer()
    if not player then return end
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
    end
end

Events.OnContainerUpdate.Add(onContainerUpdate)
Events.OnGameStart.Add(onGameStart)
