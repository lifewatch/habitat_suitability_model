sample_background <- function(target_group_data, grouping = "month", resample_layer, window,n_multiplier, presence_data){
  path <- file.path(datadir, paste0("bias_", grouping))
  if(!dir.exists(path)) dir.create(path)
  tgb <- tibble() #create empty tibble
  #Loop over the different subsets
  for(subset in unique(target_group_data[[grouping]])){
    #Select the monthly data
    data_subset <- target_group_data%>%
      filter(get(grouping) == subset)%>%
      st_as_sf(coords = c("longitude","latitude"), crs = 4326)%>%
      st_transform(crs = 25832)%>%
      mutate(longitude = st_coordinates(.)[,1],
             latitude = st_coordinates(.)[,2]) %>%
      st_drop_geometry()
    presence_subset <- presence_data%>%
      filter(get(grouping) == subset)
    #Turn the coordinates into a spatial point process
    spp <- ppp(x = data_subset$longitude,
               y = data_subset$latitude,
               window = window)
    # Calculate the smoothing parameter based on Cronie and Van Lieshout
    s <- bw.CvL(spp)
    #Perform a 2d kernel density estimation
      den <- density.ppp(spp,dimyx = c(dim(resample_layer)[2], dim(resample_layer)[1]),sigma=s, positive = T)
    denrast <- terra::rast(den)
    crs(denrast) <- "EPSG:25832"
    #Save the monthly kernel density as a .tif file
    terra::writeCDF(x = denrast,
                    filename = file.path(path, paste0("bias_", grouping, subset,".nc")),
                    varname = "sampling effort",
                    longname = paste("density of the sampling effort",
                                     grouping, subset),
                    overwrite = TRUE)
    #Sample monthly background points based on the sampling bias
    tgb_sub <- sdm::background(denrast,n=n_multiplier*nrow(presence_subset),method = 'gRandom',bias=denrast)%>%
      dplyr::select("longitude"=x,
                    "latitude"=y)%>%
      st_as_sf(coords = c("longitude", "latitude"), crs = "epsg:25832")%>%
      st_transform(dst = 4326, crs = 4326, src = 25832)%>%
      mutate(longitude = st_coordinates(.)[,1],latitude = st_coordinates(.)[,2])%>%
      st_drop_geometry()%>%
      dplyr::mutate(!!grouping := subset,
                    occurrence_status = 0)
    
    tgb <- rbind(tgb,tgb_sub)
    
  }
  return(tgb)
}
