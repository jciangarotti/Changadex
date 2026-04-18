Add-Type -AssemblyName System.Drawing

function New-ChangadexImage {
    param(
        [int]$Size,
        [string]$OutputPath,
        [bool]$ShowTitle
    )

    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    # Paleta survival: verde oliva oscuro, marron gastado, amarillo aviso.
    $bgTop    = [System.Drawing.Color]::FromArgb(255, 30, 38, 26)
    $bgBot    = [System.Drawing.Color]::FromArgb(255, 18, 22, 16)
    $clipbrd  = [System.Drawing.Color]::FromArgb(255, 94, 68, 34)
    $clipbrd2 = [System.Drawing.Color]::FromArgb(255, 118, 86, 42)
    $paper    = [System.Drawing.Color]::FromArgb(255, 232, 220, 188)
    $paperSh  = [System.Drawing.Color]::FromArgb(255, 198, 186, 152)
    $check    = [System.Drawing.Color]::FromArgb(255, 96, 176, 62)
    $miss     = [System.Drawing.Color]::FromArgb(255, 60, 60, 60)
    $accent   = [System.Drawing.Color]::FromArgb(255, 240, 196, 48)

    # Fondo gradiente
    $rect = New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect, $bgTop, $bgBot, 90)
    $g.FillRectangle($brush, $rect)
    $brush.Dispose()

    # Borde tenue
    $pen = New-Object System.Drawing.Pen($accent, [Math]::Max(1, [int]($Size / 64)))
    $pen.Color = [System.Drawing.Color]::FromArgb(80, 240, 196, 48)
    $g.DrawRectangle($pen, 1, 1, $Size - 3, $Size - 3)
    $pen.Dispose()

    # Clipboard (tabla)
    $cbMargin = [int]($Size * 0.16)
    $cbX = $cbMargin
    $cbY = [int]($Size * 0.12)
    $cbW = $Size - $cbMargin * 2
    $cbH = [int]($Size * 0.76)
    $cbRect = New-Object System.Drawing.Rectangle($cbX, $cbY, $cbW, $cbH)
    $cbBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $cbRect, $clipbrd2, $clipbrd, 90)
    $g.FillRectangle($cbBrush, $cbRect)
    $cbBrush.Dispose()

    # Pinza del clipboard (arriba)
    $clipW = [int]($cbW * 0.35)
    $clipX = $cbX + ($cbW - $clipW) / 2
    $clipY = $cbY - [int]($Size * 0.04)
    $clipH = [int]($Size * 0.08)
    $clipBrush = New-Object System.Drawing.SolidBrush(
        [System.Drawing.Color]::FromArgb(255, 160, 160, 160))
    $g.FillRectangle($clipBrush, $clipX, $clipY, $clipW, $clipH)
    $clipBrush.Dispose()

    # Hoja de papel interna
    $paperPad = [int]($Size * 0.035)
    $paperX = $cbX + $paperPad
    $paperY = $cbY + $paperPad + [int]($Size * 0.03)
    $paperW = $cbW - $paperPad * 2
    $paperH = $cbH - $paperPad * 2 - [int]($Size * 0.03)
    $paperBrush = New-Object System.Drawing.SolidBrush($paper)
    $g.FillRectangle($paperBrush, $paperX, $paperY, $paperW, $paperH)
    $paperBrush.Dispose()

    # Filas de checklist: tres marcadas (verde) y una sin marcar
    $rowH = [int]($paperH / 5)
    $boxSize = [int]($rowH * 0.55)
    $leftPad = [int]($paperW * 0.08)
    $statuses = @($true, $true, $false, $true)
    for ($i = 0; $i -lt $statuses.Length; $i++) {
        $ry = $paperY + [int]($rowH * 0.35) + $rowH * $i
        $bx = $paperX + $leftPad
        $by = $ry

        # Caja checkbox
        $boxPen = New-Object System.Drawing.Pen($miss, [Math]::Max(1, [int]($Size / 80)))
        $g.DrawRectangle($boxPen, $bx, $by, $boxSize, $boxSize)
        $boxPen.Dispose()

        if ($statuses[$i]) {
            # Tilde verde
            $chkPen = New-Object System.Drawing.Pen($check, [Math]::Max(2, [int]($Size / 48)))
            $chkPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
            $chkPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
            $p1x = $bx + [int]($boxSize * 0.15)
            $p1y = $by + [int]($boxSize * 0.55)
            $p2x = $bx + [int]($boxSize * 0.42)
            $p2y = $by + [int]($boxSize * 0.82)
            $p3x = $bx + [int]($boxSize * 0.95)
            $p3y = $by + [int]($boxSize * 0.20)
            $g.DrawLines($chkPen, @(
                (New-Object System.Drawing.Point($p1x, $p1y)),
                (New-Object System.Drawing.Point($p2x, $p2y)),
                (New-Object System.Drawing.Point($p3x, $p3y))
            ))
            $chkPen.Dispose()
            $lineColor = $miss
        } else {
            $lineColor = [System.Drawing.Color]::FromArgb(200, 120, 120, 120)
        }

        # Linea de "texto" al lado
        $lineX = $bx + $boxSize + [int]($paperW * 0.06)
        $lineW = $paperW - ($lineX - $paperX) - [int]($paperW * 0.08)
        $lineY = $by + [int]($boxSize / 2) - [Math]::Max(1, [int]($Size / 96))
        $lineH = [Math]::Max(2, [int]($Size / 48))
        $linePen = New-Object System.Drawing.SolidBrush($lineColor)
        $g.FillRectangle($linePen, $lineX, $lineY, $lineW, $lineH)
        $linePen.Dispose()
    }

    # Titulo "CHANGADEX" al pie, solo en poster
    if ($ShowTitle -and $Size -ge 128) {
        $fontSize = [Math]::Max(10, [int]($Size * 0.09))
        $font = New-Object System.Drawing.Font("Impact", $fontSize, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush($accent)
        $titleText = "CHANGADEX"
        $titleSize = $g.MeasureString($titleText, $font)
        $titleX = ($Size - $titleSize.Width) / 2
        $titleY = $Size - $titleSize.Height - [int]($Size * 0.01)
        # Sombra
        $shadowBrush = New-Object System.Drawing.SolidBrush(
            [System.Drawing.Color]::FromArgb(200, 0, 0, 0))
        $g.DrawString($titleText, $font, $shadowBrush, $titleX + 2, $titleY + 2)
        $g.DrawString($titleText, $font, $titleBrush, $titleX, $titleY)
        $font.Dispose()
        $titleBrush.Dispose()
        $shadowBrush.Dispose()
    }

    $g.Dispose()
    $bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Generated $OutputPath"
}

$modRoot = "C:\Users\ciang\Zomboid\mods\Changadex"
New-ChangadexImage -Size 256 -OutputPath "$modRoot\poster.png"     -ShowTitle $true
New-ChangadexImage -Size 256 -OutputPath "$modRoot\42\poster.png"  -ShowTitle $true
New-ChangadexImage -Size 64  -OutputPath "$modRoot\icon.png"       -ShowTitle $false
New-ChangadexImage -Size 64  -OutputPath "$modRoot\42\icon.png"    -ShowTitle $false
