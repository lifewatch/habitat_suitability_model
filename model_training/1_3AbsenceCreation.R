# Loading the required packages
library(dplyr)
library(sf)
library(ggplot2)
library(lubridate)
library(stringr)
library(ows4R)
library(readr)
library(CoordinateCleaner)


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
  filter(!is.na(time))%>%
  cc_dupl(lon = "longitude",
          lat = "latitude",
          value = "clean",
          species="scientific_name",
          additions="time")%>%
  arrange(time)%>%
  mutate(year_month=paste(year,month,sep='-'))%>%
  mutate(year_month=factor(year_month,levels=unique(year_month),ordered=TRUE))%>%
  dplyr::filter(year_month %in% levels(mydata_eurobis$year_month))%>% #only keep background for months we have presences in
  sf::st_as_sf(coords=c("longitude", "latitude"),
               crs=4326)%>%
  st_filter(y = spatial_extent)%>% #Only keep those that fall into the spatial_extent.
  dplyr::mutate(longitude = sf::st_coordinates(.)[,1],
                latitude = sf::st_coordinates(.)[,2])%>%
  dplyr::select(!c(datasetid,occurrence_id,year,month,day))%>%
  sf::st_drop_geometry()

if(!dir.exists(file.path(datadir,"monthly_bias"))) dir.create(file.path(datadir,"monthly_bias"))
target_background <- tibble() #create empty tibble
#Loop over the different months
for(month in unique(mydata_eurobis$year_month)){
  #Select the monthly data
  monthly_data <- target_group%>%
    filter(year_month == !!month)
  
  #Perform a 2d kernel density estimation
  target_density <- ks::kde(x = cbind(monthly_data$longitude,monthly_data$latitude),
                            xmin = bbox[1:2],
                            xmax = bbox[3:4])%>%
    raster::raster()%>% #cannot use terra::rast direcly
    terra::rast()
  #Save the monthly kernel density as a .tif file
  terra::time(target_density) <- lubridate::floor_date(monthly_data$time[1],
                                                       unit = "month")#provide the right month information to the raster
  terra::crs(target_density) <- "EPSG:4326"
  target_density <- terra::crop(target_density, ospar, mask = TRUE)
  target_density_normalized <- (target_density - minmax(target_density)[1])/(minmax(target_density)[2]-minmax(target_density)[1])
  terra::writeCDF(x = target_density_normalized,
                  filename = file.path(datadir,"monthly_bias",paste0("bias_",month,".nc")),
                  varname = "density",
                  longname = "normalized density of the sampling bias",
                  overwrite = TRUE)
  #Sample monthly background points based on the sampling bias
  background <- sdm::background(target_density_normalized,n=500,method = 'gRandom',bias=target_density_normalized)%>%
    dplyr::select("longitude"=x,
                  "latitude"=y)%>%
    dplyr::mutate(time= time(target_density_normalized),
                  scientific_name = mydata_eurobis$scientific_name[1],
                  year_month = month,
                  occurrence_status = 0)
  target_background <- rbind(target_background,background)
  
}

pback <- rbind(mydata_eurobis,target_background) #presence-background data
save(target_aphiaids, file=file.path(datadir,"target_aphiaids"))
save(target_background, file=file.path(datadir,"target_background.RData"))
save(pback, file = file.path(datadir,"pback.RData"))



