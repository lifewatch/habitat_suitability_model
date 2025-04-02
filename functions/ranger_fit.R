#' Fit and Tune a Random Forest Model Using Ranger
#'
#' This function fits and tunes a Random Forest classification model using the `ranger` engine. It allows for custom tuning of hyperparameters and evaluates performance using specified metrics.
#'
#' @param folds A resampling object (e.g., created with `vfold_cv`) for cross-validation.
#' @param ensemble_ctrl A control object for the tuning process, created with `control_grid()`.
#' @param recipe A preprocessed recipe object specifying the data transformations.
#' @return A `tune_results` object containing the results of the model tuning process.
#' @details This function:
#'          1. Defines custom tunable hyperparameters (`splitrule` and `max.depth`).
#'          2. Specifies a Random Forest model using the `ranger` engine.
#'          3. Creates a tuning grid for hyperparameters.
#'          4. Constructs a workflow combining the model and the recipe.
#'          5. Tunes the model using grid search and evaluates it with specified metrics.
#' @examples
#' # Example usage:
#' fitted_ranger <- ranger_fit(
#'   folds = knndm_folds,
#'   ensemble_ctrl = ctrl_grid,
#'   recipe = Occurrence_rec
#' )
#' @export
ranger_fit <- function(folds, ensemble_ctrl, recipe){

  #Implement custom tune parameters
  splittingrule <- function(values = c("hellinger","gini","extratrees")) {
    new_qual_param(
      type = "character",
      values = values,
      label = c(splitrule = "Splitting rule")
    )
  }
  
  max_depth <- function(range = c(1L, 10L), trans = NULL) {
    new_quant_param(
      type = "integer",
      range = range,
      inclusive = c(TRUE, TRUE),
      trans = trans,
      label = c(max.depth = "Maximum tree depth"),
      finalize = NULL
    )
    
    
  }
  #Create model specification
  ranger_opt <- rand_forest(trees=2000)%>%
    set_engine("ranger",
               splitrule=tune(),
               max.depth=tune(),
               probability=TRUE,
               replace=TRUE)%>%
    set_mode("classification")

  #Create tuning grid
  ranger_tuning <- dials::grid_regular(
    splittingrule(values = c("gini", "extratrees", "hellinger")),
    max_depth(c(1,4)))
  
  #Create workflow
  ranger_wf <-
    workflow()%>%
    add_model(ranger_opt)%>%
    add_recipe(recipe)
  
  #fit model
  start_time <- Sys.time()
  ranger_fit <- tune_grid(ranger_wf,
                          resamples = folds,
                          grid=ranger_tuning,
                          control=ensemble_ctrl,
                          metrics =metric_set(accuracy,
                                              roc_auc,
                                              boyce_cont,
                                              tss,
                                              pr_auc,
                                              sens))
  end_time <- Sys.time()
  return(ranger_fit)
}


