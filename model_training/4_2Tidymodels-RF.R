# PARAMETER CHOICES -------------------------------------------------------
#Tidymodels
#   trees = 2000
#   mtry = default = floor(sqrt(ncol(x)))
#   engine = ranger
#   mode = classification
#   min_n = default = 10 for classification

#Ranger
#   splitrule : "hellinger", "gini", "extratrees" (tune)
#   max.depth: 1-4 (tune)
#   probability = TRUE
#   replace = TRUE

#randForest
#   replace = TRUE
#   sampsize = amount of presences in folds

# IMPLEMENT CUSTOM TUNE PARAMETERS -------------------------------------

splittingrule <- function(values = c("hellinger","gini","extratrees")) {
  new_qual_param(
    type = "character",
    values = values,
    # By default, the first value is selected as default. We'll specify that to
    # make it clear.
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

# MODEL ----------------------------------------------------------------
library(randomForest)
ratio <-table(folds_eq$splits[[8]]$data[folds_eq$splits[[8]]$in_id,1])
spsize <- c("0" = ratio[[1]], "1" = ratio[[1]]) # sample size for both classes

ranger_opt <- rand_forest(trees=2000)%>%
  set_engine("ranger",
             splitrule=tune(),
             max.depth=tune(),
             probability=TRUE,
             replace=TRUE)%>%
  set_mode("classification")

ranger_tuning <- dials::grid_regular(
  splittingrule(values = c("gini", "extratrees", "hellinger")),
  max_depth(c(1,4)))

randForest_opt <- rand_forest(trees = 2000)%>%
  set_engine('randomForest',
             replace=TRUE,
             sampsize=spsize)%>%
  set_mode('classification')



# WORFKLOW ----------------------------------------------------------------

ranger_wf <-
  workflow()%>%
  add_model(ranger_opt)%>%
  add_recipe(Occurrence_rec)

randForest_wf <-
  workflow()%>%
  add_model(randForest_opt)%>%
  add_recipe(Occurrence_rec)

# FIT ---------------------------------------------------------------------
start_time <- Sys.time()
ranger_fit <- tune_grid(ranger_wf,
                        resamples = folds_eq,
                        grid=ranger_tuning,
                        control=ctrl_grid,
                        metrics =metric_set(accuracy,
                                            roc_auc,
                                            boyce_cont,
                                            tss,
                                            pr_auc,
                                            sens))
end_time <- Sys.time()
#15min


start_time <- Sys.time()
randForest_fit <- fit_resamples(randForest_wf,
                        resamples = folds_eq,
                        control=ctrl_res,
                        metrics =metric_set(accuracy,
                                            roc_auc,
                                            boyce_cont,
                                            tss,
                                            pr_auc,
                                            sens))
end_time <- Sys.time()
#5min