#FUNKSJONER FOR DOFFIN-SCRAPING

#biblioteker
library(tidyverse)
library(rvest) #scrape-pakke
library(janitor)

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