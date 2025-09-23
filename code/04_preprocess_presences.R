##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-26
# Script Name: ~/habitat_suitability_model/code/04_preprocess_presences.R
# Script Description: Perform data cleaning and thinning steps on the data.
# SETUP ------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
source("code/01_setup.R")

##################################################################################
##################################################################################


# FUNCTIONS ---------------------------------------------------------------
#clean_presence
# INPUT -------------------------------------------------------------------
#presence_points is either the output of wrapper1 or a csv file given by the user with
#columns: longitude, latitude, time, species_name
if(is.null(user_data)){
presence_points <- readr::read_csv(file.path(datadir, "presence_points.csv"))
} else { presence_points <- user_data}
tempsal <- terra::rast(file.path(envdir, "tempsal.nc"))

# WORKFLOW ----------------------------------------------------------------

# Clean the presence data
cleaned_data <- clean_presence(
  data = presence_points,
  study_area = study_area
)

cleaned_data
# Thinning to one occurrence per pixel
thinned_m <- thin_points(
  data = cleaned_data,
  method = "grid",
  group_col = "year_month",
  raster_obj = tempsal,
  trials = 5,
  long_col = "longitude",
  lat_col = "latitude",
  seed = 1234
)
thinned_m <- thinned_m[[1]]

thinned_d <- thin_points(
  data = cleaned_data,
  method = "grid",
  group_col = "decade",
  raster_obj = tempsal,
  trials = 5,
  long_col = "longitude",
  lat_col = "latitude",
  seed = 1234
)
thinned_d <- thinned_d[[1]]

# OUTPUT ------------------------------------------------------------------

saveRDS(cleaned_data, file.path(datadir, "cleaned_data.RDS"))
saveRDS(thinned_m, file.path(datadir, "thinned_m.RDS"))
saveRDS(thinned_d, file.path(datadir, "thinned_d.RDS"))

