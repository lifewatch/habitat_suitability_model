# PARAMETER CHOICES -------------------------------------------------------
#Tidymodels
#   trees = 10 to 5000
#   tree_depth = 3 to 20
#   learn_rate = 0.01 to 0.5
#   sample_size = 0.6-0.85
#   mode = classification


# IMPLEMENT CUSTOM TUNE PARAMETERS -------------------------------------



# MODEL ----------------------------------------------------------------

xgb_mod <- boost_tree(
  trees = tune(),
  tree_depth = tune(),
  learn_rate = tune(),
  sample_size = tune()
) %>%
  set_engine("xgboost") %>%
  set_mode("classification")

sample_size_param <- dials::sample_prop(range = c(0.6, 0.85))
learn_param <- dials::learn_rate(range=c(-2,-0.4))%>% value_set(c(-2, -1, -0.4))
xgb_grid <- dials::parameters(trees(c(10,5000)),
                       tree_depth(c(3,20)),
                       learn_rate = learn_param,
                       sample_size = sample_size_param)
xgb_grid <- grid_regular(xgb_grid,
                         levels=c(trees=4,tree_depth=3,learn_rate=3, sample_size = 3))





# WORFKLOW ----------------------------------------------------------------

xgb_wf <- workflow() %>%
  add_model(xgb_mod) %>%
  add_recipe(Occurrence_rec)

# FIT ---------------------------------------------------------------------
start_time <- Sys.time()
xgb_fit <- 
  xgb_wf %>% 
  tune_grid(
    resamples = folds_eq,
    grid = xgb_grid,
    control=ctrl_grid,
    metrics =metric_set(accuracy,
                        roc_auc,
                        boyce_cont,
                        tss,
                        pr_auc,
                        sens))
end_time <- Sys.time()
#Takes 14.2 hours
save(xgb_fit,file=file.path(datadir,"xgb_fit"))
