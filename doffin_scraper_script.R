#DOFFIN-SCRAPER
#script som scraper doffin
#p.t. henter det ut kunngjorte konkurranser innen utvalgte CPV-er og for en liste med utvalgte kunder, som er kunngjort i løpet av siste uka og enda ikke utgått.

#biblioteker
library(tidyverse)
library(rvest) #scrape-pakke
library(janitor)


#parametre
fradato = format(Sys.Date() - 7, "%d.%m.%Y")
tildato = format(Sys.Date(), "%d.%m.%Y")
cpv_oppslag = "73000000+75110000+79300000+79400000+98342000"

#73000000 Forsknings- og utviklingsvirksomhet og tilhørende konsulenttjenester
    #73200000  -  Konsulentvirksomhet i forbindelse med forskning og utvikling
#75110000 - Allmenne offentlige tjenester
#79300000  -  Markeds- og økonomisk analyse; offentlig meningsmåling og statistikk
    #79310000  -  Market research services
        #79311200  -  Utførelse av undersøkelse
    #79330000  -  Statistiske tjenesteytelser
#79400000  -  Bedriftsrådgivning og administrativ rådgivning og beslektede tjenester
#98342000  -  Arbeidsmiljøtjenester

#funksjoner
#doffin_url_builder
#definerer funksjonen som en i utgangspunktet tom funksjon, kun sidenummer, antall resultater pr side, og sortering etter kunngjøringsdato. isadvancedsearch og includeexpired er false.
#CamelCase

#argumenter
#query: "Direktoratet+for+høyere+utdanning+og+kompetanse+(HK-dir)"',
#PageNumber: sidenummer, brukt over
#PageSize:  hvor mange treff pr side
#&OrderingType: 0 - relevans, 1 - kunngjøringsdato, 2 - tilbudsfrist, 3 - doffin-referanse, 4 - tittel, 5 - publisert av
#OrderingDirection:  0 - stigende, 1 - synkende
#RegionId:  div geokoder på regionnivå
#CountyId: div goekoder på flkenivå
#MunicipalityId. div geokoder på kommunenivå
#IsAdvancedSearch: true hvis du inkluderer overliggende regioner , false som standard
#location:  usikker på denne, kanskje en kombo av geokodene?
#NoticeType:  kunngjøringstype - blank = alle, 1 = veiledende, 2 = kunngjøring av konkurranse, 3 = tildeling, 4 = intensjonskunngjøring, 6 = kjøperprofil, 999999 = Dynamisk innkjøpsprofil.
#PublicationType: blank = alle, 1 = nasjonal, 2 = europeisk, 5 = market consulting
#IncludeExpired: #skal utgåtte inkluderes? true hvis ja, false hvis nei
#Cpvs: CPV-koder her - flere bindes sammen med + , eksempel: Cpvs=34000000+33000000
#EpsReferenceNr: Doffin referanse-nr.
#DeadlineFromDate; tilbudsfrist fra, formateres 01.01.2022 DD.MM.ÅÅÅÅ
#DeadlineToDate: tilbudsfrist til, formateres 01.02.2022
#PublishedFromDate: #kunngjøringsdato fra, formateres 01.02.2022
#PublishedToDate: #kunngjøringsdato til, formaters også 01.02.2022

doffin_url_builder = function(Query = "", PageNumber = "1", PageSize = "100", OrderingType = "1", OrderingDirection = "1", RegionId = "", CountyId = "", MunicipalityId = "", IsAdvancedSearch = "false", Location = "", NoticeType = "", PublicationType = "", IncludeExpired = "false", Cpvs = "", EpsReferenceNr = "", DeadlineFromDate = "", DeadlineToDate = "", PublishedFromDate = "", PublishedToDate = ""){
  temp_url = paste0("https://doffin.no/Notice?",
                    "query=", Query,
                    "&PageNumber=", PageNumber,
                    "&PageSize=", PageSize,
                    "&OrderingType=", OrderingType, 
                    "&OrderingDirection=", OrderingDirection, 
                    "&RegionId=", RegionId,
                    "&CountyId=", CountyId,
                    "&MunicipalityId=", MunicipalityId,
                    "&IsAdvancedSearch=", IsAdvancedSearch,
                    "&location=", Location,
                    "&NoticeType=", NoticeType,
                    "&PublicationType=", PublicationType,
                    "&IncludeExpired=", IncludeExpired,
                    "&Cpvs=", Cpvs,
                    "&EpsReferenceNr=", EpsReferenceNr,
                    "&DeadlineFromDate=", DeadlineFromDate,
                    "&DeadlineToDate=&", DeadlineToDate,
                    "PublishedFromDate=", PublishedFromDate,
                    "&PublishedToDate=", PublishedToDate
  )
}

