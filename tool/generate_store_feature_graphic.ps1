Add-Type -AssemblyName System.Drawing

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$storeDir = Join-Path $root 'assets\store'
New-Item -ItemType Directory -Force -Path $storeDir | Out-Null

$width = 1024
$height = 500
$bitmap = New-Object System.Drawing.Bitmap $width, $height
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

function New-Brush([int]$a, [int]$r, [int]$g, [int]$b) {
    return New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($a, $r, $g, $b))
}

function New-Pen([int]$a, [int]$r, [int]$g, [int]$b, [float]$width) {
    return New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb($a, $r, $g, $b)), $width
}

function Add-RoundRect($g, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r, $fill, $stroke) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    $g.FillPath($fill, $path)
    if ($null -ne $stroke) {
        $g.DrawPath($stroke, $path)
    }
    $path.Dispose()
}

function Add-Text($g, [string]$text, $font, $brush, [float]$x, [float]$y) {
    $g.DrawString($text, $font, $brush, $x, $y)
}

$rect = New-Object System.Drawing.Rectangle 0, 0, $width, $height
$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(255, 7, 19, 39)), ([System.Drawing.Color]::FromArgb(255, 28, 37, 68)), 20
$graphics.FillRectangle($bgBrush, $rect)

$glowMint = New-Brush 54 18 194 148
$glowBlue = New-Brush 42 42 105 255
$graphics.FillEllipse($glowMint, 660, -160, 430, 430)
$graphics.FillEllipse($glowBlue, -150, 270, 370, 370)

$cardFill = New-Brush 222 39 48 76
$cardStroke = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(126, 93, 107, 139)), 2
$chipFill = New-Brush 230 11 31 54
$chipStroke = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(135, 18, 194, 148)), 2

$white = New-Brush 255 245 248 255
$muted = New-Brush 255 184 194 215
$mint = New-Brush 255 18 194 148
$blue = New-Brush 255 77 137 255

$titleFont = New-Object System.Drawing.Font 'Segoe UI', 48, ([System.Drawing.FontStyle]::Bold)
$subFont = New-Object System.Drawing.Font 'Malgun Gothic', 20, ([System.Drawing.FontStyle]::Regular)
$chipFont = New-Object System.Drawing.Font 'Malgun Gothic', 15, ([System.Drawing.FontStyle]::Bold)
$rightTitleFont = New-Object System.Drawing.Font 'Malgun Gothic', 18, ([System.Drawing.FontStyle]::Bold)
$smallFont = New-Object System.Drawing.Font 'Malgun Gothic', 16, ([System.Drawing.FontStyle]::Regular)
$footerFont = New-Object System.Drawing.Font 'Malgun Gothic', 15, ([System.Drawing.FontStyle]::Regular)

Add-RoundRect $graphics 48 68 540 330 34 $cardFill $cardStroke
Add-Text $graphics 'Strategy' $titleFont $white 94 104
Add-Text $graphics 'Workbench' $titleFont $mint 94 164
Add-Text $graphics '전략과 포트폴리오를 한눈에' $subFont $muted 98 254

Add-RoundRect $graphics 96 318 152 44 22 $chipFill $chipStroke
Add-RoundRect $graphics 266 318 178 44 22 $chipFill $chipStroke
Add-RoundRect $graphics 462 318 92 44 22 $chipFill $chipStroke
Add-Text $graphics '전략 스코어' $chipFont $mint 121 326
Add-Text $graphics '리밸런싱 코치' $chipFont $mint 289 326
Add-Text $graphics 'KR/US' $chipFont $mint 480 326

Add-RoundRect $graphics 638 80 310 130 28 $cardFill $cardStroke
Add-RoundRect $graphics 638 226 310 164 28 $cardFill $cardStroke

$chartPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 18, 194, 148)), 7
$chartPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$chartPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$points = @(
    (New-Object System.Drawing.Point 674, 162),
    (New-Object System.Drawing.Point 720, 134),
    (New-Object System.Drawing.Point 770, 148),
    (New-Object System.Drawing.Point 824, 106),
    (New-Object System.Drawing.Point 892, 118)
)
$graphics.DrawLines($chartPen, $points)
Add-Text $graphics '+ 전략 신호' $rightTitleFont $white 674 102
Add-Text $graphics '오늘의 Top Picks' $smallFont $muted 674 170

Add-Text $graphics '포트폴리오' $rightTitleFont $white 676 252
Add-Text $graphics '리스크 보유' $smallFont $muted 676 296
Add-RoundRect $graphics 870 294 36 28 14 $chipFill $chipStroke
Add-Text $graphics '2' $smallFont $mint 883 296
Add-Text $graphics '신규 편입' $smallFont $muted 676 330
Add-RoundRect $graphics 870 328 36 28 14 $chipFill $chipStroke
Add-Text $graphics '3' $smallFont $mint 883 330

Add-RoundRect $graphics 676 368 48 10 5 $mint $null
Add-RoundRect $graphics 736 368 86 10 5 $blue $null
Add-RoundRect $graphics 834 368 76 10 5 $mint $null

$strip = New-Brush 170 7 19 39
$graphics.FillRectangle($strip, 0, 438, $width, 62)
Add-Text $graphics '투자 판단을 돕는 전략 워크벤치 · 매매 권유가 아닌 정보 제공 앱' $footerFont $muted 104 458

$out = Join-Path $storeDir 'feature_graphic_1024x500.png'
$bitmap.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)

$graphics.Dispose()
$bitmap.Dispose()
Write-Output $out
