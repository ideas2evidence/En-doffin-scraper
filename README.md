# Noe kode for bruk av Doffins API (v003)

Noe enkel R-kode for å søke på [Doffin.no](https://doffin.no/) etter ulike oppføringer og formatere funnene som et nyhetsbrev. 

Benytter seg av [Doffins produksjons-API] (https://dof-notices-prod-api.developer.azure-api.net/apis). API-et inneholder to endepunkt - Notices og Public, der det første er for publisering av konkurranser, og det andre for å søke og laste ned konkurranser. Vi bruker sistnevnte. Se https://github.com/anskaffelser/eforms-sdk-nor for mer informasjon. 

Koden gjennomgås i en kort [proof-of-concept](poc_api_nye_doffin.md), som viser hvordan innhold fra nye doffin.no hentes ut.

I tillegg kan det være verdt å nevne at Doffin nå har fått sin egen [datavisualiserings-portal](https://www.doffin.no/data). De har også lagt ut komplette datasett over utlysninger for tidligere år.

## Utviklingsmuligheter
- Mer feilhåndtering.

## Tidligere versjoner

I tidligere versjoner har dette basert seg på webscraping og på å benytte samme API som produksjon. Nå er det et offisielt og stuerent API.

*Versjon 002 - udokumentert API* 
- [En proof-of-concept](old_api_doffin/poc_scraper_nye_doffin.md) som gjennomgår hvordan innhold fra nye doffin.no hentes ut.

*Versjon 001 - webscraper* 
- [En kort proof-of-concept](old_doffin/poc_kort_doffin_scraper.md) som gjennomgår hvordan innhold fra doffin.no hentes ut.
- [Et script](old_doffin/doffin_scraper_script.R) som har de nødvendige funksjonene og kjører dem.
- [En Rmd-fil som har det samme som scriptet, men formaterer det litt penere for lesing](old_doffin/report_test.Rmd). Et eksempel på en slik rapport ligger <a href="https://rawcdn.githack.com/ideas2evidence/En-doffin-scraper/74ff77f6a1cb36f37ca0186c11bcd6c51fd038ac/rapporter/Doffin_rapport_2022-03-14.html" target = "_blank">her borte.</a>
- [Et annet script](old_doffin/newsletter_creator.R) som kjører den automatiske rapporten, og sender den på epost til predefinerte mottakere. 
- [Et eksempel på en analyse](old_doffin/poc_doffin_analyse.md) - eller i hvert fall noen enkle grafer.

