##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-04-01
# Script Name: ~/habitat_suitability_model/code/09_ensemble_month_final_fit.R
# Script Description: Train the monthly model on the entire dataset.

source("load_common_packages.R")
source("functions/stack_model.R")
source("functions/train_model.R")

# INPUT VARIABLES
#===============================================================
# datadir = data/derived_data

# INPUT FILES
#===============================================================
# data/derived_data/env_decade.RDS

# OUTPUT FILES
#===============================================================
# data/derived_data/modelling_decade/final/*


ifelse(!dir.exists(file.path(datadir,
                             "modelling_decade")), dir.create(file.path(datadir,
                                                                       "modelling_decade")), FALSE)
env_decade <- readRDS(file.path(datadir,
                               paste0("env_decade.RDS")))
train_model(occurrences = env_decade,
            time = "decade",
            file_path = file.path(datadir,
                                  "modelling_decade",
                                  "final"))

stack_model(file_path = file.path(datadir,
                                  "modelling_decade",
                                  "final"))
