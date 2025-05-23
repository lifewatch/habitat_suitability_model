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
target_group <- readRDS(file.path(datadir, "target_group.RDS"))
# WORKFLOW ----------------------------------------------------------------

# Thinning to one occurrence per pixel
thinned_tg_m <- thin_points(
  data = target_group,
  method = "grid",
  group_col = "month",
  raster_obj = tempsal[[1]],
  trials = 5,
  seed = 1234
)
thinned_tg_m <- thinned_tg_m[[1]]%>%dplyr::select(
  longitude = long,
  latitude = lat,
  occurrence_status,
  month,
  decade
)

thinned_tg_d <- thin_points(
  data = target_group,
  method = "grid",
  group_col = "decade",
  raster_obj = tempsal[[1]],
  trials = 5,
  seed = 1234
)
thinned_tg_d <- thinned_tg_d[[1]]%>%dplyr::select(
  longitude = long,
  latitude = lat,
  occurrence_status,
  month,
  decade
)

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
                               grouping = "month",
                               resample_layer = tempsal[[1]],
                               window = win,
                               n_multiplier = 5,
                               presence_data = thinned_m)
# OUTPUT -----------------------------------------------------------------
pback_month <- rbind(thinned_m%>%dplyr::select(-decade), tgb_month) #presence-background data monthly
saveRDS(pback_month, file = file.path(datadir, "pback_month.RDS"))
pback_decade <- rbind(thinned_d%>%dplyr::select(-month), tgb_decade)
saveRDS(pback_decade, file = file.path(datadir,"pback_decade.RDS"))
saveRDS(thinned_tg_m, file=file.path(datadir,"thinned_tg_m.RDS"))
saveRDS(thinned_tg_d, file=file.path(datadir,"thinned_tg_d.RDS"))



