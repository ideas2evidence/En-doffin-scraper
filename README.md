# En Doffin-scraper 

Noe enkel R-kode for å søke på [Doffin.no](https://doffin.no/) etter ulike oppføringer og formatere funnene som et nyhetsbrev. 

Har påbegynt en oppdatering for å tilpasse scriptene til nye doffin, hvor det blant annet finnes et API, og data kan hentes ut uten webscraping. Etter første 1-måneds-opphold-uten-å-kjøre-koden var det imidlertid flere ting som ga litt uventa resultater, så det må undersøkes nærmere.

*Inneholder:*

- [En proof-of-concept](poc_scraper_nye_doffin.md) som gjennomgår hvordan innhold fra nye doffin.no hentes ut.

*Gammel versjon inneholder* 
- [En kort proof-of-concept](old_doffin/poc_kort_doffin_scraper.md) som gjennomgår hvordan innhold fra doffin.no hentes ut.
- [Et script](old_doffin/doffin_scraper_script.R) som har de nødvendige funksjonene og kjører dem.
- [En Rmd-fil som har det samme som scriptet, men formaterer det litt penere for lesing](old_doffin/report_test.Rmd). Et eksempel på en slik rapport ligger <a href="https://rawcdn.githack.com/ideas2evidence/En-doffin-scraper/74ff77f6a1cb36f37ca0186c11bcd6c51fd038ac/rapporter/Doffin_rapport_2022-03-14.html" target = "_blank">her borte.</a>
- [Et annet script](old_doffin/newsletter_creator.R) som kjører den automatiske rapporten, og sender den på epost til predefinerte mottakere. 
- [Et eksempel på en analyse](old_doffin/poc_doffin_analyse.md) - eller i hvert fall noen enkle grafer.

*Videre utviklingsmuligheter*: 
- Mer feilhåndtering.