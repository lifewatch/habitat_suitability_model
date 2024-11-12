# Loading the required packages

library(tidymodels)
#devtools::install_github("jiho/autoplot")
library(autoplot)
library(stacks) #for ensembling the individual models together
library(workflows)
library(ranger) #for the randomforest model
library(mgcv) #for the GAM model
library(xgboost) #for the xgboost model
library(earth) #for the MARS model
library(tidysdm)

# Load data

# Load presence-absence related to environmental data
load(file.path(datadir,"pback_env.RData"))

#Turn our occurrence into a factor so that there are two known levels, either
#present or absent.
pback_env$occurrence_status<-factor(pback_env$occurrence_status)
#Remove all these columns because the data we want to predict on also only has the environmental values,
#model will only accept input to predict on with the same columns as the data the model was trained on.
data <- pback_env%>%
  dplyr::select(-c(time,scientific_name,year_month,longitude,latitude))%>%
  drop_na()%>%
  dplyr::mutate(occurrence_status=factor(occurrence_status,level=c(1,0)))%>% #the first level should be the level of interest (positive class, so presences)
  as_tibble()

# Data splitting

#Generate the custom sets where the background is never included into the test but always in the training

set.seed(222)
#Put 4/5 in the training set
data_split<- initial_split(data, prop=4/5)

#Create data frames for the two sets:
train_data <- training(data_split)
test_data <- testing(data_split)

#Create folds in the training data so we can do our validation.
#Out of the 80% reserved for training data, use 10% each time for validation
#This is why we choose the number of folds v=8
folds <- vfold_cv(train_data, v=8)
folds
nested_folds <- nested_cv(data,
                          outside = vfold_cv(5),
                          inside = vfold_cv(4))
nested_folds


# Pre-process your data with recipes

#The general form is: recipe(formula, data)

#The formula is only used to declare the variables, their roles and nothing else.
#All the rest can be added later.

#Doesn't matter the data here is train_data. Just used to catalog the names of the 
#variables and their types. 
#The formula here states that occurrenceStatus is modelled in relation to all the other columns
Occurrence_rec <- 
  recipe(occurrence_status ~., data=train_data)

#Can also do some pre-processing of the variables with this recipe, but which should you do?
# step_* functions
#Can also provide some checks here. These check_* functions conduct some sort of 
#data validation, if no issue is found, they return the data as it is, otherwise they show an error.

# Fit a model with a recipe, using a model workflow
# Making an ensemble model with stacks

#We already generated our our rsample rset objects
data_split
train_data
test_data

#We also already made some folds
folds

#And a recipe
Occurrence_rec

#Because we use tune_grid()
ctrl_grid <- control_stack_grid()
ctrl_res <- control_stack_resamples()

#set the number of trees to 500 (also the default), use it for classification into
#presence-absence, and the algorithm to ranger (also the default)
rf_mod <- rand_forest(trees=500,mode="classification",engine="ranger")
rf_opt <- rand_forest(trees=2000)%>%
  set_engine("ranger",
             splitrule="hellinger",
             max.depth=2,
             probability=TRUE,
             replace=TRUE)%>%
  set_mode('classification')
rf_opt <- rand_forest(trees=2000)%>%
  set_engine("ranger",
             splitrule=tune(),
             max.depth=tune())%>%
  set_mode("classification")
rf_grid <- parameters(splitrule(c("gini","extratrees","hellinger")),
                       max.depth(c(2,3,4)))
tuning_grid <- dials::grid_regular(
  max.depth(range = c(2, 5)),
  splitrule(values = c("gini", "extratrees", "hellinger")),
  levels = 5  # This specifies 5 levels within the range of 2 to 5 for max_depth
)
max.depth = 2:5, # this can be a vector of numbers
splitrule = c("gini", "extratrees", "hellinger"), # only allowed options

#After your model is defined, create a worfklow object and add your model and recipe
rf_wf <-
  workflow() %>%
  add_model(rf_mod) %>%
  add_recipe(Occurrence_rec)

rf_wf_opt <-
  workflow()%>%
  add_model(rf_opt)%>%
  add_recipe(Occurrence_rec)

#The workflow can then be fit or tuned, in this case it's fit but with resamples
#so we have to provide the folds
#Runs +- 2min
rf_fit <-
  fit_resamples(
    rf_wf,
    resamples = folds,
    control = ctrl_res,
    metrics =metric_set(accuracy,
                        roc_auc,
                        boyce_cont,
                        tss,
                        pr_auc,
                        sens)
  )
