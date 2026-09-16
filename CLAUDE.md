# Villa Sol y Viento — projectinstructies

Statische website voor een vakantievilla in Mijas, Costa del Sol.
Live op **https://villasolyviento.com** via GitHub Pages (`CNAME` in de repo-root).

## Altijd controleren in de browser

**Na elke wijziging aan HTML, CSS of JavaScript controleer je het resultaat zelf
met de Claude in Chrome-plugin.** Niet alleen "de code ziet er goed uit" — echt
kijken naar de gerenderde pagina.

Vraag de gebruiker niet om te controleren wat je zelf kunt zien.

Wat de controle minimaal omvat:

1. **Open de pagina** die je hebt gewijzigd — lokaal via `tools\serve.ps1`
   (http://localhost:8080/), of de live site als het al gepusht is.
2. **Maak een screenshot en kijk ernaar.** Klopt de opmaak? Staat er niets
   overlappend, afgesneden of leeg?
3. **Test de interactie die je hebt aangeraakt.** Klik de knop, open de
   lightbox, gebruik de filtertabs, klap het mobiele menu uit.
4. **Controleer mobiel formaat** (ongeveer 390px breed) bij lay-outwijzigingen —
   daar gaat het het snelst mis.
5. **Lees de console** op fouten met `read_console_messages`.

Bij twijfel over laadgedrag of paginagewicht: gebruik `read_network_requests`.
Zo is eerder ontdekt dat de fotopagina 40 MB downloadde.

## Structuur

```
index.html  about.html  pictures.html                de vijf pagina's (Engels)
about-us.html  book.html
style.css  script.js                                 gedeeld door alle pagina's
Website lokaal bekijken.cmd                          dubbelklik: site lokaal openen
images/<categorie>/                                  originele foto's (~2200px)
images/thumbs/<categorie>/                           thumbnails (~700px)
tools/                                               onderhoudsscripts
```

De site is **alleen Engels**. De Nederlandse versie (`/nl/`) is verwijderd;
voeg geen tweede taal toe zonder overleg.

## Adressen zonder .html

Links, canonicals en de sitemap gebruiken de korte vorm: `/`, `/about`,
`/pictures`, `/about-us`, `/book` — nooit `about.html`. GitHub Pages serveert
`about.html` vanzelf op `/about`; `tools/serve.ps1` doet lokaal hetzelfde, zodat
je test wat er live gebeurt. Schrijf interne links dus als `href="/about"`.

De `.html`-bestanden zelf kunnen niet weg: `/about` werkt alléén doordat
`about.html` bestaat. Daardoor blijft `/about.html` ook bereikbaar. Een klein
script bovenin de `<head>` van elke pagina stuurt zo'n adres op een webserver
direct door naar de korte vorm (`/about.html` → `/about`, `/index.html` → `/`).
**Neem dat script over in elke nieuwe pagina.** Omzetten naar mappen
(`about/index.html`) lost het niet op: dan werkt `/about/index.html` nog steeds
en krijgen alle adressen een slash op het eind.

## Lokaal bekijken

De gebruiker bekijkt de site vóór publicatie zelf door te dubbelklikken op
**`Website lokaal bekijken.cmd`** in de projectmap. Dat start `tools\serve.ps1`
en opent http://localhost:8080/ in de browser; draait de server al, dan opent
het alleen de browser. Het bestand staat in de `exclude`-lijst van `_config.yml`.

Dubbelklikken op een losse pagina (file://) werkt ook. Het doorstuurscript slaat
file:// over (anders stuurt het door naar een bestand dat niet bestaat), en
`script.js` laat de interne links daar naar de bestanden wijzen (`/about` →
`about.html`). Test voor publicatie toch via de server: alleen die werkt
precies zoals de live site.

## Foto's

De gebruiker beheert de mappen in `images/<categorie>/` zelf: ze zet er nieuwe
foto's in, verplaatst ze tussen categorieën en verwijdert ze. Die mappen zijn
leidend. Als ze vraagt de site bij te werken naar "de foto's zoals ze er nu in
staan", synchroniseer je `pictures.html` daarmee.

- **Verklein of overschrijf niets in `images/<categorie>/` zonder te vragen.**
  Dat zijn de hoogste kwaliteit die er nog is; de lightbox en de downloadknop
  serveren ze rechtstreeks. De oorspronkelijke camerabestanden bestaan niet
  meer — wat hier staat is alles.
- Het raster toont thumbnails uit `images/thumbs/`; de `<figure>` verwijst via
  `data-full` naar het origineel.
- Geef nieuwe foto's een beschrijvende naam (`pool-steps.jpg`, niet
  `DSC09927.jpg`).

Na het toevoegen, verplaatsen of verwijderen van foto's:

```
powershell -File tools\optimize-originals.ps1 -WhatIf   # eerst kijken
powershell -File tools\optimize-originals.ps1           # ruwe foto's verkleinen
powershell -File tools\make-thumbnails.ps1              # thumbnails bijwerken
```

`optimize-originals.ps1` verkleint alleen foto's die groter zijn dan 2200px en
slaat de rest over, dus herhaald uitvoeren is veilig. Draai het pas ná overleg
als het om een bewust hoge-resolutiefoto gaat.

Overige scripts: `make-social-image.ps1` (deelafbeelding 1200×630),
`add-seo-tags.ps1` (canonical/hreflang/Open Graph, idempotent),
`serve.ps1` (lokale webserver om te testen vóór publicatie).

## Gereedschap op deze machine

Geen Node, Python of ImageMagick. Voor beeldbewerking is er PowerShell met
`System.Drawing`. AVIF kan `System.Drawing` niet lezen — gebruik daarvoor Chrome
als decoder (canvas → `toDataURL`).

## Toon en stijl

Warm, licht en zonnig — niet het donkerblauwe zakelijke uiterlijk van de
zustersite Superb Real Estate. Serif (Fraunces) voor koppen, Inter voor tekst.

Boekingen lopen bij voorkeur **rechtstreeks** via e-mail of WhatsApp. Airbnb
staat er alleen als link om de actuele beschikbaarheid te checken, op de
boekingspagina — niet als gelijkwaardig boekingskanaal, en niet in de footer.

## Wat wel en niet gepubliceerd wordt

GitHub Pages serveert standaard élk bestand in de repo — ook dit bestand en de
scripts in `tools/`. Daarom staat in `_config.yml` een `exclude`-lijst die
bepaalt wat er niet naar de webserver gaat.

**Voeg je een bestand toe dat niet publiek hoort te zijn** (documentatie,
scripts, notities), zet het dan in die lijst. Controleer na een push met
`curl -o /dev/null -w "%{http_code}" https://villasolyviento.com/<pad>` dat het
een 404 geeft.

## Live site

De site staat online. Wijzigingen zijn pas zichtbaar na commit en push naar
`origin/main`. **Commit of push niet uit jezelf** — vraag het eerst.
