##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-04-01
# Script Name: ~/habitat_suitability_model/code/08_decade_evaluation.R
# Script Description: Evaluate the decadal training with cross-validation.
# SETUP ------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
source("code/01_setup.R")

##################################################################################
##################################################################################

# WORKFLOW

env_decade <- readRDS(file.path(datadir,
                               paste0("env_decade.RDS"))) 
evaluate_model(occurrences = env_decade,
               time = "decade",
               file_path_general = file.path(datadir,
                                             "modelling_decade"))
