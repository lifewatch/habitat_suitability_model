#Required packages

# library(eurobis)
# library(maptools)
# library(dplyr)
# library(sf)
# library(maps)
# library(ggplot2)
# library(lubridate)
# library(CoordinateCleaner)
# library(arulesViz)
# library(tidyverse)
# library(worrms)
# library("devtools")
# devtools::install_github("vlizBE/imis")
# require(imis)



# spatial_extent ----------------------------------------------------------
# Defining the study area
#Download and unzip the ospar shapefiles
url <- "https://odims.ospar.org/public/submissions/ospar_regions/regions/2017-01/002/ospar_regions_2017_01_002-gis.zip"
download.file(url,file.path(spatdir,"ospar_REGIONS.zip"),mode="wb")
unzip(zipfile=file.path(spatdir,"ospar_REGIONS.zip"),exdir=spatdir)

#Visualize the different regions
ospar<- st_read(file.path(spatdir,"ospar_regions_2017_01_002.shp"))
st_read(file.path("data",""))



#Only keeping region II and III from the shapefile.
ospar <- ospar[ospar$Region %in% region,]
ggplot(data=ospar)+geom_sf()
#Only keeping the region and geometry info
ospar<- ospar %>% dplyr::select(Region)


#Bring together the different ospar regions into one area
spatial_extent <- st_union(ospar)


# download_presence -------------------------------------------------------

# Make a connection with the data_lake
data_lake <- S3FileSystem$create(
  anonymous = T,
  scheme = "https",
  endpoint_override = "s3.waw3-1.cloudferro.com"
)

s3_path <- "emodnet/biology/eurobis_occurrence_data/eurobis_occurrences_geoparquet_2024-10-01.parquet"
eurobis <- open_dataset(
  s3_path,
  filesystem = data_lake,
  format = "parquet"  # Specify the file format
)


#Downloading the occurrence data from EurOBIS
bbox <- sf::st_bbox(spatial_extent)
mydata_eurobis <- eurobis %>%
  filter(aphiaidaccepted==aphia_id,
         longitude > bbox[1], longitude < bbox[3],
         latitude > bbox[2], latitude < bbox[4],
         observationdate >= as.POSIXct(date_start),
         observationdate <= as.POSIXct(date_end)) %>%
  dplyr::select(datasetid,
                latitude,
                longitude,
                time=observationdate,
                scientific_name = scientificname_accepted,
                occurrence_id=occurrenceid) %>%
  collect()%>%
  sf::st_as_sf(coords=c("longitude", "latitude"),
               crs=4326)


# dataset_metadata --------------------------------------------------------

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


# generate dataset metadata

datasetidsoi <- mydata_eurobis %>% distinct(datasetid) %>% 
  mutate(datasetid = as.numeric(str_extract(datasetid, "\\d+")))
# retrieve data by dataset
all_info <- data.frame()
for (i in datasetidsoi$datasetid){
  dataset_info <- fdr2(i)
  all_info <- rbind(all_info, dataset_info)
}
names(all_info)[1]<-"datasetid"
write.csv(all_info,file=file.path(datadir,"allDatasets.csv"),row.names = F, append=FALSE)
alldataset <- read.csv(file.path(datadir,"allDatasets.csv"))


# data_pre-processing -----------------------------------------------------

# Filter out datasets based on a keyword

alldataset <- alldataset %>%
  rowwise() %>%
  mutate("discard"=any(across(-description, # because in the description of SCANS, the word stranding is also mentioned, wrongly discarding this dataset
                              ~grepl(paste(word_filter, collapse = "|"),
                                     .,ignore.case=TRUE))))

alldataset_selection<-alldataset%>%
  filter(discard==FALSE)

alldataset_flagged <- alldataset%>%
  filter(discard==TRUE)

# Select columns of interest
mydata_eurobis <- mydata_eurobis %>%
  filter(!is.na(time))%>%
  st_filter(y = spatial_extent)%>%
  filter(datasetid %in% alldataset_selection$datasetid)%>%
  dplyr::distinct(occurrence_id,.keep_all = TRUE)%>%
  arrange(time)%>%
  dplyr::mutate(longitude = sf::st_coordinates(.)[,1],
                latitude = sf::st_coordinates(.)[,2],
                occurrence_status = 1)%>%
  dplyr::select(!c(datasetid,occurrence_id))%>%
  sf::st_drop_geometry()

#Remove duplicates
mydata_eurobis <- cc_dupl(mydata_eurobis, lon = "longitude", lat = "latitude",value = "clean",species="scientific_name", additions="time")

#Add month information

#Add decadal information


mydata_eurobis <- mydata_eurobis%>%
  mutate(month = month(time), decade= year(time) - year(time) %% 10)%>%
  mutate(decade= factor(decade,levels=unique(decade)))%>%
  select(!c(scientific_name,time))


# outputs -----------------------------------------------------------------

#Save output
save(mydata_eurobis, file = file.path(datadir,"mydata_eurobis.RData"))
save(ospar, file = file.path(datadir, "ospar.RData"))
save(spatial_extent, file = file.path(datadir,"spatial_extent.RData"))
save(alldataset_selection, file = file.path(datadir,"alldataset_selection.RData"))

