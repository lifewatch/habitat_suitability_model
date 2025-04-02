#' Fit a Generalized Additive Model (GAM) Using mgcv
#'
#' This function fits and tunes a Generalized Additive Model (GAM) for classification using the `mgcv` engine. It allows for tuning of degrees of freedom for smooth terms and evaluates model performance using specified metrics.
#'
#' @param folds A resampling object (e.g., created with `vfold_cv`) for cross-validation.
#' @param ensemble_ctrl A control object for the tuning process, created with `control_grid()`.
#' @param recipe A preprocessed recipe object specifying the data transformations.
#' @return nog aanpassen hier
#' @details This function:
#'          1. Specifies a GAM model with a logit link function and REML method.
#'          2. Tunes the degrees of freedom for smooth terms using a grid search.
#'          3. Constructs a workflow combining the model and the recipe.
#'          4. Fits and evaluates the model using the specified resampling and metrics.
#' @examples
#' # Example usage:
#' fitted_gam <- gam_fit(
#'   folds = inner_month,
#'   ensemble_ctrl = ctrl_grid,
#'   recipe = Occurrence_rec
#' )
#' @export
gam_fit <- function(folds, ensemble_ctrl, recipe){

 
  #Create model specification
  gam_mod <- gen_additive_mod(adjust_deg_free = tune()) %>% 
    set_engine("mgcv",
               family = binomial(link = "logit"),
               method = "REML") %>% 
    set_mode("classification")

  #Create tuning grid
  gam_grid <- grid_regular(adjust_deg_free(),
                           levels=4)
  
  #Create workflow
  gam_wf <-
    workflow()%>%
    add_recipe(recipe)%>%
    add_model(gam_mod, formula = occurrence_status ~ s(bathy, k = 15)+ s(thetao, k = 15)+ s(so, k = 15) + s(npp, k = 15))
  
  
  #fit model
  start_time <- Sys.time()
  gam_fit <-
    gam_wf%>%
    tune_grid(
      resamples = folds,
      grid=gam_grid,
      control=ensemble_ctrl,
      metrics =metric_set(accuracy,
                          roc_auc,
                          boyce_cont,
                          tss,
                          pr_auc,
                          sens)
    )
  end_time <- Sys.time()
  return(gam_fit)
}



