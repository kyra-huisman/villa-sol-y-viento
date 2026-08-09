<#
  Genereert kleine thumbnails voor het fotoraster op de Pictures-pagina.

  De originele foto's in images/<categorie>/ blijven ONGEWIJZIGD — die worden
  gebruikt voor de lightbox en de downloadknop. Dit script schrijft alleen naar
  images/thumbs/<categorie>/.

  Opnieuw uitvoeren is veilig: bestaande thumbnails worden overschreven, en
  thumbnails van inmiddels verwijderde foto's worden opgeruimd.

  Gebruik:  powershell -File tools\make-thumbnails.ps1
#>

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root      = Split-Path -Parent $PSScriptRoot
$imgDir    = Join-Path $root "images"
$thumbRoot = Join-Path $imgDir "thumbs"

$maxDim  = 700   # lange zijde; ruim genoeg voor retina-schermen in het raster
$quality = 78

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
             Where-Object { $_.MimeType -eq 'image/jpeg' }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
    [System.Drawing.Imaging.Encoder]::Quality, [int64]$quality)

function New-Thumbnail($srcPath, $destPath) {
    $img = [System.Drawing.Image]::FromFile($srcPath)
    try {
        $scale = [Math]::Min(1.0, $maxDim / [Math]::Max($img.Width, $img.Height))
        $w = [int]([Math]::Round($img.Width  * $scale))
        $h = [int]([Math]::Round($img.Height * $scale))

        $bmp = New-Object System.Drawing.Bitmap($w, $h)
        try {
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            try {
                $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
                $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $g.DrawImage($img, 0, 0, $w, $h)
            } finally { $g.Dispose() }
            $bmp.Save($destPath, $jpegCodec, $encoderParams)
        } finally { $bmp.Dispose() }
    } finally { $img.Dispose() }
}

if (-not (Test-Path $thumbRoot)) { New-Item -ItemType Directory -Path $thumbRoot | Out-Null }

$made       = 0
$bytesFull  = 0
$bytesThumb = 0
$expected   = New-Object System.Collections.Generic.HashSet[string]

# Alle categoriemappen behalve 'thumbs' zelf
$categories = Get-ChildItem -Path $imgDir -Directory | Where-Object { $_.Name -ne 'thumbs' }

foreach ($cat in $categories) {
    $destCat = Join-Path $thumbRoot $cat.Name
    if (-not (Test-Path $destCat)) { New-Item -ItemType Directory -Path $destCat | Out-Null }

    $photos = Get-ChildItem -Path $cat.FullName -File |
              Where-Object { $_.Extension -match '^\.(jpg|jpeg)$' }

    foreach ($photo in $photos) {
        $destPath = Join-Path $destCat $photo.Name
        [void]$expected.Add($destPath)
        try {
            New-Thumbnail -srcPath $photo.FullName -destPath $destPath
            $bytesFull  += $photo.Length
            $bytesThumb += (Get-Item $destPath).Length
            $made++
        } catch {
            Write-Output "  MISLUKT: $($cat.Name)/$($photo.Name) -> $($_.Exception.Message)"
        }
    }
}

# Verweesde thumbnails opruimen (foto verwijderd uit de bronmap)
$removed = 0
if (Test-Path $thumbRoot) {
    Get-ChildItem -Path $thumbRoot -Recurse -File | ForEach-Object {
        if (-not $expected.Contains($_.FullName)) {
            Remove-Item -Force $_.FullName
            $removed++
        }
    }
}

Write-Output "Thumbnails gemaakt: $made"
if ($removed -gt 0) { Write-Output "Verweesde thumbnails verwijderd: $removed" }
Write-Output ("Origineel totaal:  {0:N1} MB" -f ($bytesFull  / 1MB))
Write-Output ("Thumbnails totaal: {0:N1} MB" -f ($bytesThumb / 1MB))
if ($bytesFull -gt 0) {
    Write-Output ("Besparing in het raster: {0:N0}%" -f ((1 - $bytesThumb / $bytesFull) * 100))
}
