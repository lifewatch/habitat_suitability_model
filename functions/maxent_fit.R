#' Fit and Tune a MaxEnt model
#'
#' This function fits and tunes a MaxEnt model
#'
#' @param folds A resampling object (e.g., created with `vfold_cv`) for cross-validation.
#' @param ensemble_ctrl A control object for the tuning process, created with `control_grid()`.
#' @param recipe A preprocessed recipe object specifying the data transformations.
#' @return A `tune_results` object containing the results of the model tuning process.
#' @details This function:
#'          1. Defines custom tunable hyperparameters (`splitrule` and `max.depth`).
#'          2. Specifies a Random Forest model using the maxent engine.
#'          3. Creates a tuning grid for hyperparameters.
#'          4. Constructs a workflow combining the model and the recipe.
#'          5. Tunes the model using grid search and evaluates it with specified metrics.
#' @examples
#' # Example usage:
#' fitted_maxent <- maxent_fit(
#'   folds = knndm_folds,
#'   ensemble_ctrl = ctrl_grid,
#'   recipe = Occurrence_rec
#' )
#' @export
maxent_fit <- function(folds, ensemble_ctrl, recipe){

  
  #Create model specification
  maxnet_mod <- maxent(
    feature_classes = tune(),
    regularization_multiplier = tune()
  ) %>%
    set_engine("maxnet") %>%
    set_mode("classification")

  #Create tuning grid
  regularization_multiplier <- c(0.5, 1, 2, 3, 4)
  feature_classes <- c("l", "lq", "h", "lqh", "lqhp")
  
  # Create a data frame with all combinations
  maxnet_grid <- expand.grid(
    regularization_multiplier = regularization_multiplier,
    feature_classes = feature_classes
  )
  
  #Create workflow
  maxnet_wf <- workflow() %>%
    add_model(maxnet_mod) %>%
    add_recipe(recipe)
  
  #fit model
  start_time <- Sys.time()
  maxnet_fit <- 
    maxnet_wf %>% 
    tune_grid(
      resamples = folds,
      grid = maxnet_grid,
      control=ensemble_ctrl,
      metrics =metric_set(accuracy,
                          roc_auc,
                          boyce_cont,
                          tss,
                          pr_auc,
                          sens))
  end_time <- Sys.time()
  return(maxnet_fit)
}


