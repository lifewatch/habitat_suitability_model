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

#Calculating class weights
w <- 1/table(train_data$occurrence_status)
w <- w/sum(w)
weights <- rep(0, nrow(train_data))
weights[train_data$occurrence_status == 0] <- w[2]
weights[train_data$occurrence_status == 1] <- w[1]

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
             max.depth=2,
             probability=TRUE,
             class.weights=w,
             replace=TRUE)%>%
  set_mode("classification")
splittingrule <- function(values = c("hellinger","gini","extratrees")) {
  new_qual_param(
    type = "character",
    values = values,
    # By default, the first value is selected as default. We'll specify that to
    # make it clear.
    label = c(splitrule = "Splitting rule")
  )
}

tuning_grid <- dials::grid_regular(
  splittingrule(values = c("gini", "extratrees", "hellinger")))


rf_wf_opt <-
  workflow()%>%
  add_model(rf_opt)%>%
  add_recipe(Occurrence_rec)

rf_opt_fit <- tune_grid(rf_wf_opt,
                            resamples = folds,
                        grid=tuning_grid,
                            control=ctrl_grid,
                            metrics =metric_set(accuracy,
                                                roc_auc,
                                                boyce_cont,
                                                tss,
                                                pr_auc,
                                                sens))



# Misschien probleem dat we moeten rescalen want is relatief 
testrf <- rf_opt_fit$.predictions[[1]]%>%filter(splitrule=="hellinger")
normalized <- function(x) (x- min(x))/(max(x) - min(x))
rf_rescale <- data.frame(pred1=normalized(testrf$.pred_1),
                         pred0=normalized(testrf$.pred_0),
                         testrf$occurrence_status)
rf_rescale
rf_rescale_diff <- rf_rescale%>%group_by(testrf.occurrence_status)%>%summarize(gem1=median(pred1),gem0=median(pred0))
rf_rescale_diff
library(modEvA)
thresh <-optiThresh(pred=testrf$.pred_1,obs=as.numeric(as.character((testrf$occurrence_status))))
optiPair(pred=testrf$.pred_1,obs=as.numeric(as.character((testrf$occurrence_status))),measures = c("Sensitivity", "Specificity"), main = "Optimal balance")
#This gives us a threshold of 0.17
threshold <- 0.17
new_pred <- testrf%>%mutate(binary_pred = ifelse(.pred_1 >= threshold, 1, 0))%>%
  select(binary_pred,occurrence_status)
new_pred
sens_vec(estimate=factor(new_pred$binary_pred,levels=c("1","0")),truth=new_pred$occurrence_status)
spec_vec(estimate=factor(new_pred$binary_pred,levels=c("1","0")),truth=new_pred$occurrence_status)
