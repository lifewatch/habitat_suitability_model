# Loading the required packages
library(dplyr)
library(sf)
library(ggplot2)
library(lubridate)
library(stringr)
library(ows4R)
library(readr)
library(CoordinateCleaner)


# download_target-group ---------------------------------------------------

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

#Check which of the aphiaids belong to the target group (+-5min)
target_aphiaids <- worrms::wm_classification_(aphiaid_list[[1]])%>%
  dplyr::filter(rank == "Class",
                scientificname==target_group)%>%
  dplyr::select(aphiaid="id")%>%
  dplyr::mutate(aphiaid=as.numeric(aphiaid))

#Download target group points from EurOBIS
target_group <- eurobis %>%
  filter(datasetid %in% list_dasid,
         aphiaidaccepted %in% target_aphiaids$aphiaid,
         longitude > bbox[1], longitude < bbox[3],
         latitude > bbox[2], latitude < bbox[4],
         observationdate >= date_start,
         observationdate <= date_end) %>%
  dplyr::select(datasetid,
                latitude,
                longitude,
                time=observationdate,
                scientific_name = scientificname_accepted,
                occurrence_id = occurrenceid) %>%
  collect()%>%
  filter(!is.na(time))%>%
  cc_dupl(lon = "longitude",
          lat = "latitude",
          value = "clean",
          species="scientific_name",
          additions="time")%>%
  arrange(time)%>%
  sf::st_as_sf(coords=c("longitude", "latitude"),
               crs=4326)%>%
  st_filter(y = spatial_extent)%>% #Only keep those that fall into the spatial_extent.
  dplyr::mutate(longitude = sf::st_coordinates(.)[,1],
                latitude = sf::st_coordinates(.)[,2])%>%
  mutate(month = month(time), decade= year(time) - year(time) %% 10)%>%
  mutate(decade= factor(decade,levels=unique(decade)))%>%
  dplyr::select(!c(datasetid,occurrence_id,scientific_name,time))%>%
  sf::st_drop_geometry()


# create monthly bias files ------------------------------------------------

if(!dir.exists(file.path(datadir,"bias_monthly"))) dir.create(file.path(datadir,"bias_monthly"))
tgb_month <- tibble() #create empty tibble
#Loop over the different months
for(m in unique(mydata_eurobis$month)){
  #Select the monthly data
  monthly_data <- target_group%>%
    filter(month == m)
  
  #Perform a 2d kernel density estimation
  target_density <- ks::kde(x = cbind(monthly_data$longitude,monthly_data$latitude),
                            xmin = bbox[1:2],
                            xmax = bbox[3:4])%>%
    raster::raster()%>% #cannot use terra::rast direcly
    terra::rast()
  #Save the monthly kernel density as a .tif file
  terra::crs(target_density) <- "EPSG:4326"
  target_density <- terra::crop(target_density, ospar, mask = TRUE)
  target_density_normalized <- (target_density - minmax(target_density)[1])/(minmax(target_density)[2]-minmax(target_density)[1])
  terra::writeCDF(x = target_density_normalized,
                  filename = file.path(datadir,"bias_monthly",paste0("bias_",lubridate::month(m,label=TRUE),".nc")),
                  varname = "sampling effort",
                  longname = paste("normalized density of the sampling bias",
                                   lubridate::month(m,label=TRUE)),
                  overwrite = TRUE)
  #Sample monthly background points based on the sampling bias
  tgb <- sdm::background(target_density_normalized,n=2500,method = 'gRandom',bias=target_density_normalized)%>%
    dplyr::select("longitude"=x,
                  "latitude"=y)%>%
    dplyr::mutate(month = m,
                  occurrence_status = 0)
  
  tgb_month <- rbind(tgb_month,tgb)
  
}


# create decadal bias files -----------------------------------------------

if(!dir.exists(file.path(datadir,"bias_decad"))) dir.create(file.path(datadir,"bias_decad"))
tgb_decad <- tibble() #create empty tibble
#Loop over the different months
for(d in unique(mydata_eurobis$decade)){
  #Select the monthly data
  decadal_data <- target_group%>%
    filter(decade == d)
  
  #Perform a 2d kernel density estimation
  target_density <- ks::kde(x = cbind(decadal_data$longitude,decadal_data$latitude),
                            xmin = bbox[1:2],
                            xmax = bbox[3:4],
                            gridsize= c(300,200))%>% #to get a resolution of 0.083x 0.07
    raster::raster()%>% #cannot use terra::rast directly
    terra::rast()
  #Save the monthly kernel density as a .tif file
  terra::crs(target_density) <- "EPSG:4326"
  target_density <- terra::crop(target_density, ospar, mask = TRUE)
  target_density_normalized <- (target_density - minmax(target_density)[1])/(minmax(target_density)[2]-minmax(target_density)[1])
  terra::writeCDF(x = target_density_normalized,
                  filename = file.path(datadir,"bias_decad",paste0("bias_",d,".nc")),
                  varname = "sampling effort",
                  longname = paste("normalized density of the sampling bias",
                                   d),
                  overwrite = TRUE)
  #Sample monthly background points based on the sampling bias
  tgb <- sdm::background(target_density_normalized,n=nrow(decadal_data),method = 'gRandom',bias=target_density_normalized)%>%
    dplyr::select("longitude"=x,
                  "latitude"=y)%>%
    dplyr::mutate(decade = d,
                  occurrence_status = 0)
  
  tgb_decad <- rbind(tgb_decad,tgb)
  
}


# check plots -------------------------------------------------------------


ggplot(data=spatial_extent)+geom_sf()+geom_point(data=tgb, aes(x = longitude, y = latitude))

# outputs -----------------------------------------------------------------


pback_month <- rbind(mydata_eurobis[,-5], tgb_month) #presence-background data monthly
pback_decad <- rbind(mydata_eurobis[,-4], tgb_decad)
save(target_aphiaids, file=file.path(datadir,"target_aphiaids.RData"))
save(target_background, file=file.path(datadir,"target_background.RData"))
save(pback, file = file.path(datadir,"pback.RData"))



