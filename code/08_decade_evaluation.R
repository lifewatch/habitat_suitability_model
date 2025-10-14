##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-04-01
# Script Name: ~/habitat_suitability_model/code/08_decade_evaluation.R
# Script Description: Evaluate the decadal training with cross-validation.

source("load_common_packages.R")
source("functions/evaluate_model.R")

# INPUT VARIABLES
#===============================================================
# datadir = data/derived_data

# INPUT FILES
#===============================================================
# data/derived_data/env_decade.RDS

# OUTPUT FILES
#===============================================================
# data/derived_data/modelling_decade/*



##################################################################################
##################################################################################

# WORKFLOW

env_decade <- readRDS(file.path(datadir,
                               paste0("env_decade.RDS")))
evaluate_model(occurrences = env_decade,
               time = "decade",
               file_path_general = file.path(datadir,
                                             "modelling_decade"))
