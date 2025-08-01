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
# install.packages("vlizBE/imis")
 # pkgs_installed <- installed.packages(lib.loc = renv::paths$library())[, "Package"]
 # renv::install(setdiff(unique(renv::dependencies()$Package), pkgs_installed))
# devtools::install_github("bio-oracle/biooracler")

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
                  "mgcv",
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

#Study area
if(!exists("study_area")){ #If no user study_area shapefile was given, ospar regions II, III and IV are chosen
study_area <- load_ospar(c("II","III", 'IV'), filepath = file.path(spatdir,"ospar_regions_2017_01_002.shp"))
}
bbox <- sf::st_bbox(study_area)

date_start <- as.POSIXct("2000-01-01")
date_end <- as.POSIXct("2019-12-31")
temporal_extent <- lubridate::interval(date_start,date_end)
possible_aphiaids <- c(137117, #Phocoena phocoena
                       137084, #Phoca vitulina
                       137094, #Delphinus delphis
                       137111) #Tursiops truncatus
                       
aphiaid <- possible_aphiaids[1] #Choice of species

# User data presences instead of EurOBIS data
user_data <- NULL
user_data_path <- NULL #Change this with the path to your user data .csv file
if(!is.null(user_data_path)){
  user_data <- read.csv(user_data_path)
}

# OUTPUT ------------------------------------------------------------------

