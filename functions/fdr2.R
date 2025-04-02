# function to read dataset characteristics, code from: https://github.com/EMODnet/EMODnet-Biology-Benthos_greater_North_Sea
fdr2<-function(dasid){
  datasetrecords <- datasets(dasid)
  dascitations <- getdascitations(datasetrecords)
  if(nrow(dascitations)==0)dascitations<-tibble(dasid=as.character(dasid),title="",citation="")
  if(nrow(dascitations)==1) if(is.na(dascitations$citation)) dascitations$citation<-""
  daskeywords <- getdaskeywords(datasetrecords)
  if(nrow(daskeywords)==0)daskeywords<-tibble(dasid=as.character(dasid),title="",keyword="")
  if(nrow(daskeywords)==1) if(is.na(daskeywords$keyword))daskeywords$keyword<-""
  dascontacts <- getdascontacts(datasetrecords)
  if(nrow(dascontacts)==0)dascontacts<-tibble(dasid=as.character(dasid),title="",contact="")
  if(nrow(dascontacts)==1) if(is.na(dascontacts$contact))dascontacts$contact<-""
  dastheme <- getdasthemes(datasetrecords)
  if(nrow(dastheme)==0)dastheme<-tibble(dasid=as.character(dasid),title="",theme="")
  if(nrow(dastheme)==1) if(is.na(dastheme$theme))dastheme$theme<-""
  dastheme2 <- aggregate(theme ~ dasid, data = dastheme, paste, 
                         collapse = " , ")
  daskeywords2 <- aggregate(keyword ~ dasid, data = daskeywords, 
                            paste, collapse = " , ")
  dascontacts2 <- aggregate(contact ~ dasid, data = dascontacts, 
                            paste, collapse = " , ")
  output <- dascitations %>% left_join(dascontacts2, by = "dasid") %>% 
    left_join(dastheme2, by = "dasid") %>% left_join(daskeywords2, 
                                                     by = "dasid")
  return(output)
}