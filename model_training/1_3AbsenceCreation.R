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
list_dasid <- alldataset_selection$datasetid

#Some workaround to get the Class information while it is not in the parquet file
#Generate a list of all the distinct aphiaids over the datasets
aphiaid_list <- eurobis %>%
  filter(datasetid %in% list_dasid,
         longitude > bbox[1], longitude < bbox[3],
         latitude > bbox[2], latitude < bbox[4],
         observationdate >= as.POSIXct(date_start),
         observationdate <= as.POSIXct(date_end)) %>%
  dplyr::select(aphiaid) %>%
  distinct()%>%
  collect()

#Check which of the aphiaids belong to the target group (+-25min)
result <- tibble(Class=purrr::map_vec(aphiaid_list$aphiaid, \(x) ifelse(any(worrms::wm_classification(x)$rank == "Class"),
                                                                        worrms::wm_classification(x)[[which(worrms::wm_classification(x)$rank == "Class"), 3]],
                                                                        NA)))
#returns some empty columns, because e.g Reptilia don't have the class trait and some other aphiaids don't go to class level.

#Keep in this list the aphiaIDs of the target_group
class_list <- cbind(aphiaid_list, result)
class_list_filtered <- class_list%>%
  filter(Class==target_group)

target_background <- eurobis %>%
  filter(datasetid %in% list_dasid,
         aphiaidaccepted %in% class_list_filtered$aphiaid,
         longitude > bbox[1], longitude < bbox[3],
         latitude > bbox[2], latitude < bbox[4],
         observationdate >= as.POSIXct(date_start),
         observationdate <= as.POSIXct(date_end)) %>%
  dplyr::select(datasetid,
                latitude,
                longitude,
                time=observationdate,
                scientific_name = scientificname_accepted,
                occurrence_id = occurrenceid) %>%
  mutate(year=year(time),
         month=month(time),
         day = day(time))%>%
  collect()%>%
  sf::st_as_sf(coords=c("longitude", "latitude"),
               crs=4326)

target_background <- target_background %>%
  filter(!is.na(time))%>%
  cc_dupl(lon = "longitude",
          lat = "latitude",
          value = "clean",
          species="scientific_name",
          additions="time")%>%
  arrange(time)%>%
  st_filter(y = spatial_extent)%>%
  mutate(year_month=paste(year,month,sep='-'))%>%
  mutate(year_month=factor(year_month,levels=unique(year_month),ordered=TRUE))%>%
  dplyr::mutate(longitude = sf::st_coordinates(.)[,1],
                latitude = sf::st_coordinates(.)[,2],
                occurrence_status = 0)%>%
  dplyr::select(!c(datasetid,occurrence_id))%>%
  sf::st_drop_geometry()

year_month <- target_background%>%
  filter(year_month=="2000-1")
ggplot(data=spatial_extent)+
  geom_sf()+
  geom_sf(data= st_as_sf(year_month,coords=c("longitude","latitude"),crs=4326))

plot(x=year_month$longitude,y=year_month$latitude)


# Do a 2d kernel density estimation.
target_density <- ks::kde(cbind(year_month$longitude,year_month$latitude))%>%
  raster::raster()%>% #cannot use terra::rast direcly
  terra::rast()
terra::crs(target_density) <- "EPSG:4326"
plotdata <- cbind(data.frame(target_density),crds(target_density))
ggplot(data=spatial_extent)+
  geom_sf()+
  geom_raster(data=plotdata,aes(x=x,y=y,fill=layer,alpha = 0.7))+
  scale_fill_viridis_c()

land_mask <- ifel(raster_bathymetry > 0, NA, raster_bathymetry)
test <- terra::crop(terratest,land_mask)
test <- terra::resample(test,land_mask)
sample_bias <- mask(test, land_mask)
# Normalize bias file between 0 and 1.
sample_bias_normalized <- (m - minmax(m)[1])/(minmax(m)[2]-minmax(m)[1])
background <- sdm::background(raster_bathymetry,n=500,method = 'gRandom',bias=sample_bias_normalized)

ggplot(data=spatial_extent)+
  geom_sf()+
  geom_point(data=background,aes(x=x,y=y))

pa_occurrence <- rbind(mydata.eurobis, target_background)
summary(pa_occurrence)


save(absence, file=file.path(datadir,"absence.RData"))


