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

# FUNCTIONS ---------------------------------------------------------------
lapply(list.files("functions", full.names = TRUE),source)
# INPUT -------------------------------------------------------------------

# WORKFLOW ----------------------------------------------------------------
# Define different folders
downloaddir <- "data/raw_data"
datadir     <- "data/derived_data"
mapsdir     <- "results/geospatial_layers"
modeldir   <- "results/models"
figdir    <- "results/figures_tables"
envdir <-"data/raw_data/environmental_layers"
occdir <-"data/raw_data/occurrences"
spatdir <- "data/raw_data/spatial_layers"
scriptsdir <- "code/"
folderstruc <- c(downloaddir,
                 datadir,
                 mapsdir,
                 modeldir,
                 figdir,
                 envdir,
                 occdir,
                 spatdir,
                 scriptsdir)

#Check for their existence, create if missing
for(i in 1:length(folderstruc)){
  if(!dir.exists(folderstruc[i])){
    # If not, create the folder
    dir.create(folderstruc[i],recursive = TRUE)
    cat("Folder created:", folderstruc[i], "\n")
  } else {
    cat("Folder already exists:", folderstruc[i], "\n")
  }
}

#Download the necessary R packages
if(!require('renv'))install.packages('renv')
#Possibly re-start R for renv/activate.R to work.
package_list <- c("arrow",
                  "bundle",
                  "CAST",
                  "CoordinateCleaner",
                  "dismo",
                  "doFuture",
                  "doParallel",
                  "downloader",
                  "foreach",
                  "future",
                  "GeoThinneR",
                  "ks",
                  "mgcv",
                  "modEvA",
                  "ows4R",
                  "randomForest",
                  "ranger",
                  "raster",
                  "sdm",
                  "sf",
                  "sp",
                  "spatialEco",
                  "spatstat",
                  "stacks",
                  "stats",
                  "terra",
                  "tidymodels",
                  "tidysdm",
                  "tidyverse",
                  "utils",
                  "worrms",
                  "xgboost")
#Load all the packages with library()
lapply(package_list, require, character.only = TRUE)
library(imis)

#Define user input choices
study_area <- load_ospar(c("II","III"), filepath = file.path(spatdir,"ospar_regions_2017_01_002.shp"))
bbox <- sf::st_bbox(study_area)
date_start <- as.POSIXct("1999-01-01")
date_end <- as.POSIXct("2019-12-31")
temporal_extent <- lubridate::interval(date_start,date_end)
possible_aphiaids <- c(137117, 137084, 137094, 137111, 137101, 137087)
aphiaid <- possible_aphiaids[1]

#Choosing the bounding box to assess the monthly trend
min_lon <- 1.8
max_lon <- 2.5
min_lat <- 51
max_lat <- 52

# OUTPUT ------------------------------------------------------------------

