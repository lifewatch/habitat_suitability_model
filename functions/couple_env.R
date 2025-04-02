#' Couple Environmental Data with Observational Records
#'
#' This function extracts environmental data for given observations based on their spatial and temporal locations. It couples the input dataset with environmental variables such as temperature, net primary production (NPP), salinity, and bathymetry.
#'
#' @param data A data frame containing observational records with `longitude` and `latitude` columns.
#' @param thetao_rast A raster object representing temperature data.
#' @param npp_rast A raster object representing net primary production (NPP) data.
#' @param so_rast A raster object representing salinity data.
#' @param bathy_rast A raster object representing bathymetry data.
#' @param timescale A string indicating the timescale column in the dataset used for temporal matching.
#' @return A data frame combining the original observations with extracted environmental variables.
#' @details This function:
#'          1. Extracts temperature, NPP, salinity, and bathymetry values for each observation using bilinear interpolation.
#'          2. Matches environmental values based on the temporal information specified by the `timescale` column.
#'          3. Removes records with missing environmental data.
#' @examples
#' # Example usage:
#' env_month <- couple_env(
#'   data = pback_month,
#'   thetao_rast = thetao_avg_m,
#'   npp_rast = npp_avg_m,
#'   so_rast = so_avg_m,
#'   bathy_rast = bathy,
#'   timescale = "month"
#' )
#' @export
couple_env <- function(data, thetao_rast, npp_rast, so_rast, bathy_rast, timescale){
  #For each environmental variable it collects first a value for every raster (every month/decade)
  #Afterwards it selects the correct rastervalue out of these, by simple indexing
  #For temperature
  thetao_full <- terra::extract(x=thetao_rast, y=data[,c("longitude","latitude")], method="bilinear", na.rm=TRUE,df=T,ID=FALSE)
  thetao_select <- data.frame(thetao = thetao_full[cbind(1:nrow(data),as.numeric(data[[timescale]]))])
  
  #For NPP
  npp_full <- terra::extract(x=npp_rast, y=data[,c("longitude","latitude")], method="bilinear", na.rm=TRUE,df=T,ID=FALSE)
  npp_select <- data.frame(npp = npp_full[cbind(1:nrow(data),as.numeric(data[[timescale]]))])
  
  
  #For salinity
  so_full <- terra::extract(x=so_rast, y=data[,c("longitude","latitude")], method="bilinear", na.rm=TRUE,df=T,ID=FALSE)
  so_select <- data.frame(so = so_full[cbind(1:nrow(data),as.numeric(data[[timescale]]))])
  
  #For bathymetry
  bathy_select <- terra::extract(x=bathy_rast, y=data[,c("longitude","latitude")], method="bilinear", na.rm=TRUE,df=T,ID=FALSE)
  
  #Combining the environmental values
  pback_env <- cbind(data,thetao_select,npp_select,so_select,bathy_select)%>%drop_na()
  return(pback_env)
}