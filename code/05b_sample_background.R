##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-26
# Script Name: ~/habitat_suitability_model/code/05_sample_background.R
# Script Description: Sample the background based on the target-group background
# methodolody.

source("load_common_packages.R")
source("functions/connect_eurobis.R")
source("functions/download_tg.R")
source("functions/normalize_raster.R")
source("functions/sample_background.R")


# INPUT VARIABLES
#===============================================================
# **envdir**
# **datadir**
# study_area


# INPUT FILES
#===============================================================
# data/raw_data/environmental_layers/tempsal.nc
# data/derived_data/thinned_m.RDS
# data/derived_data/thinned_d.RDS
# data/derived_data/thinned_tg_m.RDS
# data/derived_data/thinned_tg_d.RDS

# OUTPUT FILES
#===============================================================
# data/derived_data/pback_month.RDS
# data/derived_data/pback_decade.RDS


# datasets_selection <- read.csv(file.path(datadir, "datasets_selection.csv"))
tempsal <- terra::rast(file.path(envdir, "tempsal.nc"))
thinned_m <- readRDS(file.path(datadir, "thinned_m.RDS"))
thinned_d <- readRDS(file.path(datadir, "thinned_d.RDS"))
thinned_tg_m <- readRDS(file.path(datadir, "thinned_tg_m.RDS"))
thinned_tg_d <- readRDS(file.path(datadir, "thinned_tg_d.RDS"))
# WORKFLOW ----------------------------------------------------------------


# Given a specific subsetting (e.g. monthly) of the presence data, sample a background for every subset
spatial_extent_proj <- st_transform(study_area, crs=25832)
#as.owin needs a projected CRS, not a geographic (latitude-longitude) CRS like WGS84.
#We need to reproject out object to a projected CRS, such as UTM, suitable for the analysis in meters.
#https://epsg.io/25832
win <- as.owin(spatial_extent_proj)
tgb_decade <- sample_background(target_group_data = thinned_tg_d,
                  grouping = "decade",
                  resample_layer = tempsal[[1]],
                  window = win,
                  n_multiplier = 5,
                  presence_data = thinned_d)

tgb_month <- sample_background(target_group_data = thinned_tg_m,
                               grouping = "year_month",
                               resample_layer = tempsal[[1]],
                               window = win,
                               n_multiplier = 5,
                               presence_data = thinned_m)

# OUTPUT -----------------------------------------------------------------
pback_month <- rbind(thinned_m%>%dplyr::select(-c(decade, month)), tgb_month) #presence-background data monthly
saveRDS(pback_month, file = file.path(datadir, "pback_month.RDS"))
pback_decade <- rbind(thinned_d%>%dplyr::select(-c(month, year_month)), tgb_decade)
saveRDS(pback_decade, file = file.path(datadir,"pback_decade.RDS"))




