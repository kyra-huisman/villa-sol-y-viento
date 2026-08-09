<#
  Voegt canonical-, hreflang-, Open Graph- en Twitter-tags toe aan alle pagina's.

  Idempotent: bestaande blokken worden vervangen, dus opnieuw uitvoeren is veilig.
  Voer dit uit nadat je een pagina hebt toegevoegd of de domeinnaam wijzigt.
#>

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$site = "https://villasolyviento.com"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$startMark = "<!-- seo:start -->"
$endMark   = "<!-- seo:end -->"

# file => @{ canonical; en; nl; locale; ogType; imgAlt }
$pages = @(
  @{ file="index.html";       canonical="/";                  en="/";                  nl="/nl/";                 locale="en_GB"; imgAlt="Villa Sol y Viento seen from the garden, with palm trees and mountains behind" },
  @{ file="about.html";       canonical="/about.html";        en="/about.html";        nl="/nl/about.html";       locale="en_GB"; imgAlt="Villa Sol y Viento seen from the garden" },
  @{ file="pictures.html";    canonical="/pictures.html";     en="/pictures.html";     nl="/nl/pictures.html";    locale="en_GB"; imgAlt="Villa Sol y Viento seen from the garden" },
  @{ file="book.html";        canonical="/book.html";         en="/book.html";         nl="/nl/book.html";        locale="en_GB"; imgAlt="Villa Sol y Viento seen from the garden" },
  @{ file="nl\index.html";    canonical="/nl/";               en="/";                  nl="/nl/";                 locale="nl_NL"; imgAlt="Villa Sol y Viento gezien vanuit de tuin, met palmbomen en bergen erachter" },
  @{ file="nl\about.html";    canonical="/nl/about.html";     en="/about.html";        nl="/nl/about.html";       locale="nl_NL"; imgAlt="Villa Sol y Viento gezien vanuit de tuin" },
  @{ file="nl\pictures.html"; canonical="/nl/pictures.html";  en="/pictures.html";     nl="/nl/pictures.html";    locale="nl_NL"; imgAlt="Villa Sol y Viento gezien vanuit de tuin" },
  @{ file="nl\book.html";     canonical="/nl/book.html";      en="/book.html";         nl="/nl/book.html";        locale="nl_NL"; imgAlt="Villa Sol y Viento gezien vanuit de tuin" }
)

foreach ($p in $pages) {
    $path = Join-Path $root $p.file
    $html = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

    # Eerder toegevoegd blok weghalen zodat dit script herhaalbaar is
    $pattern = [regex]::Escape($startMark) + "(?s).*?" + [regex]::Escape($endMark) + "\r?\n?"
    $html = [regex]::Replace($html, $pattern, "")

    # Titel en omschrijving overnemen uit de pagina zelf
    $title = ([regex]::Match($html, '<title>(.*?)</title>')).Groups[1].Value
    $desc  = ([regex]::Match($html, '<meta name="description" content="(.*?)"')).Groups[1].Value

    $hasOgTitle = $html -match 'property="og:title"'
    $hasOgDesc  = $html -match 'property="og:description"'
    $hasOgType  = $html -match 'property="og:type"'

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine($startMark)
    [void]$sb.AppendLine("<link rel=""canonical"" href=""$site$($p.canonical)""/>")
    [void]$sb.AppendLine("<link rel=""alternate"" hreflang=""en"" href=""$site$($p.en)""/>")
    [void]$sb.AppendLine("<link rel=""alternate"" hreflang=""nl"" href=""$site$($p.nl)""/>")
    [void]$sb.AppendLine("<link rel=""alternate"" hreflang=""x-default"" href=""$site$($p.en)""/>")
    if (-not $hasOgType)  { [void]$sb.AppendLine("<meta property=""og:type"" content=""website""/>") }
    if (-not $hasOgTitle) { [void]$sb.AppendLine("<meta property=""og:title"" content=""$title""/>") }
    if (-not $hasOgDesc)  { [void]$sb.AppendLine("<meta property=""og:description"" content=""$desc""/>") }
    [void]$sb.AppendLine("<meta property=""og:url"" content=""$site$($p.canonical)""/>")
    [void]$sb.AppendLine("<meta property=""og:site_name"" content=""Villa Sol y Viento""/>")
    [void]$sb.AppendLine("<meta property=""og:locale"" content=""$($p.locale)""/>")
    [void]$sb.AppendLine("<meta property=""og:image"" content=""$site/images/social-share.jpg""/>")
    [void]$sb.AppendLine("<meta property=""og:image:width"" content=""1200""/>")
    [void]$sb.AppendLine("<meta property=""og:image:height"" content=""630""/>")
    [void]$sb.AppendLine("<meta property=""og:image:alt"" content=""$($p.imgAlt)""/>")
    [void]$sb.AppendLine("<meta name=""twitter:card"" content=""summary_large_image""/>")
    [void]$sb.AppendLine($endMark)

    $html = $html -replace '</head>', ($sb.ToString() + "</head>")
    [System.IO.File]::WriteAllText($path, $html, $utf8NoBom)
    Write-Output "Bijgewerkt: $($p.file)"
}
