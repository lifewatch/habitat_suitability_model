#Download the target group for marine mammals based on a list of datasets
download_tg <- function(list_dasid, spatial_extent, temporal_extent){
  #Connect to eurobis database
  cat("Connecting to Eurobis...\n")
  eurobis <- connect_eurobis()

  #Download target group points from EurOBIS
  cat("Download Eurobis data...\n")
  eurobis <- connect_eurobis()
  target_group_occurrences <- eurobis %>%
    dplyr::filter(datasetid %in% list_dasid,
           order %in% c("Cetartiodactyla", "Sirenia", "Carnivora"),
           longitude > spatial_extent[1], longitude < spatial_extent[3],
           latitude > spatial_extent[2], latitude < spatial_extent[4],
           observationdate >= int_start(temporal_extent),
           observationdate <= int_end(temporal_extent)) %>%
    dplyr::select(datasetid,
                  latitude,
                  longitude,
                  time=observationdate,
                  scientific_name = scientificname_accepted,
                  occurrence_id = occurrenceid) %>%
    dplyr::collect()
  
  return(target_group_occurrences)
}
