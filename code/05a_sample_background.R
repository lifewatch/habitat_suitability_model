##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-26
# Script Name: ~/habitat_suitability_model/code/05_sample_background.R
# Script Description: Sample the background based on the target-group background
# methodolody.
# SETUP ------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
source("code/01_setup.R")

##################################################################################
##################################################################################

# FUNCTIONS ---------------------------------------------------------------
#download_tg
#sample_background
#connect_eurobis

# INPUT -------------------------------------------------------------------
datasets_selection <- read.csv(file.path(datadir, "datasets_selection.csv"))
tempsal <- terra::rast(file.path(envdir, "tempsal.nc"))
thinned_m <- readRDS(file.path(datadir, "thinned_m.RDS"))
thinned_d <- readRDS(file.path(datadir, "thinned_d.RDS"))
# WORKFLOW ----------------------------------------------------------------

if(is.null(user_data)){
  # Define the list of datasets that passed through the filtering
  list_dasid <- datasets_selection$datasetid
  
  # For a given species and lists of datasets, download the full target-group occurrences
  target_group <- download_tg(aphia_id = aphiaid, 
                              list_dasid= list_dasid, 
                              spatial_extent = bbox, 
                              temporal_extent = temporal_extent)
  
  #Pre-process the target-group similar to the presence data
  
  target_group <- clean_presence(target_group, study_area)
  
  # Thinning to one occurrence per pixel
  thinned_tg_m <- thin_points(
    data = target_group,
    method = "grid",
    group_col = "year_month",
    raster_obj = tempsal[[1]],
    trials = 5,
    lon_col = "longitude",
    lat_col = "latitude",
    seed = 1234
  )
  thinned_tg_m <- thinned_tg_m$original_data[thinned_tg_m$retained[[1]],]%>%dplyr::select(
    longitude,
    latitude,
    occurrence_status,
    month,
    decade,
    year_month
  )
  
  thinned_tg_d <- thin_points(
    data = target_group,
    method = "grid",
    group_col = "decade",
    lon_col = "longitude",
    lat_col = "latitude",
    raster_obj = tempsal[[1]],
    trials = 5,
    seed = 1234
  )
  thinned_tg_d <- thinned_tg_d$original_data[thinned_tg_d$retained[[1]],]%>%dplyr::select(
    longitude,
    latitude,
    occurrence_status,
    month,
    decade,
    year_month
  )
} else { #In the case of user data, we don't collect the target group as this is based on the 
  thinned_tg_m <- thinned_m
  thinned_tg_d <- thinned_d
}
saveRDS(target_group, file=file.path(datadir,"target_group.RDS"))
saveRDS(thinned_tg_m, file=file.path(datadir,"thinned_tg_m.RDS"))
saveRDS(thinned_tg_d, file=file.path(datadir,"thinned_tg_d.RDS"))