rf_opt_fit <- fit_resamples(rf_wf_opt,
  resamples = folds,
  control=ctrl_res,
  metrics =metric_set(accuracy,
                      roc_auc,
                      boyce_cont,
                      tss,
                      pr_auc,
                      sens))
rf_rng_shallow <- ranger::ranger(formula = occurrence_status ~ .,
                         data = train_data, 
                         num.trees = 2000,
                         probability = TRUE, # fit a probability forest
                         splitrule = "hellinger",
                         max.depth = 2,
                         replace=TRUE,
                         class.weights = c(6.67,1)) # fit shallow trees

testpredict<-predict(rf_rng_shallow,train_data)
testpredict <- testpredict$predictions
#With resamples as we need to provide this type to the stack command later
rf_fit
rf_metrics <- collect_metrics(rf_fit)
rf_opt_metrics <- collect_metrics(rf_opt_fit)
save(rf_metrics,file=file.path(datadir,"rf_default_metrics.RData"))
save(rf_fit, file=file.path(datadir, "rf_default_fit.RData"))
test 
sens(test,truth="occurrence_status",estimate=".pred_class")
# Tuning model parameters

#More information found on https://parsnip.tidymodels.org/reference/details_gen_additive_mod_mgcv.html
gam_mod <- gen_additive_mod(adjust_deg_free = tune()) %>% 
  set_engine("mgcv") %>% 
  set_mode("classification")
gam_wf <-
  workflow()%>%
  add_recipe(Occurrence_rec)%>%
  add_model(gam_mod, formula = occurrenceStatus ~ s(bathy)+ s(thetao)+ s(so) + s(npp))
gam_grid <- grid_regular(adjust_deg_free(),
                         levels=4)
gam_fit <-
  gam_wf%>%
  tune_grid(
    resamples = folds,
    grid=gam_grid,
    control=ctrl_grid
  )


#Tune the xgboost model, see: https://parsnip.tidymodels.org/reference/details_boost_tree_xgboost.html
xgb_mod <- boost_tree(
  trees = tune(),
  tree_depth = tune(),
  learn_rate = tune()
) %>%
  set_engine("xgboost") %>%
  set_mode("classification")
xgb_wf <- workflow() %>%
  add_model(xgb_mod) %>%
  add_recipe(Occurrence_rec)
#grid_regular chooses sensible hyperparameter values to try, but want to choose ourself
#Can give th elower and upper bound limit we want to use
xgb_grid <- parameters(trees(),
                       tree_depth(c(3,20)),
                       learn_rate(c(-4,0)))
xgb_grid <- grid_regular(xgb_grid,
                         levels=c(trees=5,tree_depth=3,learn_rate=3))



xgb_fit <- 
  xgb_wf %>% 
  tune_grid(
    resamples = folds,
    grid = xgb_grid,
    control=ctrl_grid,
    metrics =metric_set(accuracy,
                        roc_auc,
                        boyce_cont,
                        tss,
                        pr_auc,
                        sens))
#Runs for +- 40min
xgb_fit



#devtools::install_github("tidymodels/tune")
#Need to update to this version of the tune package, otherwise it fails
mars_mod <- 
  mars(prod_degree = tune(), prune_method = tune()) %>% 
  # This model can be used for classification or regression, so set mode
  set_mode("classification") %>% 
  set_engine("earth")#,glm=list(family=binomial))
mars_mod
mars_grid <- grid_regular(prod_degree(),prune_method(),
                          levels=c(prod_degree=2,prune_method=2))
mars_grid
#trying to normalize to get rid of the fitted probabilities numerically 0 or 1 occurred
rec_norm <- Occurrence_rec%>%
  step_normalize(all_numeric_predictors())
mars_wf <-
  workflow()%>%
  add_model(mars_mod)%>%
  add_recipe(rec_norm) #originally was Occurrence_rec
mars_fit <-
  mars_wf%>%
  tune_grid(
    resamples = folds,
    grid=mars_grid,
    control=ctrl_grid
  )

mars_fit

#Stacking

stack_data <- 
  stacks() %>%
  add_candidates(rf_fit) %>%
  add_candidates(mars_fit)%>%
  add_candidates(gam_fit)%>%
  add_candidates(xgb_fit)

stack_data

stack_mod <-
  stack_data %>%
  blend_predictions()
#16h28-16h29

stack_mod

#Now fit the whole model on the training set
stack_fit <-
  stack_mod %>%
  fit_members()
#16h30 - 16h33
stack_fit

#Saving the model
saveRDS(stack_fit,file.path(datadir,"stacked_model_126415.rds"))





