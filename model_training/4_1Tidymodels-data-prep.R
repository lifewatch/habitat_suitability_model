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

# Load data + feature engineering -----------------------------------------
pback_month
pback_decad

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
subset_data <- data[sample(1:nrow(data),10000),]
subset_data

#Create folds in the training data so we can do our validation.
#Out of the 80% reserved for training data, use 10% each time for validation
#This is why we choose the number of folds v=8
folds <- vfold_cv(train_data, v=8)
folds
folds_eq <- vfold_cv(train_data, v = 8, strata = occurrence_status)


# COLLECT METRICS ---------------------------------------------------------

#RUN THE CODE FOR MONTHLY
metrics_monthly <- c()
metrics_monthly["ranger"] <- collect_metrics(ranger_fit)
metrics_monthly["randforest"] <- collect_metrics(randForest_fit)
metrics_monthly["gam"] <- collect_metrics(gam_fit)
metrics_monthly["xgb"] <- collect_metrics(xgb_fit)
metrics_monthly["mars"] <- collect_metrics(mars_fit)
metrics_monthly["maxent"] <- collect_metrics(maxent_fit)
metrics_monthly["ensemble"] <- 

#RUN THE CODE FOR DECADAL
metrics_decad <- c()


# Pre-processing ----------------------------------------------------------


# Pre-process your data with recipes

#The general form is: recipe(formula, data)

#The formula is only used to declare the variables, their roles and nothing else.
#All the rest can be added later.

#Doesn't matter the data here is train_data. Just used to catalog the names of the 
#variables and their types. 
#The formula here states that occurrenceStatus is modelled in relation to all the other columns
Occurrence_rec <- 
  recipe(occurrence_status ~., data=train_data)
  step_normalize(all_numeric_predictors())

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
ctrl_grid <- control_grid(verbose=TRUE,save_pred = TRUE, save_workflow = TRUE)
ctrl_res <- control_stack_resamples()




set.seed(222)
#Put 4/5 in the training set
data_split<- initial_split(data, prop=4/5)

#Create data frames for the two sets:
train_data <- training(data_split)
test_data <- testing(data_split)


# decadal folds -----------------------------------------------------------

## Outer fold (stratified 4-fold CV)

### Stratified 4-fold CV based on presence-only
presence_decad <- pback_decad[pback_decad$occurrence_status==1,]
outer_decad <- vfold_cv(data = pres_decad,
                        v = 4,
                        strata = "decade")

### add background points to every fold
indices <- list()
for(i in 1:nrow(outer_decad)){
manual_split <- c(outer_decad$splits[[i]]$in_id,seq(from = nrow(pres_decad)+1, to=nrow(pback_decad), by=1)) #background points at the end of this dataframe
indices[[i]] <- list(analysis = as.integer(manual_split),
                       assessment = setdiff(1:nrow(pback_decad),manual_split)) #test set is presence points not used in a fold
}
splits <- lapply(indices, FUN=make_splits, data = pback_decad)
outer_decad <- manual_rset(splits, c("Fold1", "Fold2","Fold3","Fold4"))

for( i in 1:nrow(outer_decad)){
  train_decad <- outer_decad$splits[[1]]$data[outer_decad$splits[[1]]$in_id,]
}

## Inner fold (LTO-CV)
inner_decad <- CAST::CreateSpacetimeFolds(
  train_decad,
  spacevar = NA,
  timevar = "decade",
  k = 3,
  class = NA,
  seed = sample(1:1000, 1)
)
splits_pre <- c()
for(i in 1:3){
splits_pre[[i]] <- list(analysis = inner_decad$index[[i]],
     assessment = inner_decad$indexOut[[i]])
}

splits <- lapply(splits_pre, FUN= make_splits, data = train_decad)
inner_decad <- manual_rset(splits,c("Fold1","Fold2","Fold3"))


# monthly folds -----------------------------------------------------------
#Outer-fold (stratified 4-fold CV) stratify on months and also only presence points. 
pres_month <- pback_month[pback_month$occurrence_status==1,]
outer_month <- vfold_cv(data = pres_month,
                        v = 4,
                        strata = "month")

### add background points to every fold
indices <- list()
for(i in 1:nrow(outer_month)){
  manual_split <- c(outer_month$splits[[i]]$in_id,seq(from = nrow(pres_month)+1, to=nrow(pback_month), by=1)) #background points at the end of this dataframe
  indices[[i]] <- list(analysis = as.integer(manual_split),
                       assessment = setdiff(1:nrow(pback_month),manual_split)) #test set is presence points not used in a fold
}
splits <- lapply(indices, FUN=make_splits, data = pback_month)
outer_month <- manual_rset(splits, c("Fold1", "Fold2","Fold3","Fold4"))

for( i in 1:nrow(outer_month)){
  train_month <- outer_month$splits[[1]]$data[outer_month$splits[[1]]$in_id,]
}

##Inner-fold based on the knndm CAST R package

library(CAST)
train_month
test_points <- pback_env[1:5000,]

#To make the folds that can predict on the features, we average the conditions over all the months
#as a general indication of the predictive space.
#The actual capability of prediction will be tested later on with the area of applicability
thetao_mean <- terra::mean(terra::rast(thetao_avg))
so_mean <- terra::mean(terra::rast(so_avg))
npp_mean <- terra::mean(terra::rast(npp_avg))
#Because the extents do not match
ext(bathy) <- ext(thetao_mean)
ext(npp_mean) <- ext(thetao_mean)
bathy <- resample(bathy, thetao_mean)
npp_mean <- resample(npp_mean,thetao_mean)
predictors_mean <- c(thetao_mean, so_mean, npp_mean, bathy)
names(predictors_mean) <- c("thetao","so","npp","bathymetry")

#Make inner fold based on outer fold
knndm_folds <- CAST::knndm(
  test_points[,c(7,8,9,10)],
  modeldomain = predictors_mean,
  space = "feature",
  k = 5,
  maxp = 0.6,
  clustering = "hierarchical",
  linkf = "ward.D2",
  samplesize = 10000,
  sampling = "Fibonacci",
  useMD = FALSE
)

test_points_sf <- sf::st_as_sf(test_points,coords=c("longitude","latitude"),crs="EPSG:4326") 

#Create rsample folds based on this cross-validation:
splits_pre <- c()
for(i in 1:5){
  splits_pre[[i]] <- list(analysis = knndm_folds$indx_train[[i]],
                          assessment = knndm_folds$indx_test[[i]])
}

splits <- lapply(splits_pre, FUN= make_splits, data = train_month)
inner_month <- manual_rset(splits,c("Fold1","Fold2","Fold3","Fold4","Fold5"))



#visualize the nearest neighbour feature space distances under consideration of cross-validation
dist_knndm <- geodist(test_points_sf[,c(5,6,7,8)],
                      modeldomain = predictors_mean,
                      type = "feature",
                      sampling="Fibonacci",
                      samplesize = 5000,
                      cvfolds = knndm_folds$indx_test)

plot(dist_knndm)+scale_x_log10()
plot(knndm_folds,type="simple")
plot(knndm_modeldomain_test, type = "simple")