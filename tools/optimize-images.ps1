<#
  Resizes/compresses the curated shortlist of source photos (from "Alle foto's")
  into web-ready JPEGs under images/<category>/<name>.jpg.
  Re-run any time the shortlist below changes; safe to re-run (overwrites outputs).
#>

Add-Type -AssemblyName System.Drawing

$root   = "C:\Users\kyra\Desktop\Website Villa Sol y Viento"
$srcDir = Join-Path $root "Alle foto's"
$imgDir = Join-Path $root "images"
$maxDim = 2200
$quality = 82

# category => list of @{src=; dest=}
# Kept in sync with "Alle foto's" — entries are only ever added/removed here
# when a source photo is added or deleted from that folder.
$map = @{
  "exterior" = @(
    @{src="cover.JPG"; dest="ext-facade-pool-jacuzzi.jpg"},
    @{src="WhatsApp Image 2025-04-28 at 22.37.54 (1).jpeg"; dest="ext-aerial-golden-hour-1.jpg"},
    @{src="WhatsApp Image 2025-04-28 at 22.37.54.jpeg"; dest="ext-aerial-golden-hour-2.jpg"},
    @{src="dji_fly_20250408_132126_64_1744111317738_photo.JPG"; dest="ext-aerial-topdown-terrace.jpg"},
    @{src="DSC09859.jpg"; dest="ext-facade-detail.jpg"}
  );
  "pool" = @(
    @{src="29713cb0-e336-4122-963c-775b72d63547.jpg"; dest="pool-facade.jpg"},
    @{src="DSC00003.jpg"; dest="pool-long-view.jpg"},
    @{src="DSC00006.jpg"; dest="pool-close.jpg"},
    @{src="DSC09927.jpg"; dest="pool-steps.jpg"},
    @{src="DSC09926.jpg"; dest="terrace-archway.jpg"}
  );
  "jacuzzi" = @(
    @{src="20250219_161824.jpg"; dest="jacuzzi-view.jpg"}
  );
  "garden" = @(
    @{src="DSC00013.jpg"; dest="garden-picnic-table.jpg"},
    @{src="DSC00016.jpg"; dest="garden-treehouse-tire-swing.jpg"},
    @{src="DSC00018.jpg"; dest="garden-treehouse-slide.jpg"},
    @{src="20250219_141942.jpg"; dest="games-pool-table.jpg"}
  );
  "living" = @(
    @{src="DSC09855.jpg"; dest="kitchen-1.jpg"},
    @{src="DSC09989.jpg"; dest="kitchen-dining-1.jpg"},
    @{src="DSC09881.jpg"; dest="living-room-2.jpg"},
    @{src="DSC09982.jpg"; dest="kitchen-3.jpg"},
    @{src="DSC09992.jpg"; dest="living-dining-sea-view.jpg"}
  );
  "bedrooms" = @(
    @{src="DSC09833.jpg"; dest="bedroom-studio.jpg"},
    @{src="DSC09848.jpg"; dest="bedroom-art-1.jpg"},
    @{src="DSC09865.jpg"; dest="bedroom-teal-2.jpg"},
    @{src="DSC09887.jpg"; dest="bedroom-teal-twin.jpg"},
    @{src="DSC09894.jpg"; dest="bedroom-pink-1.jpg"},
    @{src="DSC09911.jpg"; dest="bedroom-teal-doors.jpg"},
    @{src="DSC09915.jpg"; dest="bedroom-palm-view.jpg"},
    @{src="DSC09957.jpg"; dest="bedroom-pink-view.jpg"}
  );
  "bathrooms" = @(
    @{src="DSC09862.jpg"; dest="bathroom-shower-1.jpg"},
    @{src="DSC09871.jpg"; dest="bathroom-mirror.jpg"},
    @{src="DSC09919.jpg"; dest="bathroom-tub-view.jpg"},
    @{src="DSC09979.jpg"; dest="bathroom-black.jpg"}
  );
  "floorplans" = @(
    @{src="Floorplan Top floor New met NR.jpg"; dest="floorplan-top-floor.jpg"},
    @{src="Floorplan Ground floor New met NR.jpg"; dest="floorplan-ground-floor.jpg"},
    @{src="Floorplan Lower level New met NR.jpg"; dest="floorplan-lower-level.jpg"}
  );
}

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [int64]$quality)

function Save-Optimized($srcPath, $destPath) {
    $img = [System.Drawing.Image]::FromFile($srcPath)
    try {
        if ($img.PropertyIdList -contains 0x0112) {
            $o = [int]($img.GetPropertyItem(0x0112).Value[0])
            switch ($o) {
                2 { $img.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX) }
                3 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
                4 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipX) }
                5 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipX) }
                6 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
                7 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipX) }
                8 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
            }
        }

        $scale = [Math]::Min(1.0, $maxDim / [Math]::Max($img.Width, $img.Height))
        $w = [int]([Math]::Round($img.Width * $scale))
        $h = [int]([Math]::Round($img.Height * $scale))

        $bmp = New-Object System.Drawing.Bitmap($w, $h)
        try {
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            try {
                $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
                $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $g.DrawImage($img, 0, 0, $w, $h)
            } finally { $g.Dispose() }
            $bmp.Save($destPath, $jpegCodec, $encoderParams)
        } finally { $bmp.Dispose() }
    } finally { $img.Dispose() }
}

# clean out old flat images (superseded by categorized set below)
Get-ChildItem -Path $imgDir -File -ErrorAction SilentlyContinue | Remove-Item -Force

$total = 0
$failed = @()
foreach ($category in $map.Keys) {
    $destCatDir = Join-Path $imgDir $category
    if (-not (Test-Path $destCatDir)) { New-Item -ItemType Directory -Path $destCatDir | Out-Null }
    foreach ($entry in $map[$category]) {
        $srcPath = Join-Path $srcDir $entry.src
        $destPath = Join-Path $destCatDir $entry.dest
        if (-not (Test-Path $srcPath)) {
            $failed += "MISSING SOURCE: $($entry.src)"
            continue
        }
        try {
            Save-Optimized -srcPath $srcPath -destPath $destPath
            $total++
        } catch {
            $failed += "FAILED: $($entry.src) -> $($_.Exception.Message)"
        }
    }
}

Write-Output "Optimized: $total"
if ($failed.Count -gt 0) {
    Write-Output "Issues:"
    $failed | ForEach-Object { Write-Output "  $_" }
}
