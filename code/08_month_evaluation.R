##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-04-01
# Script Name: ~/habitat_suitability_model/code/09_ensemble_month_final_fit.R
# Script Description: Train the monthly model on the entire dataset.

source("load_common_packages.R")
source("functions/evaluate_model.R")

# INPUT VARIABLES
#===============================================================
# datadir = data/derived_data

# INPUT FILES
#===============================================================
# data/derived_data/env_month.RDS

# OUTPUT FILES
#===============================================================
# data/derived_data/modelling_month/*


##################################################################################
##################################################################################

# WORKFLOW

env_month <- readRDS(file.path(datadir,
                               paste0("env_month.RDS")))
evaluate_model(occurrences = env_month,
               time = "month",
               file_path_general = file.path(datadir,
                                             "modelling_month"))
