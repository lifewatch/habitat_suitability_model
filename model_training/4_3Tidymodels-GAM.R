# PARAMETER CHOICES -------------------------------------------------------
#Tidymodels
#   select_features
#   adjust_deg_free 1,2,3

#mgcv
  # family = binomial(link = "logit")
  #weights = ??
  # method = "REML"


# IMPLEMENT CUSTOM TUNE PARAMETERS -------------------------------------



# MODEL ----------------------------------------------------------------
gam_grid <- grid_regular(adjust_deg_free(),
                         levels=4)
gam_mod <- gen_additive_mod(adjust_deg_free = tune()) %>% 
  set_engine("mgcv",
             family = binomial(link = "logit"),
                               method = "REML") %>% 
  set_mode("classification")



# WORFKLOW ----------------------------------------------------------------



gam_wf <-
  workflow()%>%
  add_recipe(Occurrence_rec)%>%
  add_model(gam_mod, formula = occurrence_status ~ s(bathymetry)+ s(thetao)+ s(so) + s(npp))

# FIT ---------------------------------------------------------------------
start_time <- Sys.time()
gam_fit <-
  gam_wf%>%
  tune_grid(
    resamples = folds_eq,
    grid=gam_grid,
    control=ctrl_grid,
    metrics =metric_set(accuracy,
                        roc_auc,
                        boyce_cont,
                        tss,
                        pr_auc,
                        sens)
  )
end_time <- Sys.time()
#takes 12 min