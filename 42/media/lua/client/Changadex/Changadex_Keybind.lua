-- Registra la tecla "Open Changadex" en el menu de keybinds del juego.
-- Importante en B42: el registro debe hacerse en OnGameBoot (antes del main
-- menu) para que aparezca en Options > Key Bindings. El listener solo se
-- enchufa en OnGameStart para no dispararse en el menu principal.

Changadex = Changadex or {}
Changadex.Keybind = {}

Changadex.Keybind.register = function()
    local bind = {}
    bind.value = "[Changadex]"
    table.insert(keyBinding, bind)

    bind = {}
    bind.value = "Open Changadex"
    bind.key = Keyboard.KEY_N
    table.insert(keyBinding, bind)
end

Changadex.Keybind.onKeyPressed = function(key)
    if key == getCore():getKey("Open Changadex") then
        if Changadex and Changadex.toggleUI then
            Changadex.toggleUI()
        end
    end
end

Changadex.Keybind.startListener = function()
    Events.OnKeyPressed.Add(Changadex.Keybind.onKeyPressed)
end

Events.OnGameBoot.Add(Changadex.Keybind.register)
Events.OnGameStart.Add(Changadex.Keybind.startListener)
