tidymodels_prep <- function(data_pback, folds = NULL){
  #Create training_data: occurrence_status(response) and predictor variables
  training_data <- data_pback%>%
    dplyr::select(occurrence_status, thetao, npp, so, bathy)%>%
    dplyr::mutate(occurrence_status=factor(occurrence_status,level=c(1,0)))%>% #the first level should be the level of interest (positive class, so presences)
    as_tibble()
  
  #Ensemble control, so that in the end we can combine our individual models with stacks
  ctrl_grid <- control_grid(save_pred = TRUE, save_workflow = TRUE, parallel_over = "resamples")
  ctrl_res <- control_resamples(save_pred = TRUE, save_workflow = TRUE, parallel_over = "resamples")
  
  #Create a recipe, data we want to predict on needs to be the same as data this recipe was build on
  recipe <- recipe(occurrence_status ~., data=training_data)%>%
    step_normalize(all_numeric_predictors())
  
  model_training_object <- list(training_data = training_data,
                                ctrl_grid = ctrl_grid,
                                ctrl_res = ctrl_res,
                                recipe = recipe,
                                folds = folds)
  return(model_training_object)
}
