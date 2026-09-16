<#
  Eenvoudige lokale webserver om de site in de browser te bekijken vóór het
  publiceren. Zo werkt alles precies zoals live: korte adressen (/about),
  doorsturen van .html-adressen en het menu.

  Makkelijkst:  dubbelklik op "Website lokaal bekijken.cmd" in de projectmap.
                Dat start deze server en opent de site in je browser.

  Handmatig:    powershell -File tools\serve.ps1          (alleen de server)
                powershell -File tools\serve.ps1 -Open    (server + browser)
  Daarna:       http://localhost:8080/
  Stoppen:      het venster sluiten, of Ctrl+C
#>

param(
  [int]$Port = 8080,
  [switch]$Open
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$url  = "http://localhost:$Port/"

$mime = @{
  ".html"="text/html; charset=utf-8"; ".css"="text/css; charset=utf-8"
  ".js"="application/javascript; charset=utf-8"; ".json"="application/json"
  ".jpg"="image/jpeg"; ".jpeg"="image/jpeg"; ".png"="image/png"
  ".svg"="image/svg+xml"; ".webp"="image/webp"; ".avif"="image/avif"
  ".xml"="application/xml"; ".txt"="text/plain; charset=utf-8"
  ".ico"="image/x-icon"
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
try {
  $listener.Start()
} catch {
  # Draait er al een testserver op deze poort (bijvoorbeeld een venster dat nog
  # open staat)? Open dan gewoon de site, in plaats van te stoppen met een fout.
  $running = $false
  try {
    $req = [System.Net.WebRequest]::Create($url)
    $req.Proxy = $null
    $req.Timeout = 3000
    $req.GetResponse().Close()
    $running = $true
  } catch { }
  if (-not $running) { throw }
  Write-Output "Er draait al een testserver op $url"
  if ($Open) { Start-Process $url }
  exit 0
}

Write-Output "Serveert $root op $url"
Write-Output "Laat dit venster open zolang je de site bekijkt. Sluiten = server stoppen."
if ($Open) { Start-Process $url }

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

    # Adressen zonder .html afhandelen zoals GitHub Pages dat doet: /about
    # serveert about.html. Zo test je lokaal precies wat er live gebeurt.
    if (-not (Test-Path $full -PathType Leaf) -and -not [System.IO.Path]::GetExtension($full)) {
      if (Test-Path "$full.html" -PathType Leaf) { $full = "$full.html" }
    }

    # Verbindingen niet openhouden: deze server verwerkt één verzoek tegelijk,
    # en wachtende keep-alive-sockets laten de pagina onnodig lang leeg staan.
    $ctx.Response.KeepAlive = $false

    try {
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
    } catch [System.Net.HttpListenerException] {
      # De browser heeft het verzoek halverwege afgebroken, bijvoorbeeld omdat de
      # pagina doorstuurt naar een ander adres. Negeren en doorgaan, anders stopt
      # de hele server.
      try { $ctx.Response.Abort() } catch { }
    }
  }
} finally {
  $listener.Stop()
  $listener.Close()
}
