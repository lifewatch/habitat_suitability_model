# Define different folders
downloaddir <- "data/raw_data"
datadir     <- "data/derived_data"
mapsdir     <- "product/maps"
rasterdir   <- "product/species_rasters"
plotsdir    <- "product/species_plots"
envdir <-"data/raw_data/environmental_layers"
occdir <-"data/raw_data/occurrences"
spatdir <- "data/raw_data/spatial_layers"
scriptsdir <- "model_training/"
folderstruc <- c(downloaddir,
                 datadir,
                 mapsdir,
                 rasterdir,
                 plotsdir,
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
                  "CoordinateCleaner",
                  "dismo",
                  "downloader",
                  "foreach",
                  "ks",
                  "mgcv",
                  "ows4R",
                  "ranger",
                  "raster",
                  "sdm",
                  "sf",
                  "sp",
                  "spatialEco",
                  "stacks",
                  "stats",
                  "terra",
                  "tidymodels",
                  "tidyverse",
                  "utils",
                  "worrms",
                  "xgboost")
#For the packages that need to be installed from github
package_list_github <-c("vlizBE/imis",
                        "tidymodels/tune")
#Load all the packages with library()
lapply(package_list, library, character.only = TRUE)
library(imis)