#doffin_fetch_results
#en funksjon som tar en doffin-query-url som input, og returnerer resultatet som en data.frame
#basert på rvest-pakken

doffin_fetch_results = function(url){
  #henter html-fil
  temp_html = read_html(url)
  #henter ut kun utlysninger fra html-fila
  kun_utlysninger = html_elements(temp_html, 
                                  xpath = "//*[@id='content']/div/article[3]/div[@class = 'notice-search-item']")
  #setter sammen datasettet
  temp_df = data.frame(
    doffin_referanse = html_element(kun_utlysninger, 
                                    xpath = "div[@class = 'right-col']/div[1]") %>%
      html_text2(), 
    navn = html_element(kun_utlysninger, 
                        xpath = "div[@class = 'notice-search-item-header']/a[contains(@href, 'Notice')]") %>%
      html_text2(),
    publisert_av = html_element(kun_utlysninger, xpath = "div[@class = 'left-col']/div[1]") %>%
      html_text2(),
    kunngjoring_type = html_element(kun_utlysninger, xpath = "div[@class = 'left-col']/div[2]") %>%
      html_text2(), 
    kunngjoring_dato = html_element(kun_utlysninger, xpath = "div[@class = 'right-col']/div[last()]") %>%
      html_text2(), 
    tilbudsfrist_dato = html_element(kun_utlysninger, xpath = "div[@class = 'right-col']/div[2]/span") %>%
      html_text2(), 
    lenke = html_element(kun_utlysninger, 
                         xpath = "div[@class = 'notice-search-item-header']/a[contains(@href, 'Notice')]/@href") %>%
      html_text()
  )
}

#DEL 1 - CPV 

#lager URL for spørring
url = doffin_url_builder(
  NoticeType = "2",
  Cpvs = cpv_oppslag, 
  PublishedFromDate = fradato, 
  PublishedToDate = tildato
  )

#henter resultater
resultater = doffin_fetch_results(url)
resultater$`søk` = paste0("cpv: ", cpv_oppslag)

#DEL 2 - faste kunder

kunder = c(
  "Arbeids-+og+inkluderingsdepartementet",
  "NAV",
  "%22Barne-,+ungdoms-+og+familiedirektoratet%22",
  "Digitaliseringsdirektoratet",
  "Direktoratet+for+forvaltning+og+økonomistyring+(DFØ)",
  "%22Direktoratet+for+høyere+utdanning+og+kompetanse+(HK-dir)%22",
  "HK-dir",
  "Distriktssenteret",
  "Integrerings-+og+mangfoldsdirektoratet+(IMDi)",
  "Husbanken"
)

resultater_2 = data.frame()

for(i in 1:length(kunder)){
  url = doffin_url_builder(Query = kunder[i], 
                           NoticeType = "2",
                           PublishedFromDate = fradato, 
                           PublishedToDate = tildato)
  temp_resultater = doffin_fetch_results(url)
  if(nrow(temp_resultater) == 0){
    message("ingen funn for ", i, " - ", kunder[i])
  }
  if(nrow(temp_resultater) > 0){
    temp_resultater$`søk` = kunder[i]
    resultater_2 = bind_rows(resultater_2, temp_resultater)
    message("ferdig med ", i, ", ", kunder[i])
  }
  Sys.sleep(5)
}

#binder sammen
df = bind_rows(resultater, resultater_2)

#sjekker for duplikater på referansenr
test = get_dupes(df, doffin_referanse)

#hvis duplikater - legg inn en distinct her.
if(nrow(test) > 0){
  df = distinct(df, doffin_referanse, .keep_all = TRUE)
  message("fjernet ", nrow(test), " duplikater")
}

#slår opp ytterligere informasjon om de jeg har
for(i in 1:nrow(df)){
  mer_info <- read_html(paste0("https://doffin.no", df[i,7]))
  temp_cpv = html_element(mer_info, xpath = "//*[@id='notice']/div[3]/div[2]/div[5]/div/span") %>%
    html_text2()
  if(length(temp_cpv) > 0){
    df$cpv[i] = temp_cpv
  }
  if(length(temp_cpv) == 0){
    df$cpv[i] = NA
  }
  temp_beskrivelse = html_element(mer_info, xpath = "//*[@id='notice']/div[3]/div[2]/div[9]/div") %>%
    html_text2()
  if(length(temp_beskrivelse) > 0){
    df$beskrivelse[i] = temp_beskrivelse
  }
  if(length(temp_beskrivelse) == 0){
    df$beskrivelse[i] = NA
  }
  Sys.sleep(5)
}

#lagrer resultater som data.frame
write.csv(df, 
          paste0("/data/funn_", as.character(Sys.Date()), ".csv"),
          row.names = FALSE)

#rydder opp, beholder kun df, values, fn
rm(test, temp_resultater, resultater, resultater_2, mer_info)

