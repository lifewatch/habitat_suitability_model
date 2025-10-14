##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-26
# Script Name: ~/habitat_suitability_model/code/05_sample_background.R
# Script Description: Sample the background based on the target-group background
# methodolody.
# SETUP ------------------------------------

source("load_common_packages.R")
source("functions/clean_presence.R")
source("functions/connect_eurobis.R")
source("functions/download_tg.R")
source("functions/sample_background.R")

# INPUT VARIABLES
#===============================================================
# **envdir**
# **datadir**
# study_area
# bbox
# temporal_extent

# INPUT FILES
#===============================================================
# data/derived_data/datasets_selection.csv
# data/derived_data/thinned_m.RDS
# data/derived_data/thinned_d.RDS
# data/raw_data/environmental_layers/tempsal.nc

# OUTPUT FILES
#===============================================================
# data/derived_data/target_group.RDS
# data/derived_data/thinned_tg_m.RDS
# data/derived_data/thinned_tg_d.RDS



datasets_selection <- read.csv(file.path(datadir, "datasets_selection.csv"))
tempsal <- terra::rast(file.path(envdir, "tempsal.nc"))
thinned_m <- readRDS(file.path(datadir, "thinned_m.RDS"))
thinned_d <- readRDS(file.path(datadir, "thinned_d.RDS"))


# TODO: I don't know how to translate this to the workflow
# if presence_points.csv come from the user, then
#     thinned_tg_m <- thinned_m
#     thinned_tg_d <- thinned_d


# Define the list of datasets that passed through the filtering
list_dasid <- datasets_selection$datasetid

# For a given species and lists of datasets, download the full target-group occurrences
target_group <- download_tg(
    list_dasid = list_dasid,
    spatial_extent = bbox,
    temporal_extent = temporal_extent
)

#Pre-process the target-group similar to the presence data

target_group <- clean_presence(target_group, study_area, temporal_extent)

# Thinning to one occurrence per pixel
thinned_tg_m <- thin_points(
    data = target_group,
    method = "grid",
    group_col = "year_month",
    raster_obj = tempsal[[1]],
    trials = 5,
    long_col = "longitude",
    lat_col = "latitude",
    seed = 1234
)
thinned_tg_m <- thinned_tg_m[[1]]

thinned_tg_d <- thin_points(
    data = target_group,
    method = "grid",
    group_col = "decade",
    long_col = "longitude",
    lat_col = "latitude",
    raster_obj = tempsal[[1]],
    trials = 5,
    seed = 1234
)
thinned_tg_d <- thinned_tg_d[[1]]




saveRDS(target_group, file = file.path(datadir, "target_group.RDS"))
saveRDS(thinned_tg_m, file = file.path(datadir, "thinned_tg_m.RDS"))
saveRDS(thinned_tg_d, file = file.path(datadir, "thinned_tg_d.RDS"))