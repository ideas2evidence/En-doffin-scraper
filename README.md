# En Doffin-scraper 

Noe enkel R-kode for å søke på [Doffin.no](https://doffin.no/) etter ulike oppføringer og formatere funnene som et nyhetsbrev,

*Inneholder:*

- [En kort proof-of-concept](poc_kort_doffin_scraper.md) som gjennomgår hvordan innhold fra doffin.no hentes ut.
- [Et script](doffin_scraper_script.R) som har de nødvendige funksjonene og kjører dem.
- [En Rmd-fil som har det samme som scriptet, men formaterer det litt penere for lesing](report_test.Rmd). Et eksempel på en slik rapport ligger <a href="https://rawcdn.githack.com/ideas2evidence/En-doffin-scraper/74ff77f6a1cb36f37ca0186c11bcd6c51fd038ac/rapporter/Doffin_rapport_2022-03-14.html" target = "_blank">her borte.</a>
- [Et annet script](newsletter_creator.R) som kjører den automatiske rapporten, og sender den på epost til predefinerte mottakere. 