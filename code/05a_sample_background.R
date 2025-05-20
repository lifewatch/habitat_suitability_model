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

# Define the list of datasets that passed through the filtering
list_dasid <- datasets_selection$datasetid

# For a given species and lists of datasets, download the full target-group occurrences
target_group <- download_tg(aphia_id = aphiaid, 
                            list_dasid= list_dasid, 
                            spatial_extent = bbox, 
                            temporal_extent = temporal_extent)

target_group <- clean_presence(target_group, study_area, dataset_selection = datasets_selection)
saveRDS(target_group, file=file.path(datadir,"target_group.RDS"))