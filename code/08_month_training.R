##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-04-01
# Script Name: ~/habitat_suitability_model/code/09_ensemble_month_final_fit.R
# Script Description: Train the monthly model on the entire dataset.
# SETUP ------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
source("code/01_setup.R")

##################################################################################
##################################################################################

# WORKFLOW

env_month <- readRDS(file.path(datadir,
                               paste0("env_month.RDS"))) 
train_model(occurrences = env_month,
            time = "month",
            file_path = file.path(datadir,
                                  "modelling_month",
                                  "final"))

stack_model(file_path = file.path(datadir,
                                  "modelling_month",
                                  "final"))
