##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-19
# Script Name: ~/habitat_suitability_model/code/02_download_presences.R
# Script Description: In this script, the study area is defined and the occurrences
# of a species of choice inside this area are downloaded together with an overview
# of the datasets.

source("load_common_packages.R")
source("functions/connect_eurobis.R")
source("functions/fdr2.R")
source("functions/filter_dataset.R")
source("functions/load_presence.R")


# INPUT -------------------------------------------------------------------

# **datadir**
# aphiaid
# bbox
# temporal_extent

# OUTPUT -------------------------------------------------------------------

# data
#     derived_data
#         datasets_all.csv
#         datasets_selection.csv
#         presence_points.csv



# WORKFLOW ----------------------------------------------------------------

#Downloading the occurrence data from EurOBIS
presence_points <- load_presence(aphia_id = aphiaid,
                                spatial_extent = bbox,
                                temporal_extent = temporal_extent)

# generate dataset metadata
datasetidsoi <- presence_points %>% distinct(datasetid) %>%
mutate(datasetid = as.numeric(str_extract(datasetid, "\\d+")))
# retrieve data by dataset

all_info <- do.call(rbind, lapply(datasetidsoi$datasetid, fdr2))
names(all_info)[1]<-"datasetid"

# Filter out datasets based on a keyword
word_filter <- c("stranding", "museum")
datasets_selection <- filter_dataset(all_info,method="filter",filter_words = word_filter)

filtered_presence_points <- presence_points %>%
    filter(datasetid %in% datasets_selection$datasetid) %>%
    dplyr::select(!c(datasetid))

# OUTPUT -----------------------------------------------------------------

#Save output
write.csv(all_info,file=file.path(datadir,"datasets_all.csv"),row.names = F)
write.csv(datasets_selection ,file=file.path(datadir,"datasets_selection.csv"),row.names = FALSE)
write.csv(filtered_presence_points, file = file.path(datadir, "presence_points.csv"), row.names = FALSE)

