##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-04-01
# Script Name: ~/habitat_suitability_model/code/09_ensemble_month_evaluation.R
# Script Description: Nested coss-validation to assess the performance of the training method.
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

## Outer fold (stratified 5-fold CV)
### Stratified 5-fold CV based on presence-only
pres_month <- env_month[env_month$occurrence_status==1,]
outer_month <- vfold_cv(data = pres_month,
                        v = 5,
                        strata = "month")


### add background points to every fold
### Sample random background points that cover the whole study area, these get added to every test set together with the test set fraction of the presences
background_test <- sdm::background(terra::mask(thetao_avg_m[[1]], study_area), n = 10000, method = "gRandom") %>%
  dplyr::select(longitude = x, latitude = y) %>%
  dplyr::mutate(occurrence_status = 0, month = 1) %>%
  couple_env(thetao_rast = thetao_avg_m,
             npp_rast = npp_avg_m,
             so_rast = so_avg_m,
             bathy_rast = bathy,
             timescale = "month")
env_total <- rbind(env_month, background_test)
indices <- list()
for(i in 1:nrow(outer_month)){
  manual_split <- c(outer_month$splits[[i]]$in_id,seq(from = nrow(pres_month)+1, to=nrow(env_month), by=1)) #background points at the end of this dataframe
  indices[[i]] <- list(analysis = as.integer(manual_split), #training data
                       assessment = as.integer(c(setdiff(1:nrow(env_month),manual_split), seq(from = nrow(env_month)+1, to=nrow(env_total), by=1)))) #test set is presence points not used in a fold + background points randomly over the full study area
}
splits <- lapply(indices, FUN=make_splits, data = env_total)
outer_month <- manual_rset(splits, c("Fold1", "Fold2","Fold3","Fold4", "Fold5"))
for( i in 1:nrow(outer_month)){
  train_month <- outer_month$splits[[i]]$data[outer_month$splits[[i]]$in_id,]
}

performance <- list()
parameters <- list()
for( i in 1:nrow(outer_month)){
  train_month <- outer_month$splits[[i]]$data[outer_month$splits[[i]]$in_id,]
  test_month <- outer_month$splits[[i]]$data[outer_month$splits[[i]]$out_id,]
  ifelse(!dir.exists(file.path(datadir, "modelling_monthly", paste0("fold",i))), dir.create(file.path(datadir, "modelling_monthly", paste0("fold",i))), FALSE)
  ##Inner-fold based on the knndm CAST R package
  monthly_prep <- tidymodels_prep(train_month)
  train_data_m <- monthly_prep$training_data
  ctrl_grid_m <- monthly_prep$ctrl_grid
  ctrl_res_m <- monthly_prep$ctrl_res
  recipe_m <- monthly_prep$recipe
  
  prediction_layers <- terra::sds(thetao_avg_m, so_avg_m, npp_avg_m, bathy)
  names(prediction_layers) <- c("thetao", "so", "npp", "bathy")
  
  #prediction_layers need same order as train_data otherwise knndm function throws an error
  prediction_layers <- prediction_layers[names(train_data_m)[-1]] #train data with only environmental columns
  
  monthly_folds <- knndm_fold(train_data_m, prediction_layers = prediction_layers, n_folds = 4)
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
  save_bundle(fitted_month, file = file.path(datadir, "modelling_monthly",paste0("fold",i), "fitted_month.RDS"))
  
  performance[[paste0("fold",i)]] <-performance_metrics(model_fit = fitted_month, 
                                                        predict_data = test_month,
                                                        response_variable = "occurrence_status")
  saveRDS(performance[[paste0("fold",i)]], file = file.path(datadir, "modelling_monthly",paste0("fold",i), "performance.RDS"))
  parameters[[paste0("fold",i)]] <- list(ranger = collect_parameters(fitted_month, "fitted_ranger"),
                                         randforest = collect_parameters(fitted_month, "fitted_randforest"),
                                         gam = collect_parameters(fitted_month, "fitted_gam"),
                                         mars = collect_parameters(fitted_month, "fitted_mars"),
                                         maxent = collect_parameters(fitted_month, "fitted_maxent"),
                                         xgb = collect_parameters(fitted_month, "fitted_xgb"))
  saveRDS(parameters[[paste0("fold",i)]], file = file.path(datadir, "modelling_monthly",paste0("fold",i), "parameters.RDS"))
}
write.csv(dplyr::bind_rows(performance, .id = "fold"), file = file.path(datadir, "modelling_monthly", "performance_month_cv.csv"))
saveRDS(parameters, file = file.path(datadir, "modelling_monthly", "parameters_month_cv.RDS"))

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


