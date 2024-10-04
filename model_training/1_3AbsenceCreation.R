# Loading the required packages
library(dplyr)
library(sf)
library(ggplot2)
library(lubridate)
library(stringr)
library(ows4R)
library(readr)
library(CoordinateCleaner)

alldataset <- read.csv(file.path(datadir,"allDatasets.csv"))
list_dasid <- alldataset$datasetid

wfs <- WFSClient$
  new("https://geo.vliz.be/geoserver/Dataportal/wfs", "2.0.0", logger = "INFO")$
  getCapabilities()$
  findFeatureTypeByName("Dataportal:eurobis-obisenv_full")
target_path <- paste0("target_group_",aphia_id)
ifelse(!dir.exists(file.path(occdir,target_path)), dir.create(file.path(occdir,target_path)), FALSE)
for(datasetid in list_dasid){
  filename = paste0("dataset", datasetid,".csv")
  if(!file.exists(file.path(occdir,target_path, filename))){

      params <- paste0("where%3Adatasetid+IN+%28",
                   datasetid,
                   "%29")
  
  feature_pagination <- wfs$getFeatures(viewParams = params, paging = TRUE, paging_length = 50000)

  #Save the download to a csv file with the dataset and region name
  write_delim(feature_pagination, file.path(occdir,target_path, filename), delim = ",")
  } else{
    print(paste(filename,"already dowloaded"))}
  }


target_files <- list.files(file.path(occdir,target_path))
dataframes_target <- list()

for(file in target_files) {
  # Read the CSV file into a dataframe
  df <- read.csv(file.path(occdir,target_path,file))
  
  #Append the dataframe to the list
  dataframes_target <- c(dataframes_target, list(df))
}


target_background <- do.call(rbind,dataframes_target)
target_background <- data.frame(target_background)%>%
  filter(class==target_group)%>%
  filter(scientificnameaccepted!=species)

absence <- target_background%>%
  dplyr::select(scientificnameaccepted,decimallongitude,decimallatitude,datecollected)%>%
  filter(!is.na(datecollected))%>%
  dplyr::mutate(occurrenceStatus=0,datecollected=as.POSIXct(datecollected), day = day(datecollected),month = month(datecollected), year = year(datecollected))%>%
  dplyr::filter(datecollected %within% temporal_extent)%>%
  arrange(datecollected)%>%
  mutate(year_month=paste(year,month,sep='-'))%>%
  mutate(year_month=factor(year_month,levels=unique(year_month),ordered=TRUE))%>%
  mutate(copydecimallongitude = decimallongitude, copydecimallatitude=decimallatitude)

absence <-  st_as_sf(absence,coords = c("copydecimallongitude", "copydecimallatitude"), 
                     crs = st_crs(spatial_extent))
within_abs <- st_contains(spatial_extent,absence)[[1]]
absence <- absence[within_abs,]
absence <- cc_dupl(absence, lon = "decimallongitude", lat = "decimallatitude",
                   value = "clean",species="scientificnameaccepted", additions=
                     "datecollected")

save(absence, file=file.path(datadir,"absence.RData"))


