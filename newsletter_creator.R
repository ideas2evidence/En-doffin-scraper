#NYHETSBREV-LAGER

#dette scriptet lager og sender et nyhetsbrev

#forbedringspunkter
#erstatte mailR med anna pakka. her er ei liste med alternativ: https://mailtrap.io/blog/r-send-email/
#kontrollere analysen over tid. Får jeg med alt, eller gjør navnebytter det lite sammenliknbart?

#bibliotek
library(rmarkdown) #for rapporten, rapporten laster ogs? egne bibliotek
#library(mailR) #for mail, krever Java
#library(config) #for henting av eksternt - og lokalt - lagra data

#filnavn
filnavn = paste0("Doffin_rapport_",as.character(Sys.Date()), ".html")

#kjører rmarkdown::render i xfun for å ha et rein miljø (uten får en en del output i viewer, ikke html-dokumentet)
#jf. https://bookdown.org/yihui/rmarkdown-cookbook/rmarkdown-render.html

#periode-parameteret angir hvor mange dager bakover i tid søket går. standard er siste uke - 7 

#knytt
xfun::Rscript_call(
  rmarkdown::render,
  list(input = 'report_test.Rmd', 
       output_format = 'html_document',
       output_dir = 'rapporter',
       output_file = filnavn,
       params = list(
         periode = 7
       )
       )
)


#henter innloggingsinfo fra eksternt og lokalt lagra sted#
#dw = config::get(file = "../config/config.yml")

#per august etter oppgradering til R 4.2.0 funker ikke dette lenger
#https://github.com/rpremrajGit/mailR/issues/8

#send epost
# send.mail(from = "automatisk.rapportering@gmail.com",
#           to = c("eivind.hageberg@ideas2evidence.com", "oivind.skjervheim@ideas2evidence.com", "inger.nordhagen@ideas2evidence.com"),
#           replyTo = "eivind.hageberg@ideas2evidence.com",
#           subject = "Siste 7 dagers relevante kunngjøringer på Doffin",
#           body = "Se vedlagte HTML-dokument for en automatisk generert oversikt. Send gjerne reaksjoner og innspill til eivind.hageberg@ideas2evidence.com.",
#           attach.files = paste0("rapporter/",filnavn),
#           smtp = list(host.name = dw$automatisk_rapportering$host.name, 
#                       port = dw$automatisk_rapportering$port, 
#                       user.name = dw$automatisk_rapportering$user.name, 
#                       passwd = dw$automatisk_rapportering$pwd, 
#                       ssl = TRUE),
#           authenticate = TRUE,
#           send = TRUE)