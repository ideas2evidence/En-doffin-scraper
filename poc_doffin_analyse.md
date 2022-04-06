POC - Doffin-analyse
================

-   [Henter data ved hjelp av skraper-funksjonene og litt
    looping](#henter-data-ved-hjelp-av-skraper-funksjonene-og-litt-looping)
-   [Grunnleggende om datasettene](#grunnleggende-om-datasettene)
-   [Kontekst for FoU-prosjektene](#kontekst-for-fou-prosjektene)
    -   [Hvor mange konkurranser kunngjøres
        daglig/ukentlig?](#hvor-mange-konkurranser-kunngjøres-dagligukentlig)
    -   [Hvordan fordeler de seg mellom CPV-kodene? Hvor stor er oppdrag
        på
        FoU-CPVen?](#hvordan-fordeler-de-seg-mellom-cpv-kodene-hvor-stor-er-oppdrag-på-fou-cpven)
    -   [Hvem kunngjør?](#hvem-kunngjør)
    -   [Estimert verdi på kontraktene](#estimert-verdi-på-kontraktene)
-   [FoU-utlysninger mer spesifikt](#fou-utlysninger-mer-spesifikt)
    -   [Når lyses prosjektene ut?](#når-lyses-prosjektene-ut)
    -   [Lengde på frister](#lengde-på-frister)
    -   [Antall oppdrag etter oppdragsgiver (de største
        )](#antall-oppdrag-etter-oppdragsgiver-de-største-)
    -   [Estimert totalverdi](#estimert-totalverdi)

``` r
#biblioteker
library(tidyverse)
```

    ## Warning: package 'tidyverse' was built under R version 4.1.3

    ## -- Attaching packages --------------------------------------- tidyverse 1.3.1 --

    ## v ggplot2 3.3.5     v purrr   0.3.4
    ## v tibble  3.1.6     v dplyr   1.0.7
    ## v tidyr   1.1.4     v stringr 1.4.0
    ## v readr   2.1.1     v forcats 0.5.1

    ## -- Conflicts ------------------------------------------ tidyverse_conflicts() --
    ## x dplyr::filter() masks stats::filter()
    ## x dplyr::lag()    masks stats::lag()

``` r
library(knitr)
library(rvest)
```

    ## 
    ## Attaching package: 'rvest'

    ## The following object is masked from 'package:readr':
    ## 
    ##     guess_encoding

``` r
library(janitor)
```

    ## 
    ## Attaching package: 'janitor'

    ## The following objects are masked from 'package:stats':
    ## 
    ##     chisq.test, fisher.test

``` r
library(lubridate)
```

    ## 
    ## Attaching package: 'lubridate'

    ## The following objects are masked from 'package:base':
    ## 
    ##     date, intersect, setdiff, union

``` r
library(readxl)
library(i2eR)
library(i2eplot)
```

    ## 
    ## Attaching package: 'i2eplot'

    ## The following object is masked from 'package:graphics':
    ## 
    ##     barplot

``` r
#støttefunksjoner
source("scripts/scraper_functions.R")  

#valg
options(scipen = 100)
tema = theme_set(theme_i2e())

#Hvis et kurrant datasett eksisterer, bruk det  istedet for å laste inn alt mulig.
df_fou <- read_delim("data/doffin_foucpv_17032020-17032022.csv", delim = ";", escape_double = FALSE, trim_ws = TRUE)
```

    ## Rows: 852 Columns: 13

    ## -- Column specification --------------------------------------------------------
    ## Delimiter: ";"
    ## chr  (7): doffin_referanse, navn, publisert_av, kunngjoring_type, lenke, cpv...
    ## dbl  (4): estimert_totalverdi, kunngjort_uke, kunngjort_år, fristlengde
    ## date (2): kunngjoring_dato, tilbudsfrist_dato

    ## 
    ## i Use `spec()` to retrieve the full column specification for this data.
    ## i Specify the column types or set `show_col_types = FALSE` to quiet this message.

``` r
df_alle <- read_delim("data/doffin_alle_19022022-19032022.csv", delim = ";", escape_double = FALSE, 
                      col_types = cols(kunngjoring_dato = col_date(format = "%Y-%m-%d"),
                                       tilbudsfrist_dato = col_date(format = "%Y-%m-%d"),
                                       cpv = col_character()), 
                      trim_ws = TRUE)

#støttedata

#CPV-koder
#gjør også trestrukturen litt mer eksplisitt for oppsummeringsformål
cpv_koder = read_excel("input/cpv_2008_ver_2013.xlsx", col_types = c("text", "text", "skip")) %>%
  separate(., CODE, into =c("cpv", NA), sep = 8) %>% #tar vekk nr. 9, som er en verifikasjonskode
  separate(., cpv, into = c("cpv_divisjon", NA), sep = 2, remove = FALSE) %>%
  separate(., cpv, into = c("cpv_gruppe", NA), sep = 3, remove = FALSE) %>%
  separate(., cpv, into = c("cpv_klasse", NA), sep = 4, remove = FALSE) %>%
  separate(., cpv, into = c("cpv_kategori", NA), sep = 5, remove = FALSE)

cpv_divisjon = select(cpv_koder, cpv_divisjon, DA) %>%
  distinct(cpv_divisjon, .keep_all = TRUE)
```

# Henter data ved hjelp av skraper-funksjonene og litt looping

``` r
#DEL 1 - CPV 73000000

#Henter først ut data for CPV 73000000 
#for de siste to år (30 dager av gangen)
#kun kunngjøringer av konkurranser
#inkluderer også utgåtte konkurranser

cpv_oppslag = "73000000"

resultater = data.frame()

#beregner hvor mange 30 dagers perioder jeg trenger mellom i dag og en anna dato
lengde = ceiling(as.numeric(difftime(as.Date(Sys.Date()), as.Date("17.03.2020", "%d.%m.%Y"), units = "days")) / 30)

for(i in 0:lengde){
  #lager dato
  tildato = format((Sys.Date() - (30*i)), "%d.%m.%Y")
  fradato = format((Sys.Date() - (30*(i+1))), "%d.%m.%Y")
  
  #lager URL for spørring
  url = doffin_url_builder(
    NoticeType = "2",
    Cpvs = cpv_oppslag,
    PublishedFromDate = fradato, 
    PublishedToDate = tildato,
    IncludeExpired = "true"
  )
  temp_resultater = doffin_fetch_results_long(url)
  resultater = bind_rows(resultater, temp_resultater)
}
```

``` r
#fjerner litt overflødig tekst

resultater = mutate(resultater,
              doffin_referanse = str_remove(doffin_referanse, fixed("Doffin referanse: ")),
              publisert_av = str_remove(publisert_av, fixed("\r Publisert av:\r ")),
              publisert_av = str_remove_all(publisert_av, fixed("\r")),
              kunngjoring_type = str_remove(kunngjoring_type, fixed("Kunngjøringstype: ")),
              kunngjoring_dato = str_remove(kunngjoring_dato, fixed("Kunngjøringsdato: "))
              )
```

``` r
##slår opp ytterligere informasjon om de jeg har

#NB! før neste kjøring, fiks NA i xpath for sum/verdi
##denne xpathen ser ut til å feile og finne teksten "Denne anskaffelsen er delt opp i delkontrakter:"  i noen tilfeller?
#eksempler som ikke funker
#/Notice/Details/2022-303150 - har ikke info om beløp
#/Notice/Details/2022-359995 - har ikke info om beløp
#/Notice/Details/2020-359116 - har ikke info om beløp
#bør jeg da også legge inn en sjekk av at det jeg finner, faktisk er et beløp?
#evt bare den uparsa tekststrengen? 


#NB! Kan ta veldig lang tid å kjøre, avhengig av antallet treff fra over!
for(i in 1:nrow(resultater)){
  mer_info <- read_html(paste0("https://doffin.no", resultater[i,7]))
  
  temp_cpv = html_element(mer_info, xpath = "//*[@id='notice']/div[3]/div[2]/div[5]/div/span") %>%
    html_text2()
  if(length(temp_cpv) > 0){
    resultater$cpv[i] = temp_cpv
  }
  if(length(temp_cpv) == 0){
    resultater$cpv[i] = NA
  }
  
  temp_beskrivelse = html_element(mer_info, xpath = "//*[@id='notice']/div[3]/div[2]/div[9]/div") %>%
    html_text2()
  if(length(temp_beskrivelse) > 0){
    resultater$beskrivelse[i] = temp_beskrivelse
  }
  if(length(temp_beskrivelse) == 0){
    resultater$beskrivelse[i] = NA
  }
  
  #denne xpathen ser ut til å feile og finne teksten "Denne anskaffelsen er delt opp i delkontrakter:"  i noen tilfeller?
  temp_sum = html_element(mer_info, xpath = "//*[@id='notice']/div[3]/div[2]/div[11]") %>%
    html_text2() %>%
    #punktum som punktum lager problemer, må fjernes (tror disse bare kommer som inkl og ekskl)
    str_remove(., fixed("ekskl.")) %>% 
    str_remove(., fixed("inkl.")) %>%
    parse_number()
  
  
  if(length(temp_sum) > 0){
    resultater$estimert_totalverdi[i] = temp_sum
  }
  if(length(temp_sum) == 0){
    resultater$estimert_totalverdi[i] = NA
  }
  
  Sys.sleep(2)
}
```

``` r
#er det duplikater her, på doffin-nummeret?
test = get_dupes(df, doffin_referanse)
test = get_dupes(df, doffin_referanse, kunngjoring_dato, beskrivelse, fristlengde)
test = get_dupes(df)

#det kan det fort være
#usikker på hva det skyldes - kan det være rettelser?
#de har helt like datoer, beskrivelser,
#eller kan det være datooverlapp fra spørringen?
```

``` r
#litt databearbeidelse

#i fravær av en grunn, slettes dupliakter
df = distinct(df, .keep_all = TRUE)

df = mutate(resultater,
            kunngjoring_dato = as.Date(kunngjoring_dato),
            tilbudsfrist_dato = as.Date(tilbudsfrist_dato),
            kunngjort_uke = week(kunngjoring_dato),
            kunngjort_år = year(kunngjoring_dato),
            fristlengde = as.numeric(difftime(tilbudsfrist_dato, kunngjoring_dato, units = "days")),
            #får en del usannsynlige frister som sannsynligvis er feil her
            fristlengde = ifelse(fristlengde > 200, NA, fristlengde)
              )
```

``` r
#lagrer datasettet
write_excel_csv2(df, "data/funn_stort_datasett.csv")
```

``` r
#DEL 2 - ALLE UTLYSNINGER
#den siste måneden

resultater = data.frame()

#beregner hvor mange 7 dagers perioder jeg trenger mellom i dag og en anna dato
lengde = ceiling(as.numeric(difftime(as.Date(Sys.Date()), as.Date("19.02.2022", "%d.%m.%Y"), units = "days")) / 7)

for(i in 0:lengde){
  #lager dato
  tildato = format((Sys.Date() - (7*i)), "%d.%m.%Y")
  fradato = format((Sys.Date() - (7*(i+1))), "%d.%m.%Y")
  
  #lager URL for spørring
  url = doffin_url_builder(
    NoticeType = "2",
    PublishedFromDate = fradato, 
    PublishedToDate = tildato,
    IncludeExpired = "true"
  )
  temp_resultater = doffin_fetch_results_long(url)
  resultater = bind_rows(resultater, temp_resultater)
}

#fjerner overflødig tekst
resultater = mutate(resultater,
              doffin_referanse = str_remove(doffin_referanse, fixed("Doffin referanse: ")),
              publisert_av = str_remove(publisert_av, fixed("\r Publisert av:\r ")),
              publisert_av = str_remove_all(publisert_av, fixed("\r")),
              kunngjoring_type = str_remove(kunngjoring_type, fixed("Kunngjøringstype: ")),
              kunngjoring_dato = str_remove(kunngjoring_dato, fixed("Kunngjøringsdato: "))
              )

#beriker med beløp og CPV

for(i in 1:nrow(resultater)){
  mer_info <- read_html(paste0("https://doffin.no", resultater[i,7]))
  
  temp_cpv = html_element(mer_info, xpath = "//*[@id='notice']/div[3]/div[2]/div[5]/div/span") %>%
    html_text2()
  if(length(temp_cpv) > 0){
    resultater$cpv[i] = temp_cpv
  }
  if(length(temp_cpv) == 0){
    resultater$cpv[i] = NA
  }

  #denne xpathen ser ut til å feile og finne teksten "Denne anskaffelsen er delt opp i delkontrakter:"  i noen tilfeller? kanskje særlig der beløpet ikke er nevnt? Men gir na da.
  temp_sum = html_element(mer_info, xpath = "//*[@id='notice']/div[3]/div[2]/div[11]") %>%
    html_text2() %>%
    #punktum som punktum lager problemer, må fjernes (tror disse bare kommer som inkl og ekskl)
    str_remove(., fixed("ekskl.")) %>% 
    str_remove(., fixed("inkl.")) %>%
    parse_number()
  
  
  if(length(temp_sum) > 0){
    resultater$estimert_totalverdi[i] = temp_sum
  }
  if(length(temp_sum) == 0){
    resultater$estimert_totalverdi[i] = NA
  }
  message("resultat nr. ", i)
  Sys.sleep(2)
}

test = get_dupes(resultater)

#litt databearbeidelse

#i fravær av en grunn, slettes dupliakter
df = distinct(resultater, .keep_all = TRUE)

df = mutate(df,
            kunngjoring_dato = as.Date(kunngjoring_dato),
            tilbudsfrist_dato = as.Date(tilbudsfrist_dato),
            kunngjort_uke = week(kunngjoring_dato),
            kunngjort_år = year(kunngjoring_dato),
            fristlengde = as.numeric(difftime(tilbudsfrist_dato, kunngjoring_dato, units = "days")),
            #får en del usannsynlige frister som sannsynligvis er feil her
            fristlengde = ifelse(fristlengde > 200, NA, fristlengde),
            kunngjort_ukedag = wday(kunngjoring_dato, label = TRUE)
            )
#lagrer
write_excel_csv2(df, "data/doffin_alle_19022022-19032022.csv")
```

# Grunnleggende om datasettene

Her har vi:

-   1 165 kunngjorte konkurranser med alle CPV-koder, fra 19. februar
    2022 til 19. mars 2022.
-   852 kunngjorte konkurranser med CPV-koden 73000000 - Forskning og
    utvikling, fra 17. mars 2020 til 17. mars 2022.

``` r
glimpse(df_alle)
```

    ## Rows: 1,165
    ## Columns: 13
    ## $ doffin_referanse    <chr> "2022-315368", "2022-353584", "2022-399746", "2022~
    ## $ navn                <chr> "Oppdrag innen kommunikasjon og strategier for Øst~
    ## $ publisert_av        <chr> "ØSTFOLD AVFALLSSORTERING IKS", "Movar Iks", "SYKE~
    ## $ kunngjoring_type    <chr> "Kunngjøring av konkurranse", "Kunngjøring av konk~
    ## $ kunngjoring_dato    <date> 2022-03-19, 2022-03-19, 2022-03-19, 2022-03-19, 2~
    ## $ tilbudsfrist_dato   <date> 2022-04-29, 2022-04-29, 2022-04-21, 2022-04-19, 2~
    ## $ lenke               <chr> "/Notice/Details/2022-315368", "/Notice/Details/20~
    ## $ cpv                 <chr> "79340000", "90513700", "38000000", "66114000", "2~
    ## $ estimert_totalverdi <dbl> 65000000, 80000000, NA, 100000000, 40000000, 72000~
    ## $ kunngjort_uke       <dbl> 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12~
    ## $ kunngjort_år        <dbl> 2022, 2022, 2022, 2022, 2022, 2022, 2022, 2022, 20~
    ## $ fristlengde         <dbl> 41, 41, 33, 31, 34, 33, 46, 34, 31, 37, 46, 34, 37~
    ## $ kunngjort_ukedag    <chr> "lør\\.", "lør\\.", "lør\\.", "lør\\.", "lør\\.", ~

``` r
glimpse(df_fou)
```

    ## Rows: 852
    ## Columns: 13
    ## $ doffin_referanse    <chr> "2022-313886", "2022-364984", "2022-389096", "2022~
    ## $ navn                <chr> "Evaluering av reglene om konkurransebegrensende a~
    ## $ publisert_av        <chr> "Arbeids- og inkluderingsdepartementet", "Nærings-~
    ## $ kunngjoring_type    <chr> "Kunngjøring av konkurranse", "Kunngjøring av konk~
    ## $ kunngjoring_dato    <date> 2022-03-17, 2022-03-17, 2022-03-16, 2022-03-15, 2~
    ## $ tilbudsfrist_dato   <date> 2022-04-21, 2022-04-20, 2022-04-25, 2022-03-30, 2~
    ## $ lenke               <chr> "/Notice/Details/2022-313886", "/Notice/Details/20~
    ## $ cpv                 <chr> "73000000", "72221000", "73200000", "73200000", "7~
    ## $ beskrivelse         <chr> "Arbeids- og inkluderingsdepartementet ønsker å in~
    ## $ estimert_totalverdi <dbl> 1500000, 1500000, 400000, 300000, 550000, NA, 5000~
    ## $ kunngjort_uke       <dbl> 11, 11, 11, 11, 11, 11, 11, 11, 10, 10, 10, 9, 9, ~
    ## $ kunngjort_år        <dbl> 2022, 2022, 2022, 2022, 2022, 2022, 2022, 2022, 20~
    ## $ fristlengde         <dbl> 35, 34, 40, 15, 51, 30, 44, 30, 28, 28, 29, 27, 53~

# Kontekst for FoU-prosjektene

## Hvor mange konkurranser kunngjøres daglig/ukentlig?

``` r
#dato
temp = group_by(df_alle, kunngjoring_dato) %>%
  summarise(antall = n())

#ggplot(data = temp) +
#  geom_line(aes(x = kunngjoring_dato, y = antall))

lineplot(data = temp, aes(x = kunngjoring_dato, y = antall)) +
  labs(title = "Antall kunngjøringer pr. dag siste måned", y = "Antall", x = "Dato")
```

![](poc_doffin_analyse_files/figure-gfm/unnamed-chunk-10-1.png)<!-- -->

``` r
#ukedag
temp = group_by(df_alle, kunngjort_ukedag) %>%
  summarise(antall = n())

#ggplot(data = temp) +
#  geom_col(aes(x = kunngjort_ukedag, y = antall))

barplot(data = temp, aes(x = kunngjort_ukedag, y = antall, label = antall), flip = FALSE, ylim = c(0, 250)) +
  labs(title = "Antall kunngjøringer pr. ukedag")
```

![](poc_doffin_analyse_files/figure-gfm/unnamed-chunk-10-2.png)<!-- -->

``` r
#uke
temp = group_by(df_alle, kunngjort_uke) %>%
  summarise(antall = n())

ggplot(data = temp) +
  geom_col(aes(x = kunngjort_uke, y = antall))
```

![](poc_doffin_analyse_files/figure-gfm/unnamed-chunk-10-3.png)<!-- -->

## Hvordan fordeler de seg mellom CPV-kodene? Hvor stor er oppdrag på FoU-CPVen?

CPV-kodefordelinga er veldig høyreskjeiv - de aller-aller fleste kodene
er kun benytta 1 gang som hovedkode den siste måneden

``` r
#teller opp etter cpv-kode
temp = group_by(df_alle, cpv) %>%
  summarise(antall = n()) %>%
  left_join(., select(cpv_koder, cpv, cpv_divisjon, DA), by = c("cpv" = "cpv")) %>%
  arrange(desc(antall))

summary(temp$antall)
```

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##   1.000   1.000   1.000   2.142   2.000  72.000

``` r
tabell = slice_max(temp, order_by = antall, n = 20)
knitr::kable(tabell, caption = "20 mest brukte CPV-koder siste måneden")
```

| cpv      | antall | cpv_divisjon | DA                                                                               |
|:---------|-------:|:-------------|:---------------------------------------------------------------------------------|
| 45000000 |     72 | 45           | Bygge- og anlægsarbejder                                                         |
| 45231300 |     19 | 45           | Arbejder i forbindelse med vand- og kloakrørledninger                            |
| 72000000 |     19 | 72           | It-tjenester: rådgivning, programmeludvikling, internet og support               |
| 33100000 |     17 | 33           | Medicinsk udstyr                                                                 |
| 63712200 |     17 | 63           | Drift af hovedveje                                                               |
| 90620000 |     17 | 90           | Snerydning                                                                       |
| 73000000 |     16 | 73           | Forsknings- og udviklingsvirksomhed og hermed beslægtet konsulentvirksomhed      |
| 38000000 |     15 | 38           | Laboratorieudstyr, optisk udstyr og præcisionsudstyr (ikke briller)              |
| 45422000 |     12 | 45           | Tømrer- og snedkerarbejde                                                        |
| 45233222 |     11 | 45           | Vejbelægningsarbejde                                                             |
| 60000000 |      9 | 60           | Transporttjenester (ikke affaldstransport)                                       |
| 72220000 |      9 | 72           | Konsulentvirksomhed i forbindelse med systemer og teknik                         |
| 90911000 |      9 | 90           | Rengøring af boliger, bygninger og vinduer                                       |
| 33140000 |      8 | 33           | Medicinske forbrugsmaterialer                                                    |
| 79411100 |      8 | 79           | Rådgivning i forbindelse med virksomhedsudvikling                                |
| 34144710 |      7 | 34           | Læssemaskiner på hjul                                                            |
| 43261000 |      7 | 43           | Skovlgravemaskiner                                                               |
| 45233300 |      7 | 45           | Funderingsarbejde i forbindelse med anlæg af hovedveje, veje, gader og gangstier |
| 60100000 |      7 | 60           | Vejtransport                                                                     |
| 60120000 |      7 | 60           | Taxikørsel                                                                       |
| 71000000 |      7 | 71           | Arkitekt-, konstruktions-, ingeniør- og inspektionsvirksomhed                    |
| 73200000 |      7 | 73           | Konsulentvirksomhed inden for forskning og udvikling                             |
| 80590000 |      7 | 80           | Eneundervisning                                                                  |

20 mest brukte CPV-koder siste måneden

``` r
#teller opp etter cpv-divisjon
temp = group_by(temp, cpv_divisjon) %>%
  summarise(antall = sum(antall, na.rm = TRUE)) %>%
  left_join(., cpv_divisjon) %>%
  arrange(desc(antall))
```

    ## Joining, by = "cpv_divisjon"

``` r
tabell = slice_max(temp, order_by = antall, n = 20)
knitr::kable(tabell, caption = "20 mest brukte CPV-divisjoner siste måneden")
```

| cpv_divisjon | antall | DA                                                                                                         |
|:-------------|-------:|:-----------------------------------------------------------------------------------------------------------|
| 45           |    320 | Bygge- og anlægsarbejder                                                                                   |
| 79           |     83 | Forretningstjenesteydelser: forskrifter, markedsføring, rådgivning, rekruttering, trykning og sikkerhed    |
| 71           |     81 | Arkitekt-, konstruktions-, ingeniør- og inspektionsvirksomhed                                              |
| 90           |     67 | Tjenesteydelser i forbindelse med spildevand, affald, rengøring og miljøbeskyttelse                        |
| 72           |     65 | It-tjenester: rådgivning, programmeludvikling, internet og support                                         |
| 34           |     55 | Transportudstyr og transporthjælpemidler                                                                   |
| 33           |     53 | Medicinsk udstyr, lægemidler og produkter til personlig pleje                                              |
| 60           |     37 | Transporttjenester (ikke affaldstransport)                                                                 |
| 50           |     32 | Reparations- og vedligeholdelsestjenester                                                                  |
| 73           |     32 | Forsknings- og udviklingsvirksomhed og hermed beslægtet konsulentvirksomhed                                |
| 38           |     27 | Laboratorieudstyr, optisk udstyr og præcisionsudstyr (ikke briller)                                        |
| 39           |     22 | Inventar (inkl. kontorinventar), boligudstyr, husholdningsapparater (ekskl. belysning) og rengøringsmidler |
| 63           |     22 | Hjælpevirksomhed i forbindelse med transport; rejsebureauvirksomhed                                        |
| 80           |     20 | Uddannelse og undervisning                                                                                 |
| 44           |     19 | Byggekonstruktioner og -materialer; andre byggevarer (undtagen elapparatur)                                |
| 85           |     18 | Sundhedsvæsen og sociale foranstaltninger                                                                  |
| 48           |     17 | Programpakker og informationssystemer                                                                      |
| 42           |     16 | Industrimaskiner                                                                                           |
| 55           |     12 | Tjenester i forbindelse med hotel, restaurant og detailhandel                                              |
| 77           |     12 | Tjenesteydelser i forbindelse med landbrug, skovbrug, havebrug, akvakultur og biavl                        |

20 mest brukte CPV-divisjoner siste måneden

``` r
ggplot(data = temp) +
  geom_histogram(aes(x = antall), binwidth = 2)
```

![](poc_doffin_analyse_files/figure-gfm/unnamed-chunk-11-1.png)<!-- -->

CPV-kodene har et hierarkisk forhold.

## Hvem kunngjør?

``` r
temp = group_by(df_alle, publisert_av) %>%
  summarise(antall = n()) %>%
  arrange(desc(antall))

tabell = slice_max(temp, order_by = antall, n = 20)
knitr::kable(tabell)
```

| publisert_av                                   | antall |
|:-----------------------------------------------|-------:|
| SYKEHUSINNKJØP HF                              |     66 |
| Statens vegvesen                               |     35 |
| TROMS OG FINNMARK FYLKESKOMMUNE                |     28 |
| STATSBYGG                                      |     25 |
| Tromsø kommune                                 |     21 |
| Forsvarsbygg                                   |     20 |
| Bærum kommune                                  |     14 |
| INNLANDET FYLKESKOMMUNE                        |     14 |
| Universitetet i Oslo                           |     14 |
| ARBEIDS- OG VELFERDSETATEN                     |     13 |
| Oslo kommune v/ Vann- og avløpsetaten          |     13 |
| Vestland fylkeskommune                         |     13 |
| Nordland fylkeskommune                         |     12 |
| Bane NOR SF                                    |     11 |
| KRISTIANSAND KOMMUNE                           |     11 |
| Norges miljø- og biovitenskapelige universitet |     11 |
| Rogaland Fylkeskommune                         |     11 |
| Verdal Kommune                                 |     11 |
| AVINOR AS                                      |     10 |
| Forsvaret v/Forsvarets logistikkorganisasjon   |     10 |
| Hå kommune                                     |     10 |
| Trondheim kommune                              |     10 |
| Trøndelag fylkeskommune                        |     10 |

## Estimert verdi på kontraktene

Forventer topper rundt terskelverdi

``` r
temp = filter(df_alle, is.na(estimert_totalverdi) == FALSE)

#disse tallene er alt for store. har komma slått feil ut?
```

# FoU-utlysninger mer spesifikt

## Når lyses prosjektene ut?

``` r
#dato
temp = group_by(df_fou, kunngjoring_dato) %>%
  summarise(antall_kunngjøringer = n())

#blir alt for smått
#ggplot(data = temp) +
#  geom_line(aes(x = kunngjoring_dato, y = antall_kunngjøringer))

#uke
temp = group_by(df_fou, kunngjort_år, kunngjort_uke) %>%
  summarise(antall_kunngjøringer = n())
```

    ## `summarise()` has grouped output by 'kunngjort_år'. You can override using the `.groups` argument.

``` r
ggplot(data = temp) +
  geom_point(aes(x = kunngjort_uke, y = antall_kunngjøringer, colour = as.factor(kunngjort_år))) +
  geom_smooth(aes(x = kunngjort_uke, y = antall_kunngjøringer)) +
  scale_x_continuous(breaks = seq(from = 0, to = 52, by = 4), minor_breaks = NULL) +
  labs(x = "Uke", y = "Antall kunngjøringer i uka", colour = "Kunngjort år", title = "Kunngjøringer av FoU-prosjekter på Doffin etter uke", 
       subtitle = "Alle FoU-kunngjøringer 2 siste år")
```

    ## `geom_smooth()` using method = 'loess' and formula 'y ~ x'

![](poc_doffin_analyse_files/figure-gfm/unnamed-chunk-14-1.png)<!-- -->

``` r
ggplot(data = temp, aes(x = kunngjort_uke, y = antall_kunngjøringer, colour = as.factor(kunngjort_år))) +
  geom_point() +
  geom_smooth(se = FALSE) +
  scale_x_continuous(breaks = seq(from = 0, to = 52, by = 4), minor_breaks = NULL) +
  scale_y_continuous(limits = c(0, 15)) +
  labs(x = "Uke", y = "Antall kunngjøringer i uka", colour = "Kunngjort år", title = "Kunngjøringer av FoU-prosjekter på Doffin etter uke", 
       subtitle = "Alle FoU-kunngjøringer 2 siste år")
```

    ## `geom_smooth()` using method = 'loess' and formula 'y ~ x'

    ## Warning: Removed 3 rows containing non-finite values (stat_smooth).

    ## Warning: Removed 3 rows containing missing values (geom_point).

![](poc_doffin_analyse_files/figure-gfm/unnamed-chunk-14-2.png)<!-- -->

## Lengde på frister

``` r
summary(df_fou$fristlengde)
```

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
    ##    8.00   23.00   31.00   32.92   37.00  113.00      21

``` r
ggplot(data = df_fou, aes(x = fristlengde)) +
  geom_histogram(binwidth = 1) +
  labs(title = "Tid fra kunngjøring til frist for leveranse", subtitle = "Alle cpv 73000000-utlysninger på doffin fra 17. mars 2020 til 17. mars 2022",
       x = "Antall dager", y = "Antall utlysninger"
       )
```

    ## Warning: Removed 21 rows containing non-finite values (stat_bin).

![](poc_doffin_analyse_files/figure-gfm/unnamed-chunk-15-1.png)<!-- -->

## Antall oppdrag etter oppdragsgiver (de største )

``` r
temp = group_by(df_fou, publisert_av) %>%
  summarise(
    antall_oppdrag = n()
  )

summary(temp$antall_oppdrag)
```

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##   1.000   1.000   2.000   4.415   4.000  74.000

``` r
ggplot(data = temp, aes(x = antall_oppdrag)) +
  geom_histogram(binwidth = 1)
```

![](poc_doffin_analyse_files/figure-gfm/unnamed-chunk-16-1.png)<!-- -->

``` r
tabell = slice_max(temp, antall_oppdrag, n = 20)
knitr::kable(tabell)
```

| publisert_av                                         | antall_oppdrag |
|:-----------------------------------------------------|---------------:|
| Kommunal- og moderniseringsdepartementet             |             74 |
| Barne-, ungdoms- og familiedirektoratet              |             39 |
| Integrerings- og mangfoldsdirektoratet (IMDi)        |             39 |
| Norges forskningsråd                                 |             36 |
| Utdanningsdirektoratet                               |             36 |
| Norges vassdrags- og energidirektorat (NVE)          |             26 |
| Norad – Direktoratet for utviklingssamarbeid         |             24 |
| Statens vegvesen                                     |             21 |
| Arbeids- og sosialdepartementet                      |             17 |
| Kunnskapsdepartementet                               |             15 |
| Miljødirektoratet                                    |             15 |
| Samferdselsdepartementet                             |             15 |
| Direktoratet for forvaltning og økonomistyring (DFØ) |             14 |
| Nærings- og fiskeridepartementet                     |             14 |
| Husbanken                                            |             11 |
| Møre og Romsdal Fylkeskommune                        |             11 |
| Universitetet i Oslo                                 |             11 |
| Utlendingsdirektoratet - UDI                         |             11 |
| Justis- og beredskapsdepartementet                   |             10 |
| SYKEHUSINNKJØP HF                                    |             10 |

``` r
#og etter år
temp = group_by(df_fou, kunngjort_år, publisert_av) %>%
  summarise(
    antall_oppdrag = n()
  ) %>%
  pivot_wider(names_from = kunngjort_år, values_from = antall_oppdrag)
```

    ## `summarise()` has grouped output by 'kunngjort_år'. You can override using the `.groups` argument.

``` r
tabell = slice_max(temp, `2022`, n = 10)
knitr::kable(tabell)
```

| publisert_av                                         | 2020 | 2021 | 2022 |
|:-----------------------------------------------------|-----:|-----:|-----:|
| Kommunal- og distriktsdepartementet                  |   NA |   NA |    8 |
| Integrerings- og mangfoldsdirektoratet (IMDi)        |    8 |   24 |    7 |
| Norges forskningsråd                                 |   17 |   15 |    4 |
| Arbeids- og inkluderingsdepartementet                |   NA |    1 |    3 |
| Barne-, ungdoms- og familiedirektoratet              |   17 |   20 |    2 |
| Direktoratet for forvaltning og økonomistyring (DFØ) |    3 |    9 |    2 |
| Nærings- og fiskeridepartementet                     |    3 |    9 |    2 |
| Samferdselsdepartementet                             |    5 |    8 |    2 |
| Statens vegvesen                                     |    9 |   10 |    2 |
| Utdanningsdirektoratet                               |   14 |   20 |    2 |
| Nordland fylkeskommune                               |   NA |    3 |    2 |
| Kultur- og likestillingsdepartementet                |   NA |   NA |    2 |

## Estimert totalverdi

``` r
summary(df_fou$estimert_totalverdi)
```

    ##      Min.   1st Qu.    Median      Mean   3rd Qu.      Max.      NA's 
    ##         1    700000   1262500  13071727   3212500 900000000       236

``` r
temp = filter(df_fou, is.na(estimert_totalverdi) == FALSE)

ggplot(data = temp) +
  geom_histogram(aes(x = estimert_totalverdi), binwidth = 500000)
```

![](poc_doffin_analyse_files/figure-gfm/unnamed-chunk-17-1.png)<!-- -->
