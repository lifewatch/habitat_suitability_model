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
path = list(
  setup = "/mnt/inputs/01_setup.json",
  code = "./code",
  study_area_file = "/mnt/inputs/study_area.RDS"
)

# source("code/01_setup.R")
lapply(list.files("functions", full.names = TRUE),source)
sapply(list.files(path$code, full.names = T), source)
lapply(list.files("/wrp/utils", full.names = TRUE, pattern = "\\.R$"), source)

args = args_parse(commandArgs(trailingOnly = TRUE))

# Read the setup file and load the variables
print("--------------------------Inputs--------------------------")
setup <- jsonlite::read_json(path$setup)
datadir = setup$datadir
# Load aphiaid as numeric
aphiaid = setup$aphiaid
print(paste("Aphia ID:", aphiaid))
spatdir = setup$spatdir
study_area_file = path$study_area_file
print(paste("Study area file:", study_area_file))
temporal_extent = setup$temporal_extent
print(paste("Temporal extent:", temporal_extent))
print("----------------------------------------------------------")
##################################################################################
##################################################################################

# FUNCTIONS ---------------------------------------------------------------
#fdr2
#load_presence
#connect_eurobis

# INPUT -------------------------------------------------------------------
# Load the study area RDS file
study_area <- readRDS(study_area_file)
bbox <- sf::st_bbox(study_area)
# WORKFLOW ----------------------------------------------------------------
#Downloading the occurrence data from EurOBIS
mydata_eurobis <- load_presence(aphia_id = aphiaid,
                               spatial_extent = bbox,
                               temporal_extent = temporal_extent)
#
# # generate dataset metadata
# datasetidsoi <- mydata_eurobis %>% distinct(datasetid) %>%
#   mutate(datasetid = as.numeric(str_extract(datasetid, "\\d+")))
# # retrieve data by dataset
# all_info <- data.frame()
#
# for (i in datasetidsoi$datasetid){
#   dataset_info <- fdr2(i)
#   all_info <- rbind(all_info, dataset_info)
# }
#
# names(all_info)[1]<-"datasetid"
#
#
#
# # OUTPUT -----------------------------------------------------------------
#
# #Save output
# write.csv(all_info,file=file.path(datadir,"datasets_all.csv"),row.names = F, append=FALSE)
# saveRDS(mydata_eurobis, file = file.path(datadir, "mydata_eurobis.RDS"))
# saveRDS(study_area, file = file.path(datadir, "study_area.RDS"))
