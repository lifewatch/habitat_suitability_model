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



# FUNCTIONS ---------------------------------------------------------------
#tidymodels_preparation
#gam_fit
#mars_fit
#maxent_fit
#randforest_fit
#ranger_fit
#xgb_fit
#save_bundle
#knndm_fold

# INPUT -------------------------------------------------------------------
env_month <- readRDS(file.path(datadir,"env_month.RDS"))
thetao_avg_m <- terra::rast(file.path(datadir, "thetao_avg_m.tif"))
so_avg_m <- terra::rast(file.path(datadir, "so_avg_m.tif"))
npp_avg_m <- terra::rast(file.path(datadir, "npp_avg_m.tif"))
bathy <- terra::rast(file.path(envdir, "bathy.nc"))
bathy <-resample(bathy, thetao_avg_m)


# WORKFLOW ----------------------------------------------------------------

#Create a folder if it does not exist yet
ifelse(!dir.exists(file.path(datadir, "modelling_monthly")), dir.create(file.path(datadir, "modelling_monthly")), FALSE)


# Creating folds and preparing data  
##Inner-fold based on the knndm CAST R package
monthly_prep <- tidymodels_prep(env_month)
train_data_m <- monthly_prep$training_data
ctrl_grid_m <- monthly_prep$ctrl_grid
ctrl_res_m <- monthly_prep$ctrl_res
recipe_m <- monthly_prep$recipe

prediction_layers <- terra::sds(thetao_avg_m, so_avg_m, npp_avg_m, bathy)
names(prediction_layers) <- c("thetao", "so", "npp", "bathy")

#prediction_layers need same order as train_data
prediction_layers <- prediction_layers[names(train_data_m)[-1]] #train data with only environmental columns

monthly_folds <- knndm_fold(train_data_m, prediction_layers = prediction_layers)
inner_month <- monthly_folds$rsample_folds
monthly_prep$folds <- inner_month

# Model training
plan(multisession, workers = 6) #Use multisession for parallel processing
registerDoFuture()
fitted_ranger <- ranger_fit(folds = inner_month, 
                            ensemble_ctrl = ctrl_grid_m,
                            recipe = recipe_m)
fitted_randforest <- randforest_fit(folds = inner_month,
                                    ensemble_ctrl = ctrl_res_m,
                                    recipe = recipe_m)
fitted_gam <- gam_fit(folds = inner_month, 
                      ensemble_ctrl = ctrl_grid_m,
                      recipe = recipe_m)
fitted_mars <- mars_fit(folds = inner_month,
                        ensemble_ctrl = ctrl_grid_m,
                        recipe = recipe_m)
fitted_maxent <- maxent_fit(folds = inner_month,
                            ensemble_ctrl = ctrl_grid_m,
                            recipe = recipe_m)
fitted_xgb <- xgb_fit(folds = inner_month,
                      ensemble_ctrl = ctrl_grid_m,
                      recipe = recipe_m)

plan(sequential) #Return to sequential processing
stack_data <- 
  stacks() %>%
  add_candidates(fitted_ranger) %>%
  add_candidates(fitted_randforest)%>%
  add_candidates(fitted_gam)%>%
  add_candidates(fitted_mars)%>%
  add_candidates(fitted_maxent)%>%
  add_candidates(fitted_xgb)

stack_mod <-
  blend_predictions(stack_data, metric= yardstick::metric_set(boyce_cont))

fitted_month <-
  stack_mod %>%
  fit_members()
save_bundle(fitted_month, file = file.path(datadir, "modelling_monthly", "fitted_month.RDS"))

performance <-performance_metrics(model_fit = fitted_month, 
                                                      predict_data = env_month,
                                                      response_variable = "occurrence_status")
write.csv(performance, file = file.path(datadir, "modelling_monthly", "train_performance_final_month.csv"))
parameters <- list(ranger = collect_parameters(fitted_month, "fitted_ranger"),
                                       randforest = collect_parameters(fitted_month, "fitted_randforest"),
                                       gam = collect_parameters(fitted_month, "fitted_gam"),
                                       mars = collect_parameters(fitted_month, "fitted_mars"),
                                       maxent = collect_parameters(fitted_month, "fitted_maxent"),
                                       xgb = collect_parameters(fitted_month, "fitted_xgb"))
saveRDS(parameters, file = file.path(datadir, "modelling_monthly", "parameters_final_month.RDS"))

# OUTPUT ------------------------------------------------------------------
#fitted_ranger
#fitted_randforest
# fitted_gam
# fitted_mars
# fitted_maxent
# fitted_xgb
# stack_data
# stack_mod
# fitted_month

