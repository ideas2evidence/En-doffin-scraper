En kort proof-of-concept for en scraper for nye Doffin
================

- [Bakgrunn](#bakgrunn)
- [Hvordan løse dette](#hvordan-løse-dette)
- [Hvordan ser dette API-et ut?](#hvordan-ser-dette-api-et-ut)
  - [Endepunkter](#endepunkter)
  - [Obsobs - er det lov?](#obsobs---er-det-lov)
  - [Endepunkt for Søk](#endepunkt-for-søk)
  - [Suggest-APIet](#suggest-apiet)
  - [Enkeltkunngjøring](#enkeltkunngjøring)
  - [Annen informasjon](#annen-informasjon)

Målet er å lage en webscraper som kan hente data fra Doffin om relevante
utlysninger.

### Gjenstående ting å se på

# Bakgrunn

[Doffin](https://www.doffin.no/) er den nasjonale kunngjøringsdatabasen
for offentlige anskaffelser på doffin.no . Høsten 2023 kom den i ny
drakt, med nytt utseende - og viktigere for scrape-formål, ny struktur
og et nytt API.

Use-casene er fortsatt de samme:

- Det kan også potensielt være verdi å kunne se statistikk over omfanget
  av utlysninger etter ulike parametre (som. f.eks. om det er spesielle
  måneder hvor det lyses ut spesielt mye FoU-prosjekter, om det er
  aktører som i større eller mindre grad bruker Doffin (og dermed heller
  bruker andre anskaffelseskanaler).
- For å holde seg oppdatert på aktuelle kunngjøringer, kan det være en
  fordel å med jevne mellomrom få varslinger om nye kunngjøringer.
- Det kan også være nyttig å kunne sette opp abonnementer på relativt
  komplekse søk (f.eks. etter flere oppdragsgivere en kjenner godt,
  mange mindre oppdragsgivere som publiserer sjeldnere og dermed lettere
  går under radaren).

Selve Doffin-nettsida tilbyr i dag lite som passer slikt. Doffin er kun
en database og et web-grensesnitt for å søke i databasen. De overlater
til tredjepartsleverandører, som Mercell, å tilby tjenester som dekker
dette.

# Hvordan løse dette

I forrige utgave kunne en konstruere søk på nettsida med å sette sammen
søke-parameter i en URL, og så finne de ønska delene fra HTML-sidene med
xpath og css-selektorer. Denne gangen ser det derimot ut til å være et
API i bakkant, som en kan POSTe spørringer til. Dermed trenger vi disse
bibliotekene:

``` r
#biblioteker
suppressPackageStartupMessages(library(tidyverse))
```

    ## Warning: package 'ggplot2' was built under R version 4.3.3

``` r
library(httr2)
library(jsonlite)
```

    ## 
    ## Attaching package: 'jsonlite'

    ## The following object is masked from 'package:purrr':
    ## 
    ##     flatten

``` r
suppressPackageStartupMessages(library(janitor)) #for den hendige get_dupes()-funksjonen
library(robotstxt) #for å spørre om jeg får lov til å skrape
```

    ## Warning: package 'robotstxt' was built under R version 4.3.3

``` r
#settings
options(scipen = 999)
```

Her har det også skjedd en nyvinning i form av
[httr2-pakken](https://httr2.r-lib.org/), som erstatter httr-pakken.

# Hvordan ser dette API-et ut?

## Endepunkter

Etter hva jeg kan se, er det - ett endepunkt for POST av søk.
(<https://dof-search-notices-prod-app.azurewebsites.net/search>) -
endepunkt for hver enkelt kunngjøring, GET
(<https://dof-notices-prod-app.azurewebsites.net/api/dof/notices/>) -
endepunkt for cpv-koder, GET
(<https://dof-notices-prod-app.azurewebsites.net/api/dof/codes/cpvCodes>) -
endepunkter som gir forslag dynamisk (suggest), mindre nyttig for meg?
<https://dof-search-notices-prod-app.azurewebsites.net/search/suggest>

## Obsobs - er det lov?

Før en stuper inn i det, er det et par ting som må avklares:

- Tillater brukerbetingelsene for Doffin at vi bruker innholdet?

Det ser ikke ut til å være noen brukerbetingelser for bruk av nettsida
eller API.

- Tillater nettsida at vi bruker en robot for å skrape ut innholdet?

En av flere guider er
[her](https://stevenmortimer.com/scraping-responsibly-with-r/), som
anbefaler
[robotstxt-pakka](https://cran.r-project.org/web/packages/robotstxt/vignettes/using_robotstxt.html).
Her kan en teste enkelt-stier i robots.txt-fila på nettsida, og se om
det er tillatt for roboter å aksessere den. Jeg sjekker for et generelt
søkeresultat og en enkelt kunngjøring:

``` r
#kan jeg bare hente robotstxt og se hva som står der?

rt = get_robotstxt("https://www.doffin.no")
rt 
```

    ## [robots.txt]
    ## --------------------------------------
    ## 
    ## # https://www.robotstxt.org/robotstxt.html
    ## User-agent: *
    ## Disallow:

``` r
#er det noen spesifikke paths som ikke er allowed her? 
#for en søkeside
paths_allowed(
  paths = "https://dof-search-notices-prod-app.azurewebsites.net/search",
  domain = "doffin.no",
  bot = "*"
)
```

    ##  doffin.no

    ## [1] TRUE

``` r
#for en spesifikk kunngjøring
paths_allowed(
  paths = "https://www.doffin.no/notices/2024-103605",
  domain = "doffin.no",
  bot = "*"
)
```

    ##  doffin.no

    ## [1] TRUE

``` r
#APIet for en spesfikk kunngjøring
paths_allowed(
  paths = "https://dof-notices-prod-app.azurewebsites.net/api/dof/notices/2023-675241",
  domain = "doffin.no",
  bot = "*"
)
```

    ##  doffin.no

    ## [1] TRUE

``` r
#APIet for suggest
paths_allowed(
  paths = "https://dof-search-notices-prod-app.azurewebsites.net/search/suggest",
  domain = "doffin.no",
  bot = "*"
)
```

    ##  doffin.no

    ## [1] TRUE

Test-spørringene returnerer SANN, og det bør derfor være tillatt.

## Endepunkt for Søk

Et enkelt søk på “integrering”, gjøres med en POST til
“<https://dof-search-notices-prod-app.azurewebsites.net/search>”. POST
tar følgende argumenter, i JSON-format:

{ “numHitsPerPage”:20, “page”:1, “searchString”:“integrering”,
“sortBy”:“RELEVANCE”, “facets”: {“cpvCode”: {“checkedItems”:\[\]},
“type”: {“checkedItems”:\[“COMPETITION”\]}, “status”:
{“checkedItems”:\[“ACTIVE”\]}, “contractNature”: {“checkedItems”:\[\]},
“issueDate”: {“from”:null,“to”:null}, “location”: {“checkedItems”:\[\]},
“buyer”: {“checkedItems”:\[\]}, “winner”: {“checkedItems”:\[\]}} }

Det er verdt å merke seg JSON-strukturen her: de fire første elementene
er “singletons”, dvs. sett med 1 element. De andre er derimot arrays.

Her har vi følgende argumenter

- numHitsPerPage (på nettsida er dette angitt som 20, 50, 100 eller 200,
  men jeg ser at jeg også kan spesifisere denne til 2000 og få 343 treff
  tilbake.
- page. sidetallet som returneres, numerisk.
- searchString : søkestreng
- sortBy: hvordan resultatet skal sorteres, tar argumentene RELEVANCE,
  ISSUE_DAT_DESC, ISSUE_DAT_ASC, DEADLINE.

Under facets finner vi følgende - cpvCode: \[8-sifra CPV-koder\] - type:
– COMPETITION \[kan erstattes av ANNOUNCEMENT_OF_COMPETITION,
DYNAMIC_PURCHASING_SCHEME\], – PLANNING \[kan erstattes av
ADVISORY_NOTICE eller\], – RESULT \[kan erstattes av
ANNOUNCEMENT_OF_INTENT, ANNOUNCEMENT_OF_CONCLUSION_OF_CONTRACT,
CANCELLED_OR_MISSING_CONCLUSION_OF_CONTRACT\] - status (ACTIVE, EXPIRED)
(Men merk - ikke alle har en status, ser det ut til) – contractNature
(SERVICES, SUPPLIES, WORKS) – issueDate(from: YYYY-MM-DD, to:
YYYY-MM-DD, en dato kan erstattes av null) – location (lokasjonskoder
her) – buyer (her er oppdragsgivers navn inn - hvordan er disse kodet,
mon tro? Suggest returnerer ulike skrivemåter for IMDI, med ulikt antall
treff?) – winner

Prøver først helt basic med httr2.

``` r
#enkel variant
req_enkel = request(base_url = "https://dof-search-notices-prod-app.azurewebsites.net/search") |>
  req_body_json(data = list(
    searchString = "integrering",
    numHitsPerPage = 20,
    sortBy = "RELEVANCE",
    page = 1
  ))

#testkjører
req_enkel %>% req_dry_run()
```

    ## POST /search HTTP/1.1
    ## Host: dof-search-notices-prod-app.azurewebsites.net
    ## User-Agent: httr2/1.0.0 r-curl/5.2.0 libcurl/8.3.0
    ## Accept: */*
    ## Accept-Encoding: deflate, gzip
    ## Content-Type: application/json
    ## Content-Length: 80
    ## 
    ## {"searchString":"integrering","numHitsPerPage":20,"sortBy":"RELEVANCE","page":1}

``` r
#utfører spørringa
response = req_perform(req_enkel)

#ser på responsen

#status
resp_status(response)
```

    ## [1] 200

``` r
#innhold
resp_content_type(response)
```

    ## [1] "application/json"

``` r
#henter ut json-objektet som ble returnert
json = resp_body_json(response, flatten = FALSE, simplifyVector = TRUE)
```

Etter litt eksperimentering ser jeg at helt enkle forespørsler etter en
streng, med angivelse av antall treff, side og sortering går greit. Alle
variabler under facets får jeg imidlertid ikke angitt korrekt via
httr2::req_body_json, ettersom JSON-spørringen er enkelt formatert på
overordna nivå, dvs. ingen braketter, men standard-formatert under
facets med braketter også rundt arrays med kun ett element.

Dette kunne i teorien vært løst med en wrapper for formatering av
spørring. Men det er ikke helt utrivielt, ettersom en må paste sammen
mange forskjellige elementer, med korrekt parentes-angivelse, håndtere
manglende elementer, håndtere JSONs null-verdi…

``` r
#base-variant fra nettsida
query = '{
  "numHitsPerPage":20,
  "page":1,
  "searchString":"integrering",
  "sortBy":"RELEVANCE",
  "facets":
    {"cpvCode":
        {"checkedItems":[]},
      "type":
        {"checkedItems":["COMPETITION"]},
      "status":
        {"checkedItems":["ACTIVE"]},
      "contractNature":
        {"checkedItems":[]},
      "issueDate":
        {"from":null,"to":null},
      "location":
        {"checkedItems":[]},
      "buyer":
        {"checkedItems":[]},
      "winner":
        {"checkedItems":[]}}
  }'

req_base = request(base_url = "https://dof-search-notices-prod-app.azurewebsites.net/search") |>
  req_body_raw(body = query, type = "application/json")

#testkjører
req_base %>% req_dry_run()
```

    ## POST /search HTTP/1.1
    ## Host: dof-search-notices-prod-app.azurewebsites.net
    ## User-Agent: httr2/1.0.0 r-curl/5.2.0 libcurl/8.3.0
    ## Accept: */*
    ## Accept-Encoding: deflate, gzip
    ## Content-Type: application/json
    ## Content-Length: 503
    ## 
    ## {
    ##   "numHitsPerPage":20,
    ##   "page":1,
    ##   "searchString":"integrering",
    ##   "sortBy":"RELEVANCE",
    ##   "facets":
    ##     {"cpvCode":
    ##         {"checkedItems":[]},
    ##       "type":
    ##         {"checkedItems":["COMPETITION"]},
    ##       "status":
    ##         {"checkedItems":["ACTIVE"]},
    ##       "contractNature":
    ##         {"checkedItems":[]},
    ##       "issueDate":
    ##         {"from":null,"to":null},
    ##       "location":
    ##         {"checkedItems":[]},
    ##       "buyer":
    ##         {"checkedItems":[]},
    ##       "winner":
    ##         {"checkedItems":[]}}
    ##   }

``` r
#utfører spørringa
response = req_perform(req_base)

#ser på responsen

#status
resp_status(response)
```

    ## [1] 200

``` r
#innhold
resp_content_type(response)
```

    ## [1] "application/json"

``` r
#henter ut json-objektet som ble returnert
json = resp_body_json(response, flatten = FALSE, simplifyVector = TRUE)
```

Etter en kikk i dokumentasjonen for httr2::req_body_json, ser jeg at det
er jsonlite::toJSON som gjør arbeidet med å omforme listene til JSON.
Dokumentasjonen av auto_unbox foreslår at en enten wrapper det som ikke
skal unboxes i I(), eller det som skal unboxes i unbox().

``` r
req_kompleks = request(base_url = "https://dof-search-notices-prod-app.azurewebsites.net/search") |>
  req_body_json(data = list(
    searchString = unbox("integrering"),
    numHitsPerPage = unbox(20),
    sortBy = unbox("RELEVANCE"),
    page = unbox(1),
    facets = list(
      type = list(
        checkedItems = ("COMPETITION")
      ),
      cpvCode = list(
        checkedItems = ("73100000")
      )
    )
  ),
  auto_unbox = FALSE
  )

#testkjører
req_kompleks %>% req_dry_run()
```

    ## POST /search HTTP/1.1
    ## Host: dof-search-notices-prod-app.azurewebsites.net
    ## User-Agent: httr2/1.0.0 r-curl/5.2.0 libcurl/8.3.0
    ## Accept: */*
    ## Accept-Encoding: deflate, gzip
    ## Content-Type: application/json
    ## Content-Length: 171
    ## 
    ## {"searchString":"integrering","numHitsPerPage":20,"sortBy":"RELEVANCE","page":1,"facets":{"type":{"checkedItems":["COMPETITION"]},"cpvCode":{"checkedItems":["73100000"]}}}

``` r
#utfører spørringa
response = req_perform(req_kompleks)

#ser på responsen

#status
resp_status(response)
```

    ## [1] 200

``` r
#innhold
resp_content_type(response)
```

    ## [1] "application/json"

``` r
#henter ut json-objektet som ble returnert
json = resp_body_json(response, flatten = FALSE, simplifyVector = TRUE)
```

Perfekt! Dette ser ut til å fungere som forventa. Det er litt tungvindt
å måtte huske og skrive ut strukturen for hver gang, hvis det blir mye
spørringer. Det at issueDate har null-verdier, mens de øvrige er tomme
lister, gjør meg litt skeptisk til å hive meg på å lage en
generalisering rundt det.

Kan jeg spørre om flere ulike buyers?

``` r
req_kompleks = request(base_url = "https://dof-search-notices-prod-app.azurewebsites.net/search") |>
  req_body_json(data = list(
    #searchString = unbox(""),
    numHitsPerPage = unbox(20),
    sortBy = unbox("RELEVANCE"),
    page = unbox(1),
    facets = list(
      type = list(
        checkedItems = ("COMPETITION")
      ),
      buyer = list(
        checkedItems = (c("Integrerings- og mangfoldsdirektoratet (IMDi)", "Integrerings- og mangfoldsdirektoratet", "Integrerings- og Mangfoldsdirektoratet"))
      )
    )
  ),
  auto_unbox = FALSE
  )

#testkjører
req_kompleks %>% req_dry_run()
```

    ## POST /search HTTP/1.1
    ## Host: dof-search-notices-prod-app.azurewebsites.net
    ## User-Agent: httr2/1.0.0 r-curl/5.2.0 libcurl/8.3.0
    ## Accept: */*
    ## Accept-Encoding: deflate, gzip
    ## Content-Type: application/json
    ## Content-Length: 259
    ## 
    ## {"numHitsPerPage":20,"sortBy":"RELEVANCE","page":1,"facets":{"type":{"checkedItems":["COMPETITION"]},"buyer":{"checkedItems":["Integrerings- og mangfoldsdirektoratet (IMDi)","Integrerings- og mangfoldsdirektoratet","Integrerings- og Mangfoldsdirektoratet"]}}}

``` r
#utfører spørringa
response = req_perform(req_kompleks)

#ser på responsen

#status
resp_status(response)
```

    ## [1] 200

``` r
#innhold
resp_content_type(response)
```

    ## [1] "application/json"

``` r
#henter ut json-objektet som ble returnert
json = resp_body_json(response, flatten = FALSE, simplifyVector = TRUE)

#df
#test = tidyr::unnest(json$hits, cols = c(locationId, estimatedValue), names_sep = c("_"),
#                     keep_empty = TRUE)
```

Jeg kan også hente informasjon om avgjorte konkurranser. Men jeg får
ikke informasjon om vinner i første resultat, da må jeg inn i hvert
enkelt utfall.

``` r
req_kompleks = request(base_url = "https://dof-search-notices-prod-app.azurewebsites.net/search") |>
  req_body_json(data = list(
    #searchString = unbox(""),
    numHitsPerPage = unbox(20),
    sortBy = unbox("RELEVANCE"),
    page = unbox(1),
    facets = list(
      type = list(
        checkedItems = ("RESULT")
      )
    )
  ),
  auto_unbox = FALSE
  )

#testkjører
req_kompleks %>% req_dry_run()
```

    ## POST /search HTTP/1.1
    ## Host: dof-search-notices-prod-app.azurewebsites.net
    ## User-Agent: httr2/1.0.0 r-curl/5.2.0 libcurl/8.3.0
    ## Accept: */*
    ## Accept-Encoding: deflate, gzip
    ## Content-Type: application/json
    ## Content-Length: 97
    ## 
    ## {"numHitsPerPage":20,"sortBy":"RELEVANCE","page":1,"facets":{"type":{"checkedItems":["RESULT"]}}}

``` r
#utfører spørringa
response = req_perform(req_kompleks)

#ser på responsen

#status
resp_status(response)
```

    ## [1] 200

``` r
#innhold
resp_content_type(response)
```

    ## [1] "application/json"

``` r
#henter ut json-objektet som ble returnert
json = resp_body_json(response, flatten = FALSE, simplifyVector = TRUE)

#df
#test = tidyr::unnest(json$hits, cols = c(locationId, estimatedValue), names_sep = c("_"),
#                     keep_empty = TRUE)
```

Så her er måten å hente alle utlysninger av konkurranser om
FoU-prosjekter siden 1. januar 2023 på:

``` r
  # "facets":
  #   {"cpvCode":
  #       {"checkedItems":[]},
  #     "type":
  #       {"checkedItems":["COMPETITION"]},
  #     "status":
  #       {"checkedItems":["ACTIVE"]},
  #     "contractNature":
  #       {"checkedItems":[]},
  #     "issueDate":
  #       {"from":null,"to":null},
  #     "location":
  #       {"checkedItems":[]},
  #     "buyer":
  #       {"checkedItems":[]},
  #     "winner":
  #       {"checkedItems":[]}}
  # }'

req_kompleks = request(base_url = "https://dof-search-notices-prod-app.azurewebsites.net/search") |>
  req_body_json(data = list(
    searchString = unbox(""),
    numHitsPerPage = unbox(500),
    sortBy = unbox("RELEVANCE"),
    page = unbox(1),
    facets = list(
      type = list(
        checkedItems = ("COMPETITION")
      ),
      issueDate = list(
        from = unbox("2023-01-01"),
        to = unbox("2024-03-01")
      ),
      cpvCode = list(
        checkedItems = ("73000000")
      )
    )
  ),
  auto_unbox = FALSE
  )

#testkjører
req_kompleks %>% req_dry_run()
```

    ## POST /search HTTP/1.1
    ## Host: dof-search-notices-prod-app.azurewebsites.net
    ## User-Agent: httr2/1.0.0 r-curl/5.2.0 libcurl/8.3.0
    ## Accept: */*
    ## Accept-Encoding: deflate, gzip
    ## Content-Type: application/json
    ## Content-Length: 213
    ## 
    ## {"searchString":"","numHitsPerPage":500,"sortBy":"RELEVANCE","page":1,"facets":{"type":{"checkedItems":["COMPETITION"]},"issueDate":{"from":"2023-01-01","to":"2024-03-01"},"cpvCode":{"checkedItems":["73000000"]}}}

``` r
#utfører spørringa
response = req_perform(req_kompleks)

#ser på responsen

#status
resp_status(response)
```

    ## [1] 200

``` r
#innhold
resp_content_type(response)
```

    ## [1] "application/json"

``` r
#henter ut json-objektet som ble returnert
json = resp_body_json(response, flatten = FALSE, simplifyVector = TRUE)
```

### Outputen

Her får jeg dataene strukturert og fint.

- numHitsTotal er antakelig totale treff
- numHitsAccessible er antakelig treff som kan hentes

``` r
json$numHitsTotal
```

    ## [1] 484

``` r
json$numHitsAccessible
```

    ## [1] 484

- hits er den spesifikke lista med treff. 10 treff ser ut til å være en
  standard, jeg økte det over til 500

``` r
#unnester det til en data-frame-struktur.
test = tidyr::unnest(json$hits, cols = c(buyer, locationId, estimatedValue), names_sep = c("_"),
                     keep_empty = TRUE)
glimpse(test)
```

    ## Rows: 534
    ## Columns: 15
    ## $ id                          <chr> "2024-103178", "2024-103152", "2024-103143…
    ## $ buyer_id                    <chr> "ef12b41586f05a8d8adb54d617bc729d", "bc539…
    ## $ buyer_organizationId        <chr> "971 032 146", "971278374", "987 879 696",…
    ## $ buyer_name                  <chr> "KS  (Kommunesektorens organisasjon)", "ST…
    ## $ heading                     <chr> "Gir helseteknologi forventede gevinster?"…
    ## $ description                 <chr> "KS utlyser med dette et FoU-prosjekt med …
    ## $ locationId                  <chr> "anyw-cou", "NO081", "anyw-cou", "anyw-cou…
    ## $ estimatedValue_currencyCode <chr> "NOK", NA, "NOK", "NOK", NA, "NOK", "NOK",…
    ## $ estimatedValue_amount       <dbl> 2200000, NA, 4000000, 4000000, NA, 1000000…
    ## $ type                        <chr> "ANNOUNCEMENT_OF_COMPETITION", "ANNOUNCEME…
    ## $ allTypes                    <list> <"ANNOUNCEMENT_OF_COMPETITION", "COMPETIT…
    ## $ status                      <chr> "EXPIRED", "EXPIRED", "EXPIRED", "EXPIRED"…
    ## $ issueDate                   <chr> "2024-03-01T13:22:57Z", "2024-03-01T12:22:…
    ## $ deadline                    <chr> "2024-03-22T11:00:00Z", "2024-04-04T08:00:…
    ## $ receivedTenders             <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…

CPV-kode mangler her.

Her har vi mye bra informasjon om utlysningene: - id er ID-en til
utlysninga - buyer_id ser ut som organisasjonsnummeret til kunngjører. -
buyer_name er navnet på kunngjører - heading er navnet på kunngjøring -
description er en kort beskrivelse av det som anskaffes - locationID er
sted - currencycode er valutakode - amount er verdien estimert - type -
ser ut som om det er en oppramsing av kunngjøringsform,

``` r
distinct(test, type)
```

    ## # A tibble: 3 × 1
    ##   type                       
    ##   <chr>                      
    ## 1 ANNOUNCEMENT_OF_COMPETITION
    ## 2 DYNAMIC_PURCHASING_SCHEME  
    ## 3 QUALIFICATION_SCHEME

- allTypes - litt usikker på hva denne gjør? Hvis jeg unnester den, blir
  det mye. Er det alle typer kunngjøringer som er gjort på en spesifikk
  kode?

``` r
distinct(unnest(test, cols = allTypes), allTypes)
```

    ## # A tibble: 4 × 1
    ##   allTypes                   
    ##   <chr>                      
    ## 1 ANNOUNCEMENT_OF_COMPETITION
    ## 2 COMPETITION                
    ## 3 DYNAMIC_PURCHASING_SCHEME  
    ## 4 QUALIFICATION_SCHEME

- status ser ut til å være om kunngjøringen er aktiv eller utgått.
  Kunngjøringer om resultat utgår ikke
- issuedDate - kunngjøringsdato
- deadline - frist for tilbud
- receivedTenders - antall innleverte tilbud, spesifikk for kunngjøring
  av resultat
- limitedDataFlag, usikker på denne
- doffinClassicUrl - antakelig det det står.

JSON-objektet har også en “facets”. Det kan være ulike egenskaper ved
treffene, ettersom det er en liste her med en rekke under-beskrivelser,
av status, type, locations, cpvCode, contractNature. Noen eksempler:

``` r
unnest(json$facets$status$items)
```

    ## Warning: `cols` is now required when using `unnest()`.
    ## ℹ Please use `cols = c()`.

    ## # A tibble: 4 × 2
    ##   id        total
    ##   <chr>     <int>
    ## 1 EXPIRED     435
    ## 2 AWARDED      18
    ## 3 ACTIVE       10
    ## 4 CANCELLED     2

``` r
unnest(json$facets$type$items)
```

    ## Warning: `cols` is now required when using `unnest()`.
    ## ℹ Please use `cols = c()`.

    ## # A tibble: 12 × 2
    ##    id                                          total
    ##    <chr>                                       <int>
    ##  1 COMPETITION                                   484
    ##  2 ANNOUNCEMENT_OF_COMPETITION                   478
    ##  3 RESULT                                        200
    ##  4 ANNOUNCEMENT_OF_CONCLUSION_OF_CONTRACT        145
    ##  5 PLANNING                                       58
    ##  6 ADVISORY_NOTICE                                57
    ##  7 ANNOUNCEMENT_OF_INTENT                         36
    ##  8 CANCELLED_OR_MISSING_CONCLUSION_OF_CONTRACT    17
    ##  9 CHANGE_OF_CONCLUSION_OF_CONTRACT                3
    ## 10 DYNAMIC_PURCHASING_SCHEME                       3
    ## 11 QUALIFICATION_SCHEME                            3
    ## 12 NOTICE_ON_BUYER_PROFILE                         1

``` r
unnest(json$facets$locations$items)
```

    ## Warning: `cols` is now required when using `unnest()`.
    ## ℹ Please use `cols = c()`.

    ## # A tibble: 21 × 2
    ##    id       total
    ##    <chr>    <int>
    ##  1 NO08       134
    ##  2 NO081      108
    ##  3 NO0         95
    ##  4 anyw-cou    56
    ##  5 NO0A        31
    ##  6 NO07        20
    ##  7 NO06        16
    ##  8 NO060       16
    ##  9 NO0A3       16
    ## 10 NO082       13
    ## # ℹ 11 more rows

``` r
#unnest(json$facets$cpvCode$items) - lager veldig mye styr.
unnest(json$facets$contractNature$items)
```

    ## Warning: `cols` is now required when using `unnest()`.
    ## ℹ Please use `cols = c()`.

    ## # A tibble: 3 × 2
    ##   id       total
    ##   <chr>    <int>
    ## 1 SERVICES   476
    ## 2 SUPPLIES     5
    ## 3 WORKS        2

Sorteringa følger automatisk samme som nettsida, dvs. sortBy “Relevance”
er automatisk med. Alle typer kunngjøringer er automatisk med.

## Suggest-APIet

En hovedutfordring er at de som kunngjører, bruker ulike navn. Søker jeg
på “IMDi” på doffin.no, uten andre filtre, får jeg 148 treff. Søker jeg
på “Integrerings- og mangfoldsdirektoratet (IMDi)” som “buyer”, får jeg
214 treff. Men det er andre buyer-søk som gir andre antall treff. Her er
det antakelig søk jeg kan sette opp.

Payloaden her er som så:

{“facets”: {“cpvCode”: {“checkedItems”:\[\]}, “type”:
{“checkedItems”:\[\]}, “status”: {“checkedItems”:\[\]},
“contractNature”: {“checkedItems”:\[\]}, “issueDate”:
{“from”:null,“to”:null}, “location”: {“checkedItems”:\[\]}, “buyer”:
{“checkedItems”:\[\]}, “winner”:{“checkedItems”:\[\]} },
“searchString”:“integrering”}

``` r
req_enkel = request(base_url = "https://dof-search-notices-prod-app.azurewebsites.net/search/suggest") |>
  req_body_json(data = list(
    searchString = "integrering"
  ))

#testkjører
req_enkel %>% req_dry_run()
```

    ## POST /search/suggest HTTP/1.1
    ## Host: dof-search-notices-prod-app.azurewebsites.net
    ## User-Agent: httr2/1.0.0 r-curl/5.2.0 libcurl/8.3.0
    ## Accept: */*
    ## Accept-Encoding: deflate, gzip
    ## Content-Type: application/json
    ## Content-Length: 30
    ## 
    ## {"searchString":"integrering"}

``` r
#utfører spørringa
response = req_perform(req_enkel)

#ser på responsen

#status
resp_status(response)
```

    ## [1] 200

``` r
#innhold
resp_content_type(response)
```

    ## [1] "application/json"

``` r
#henter ut json-objektet som ble returnert
json = resp_body_json(response, flatten = FALSE, simplifyVector = TRUE)

#henter data
temp = as.data.frame(json$buyer)
```

## Enkeltkunngjøring

## Annen informasjon

CPV-koder m.m.
