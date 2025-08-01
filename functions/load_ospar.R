#' Download and Load OSPAR Regions
#'
#' This function downloads, unzips, and reads the OSPAR regions shapefile, 
#' and optionally filters it based on specified regions of interest.
#'
#' @param regions A character vector specifying the OSPAR regions of interest. 
#'        Default is c("I", "II", "III", "IV", "V").
#' @return A spatial object (Simple Features) representing the filtered OSPAR regions.
#' @details If the OSPAR regions shapefile does not exist in the specified directory, 
#'          the function downloads it from the OSPAR server, unzips it, and reads it into R.
#'          The function then filters the regions based on the provided `regions` argument.
#' @examples
#' # Default usage: Load all OSPAR regions
#' study_area <- load_ospar()
#'
#' # Load specific regions
#' study_area <- load_ospar(regions = c("II", "III"))
#'
#' @export
load_ospar <- function(regions=c("I","II","III","IV","V"), filepath){
  if(!file.exists(filepath)){
    url <- "https://odims.ospar.org/public/submissions/ospar_regions/regions/2017-01/002/ospar_regions_2017_01_002-gis.zip"
    download.file(url,file.path(dirname(filepath),"ospar_REGIONS.zip"),mode="wb")
    unzip(zipfile=file.path(dirname(filepath),"ospar_REGIONS.zip"),exdir=dirname(filepath))
  }
  ospar_regions <- st_read(filepath)
  #Subsetting to regions of interest
  study_area <- ospar_regions[ospar_regions$Region %in% regions,]
  study_area <- sf::st_union(study_area)
  return(study_area)
}
