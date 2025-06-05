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

##################################################################################
##################################################################################
path = list(
  code = "./code",
  tempsal_filename = "/mnt/inputs/tempsal.nc",
  datasets_selection = "/mnt/inputs/datasets_selection.csv",
  thinned_m_file = "/mnt/inputs/thinned_m.RDS",
  thinned_d_file = "/mnt/inputs/thinned_d.RDS",
  target_group = "/mnt/outputs/target_group.RDS",
)


lapply(list.files("functions", full.names = TRUE),source)
sapply(list.files(path$code, full.names = T), source)
lapply(list.files("/wrp/utils", full.names = TRUE, pattern = "\\.R$"), source)

args = args_parse(commandArgs(trailingOnly = TRUE))

# FUNCTIONS ---------------------------------------------------------------
#download_tg
#sample_background
#connect_eurobis

# INPUT -------------------------------------------------------------------
datasets_selection <- read.csv(file.path(path$datasets_selection))
tempsal <- terra::rast(file.path(path$tempsal_filename))
thinned_m <- readRDS(file.path(path$thinned_m_file))
thinned_d <- readRDS(file.path(path$thinned_d_file))
# WORKFLOW ----------------------------------------------------------------

# Define the list of datasets that passed through the filtering
list_dasid <- datasets_selection$datasetid

# For a given species and lists of datasets, download the full target-group occurrences
target_group <- download_tg(aphia_id = aphiaid,
                            list_dasid= list_dasid,
                            spatial_extent = bbox,
                            temporal_extent = temporal_extent)

target_group <- clean_presence(target_group, study_area, dataset_selection = datasets_selection)
saveRDS(target_group, file=file.path(path$target_group))