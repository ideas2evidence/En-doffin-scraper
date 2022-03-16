# En Doffin-scraper 

Noe enkel R-kode for � s�ke p� [Doffin.no](https://doffin.no/) etter ulike oppf�ringer og formatere funnene som et nyhetsbrev,

*Inneholder:*

- [En kort proof-of-concept](poc_kort_doffin_scraper.md) som gjennomg�r hvordan innhold fra doffin.no hentes ut.
- [Et script](doffin_scraper_script.R) som har de n�dvendige funksjonene og kj�rer dem.
- [En Rmd-fil som har det samme som scriptet, men formaterer det litt penere for lesing](report_test.Rmd). Et eksempel p� en slik rapport ligger <a href="https://rawcdn.githack.com/ideas2evidence/En-doffin-scraper/74ff77f6a1cb36f37ca0186c11bcd6c51fd038ac/rapporter/Doffin_rapport_2022-03-14.html" target = "_blank">her borte.</a>
- [Et annet script](newsletter_creator.R) som kj�rer den automatiske rapporten, og sender den p� epost til predefinerte mottakere. 