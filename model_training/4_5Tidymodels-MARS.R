# PARAMETER CHOICES -------------------------------------------------------
#Tidymodels
#   prod_degree = 1 see Valavi. 2021
#   num_terms = 1:20
#   prune_method = "backward"


# IMPLEMENT CUSTOM TUNE PARAMETERS -------------------------------------

# MODEL ----------------------------------------------------------------
mars_mod <- 
  mars(prod_degree = 1, prune_method = "backward", num_terms = tune()) %>% 
  # This model can be used for classification or regression, so set mode
  set_mode("classification") %>% 
  set_engine("earth")
mars_mod
mars_grid <- dials::grid_regular(num_terms(c(5,50)),levels = 5)
mars_grid

# WORFKLOW ----------------------------------------------------------------

mars_wf <-
  workflow()%>%
  add_model(mars_mod)%>%
  add_recipe(Occurrence_rec)

# FIT ---------------------------------------------------------------------
start_time <- Sys.time()
mars_fit <-
  mars_wf%>%
  tune_grid(
    resamples = folds_eq,
    grid=mars_grid,
    control=ctrl_grid,
    metrics =metric_set(accuracy,
                        roc_auc,
                        boyce_cont,
                        tss,
                        pr_auc,
                        sens)
  )
end_time <- Sys.time()
mars_fit