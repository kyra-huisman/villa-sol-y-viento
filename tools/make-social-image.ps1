<#
  Maakt images/social-share.jpg (1200x630) — de afbeelding die verschijnt als
  iemand villasolyviento.com deelt in WhatsApp, Facebook, LinkedIn etc.

  1200x630 is het formaat dat die platforms verwachten. Door zelf te croppen
  bepaal jij de uitsnede, in plaats van dat het platform willekeurig bijsnijdt.

  Bronfoto aanpassen? Wijzig $source hieronder en voer het script opnieuw uit.
#>

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root   = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root "images\garden\garden-aerial-view.jpg"
$dest   = Join-Path $root "images\social-share.jpg"

$targetW = 1200
$targetH = 630
$quality = 82

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
             Where-Object { $_.MimeType -eq 'image/jpeg' }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
    [System.Drawing.Imaging.Encoder]::Quality, [int64]$quality)

$img = [System.Drawing.Image]::FromFile($source)
try {
    # "cover"-uitsnede: vul het hele vlak, snij de overhang weg
    $scale = [Math]::Max($targetW / $img.Width, $targetH / $img.Height)
    $scaledW = $img.Width  * $scale
    $scaledH = $img.Height * $scale
    $offsetX = ($targetW - $scaledW) / 2
    $offsetY = ($targetH - $scaledH) / 2

    $bmp = New-Object System.Drawing.Bitmap($targetW, $targetH)
    try {
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        try {
            $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $g.DrawImage($img, $offsetX, $offsetY, $scaledW, $scaledH)
        } finally { $g.Dispose() }
        $bmp.Save($dest, $jpegCodec, $encoderParams)
    } finally { $bmp.Dispose() }
} finally { $img.Dispose() }

$kb = [Math]::Round((Get-Item $dest).Length / 1KB)
Write-Output "Gemaakt: images/social-share.jpg ($targetW x $targetH, $kb KB)"
