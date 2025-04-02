#' Fit and Tune a XGBoost model
#'
#' This function fits and tunes a XGBoost classification model.
#'
#' @param folds A resampling object (e.g., created with `vfold_cv`) for cross-validation.
#' @param ensemble_ctrl A control object for the tuning process, created with `control_grid()`.
#' @param recipe A preprocessed recipe object specifying the data transformations.
#' @return A `tune_results` object containing the results of the model tuning process.
#' @details This function:
#'          1. Defines custom tunable hyperparameters (`splitrule` and `max.depth`).
#'          2. Specifies a Random Forest model using the xgboost engine.
#'          3. Creates a tuning grid for hyperparameters.
#'          4. Constructs a workflow combining the model and the recipe.
#'          5. Tunes the model using grid search and evaluates it with specified metrics.
#' @examples
#' # Example usage:
#' fitted_ranger <- xgb_fit(
#'   folds = knndm_folds,
#'   ensemble_ctrl = ctrl_grid,
#'   recipe = Occurrence_rec
#' )
#' @export
xgb_fit <- function(folds, ensemble_ctrl, recipe){
  
  #Create model specification
  xgb_opt <- boost_tree(
    trees = tune(),
    tree_depth = tune(),
    learn_rate = tune()) %>%
    set_engine("xgboost") %>%
    set_mode("classification")

  #Create tuning grid
  xgb_grid <- dials::grid_regular(parameters(trees(),tree_depth(c(3,20)), learn_rate(c(-4,0))),
                                   levels = c(trees = 5, tree_depth = 3, learn_rate = 3))
 
  
  #Create workflow
  xgb_wf <- 
    workflow() %>%
    add_model(xgb_opt) %>%
    add_recipe(recipe)
  
  #fit model
  start_time <- Sys.time()
  xgb_fit <- tune_grid(xgb_wf,
                          resamples = folds,
                          grid= xgb_grid,
                          control= ensemble_ctrl,
                          metrics = metric_set(accuracy,
                                              roc_auc,
                                              boyce_cont,
                                              tss,
                                              pr_auc,
                                              sens))
  end_time <- Sys.time()
  return(xgb_fit)
}


