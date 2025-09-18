##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-19
# Script Name: ~/habitat_suitability_model/code/02_download_presences.R
# Script Description: In this script, the study area is defined and the occurrences
# of a species of choice inside this area are downloaded together with an overview 
# of the datasets.
# SETUP ------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
source("code/01_setup.R")

##################################################################################
##################################################################################

# FUNCTIONS ---------------------------------------------------------------
#fdr2
#load_presence
#connect_eurobis

# INPUT -------------------------------------------------------------------

# WORKFLOW ----------------------------------------------------------------
if(is.null(user_data)){
  #Downloading the occurrence data from EurOBIS
  presence_points <- load_presence(aphia_id = aphiaid, 
                                   spatial_extent = bbox,
                                   temporal_extent = temporal_extent)
  
  # generate dataset metadata
  datasetidsoi <- presence_points %>% distinct(datasetid) %>% 
    mutate(datasetid = as.numeric(str_extract(datasetid, "\\d+")))
  # retrieve data by dataset
  all_info <- data.frame()
  
  for (i in datasetidsoi$datasetid){
    dataset_info <- fdr2(i)
    all_info <- rbind(all_info, dataset_info)
  }
  
  names(all_info)[1]<-"datasetid"
  
  # Filter out datasets based on a keyword
  word_filter <- c("stranding", "museum")
  datasets_selection <- filter_dataset(all_info,method="filter",filter_words = word_filter)
  
  presence_points <- presence_points%>%
    filter(datasetid %in% datasets_selection$datasetid) %>%
    dplyr::select(!c(datasetid))
  
  # OUTPUT -----------------------------------------------------------------
  
  #Save output
  write.csv(all_info,file=file.path(datadir,"datasets_all.csv"),row.names = F, append=FALSE)
  write.csv(datasets_selection ,file=file.path(datadir,"datasets_selection.csv"),row.names = FALSE, append=FALSE)
  write.csv(presence_points, file = file.path(datadir, "presence_points.csv"), row.names = FALSE, append = FALSE)
}
