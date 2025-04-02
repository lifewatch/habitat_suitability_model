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
#filter_dataset
#clean_presence
# INPUT -------------------------------------------------------------------
mydata_eurobis <- readRDS(file.path(datadir, "mydata_eurobis.RDS"))
datasets_all <- read.csv(file.path(datadir,"datasets_all.csv"))
tempsal <- terra::rast(file.path(envdir, "tempsal.nc"))
study_area <- readRDS(file.path(datadir, "study_area.RDS"))
# WORKFLOW ----------------------------------------------------------------
# Filter out datasets based on a keyword
word_filter <- c("stranding", "museum")
datasets_selection <- filter_dataset(datasets_all,method="filter",filter_words = word_filter)

# Clean the presence data
cleaned_data <- clean_presence(
  data = mydata_eurobis,
  study_area = study_area,
  dataset_selection = datasets_selection
)

cleaned_data
# Thinning to one occurrence per pixel
thinned_m <- thin_points(
  data = cleaned_data,
  method = "grid",
  group_col = "month",
  raster_obj = tempsal,
  trials = 5,
  seed = 1234
)
thinned_m <- thinned_m[[1]]%>%dplyr::select(
  longitude = long,
  latitude = lat,
  occurrence_status,
  month,
  decade
)
thinned_d <- thin_points(
  data = cleaned_data,
  method = "grid",
  group_col = "decade",
  raster_obj = tempsal,
  trials = 5,
  seed = 1234
)
thinned_d <- thinned_d[[1]]%>%dplyr::select(
  longitude = long,
  latitude = lat,
  occurrence_status,
  month,
  decade
)

# OUTPUT ------------------------------------------------------------------
write.csv(datasets_selection ,file=file.path(datadir,"datasets_selection.csv"),row.names = F, append=FALSE)
saveRDS(cleaned_data, file.path(datadir, "cleaned_data.RDS"))
saveRDS(thinned_m, file.path(datadir, "thinned_m.RDS"))
saveRDS(thinned_d, file.path(datadir, "thinned_d.RDS"))

