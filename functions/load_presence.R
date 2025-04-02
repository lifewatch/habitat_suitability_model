#' Filter Occurrence Data from Datalake
#'
#' This function filters occurrence data from a datalake based on taxonomic, spatial, and temporal criteria.
#'
#' @param aphia_id A numeric AphiaID representing the species or taxonomic group of interest.
#' @param spatial_extent A numeric vector of length 4 specifying the spatial bounding box: 
#'        c(min_longitude, min_latitude, max_longitude, max_latitude). Default is c(-90, -90, 90, 90).
#' @param temporal_extent A lubridate interval object defining the temporal range of interest. 
#'        Default is from "1993-01-01" to "2019-12-31".
#' @return A spatial object (Simple Features) containing filtered occurrence records.
#' @details The function filters the Eurobis datalake for records matching the specified taxonomic ID 
#'          (AphiaID), spatial extent, and temporal extent. The resulting data includes selected fields 
#'          and is converted into a Simple Features (sf) object for spatial analysis.
#' @examples
#' # Filter data for a specific species and spatial/temporal extent
#' mydata <- load_presence(
#'   aphia_id = 137117,
#'   spatial_extent = c(-10, 35, 10, 45),
#'   temporal_extent = lubridate::interval("2000-01-01", "2019-12-31")
#' )
#'
#' @export
load_presence <- function(aphia_id, spatial_extent=c(-90,-90,90,90), temporal_extent=lubridate::interval("1993-01-01","2019-12-31")){
  # Make a connection with the data_lake
  eurobis <- connect_eurobis()
  
  mydata_eurobis <- eurobis %>%
    filter(aphiaidaccepted==aphia_id,
           longitude > spatial_extent[1], longitude < spatial_extent[3],
           latitude > spatial_extent[2], latitude < spatial_extent[4],
           observationdate >= int_start(temporal_extent),
           observationdate <= int_end(temporal_extent)) %>%
    dplyr::select(datasetid,
                  latitude,
                  longitude,
                  time=observationdate,
                  scientific_name = scientificname_accepted,
                  occurrence_id=occurrenceid) %>%
    collect()
  return(mydata_eurobis)
}
