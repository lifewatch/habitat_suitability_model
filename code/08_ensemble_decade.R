##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-04-01
# Script Name: ~/habitat_suitability_model/code/08_ensemble_decade.R
# Script Description: Training the decadal model. 
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

# INPUT -------------------------------------------------------------------
env_decade <- readRDS(file=file.path(datadir,"env_decade.RDS"))
env_decade


# WORKFLOW ----------------------------------------------------------------

#Create folder if it does not exist yet
ifelse(!dir.exists(file.path(datadir, "modelling_decade")), dir.create(file.path(datadir, "modelling_decade")), FALSE)

# Creating folds and preparing data

## Outer fold (stratified 5-fold CV)
### Stratified 4-fold CV based on presence-only
presence_decad <- env_decade[env_decade$occurrence_status==1,]
outer_decad <- vfold_cv(data = presence_decad,
                        v = 5,
                        strata = "decade")

### add background points to every fold
indices <- list()
for(i in 1:nrow(outer_decad)){
  manual_split <- c(outer_decad$splits[[i]]$in_id,seq(from = nrow(presence_decad)+1, to=nrow(env_decade), by=1)) #background points at the end of this dataframe
  indices[[i]] <- list(analysis = as.integer(manual_split),
                       assessment = setdiff(1:nrow(env_decade),manual_split)) #test set is presence points not used in a fold
}
splits <- lapply(indices, FUN=make_splits, data = env_decade)
outer_decad <- manual_rset(splits, c("Fold1", "Fold2","Fold3","Fold4", "Fold5"))
outer_decad
outer_decad$splits[[1]]
for( i in 1:nrow(outer_decad)){
  train_decad <- outer_decad$splits[[i]]$data[outer_decad$splits[[i]]$in_id,]
}

## Inner fold (LTO-CV)
inner_decad <- CAST::CreateSpacetimeFolds(
  train_decad,
  spacevar = NA,
  timevar = "decade",
  k = 3,
  class = NA,
  seed = sample(1:1000, 1)
)
splits_pre <- c()
for(i in 1:3){
  splits_pre[[i]] <- list(analysis = inner_decad$index[[i]],
                          assessment = inner_decad$indexOut[[i]])
}

decade_prep <- tidymodels_prep(train_decad, folds = NULL)
train_data_d <- decade_prep$training_data
ctrl_grid_d <- decade_prep$ctrl_grid
ctrl_res_d <- decade_prep$ctrl_res
recipe_d <- decade_prep$recipe
splits <- lapply(splits_pre, FUN= make_splits, data = train_data_d)
inner_decad <- manual_rset(splits,c("Fold1","Fold2","Fold3"))
decade_prep$folds <- inner_decad

# Model training 
plan(multisession, workers = 6) #Use multisession for parallel processing
registerDoFuture()
fitted_ranger <- ranger_fit(folds = inner_decad, 
                            ensemble_ctrl = ctrl_grid_d,
                            recipe = recipe_d)
#here save output already
save_bundle(fitted_ranger, file = file.path(datadir, "modelling_decade", "ranger.RDS"))
fitted_randforest <- randforest_fit(folds = inner_decad,
                                    ensemble_ctrl = ctrl_res_d,
                                    recipe = recipe_d)
save_bundle(fitted_randforest, file = file.path(datadir, "modelling_decade", "randforest.RDS"))
fitted_gam <- gam_fit(folds = inner_decad, 
                      ensemble_ctrl = ctrl_grid_d,
                      recipe = recipe_d)
save_bundle(fitted_gam, file = file.path(datadir, "modelling_decade", "gam.RDS"))
fitted_mars <- mars_fit(folds = inner_decad,
                        ensemble_ctrl = ctrl_grid_d,
                        recipe = recipe_d)
save_bundle(fitted_mars, file = file.path(datadir, "modelling_decade", "mars.RDS"))
fitted_maxent <- maxent_fit(folds = inner_decad,
                            ensemble_ctrl = ctrl_grid_d,
                            recipe = recipe_d)
save_bundle(fitted_maxent, file = file.path(datadir, "modelling_decade", "maxent.RDS"))
fitted_xgb <- xgb_fit(folds = inner_decad,
                            ensemble_ctrl = ctrl_grid_d,
                            recipe = recipe_d)
save_bundle(fitted_xgb, file = file.path(datadir, "modelling_decade", "xgb.RDS"))

plan(sequential) #Return to sequential processing
stack_data <- 
  stacks() %>%
  add_candidates(fitted_ranger) %>%
  add_candidates(fitted_randforest)%>%
  add_candidates(fitted_gam)%>%
  add_candidates(fitted_mars)%>%
  add_candidates(fitted_maxent)%>%
  add_candidates(fitted_xgb)

stack_data
saveRDS(stack_data, file = file.path(datadir, "modelling_decade", "stack_data.RDS"))

stack_mod <-
  blend_predictions(stack_data, metric= yardstick::metric_set(boyce_cont))
saveRDS(stack_mod, file = file.path(datadir, "modelling_decade", "stack_mod.RDS"))

stack_fit <-
  stack_mod %>%
  fit_members()
save_bundle(stack_fit, file = file.path(datadir, "modelling_decade", "stack_fit.RDS"))


# OUTPUT ------------------------------------------------------------------
#fitted_ranger
#fitted_randforest
# fitted_gam
# fitted_mars
# fitted_maxent
# fitted_xgb
# stack_data
# stack_mod
# stack_fit
