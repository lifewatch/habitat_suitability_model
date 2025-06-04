##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-19
# Script Name: ~/habitat_suitability_model/code/0_1setup.R
# Script Description: A script to make the general folder structure and load the necessary packages.
# Also load custom functions and the given user inputs.
# SETUP ------------------------------------


##################################################################################
##################################################################################
path = list(
  setup = "/mnt/outputs/01_setup.json",
  study_area_file = "/mnt/outputs/study_area.RDS",
  code = "./code"
)

# FUNCTIONS ---------------------------------------------------------------
lapply(list.files("functions", full.names = TRUE),source)
sapply(list.files(path$code, full.names = T), source)
lapply(list.files("/wrp/utils", full.names = TRUE, pattern = "\\.R$"), source)
# INPUT -------------------------------------------------------------------

args = args_parse(commandArgs(trailingOnly = TRUE))



# WORKFLOW ----------------------------------------------------------------



#Define user input choices
study_area <- load_ospar(c("II","III"), filepath = file.path(spatdir,args$study_area_name))
# write   study_area as RDS file
saveRDS(study_area, file = file.path(path$study_area_file))

# Print study_area type
print(paste("Study area type:", class(study_area)))

bbox <- sf::st_bbox(study_area)
print(paste("bbox type:", class(bbox)))
date_start <- as.POSIXct(args$start_date)
date_end <- as.POSIXct(args$end_date)
temporal_extent <- lubridate::interval(date_start,date_end)
print(paste("Temporal extent:", temporal_extent))
# possible_aphiaids <- c(137117, 137084, 137094, 137111, 137101, 137087)
possible_aphiaids = args$possible_aphiaids
# Convert possible_aphiaids to numeric if they are not already
possible_aphiaids <- as.numeric(unlist(strsplit(possible_aphiaids, ",")))
aphiaid <- possible_aphiaids[1]

#Choosing the bounding box to assess the monthly trend
min_lon <- args$min_lon
max_lon <- args$max_lon
min_lat <- args$min_lat
max_lat <- args$max_lat

# OUTPUT ------------------------------------------------------------------
# Save the user inputs as one json file
user_inputs <- list(
  temporal_extent = temporal_extent,
  possible_aphiaids = possible_aphiaids,
  aphiaid = aphiaid,
  min_lon = min_lon,
  max_lon = max_lon,
  min_lat = min_lat,
  max_lat = max_lat,
  datadir = datadir,
  mapsdir = mapsdir,
  modeldir = modeldir,
  figdir = figdir,
  envdir = envdir,
  occdir = occdir,
  spatdir = spatdir,
  study_area_file = path$study_area_file
)
jsonlite::write_json(user_inputs, file.path(path$setup), pretty = TRUE)
