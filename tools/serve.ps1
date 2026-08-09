<#
  Eenvoudige lokale webserver om de site in de browser te bekijken vóór het
  publiceren. Nodig omdat browsers (en de Claude in Chrome-plugin) een echte
  http://-URL willen; file:// werkt niet betrouwbaar.

  Gebruik:   powershell -File tools\serve.ps1
  Daarna:    http://localhost:8080/  en  http://localhost:8080/nl/
  Stoppen:   Ctrl+C, of het venster sluiten
#>

param([int]$Port = 8080)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

$mime = @{
  ".html"="text/html; charset=utf-8"; ".css"="text/css; charset=utf-8"
  ".js"="application/javascript; charset=utf-8"; ".json"="application/json"
  ".jpg"="image/jpeg"; ".jpeg"="image/jpeg"; ".png"="image/png"
  ".svg"="image/svg+xml"; ".webp"="image/webp"; ".avif"="image/avif"
  ".xml"="application/xml"; ".txt"="text/plain; charset=utf-8"
  ".ico"="image/x-icon"
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Output "Serveert $root op http://localhost:$Port/  (Ctrl+C om te stoppen)"

try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $rel = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
    if ($rel -eq "" -or $rel.EndsWith("/")) { $rel += "index.html" }

    $path = Join-Path $root ($rel -replace '/', '\')
    $full = [System.IO.Path]::GetFullPath($path)

    # Buiten de projectmap serveren we niets
    if (-not $full.StartsWith([System.IO.Path]::GetFullPath($root))) {
      $ctx.Response.StatusCode = 403
      $ctx.Response.Close()
      continue
    }

    # Verbindingen niet openhouden: deze server verwerkt één verzoek tegelijk,
    # en wachtende keep-alive-sockets laten de pagina onnodig lang leeg staan.
    $ctx.Response.KeepAlive = $false

    if (Test-Path $full -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($full).ToLower()
      $ctx.Response.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { "application/octet-stream" }
      $bytes = [System.IO.File]::ReadAllBytes($full)
      $ctx.Response.ContentLength64 = $bytes.Length
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
      $msg = [Text.Encoding]::UTF8.GetBytes("404 - niet gevonden: $rel")
      $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
    }
    $ctx.Response.Close()
  }
} finally {
  $listener.Stop()
  $listener.Close()
}
