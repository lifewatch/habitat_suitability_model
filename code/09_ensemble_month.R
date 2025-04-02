##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-04-01
# Script Name: ~/habitat_suitability_model/code/09_ensemble_month.R
# Script Description: Train the monthly model.
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
load(file.path(datadir, "env_month.RData"))
thetao_avg_m <- terra::rast(file.path(datadir, "thetao_avg_m.tif"))
so_avg_m <- terra::rast(file.path(datadir, "so_avg_m.tif"))
npp_avg_m <- terra::rast(file.path(datadir, "npp_avg_m.tif"))
bathy <- terra::rast(file.path(envdir, "bathy.nc"))
bathy <-resample(bathy, thetao_avg_m)


# WORKFLOW ----------------------------------------------------------------

#Create a folder if it does not exist yet
ifelse(!dir.exists(file.path(datadir, "modelling_monthly")), dir.create(file.path(datadir, "modelling_monthly")), FALSE)


# Creating folds and preparing data  

## Outer fold (stratified 4-fold CV)
### Stratified 4-fold CV based on presence-only
pres_month <- env_month[env_month$occurrence_status==1,]
outer_month <- vfold_cv(data = pres_month,
                        v = 4,
                        strata = "month")

### add background points to every fold
indices <- list()
for(i in 1:nrow(outer_month)){
  manual_split <- c(outer_month$splits[[i]]$in_id,seq(from = nrow(pres_month)+1, to=nrow(env_month), by=1)) #background points at the end of this dataframe
  indices[[i]] <- list(analysis = as.integer(manual_split),
                       assessment = setdiff(1:nrow(env_month),manual_split)) #test set is presence points not used in a fold
}
splits <- lapply(indices, FUN=make_splits, data = env_month)
outer_month <- manual_rset(splits, c("Fold1", "Fold2","Fold3","Fold4"))

for( i in 1:nrow(outer_month)){
  train_month <- outer_month$splits[[i]]$data[outer_month$splits[[i]]$in_id,]
}

##Inner-fold based on the knndm CAST R package
monthly_prep <- tidymodels_prep(train_month)
train_data_m <- monthly_prep$training_data
ctrl_grid_m <- monthly_prep$ctrl_grid
ctrl_res_m <- monthly_prep$ctrl_res
recipe_m <- monthly_prep$recipe

prediction_layers <- terra::sds(thetao_avg_m, so_avg_m, npp_avg_m, bathy)
names(prediction_layers) <- c("thetao", "so", "npp", "bathy")

start_time <- Sys.time()
monthly_folds <- knndm_fold(train_data_m, prediction_layers = prediction_layers)
print(Sys.time() - start_time)
inner_month <- monthly_folds$rsample_folds
monthly_prep$folds <- inner_month

# Model training
plan(multisession, workers = 6) #Use multisession for parallel processing
registerDoFuture()
fitted_ranger <- ranger_fit(folds = inner_month, 
                            ensemble_ctrl = ctrl_grid_m,
                            recipe = recipe_m)
#here save output already
save_bundle(fitted_ranger, file = file.path(datadir, "modelling_monthly", "ranger.RDS"))
fitted_randforest <- randforest_fit(folds = inner_month,
                                    ensemble_ctrl = ctrl_res_m,
                                    recipe = recipe_m)
save_bundle(fitted_randforest, file = file.path(datadir, "modelling_monthly", "randforest.RDS"))
fitted_gam <- gam_fit(folds = inner_month, 
                      ensemble_ctrl = ctrl_grid_m,
                      recipe = recipe_m)
save_bundle(fitted_gam, file = file.path(datadir, "modelling_monthly", "gam.RDS"))
fitted_mars <- mars_fit(folds = inner_month,
                        ensemble_ctrl = ctrl_grid_m,
                        recipe = recipe_m)
save_bundle(fitted_mars, file = file.path(datadir, "modelling_monthly", "mars.RDS"))
fitted_maxent <- maxent_fit(folds = inner_month,
                            ensemble_ctrl = ctrl_grid_m,
                            recipe = recipe_m)
save_bundle(fitted_maxent, file = file.path(datadir, "modelling_monthly", "maxent.RDS"))
fitted_xgb <- xgb_fit(folds = inner_month,
                            ensemble_ctrl = ctrl_grid_m,
                            recipe = recipe_m)
save_bundle(fitted_xgb, file = file.path(datadir, "modelling_monthly", "xgb.RDS"))

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
saveRDS(stack_data, file = file.path(datadir, "modelling_monthly", "stack_data.RDS"))

stack_mod <-
  blend_predictions(stack_data, metric= yardstick::metric_set(boyce_cont))
saveRDS(stack_mod, file = file.path(datadir, "modelling_monthly", "stack_mod.RDS"))

stack_fit <-
  stack_mod %>%
  fit_members()
save_bundle(stack_fit, file = file.path(datadir, "modelling_monthly", "stack_fit.RDS"))


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

