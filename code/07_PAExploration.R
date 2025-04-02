##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-28
# Script Name: ~/habitat_suitability_model/code/07_PAExploration.R
# Script Description: Make plots to assess the input data of the model
# SETUP ------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
source("code/01_setup.R")

##################################################################################
##################################################################################


# FUNCTIONS ---------------------------------------------------------------
#plot_spatial


# INPUT -------------------------------------------------------------------
cleaned_data <- readRDS(file.path(datadir, "cleaned_data.RDS"))

# WORKFLOW ----------------------------------------------------------------
spatial_decade <- plot_spatial(study_area, presence_data = cleaned_data, timescale= "decade")

temporal_decade <- ggplot(data = cleaned_data, aes(x = decade)) + 
  stat_count()+
  theme(plot.title = element_text(size=14), axis.title= element_text(size = 12),
        text = element_text(size = 12))+
  labs(title = paste("decadal occurrence records AphiaID",aphiaid))

spatial_month <- plot_spatial(study_area, presence_data = cleaned_data, timescale= "month")

temporal_month <- ggplot(data = cleaned_data, aes(x = as.factor(month))) + 
  stat_count()+
  theme(plot.title = element_text(size=14), axis.title= element_text(size = 12),
        text = element_text(size = 12))+
  labs(title = paste("monthly occurrence records AphiaID",aphiaid))


# OUTPUT ------------------------------------------------------------------

ggsave(filename = paste0("spatial_decade",aphiaid,".png"), plot = spatial_decade, path = figdir, width = 6, height = 4, dpi = 300)
ggsave(filename = paste0("temporal_decade",aphiaid,".png"), plot = temporal_decade, path = figdir, width = 6, height = 4, dpi = 300)
ggsave(filename = paste0("spatial_month",aphiaid,".png"), plot = spatial_month, path = figdir, width = 6, height = 4, dpi = 300)
ggsave(filename = paste0("temporal_month",aphiaid,".png"), plot = temporal_month, path = figdir, width = 6, height = 4, dpi = 300)

