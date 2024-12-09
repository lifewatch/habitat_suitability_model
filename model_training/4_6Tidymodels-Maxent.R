# PARAMETER CHOICES -------------------------------------------------------
#Tidysdm
#   regularization_multiplier = 0.5, 1, 2, 3, 4 see Valavi2021
#   feature_classes = "l", "lq", "h", "lqh", "lqhp" see Valavi2021


# IMPLEMENT CUSTOM TUNE PARAMETERS -------------------------------------



# MODEL ----------------------------------------------------------------
library(tidysdm)
maxnet_mod <- maxent(
  feature_classes = tune(),
  regularization_multiplier = tune()
) %>%
  set_engine("maxnet") %>%
  set_mode("classification")

regularization_multiplier <- c(0.5, 1, 2, 3, 4)
feature_classes <- c("l", "lq", "h", "lqh", "lqhp")

# Create a data frame with all combinations
maxnet_grid <- expand.grid(
  regularization_multiplier = regularization_multiplier,
  feature_classes = feature_classes
)


# WORFKLOW ----------------------------------------------------------------

maxnet_wf <- workflow() %>%
  add_model(maxnet_mod) %>%
  add_recipe(Occurrence_rec)

# FIT ---------------------------------------------------------------------
start_time <- Sys.time()
maxnet_fit <- 
  maxnet_wf %>% 
  tune_grid(
    resamples = folds_eq,
    grid = maxnet_grid,
    control=ctrl_grid,
    metrics =metric_set(accuracy,
                        roc_auc,
                        boyce_cont,
                        tss,
                        pr_auc,
                        sens))
end_time <- Sys.time()
