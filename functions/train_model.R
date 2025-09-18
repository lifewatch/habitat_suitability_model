train_model <- function(occurrences, time = "month", file_path){
cli::cli_h1("Starting model training")
cli::cli_inform(c("v" = paste("Time resolution:", time)))


cli::cli_inform(c("v" = paste("Loaded", nrow(occurrences), "records")))

# file_path can be given in function inputs
ifelse(!dir.exists(file_path), dir.create(file_path), FALSE)
# Creating folds and preparing data
n_folds <- 5
# stratify based on a combination of the occurrence status and either month or decade
# this way all the months/decades are represented and also the ratio of presence/absence is kept
if(time == "month"){
strat <- paste0(as.character(occurrences$occurrence_status),"-",
                as.character(month(ym(occurrences$year_month))))
} else if (time == "decade") {
  strat <- paste0(as.character(occurrences$occurrence_status),"-",
                  as.character(occurrences$decade))
}
strat <- factor(strat)
occurrences <- occurrences%>%
  dplyr::mutate(strat = strat)

cv_folds <- vfold_cv(data = occurrences,
                     v = n_folds,
                     strata = "strat")
occurrences <- occurrences%>%
  dplyr::select(-strat)

#Prepare all the objects necessary for model training in the tidymodels framework
prep <- tidymodels_prep(occurrences, folds = NULL)
train_data <- prep$training_data
ctrl_grid <- prep$ctrl_grid
ctrl_res <- prep$ctrl_res
recipe <- prep$recipe

indices <- list()
for(i in 1:nrow(cv_folds)){
  indices[[i]] <- list(analysis = as.integer(cv_folds$splits[[i]]$in_id), #training data
                       assessment = as.integer(setdiff(1:nrow(occurrences),cv_folds$splits[[i]]$in_id))) #test data
}
splits <- lapply(indices, FUN=make_splits, data = train_data)
cv_folds <- manual_rset(splits, paste0("Fold",seq(1,n_folds)))

cli::cli_inform(c("v" = "Cross-validation folds created"))
# Model training
cli::cli_h2("Starting model fits (parallel mode)")
future::plan(multisession, workers = 5) #Use multisession for parallel processing
registerDoFuture()
fitted_ranger <- ranger_fit(folds = cv_folds, 
                            ensemble_ctrl = ctrl_grid,
                            recipe = recipe)
save_bundle(fitted_ranger, file = file.path(file_path, "fitted_ranger.RDS"))
cli::cli_inform(c("v" = paste("ranger", "model saved")))
fitted_randforest <- randforest_fit(folds = cv_folds,
                                    ensemble_ctrl = ctrl_res,
                                    recipe = recipe)
save_bundle(fitted_randforest, file = file.path(file_path, "fitted_randforest.RDS"))
cli::cli_inform(c("v" = paste("randforest", "model saved")))
fitted_gam <- gam_fit(folds = cv_folds, 
                      ensemble_ctrl = ctrl_grid,
                      recipe = recipe)
save_bundle(fitted_gam, file = file.path(file_path, "fitted_gam.RDS"))
cli::cli_inform(c("v" = paste("gam", "model saved")))
fitted_mars <- mars_fit(folds = cv_folds,
                        ensemble_ctrl = ctrl_grid,
                        recipe = recipe)
save_bundle(fitted_mars, file = file.path(file_path, "fitted_mars.RDS"))
cli::cli_inform(c("v" = paste("mars", "model saved")))
fitted_maxent <- maxent_fit(folds = cv_folds,
                            ensemble_ctrl = ctrl_grid,
                            recipe = recipe)
save_bundle(fitted_maxent, file = file.path(file_path, "fitted_maxent.RDS"))
cli::cli_inform(c("v" = paste("maxent", "model saved")))
fitted_xgb <- xgb_fit(folds = cv_folds,
                      ensemble_ctrl = ctrl_grid,
                      recipe = recipe)
save_bundle(fitted_xgb, file = file.path(file_path, "fitted_xgb.RDS"))
cli::cli_inform(c("v" = paste("xgb", "model saved")))
plan(sequential) #Return to sequential processing
rm(
  fitted_ranger,
  fitted_randforest,
  fitted_gam,
  fitted_mars,
  fitted_maxent,
  fitted_xgb
)
gc()
}
