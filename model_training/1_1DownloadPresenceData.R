# Loading the required packages

library(eurobis)
library(maptools)
library(dplyr)
library(sf)
library(maps)
library(ggplot2)
library(lubridate)
library(CoordinateCleaner)
library(arulesViz)
library(tidyverse)
library(worrms)
#library("devtools")
#devtools::install_github("vlizBE/imis")
require(imis)



# Defining the study area
#Download and unzip the ospar shapefiles
url <- "https://odims.ospar.org/public/submissions/ospar_regions/regions/2017-01/002/ospar_regions_2017_01_002-gis.zip"
download.file(url,paste0(spatdir,"/ospar_REGIONS.zip"),mode="wb")
unzip(zipfile=paste0(spatdir,"/ospar_REGIONS.zip"),exdir=spatdir)

#Visualize the different regions
ospar<- st_read(paste0(spatdir,"/ospar_regions_2017_01_002.shp"))


#Only keeping region II and III from the shapefile.
ospar <- ospar[ospar$Region %in% region,]
ggplot(data=ospar)+geom_sf()
#Only keeping the region and geometry info
ospar<- ospar %>% dplyr::select(Region)
#Not necessary anymore
ospar <- st_make_valid(ospar)

#Bring together the different ospar regions into one area
spatial_extent <- st_union(ospar)


# Download Occurrence data from eurOBIS



#Does not work when knitting, but works when running seperately
mydata.eurobis<- eurobis_occurrences_full(aphiaid=aphia_id)
#save(mydata.eurobis, file=paste0("data/raw_data/mydata.eurobis.RData"))
#load(paste0(occDir,"data/raw_data/mydata.eurobis.RData"))


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




datasetidsoi <- mydata.eurobis %>% distinct(datasetid) %>% 
  mutate(datasetid = as.numeric(str_extract(datasetid, "\\d+")))
#==== retrieve data by dataset ==============
all_info <- data.frame()
for (i in datasetidsoi$datasetid){
  dataset_info <- fdr2(i)
  all_info <- rbind(all_info, dataset_info)
}
names(all_info)[1]<-"datasetid"
write.csv(all_info,file=file.path(datadir,"allDatasets.csv"),row.names = F, append=FALSE)
alldataset <- read.csv(file.path(datadir,"allDatasets.csv"))




#Fit the datafiltering in here as well. 
#because in the description of SCANS, the word stranding is also mentioned, wrongly discarding this dataset
alldataset <- alldataset %>%
  rowwise() %>%
  mutate("discard"=any(across(-description, ~grepl(paste(word_filter, collapse = "|"), .,ignore.case=TRUE))))

alldataset_selection<-alldataset%>%
  filter(discard==FALSE)

alldataset_flagged <- alldataset%>%
  filter(discard==TRUE)

# Select columns of interest
mydata.eurobis <- mydata.eurobis %>%
  dplyr::select(scientificnameaccepted,decimallongitude,decimallatitude,datecollected,geometry=the_geom)%>%
  filter(!is.na(datecollected))%>%
  # Give date format to eventDate and fill out month and year columns and assign 1 to occurrenceStatus
  dplyr::mutate(occurrenceStatus = 1,day = day(datecollected),month = month(datecollected),year=year(datecollected))

#check which occurrence points fall within the study area
within_area <- st_contains(spatial_extent,mydata.eurobis)[[1]]

#Only retain points inside the study area
mydata.eurobis <- mydata.eurobis[within_area,]

mydata.eurobis <- mydata.eurobis%>%
  dplyr::filter(datecollected %within% temporal_extent)%>%
  arrange(datecollected)%>%
  mutate(year_month=paste(year,month,sep='-'))%>%
  mutate(year_month=factor(year_month,levels=unique(year_month),ordered=TRUE))





#Remove duplicates
mydata.eurobis <- cc_dupl(mydata.eurobis, lon = "decimallongitude", lat = "decimallatitude",
                          value = "clean",species="scientificnameaccepted", additions=
                            "datecollected")

save(mydata.eurobis, file = file.path(datadir,"presence.RData"))
save(spatial_extent, file = file.path(datadir,"spatial_extent.RData"))

