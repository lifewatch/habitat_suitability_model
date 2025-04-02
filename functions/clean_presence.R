#' Clean and Prepare Presence Data
#'
#' This function cleans and prepares presence data by filtering, removing duplicates, and adding monthly/decadal information.
#'
#' @param data A spatial data frame (Simple Features) containing the raw occurrence records, needs to contain the following columns:
#' "longitude", "latitude", "scientific_name", "time".
#' @param study_area A spatial object defining the geographic region of interest.
#' @param dataset_selection A data frame containing the selected dataset IDs for filtering.
#' @return A cleaned and prepared data frame with relevant fields for analysis, including spatial and temporal information.
#' @details The function performs the following steps:
#'          1. Filters out rows with missing temporal information (`time`).
#'          2. Filters data based on the provided study area.
#'          3. Filters records belonging to selected dataset IDs.
#'          4. Removes duplicate occurrence records.
#'          5. Adds information about month, and decade.
#'          6. Drops unnecessary columns.
#' @examples
#' # Example usage:
#' cleaned_data <- clean_presence(
#'   data = mydata_eurobis,
#'   study_area = study_area,
#'   dataset_selection = alldataset_selection
#' )
#'
#' @export
clean_presence <- function(data, study_area, dataset_selection) {
  # Step 1: Remove duplicates
  data <- cc_dupl(
    data, 
    lon = "longitude", 
    lat = "latitude", 
    value = "clean", 
    species = "scientific_name", 
    additions = "time"
  )
  # Step 2: Select columns of interest and apply initial filters
  data <- sf::st_as_sf(data,coords=c("longitude","latitude"),crs="EPSG:4326") %>%
    filter(!is.na(time)) %>%
    st_filter(y = study_area) %>%
    filter(datasetid %in% dataset_selection$datasetid) %>%
    dplyr::distinct(occurrence_id, .keep_all = TRUE) %>%
    arrange(time) %>%
    dplyr::mutate(
      longitude = sf::st_coordinates(.)[, 1],
      latitude = sf::st_coordinates(.)[, 2],
      occurrence_status = 1
    ) %>%
    dplyr::select(!c(datasetid, occurrence_id)) %>%
    sf::st_drop_geometry()
  
  
  
  # Step 3: Add month and decadal information
  data <- data %>%
    mutate(
      month = month(time),
      decade = year(time) - year(time) %% 10
    ) %>%
    mutate(decade = factor(decade, levels = unique(decade))) %>%
    dplyr::select(!c(scientific_name, time))
  
  return(data)
}
