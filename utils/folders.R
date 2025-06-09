# Define different folders
downloaddir <- "/mnt/data/raw_data"
datadir     <- "/mnt/data/derived_data"
mapsdir     <- "/mnt/results/geospatial_layers"
modeldir   <- "/mnt/results/models"
figdir    <- "/mnt/results/figures_tables"
envdir <-"/mnt/data/raw_data/environmental_layers"
occdir <-"/mnt/data/raw_data/occurrences"
spatdir <- "/mnt/data/raw_data/spatial_layers"
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