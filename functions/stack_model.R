stack_model <- function(file_path){
cli::cli_h1(paste0("Loading tuned models at: ",file_path))

plan(sequential) #Return to sequential processing  
# Load models

fitted_xgb <- open_bundle(file.path(file_path, "fitted_xgb.RDS"))
cli::cli_inform(c("v" = "Model loaded: XGBoost"))
fitted_ranger <- open_bundle(file.path(file_path, "fitted_ranger.RDS"))
cli::cli_inform(c("v" = "Model loaded: Ranger"))
fitted_randforest <- open_bundle(file.path(file_path, "fitted_randforest.RDS"))
cli::cli_inform(c("v" = "Model loaded: Randforest"))
fitted_maxent <- open_bundle(file.path(file_path, "fitted_maxent.RDS"))
cli::cli_inform(c("v" = "Model loaded: MaxEnt"))
fitted_mars <- open_bundle(file.path(file_path, "fitted_mars.RDS"))
cli::cli_inform(c("v" = "Model loaded: MARS"))
fitted_gam <- open_bundle(file.path(file_path, "fitted_gam.RDS"))
cli::cli_inform(c("v" = "Model loaded: GAM"))

cli::cli_h2("Stacking individual models")

stack_data <- 
  stacks() %>%
  add_candidates(fitted_ranger) %>%
  add_candidates(fitted_randforest)%>%
  add_candidates(fitted_gam)%>%
  add_candidates(fitted_mars)%>%
  add_candidates(fitted_maxent)%>%
  add_candidates(fitted_xgb)
cli::cli_inform(c("v" = "Stacked dataset created"))

stack_mod <-
  blend_predictions(stack_data, metric= yardstick::metric_set(boyce_cont))
cli::cli_inform(c("v" = "Predictions blended using BCI"))

options(future.globals.maxSize = 5 * 1024^3)  # 5 GiB
future::plan("sequential")

fitted_stack <- stacks::fit_members(stack_mod)

# fitted_stack <-
#   stack_mod %>%
#   fit_members()
cli::cli_inform(c("v" = "Stacked model fitted"))

save_bundle(fitted_stack, file = file.path(file_path, "fitted_stack.RDS"))
cli::cli_inform(c("v" = "Stacked model saved"))
parameters <- list(ranger = collect_parameters(fitted_stack, "fitted_ranger"),
                   randforest = collect_parameters(fitted_stack, "fitted_randforest"),
                   gam = collect_parameters(fitted_stack, "fitted_gam"),
                   mars = collect_parameters(fitted_stack, "fitted_mars"),
                   maxent = collect_parameters(fitted_stack, "fitted_maxent"),
                   xgb = collect_parameters(fitted_stack, "fitted_xgb"))
saveRDS(parameters, file = file.path(file_path, "parameters.RDS"))
cli::cli_inform(c("v" = "Parameters stacked model saved"))
}