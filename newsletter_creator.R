#NYHETSBREV-LAGER

#dette scriptet lager og sender et nyhetsbrev

#bibliotek
library(rmarkdown) #for rapporten, rapporten laster ogs� egne bibliotek
library(mailR) #for mail, krever Java
library(config) #for henting av eksternt - og lokalt - lagra data

#filnavn
filnavn = paste0("Doffin_rapport_",as.character(Sys.Date()), ".html")

#f�rste fors�k
#render(input = "report_test.Rmd", output_format = "html_document")
#gir en del output fra siste chunk i viewer, ikke html-dokumentet. det er jo feil?
#leser meg opp på https://bookdown.org/yihui/rmarkdown-cookbook/rmarkdown-render.html
#det var noe med miljøet, og at jeg bør kjøre det fra et reint miljø?
#knytt
xfun::Rscript_call(
  rmarkdown::render,
  list(input = 'report_test.Rmd', 
       output_format = 'html_document',
       output_dir = 'rapporter',
       output_file = filnavn)
)



send.mail(from = "automatisk.rapportering@gmail.com",
          to = c("eivind.hageberg@ideas2evidence.com", "oivind.skjervheim@ideas2evidence.com", "inger.nordhagen@ideas2evidence.com"),
          replyTo = "eivind.hageberg@ideas2evidence.com",
          subject = "Siste 7 dagers relevante kunngjøringer på Doffin",
          body = "Se vedlagte HTML-dokument for en automatisk generert oversikt. Send gjerne reaksjoner og innspill til eivind.hageberg@ideas2evidence.com.",
          attach.files = paste0("rapporter/",filnavn),
          smtp = list(host.name = dw$automatisk_rapportering$host.name, 
                      port = dw$automatisk_rapportering$port, 
                      user.name = dw$automatisk_rapportering$user.name, 
                      passwd = dw$automatisk_rapportering$pwd, 
                      ssl = TRUE),
          authenticate = TRUE,
          send = TRUE)