<#
  Verkleint ruwe camerafoto's die in images/<categorie>/ zijn gezet.

  Werkwijze: zet nieuwe foto's gewoon in de juiste categoriemap en voer dit
  script uit. Foto's die groter zijn dan 2200px op de lange zijde worden ter
  plaatse verkleind naar 2200px (kwaliteit 82), met de juiste beeldrotatie.

  Foto's die al 2200px of kleiner zijn worden OVERGESLAGEN. Het script kan dus
  zonder risico opnieuw worden uitgevoerd — er gaat geen kwaliteit verloren
  door herhaald opslaan.

  Draai hierna tools\make-thumbnails.ps1 om de thumbnails bij te werken.

  Gebruik:  powershell -File tools\optimize-originals.ps1
            powershell -File tools\optimize-originals.ps1 -WhatIf            (alleen tonen)
            powershell -File tools\optimize-originals.ps1 -MaxDim 3500       (ruimere grens)

  Met -MaxDim geef je een andere bovengrens op. Handig als je één foto bewust
  op hogere resolutie wilt houden: alles onder die grens blijft ongemoeid.
#>

param(
    [switch]$WhatIf,
    [int]$MaxDim = 2200
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root   = Split-Path -Parent $PSScriptRoot
$imgDir = Join-Path $root "images"

$maxDim  = $MaxDim
$quality = 82

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
             Where-Object { $_.MimeType -eq 'image/jpeg' }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
    [System.Drawing.Imaging.Encoder]::Quality, [int64]$quality)

function Get-Dimensions($path) {
    $img = [System.Drawing.Image]::FromFile($path)
    try { return @($img.Width, $img.Height) } finally { $img.Dispose() }
}

function Resize-InPlace($path) {
    $tmp = "$path.tmp"
    $img = [System.Drawing.Image]::FromFile($path)
    try {
        # Beeldrotatie uit de EXIF-gegevens toepassen, anders staan
        # telefoonfoto's op hun kant
        if ($img.PropertyIdList -contains 0x0112) {
            switch ([int]($img.GetPropertyItem(0x0112).Value[0])) {
                2 { $img.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX) }
                3 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
                4 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipX) }
                5 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipX) }
                6 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
                7 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipX) }
                8 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
            }
        }
        $scale = $maxDim / [Math]::Max($img.Width, $img.Height)
        $w = [int]([Math]::Round($img.Width  * $scale))
        $h = [int]([Math]::Round($img.Height * $scale))

        $bmp = New-Object System.Drawing.Bitmap($w, $h)
        try {
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            try {
                $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
                $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $g.DrawImage($img, 0, 0, $w, $h)
            } finally { $g.Dispose() }
            $bmp.Save($tmp, $jpegCodec, $encoderParams)
        } finally { $bmp.Dispose() }
    } finally { $img.Dispose() }

    Move-Item -Force $tmp $path
    return @($w, $h)
}

$categories = Get-ChildItem -Path $imgDir -Directory | Where-Object { $_.Name -ne 'thumbs' }

$done = 0; $skipped = 0; $before = 0; $after = 0
foreach ($cat in $categories) {
    $photos = Get-ChildItem -Path $cat.FullName -File |
              Where-Object { $_.Extension -match '^\.(jpg|jpeg)$' }

    foreach ($photo in $photos) {
        $dims = Get-Dimensions $photo.FullName
        if ([Math]::Max($dims[0], $dims[1]) -le $maxDim) { $skipped++; continue }

        $sizeBefore = $photo.Length
        if ($WhatIf) {
            Write-Output ("ZOU VERKLEINEN  {0}/{1}  {2}x{3}  ({4:N1} MB)" -f `
                $cat.Name, $photo.Name, $dims[0], $dims[1], ($sizeBefore / 1MB))
            $done++
            continue
        }

        $new = Resize-InPlace $photo.FullName
        $sizeAfter = (Get-Item $photo.FullName).Length
        $before += $sizeBefore; $after += $sizeAfter; $done++
        Write-Output ("{0}/{1}  {2}x{3} -> {4}x{5}  ({6:N1} MB -> {7:N0} KB)" -f `
            $cat.Name, $photo.Name, $dims[0], $dims[1], $new[0], $new[1],
            ($sizeBefore / 1MB), ($sizeAfter / 1KB))
    }
}

Write-Output ""
if ($WhatIf) {
    Write-Output "Te verkleinen: $done   Al in orde: $skipped   (niets gewijzigd)"
} else {
    Write-Output "Verkleind: $done   Overgeslagen (al klein genoeg): $skipped"
    if ($done -gt 0) {
        Write-Output ("Bespaard: {0:N1} MB" -f (($before - $after) / 1MB))
        Write-Output "Vergeet niet: powershell -File tools\make-thumbnails.ps1"
    }
}
