# Define different folders
downloaddir <- "data/raw_data"
datadir     <- "data/derived_data"
mapsdir     <- "product/maps"
rasterdir   <- "product/species_rasters"
plotsdir    <- "product/species_plots"
envdir <-"data/raw_data/environmental_layers"
occdir <-"data/raw_data/occurrences"
spatdir <- "data/raw_data/spatial_layers"
folderstruc <- c(downloaddir,
                 datadir,
                 mapsdir,
                 rasterdir,
                 plotsdir,
                 envdir,
                 occdir,
                 spatdir)

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
#Using the pacman R package, multiple packages can be downloaded easily 
if(!require('pacman'))install.packages('pacman')
pacman::p_load("arules",
               "arulesViz",
               "CoordinateCleaner",
               "downloader",
               "earth",
               "eurobis",
               "imis",
               "mgcv",
               "ows4R",
               "pacman",
               "ranger",
               "raster",
               "sf",
               "sp",
               "stacks",
               "stats",
               "terra",
               "tidymodels",
               "tidyverse",
               "utils",
               "worrms",
               "xgboost")

#For the packages that need to be installed from github
pacman::p_install_gh("vlizBE/imis",
                     "tidymodels/tune")
