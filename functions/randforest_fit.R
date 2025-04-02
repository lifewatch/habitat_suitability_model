#' Fit a Random Forest Model Using randomForest Engine
#'
#' This function fits a Random Forest classification model using the `randomForest` engine. It calculates minimum sample sizes for each class based on resampling splits and evaluates model performance using specified metrics.
#'
#' @param folds A resampling object (e.g., created with `vfold_cv`) for cross-validation.
#' @param ensemble_ctrl A control object for the resampling process, created with `control_resamples()`.
#' @param recipe A preprocessed recipe object specifying the data transformations.
#' @return A `resample_results` object containing the fitted model and evaluation metrics.
#' @details This function:
#'          1. Computes minimum sample sizes for each class across resampling folds.
#'          2. Specifies a Random Forest model using the `randomForest` engine.
#'          3. Constructs a workflow combining the model and the recipe.
#'          4. Fits the model on resampled data and evaluates it with specified metrics.
#' @examples
#' # Example usage:
#' fitted_randforest <- randforest_fit(
#'   folds = inner_month,
#'   ensemble_ctrl = ctrl_res,
#'   recipe = Occurrence_rec
#' )
#' @export
randforest_fit <- function(folds, ensemble_ctrl, recipe){
# spsize <- list()
#   for(i in 1:nrow(folds)){
#     
#   ratio <-table(folds$splits[[i]]$data[folds$splits[[i]]$in_id,"occurrence_status"])
#   freq <- c("0" = ratio[[2]], "1" = ratio[[1]])
#   spsize[[i]] <- freq
#   }
# min_sampsize <- apply(do.call(rbind,spsize),2,min)

    
   
library(randomForest)
library(themis) #for downsampling
  
#Create model specification
randForest_opt <- rand_forest(trees = 2000)%>%
  set_engine('randomForest',
             replace=TRUE)%>%
  set_mode('classification')

#Update recipe for downsampling
recipe_updated <- recipe %>%
  step_downsample(occurrence_status)

  #Create workflow
randForest_wf <-
  workflow()%>%
  add_model(randForest_opt)%>%
  add_recipe(recipe_updated)
  
  #fit model
start_time <- Sys.time()
randforest_fit <- fit_resamples(randForest_wf,
                                resamples = folds,
                                control=ensemble_ctrl,
                                metrics =metric_set(accuracy,
                                                    roc_auc,
                                                    boyce_cont,
                                                    tss,
                                                    pr_auc,
                                                    sens))
end_time <- Sys.time()
  return(randforest_fit)
}


