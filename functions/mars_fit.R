#' Fit and Tune a MARS model
#'
#' This function fits and tunes a MARS model.
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
#' fitted_mars <- mars_fit(
#'   folds = knndm_folds,
#'   ensemble_ctrl = ctrl_grid,
#'   recipe = Occurrence_rec
#' )
#' @export
mars_fit <- function(folds, ensemble_ctrl, recipe){

  
  #Create model specification
  mars_mod <- 
    mars(prod_degree = 1, prune_method = "backward", num_terms = tune()) %>% 
    # This model can be used for classification or regression, so set mode
    set_mode("classification") %>% 
    set_engine("earth")

  #Create tuning grid
  mars_grid <- dials::grid_regular(num_terms(c(5,50)),levels = 5)
  
  #Create workflow
  mars_wf <-
    workflow()%>%
    add_model(mars_mod)%>%
    add_recipe(recipe)
  
  #fit model
  start_time <- Sys.time()
  mars_fit <-
    mars_wf%>%
    tune_grid(
      resamples = folds,
      grid=mars_grid,
      control=ensemble_ctrl,
      metrics =metric_set(accuracy,
                          roc_auc,
                          boyce_cont,
                          tss,
                          pr_auc,
                          sens)
    )
  end_time <- Sys.time()
  return(mars_fit)
}
