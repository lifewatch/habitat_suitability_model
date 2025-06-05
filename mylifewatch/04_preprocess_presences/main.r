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

##################################################################################
##################################################################################

path = list(
  setup = "/mnt/inputs/01_setup.json",
  code = "./code",
  temporal_extent_file = "/mnt/inputs/temporal_extent.RDS",
  datasets_all_file = "/mnt/inputs/datasets_all.csv",
  mydata_eurobis_file = "/mnt/inputs/mydata_eurobis.RDS",
  study_area_file = "/mnt/inputs/study_area.RDS",
  tempsal_output_filename = "tempsal.nc",
  npp_output_filename = "npp.nc",
  output_path = "/mnt/outputs/out.json"
)


lapply(list.files("functions", full.names = TRUE),source)
sapply(list.files(path$code, full.names = T), source)
lapply(list.files("/wrp/utils", full.names = TRUE, pattern = "\\.R$"), source)

args = args_parse(commandArgs(trailingOnly = TRUE))


# FUNCTIONS ---------------------------------------------------------------
#filter_dataset
#clean_presence
# INPUT -------------------------------------------------------------------
mydata_eurobis <- readRDS(file.path(path$mydata_eurobis_file))
datasets_all <- read.csv(file.path(path$datasets_all_file))
tempsal <- terra::rast(file.path(envdir, "tempsal.nc"))
study_area <- readRDS(file.path(path&study_area_file))
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

