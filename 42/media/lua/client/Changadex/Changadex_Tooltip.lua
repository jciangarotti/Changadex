-- Patch de ISToolTipInv:render para agregar una fila al final del tooltip
-- con el formato "Descubierto: Si" (verde) / "Descubierto: No" (rojo),
-- al estilo de las demas filas del tooltip del juego.

require "ISUI/ISToolTipInv"

Changadex = Changadex or {}

local FONT = UIFont.Small
local FH = getTextManager():getFontHeight(FONT)
local PAD_X = 8
local PAD_TOP = 3
local PAD_BOT = 4

local origRender = ISToolTipInv.render
function ISToolTipInv:render()
    origRender(self)

    -- Si el context menu esta visible, el tooltip no se dibujo (ver
    -- ISToolTipInv:render original) — no dibujamos fila extra.
    if ISContextMenu and ISContextMenu.instance and ISContextMenu.instance.visibleCheck then
        return
    end
    if not self.item or not self.item.getFullType then return end
    if self.width <= 0 or self.height <= 0 then return end

    local fullType = self.item:getFullType()
    if not fullType or not Changadex.isDiscovered then return end

    local isDiscovered = Changadex.isDiscovered(fullType)
    local label = Changadex.text("UI_Changadex_TooltipLabel")
    local value = isDiscovered
        and Changadex.text("UI_Changadex_Yes")
        or Changadex.text("UI_Changadex_No")

    local vR, vG, vB
    if isDiscovered then
        vR, vG, vB = 0.25, 0.85, 0.3
    else
        vR, vG, vB = 0.9, 0.25, 0.25
    end

    local rowH = FH + PAD_TOP + PAD_BOT
    local rowY = self.height
    -- Fondo de la fila extra — matchea el tooltip (negro con borde gris tenue).
    self:drawRect(0, rowY, self.width, rowH, 0.95, 0, 0, 0)
    self:drawRectBorder(0, rowY, self.width, rowH, 0.7, 0.35, 0.35, 0.35)

    local textY = rowY + PAD_TOP
    self:drawText(label, PAD_X, textY, 1, 1, 1, 1, FONT)
    local valW = getTextManager():MeasureStringX(FONT, value)
    self:drawText(value, self.width - valW - PAD_X, textY, vR, vG, vB, 1, FONT)
end
