
library(tidymodels)
#devtools::install_github("jiho/autoplot")
library(autoplot)
library(stacks) #for ensembling the individual models together
library(workflows)
library(ranger) #for the randomforest model
library(mgcv) #for the GAM model
library(xgboost) #for the xgboost model
library(earth) #for the MARS model

model <- readRDS(file.path(datadir,'stacked_model.rds'))

#Can use these to give some information of the performance of the individual models before they were stacked
#These can be used to provide some training statistics
#To provide good test statistics, need to at minimum use the test data and better would be to have an independent test set. 
model$model_metrics
model$equations

# Load presence-absence related to environmental data
PAdata <- file.path(datadir,"PA_env.RData")

load(PAdata)
#Turn our occurrence into a factor so that there are two known levels, either
#present or absent.
PA_env$occurrenceStatus<-factor(PA_env$occurrenceStatus)
#Remove all these columns because the data we want to predict on also only has the environmental values,
#model will only accept input to predict on with the same columns as the data the model was trained on.
PA_env <- PA_env%>%select(-c(scientificnameaccepted,decimallongitude,decimallatitude,datecollected,day,month,year,year_month,geometry))%>%
  drop_na()%>%
  mutate(bathy=slice_1_img)%>%
  select(-slice_1_img)

#Why make this into a tibble?
data <- as_tibble(PA_env)
data

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

library(caret)
test <- stats::predict(model,test_data,type="prob")
test
member_test <- stats::predict(model,test_data,type="prob",members=TRUE)
member_test

#Might be interesting to also extract the best performing model of the types of models that didn't get included
#Just to plot their response curves and compare how they look like. 

#Sample random data or use the model data? 
#Sample random values for our environmental variables
# df <- data.frame(temp = rnorm(5000, 10, 4),
#                  sal = rnorm(5000, 32, 3),
#                  npp = rnorm(5000, 1000, 300),
#                  bathy=-rlnorm(5000,3.7,1)) 



#All the possible values of the model
df <- data%>%dplyr::select(-occurrenceStatus)

head(df) 

#Make a temporary dataframe with a column for each variable
df_temp <- data.frame(matrix(ncol = ncol(df), nrow = 100)) 
head(df_temp)
colnames(df_temp) <- colnames(df) 
#Fill each column of this dataframe with the mean value of each variable
df_temp[] <- rep(apply(df, 2, mean, na.rm = T), each = 100) 
df_temp
#In each iteration we keep all the variables at the mean value except for one
#This one variable we give 100 different values between the min and max value we used for the model
#This way we can see how the response changes for different values of this variable, when the others are kept at an average level
for (i in 1:ncol(df)) {      
  df_temp_proc <- df_temp      
  df_temp_proc[,i] <- seq(min(df[,i]), max(df[,i]), length.out = 100)
  pred <- stats::predict(model, df_temp_proc,type="prob")[,2]
  if (i == 1) {     
    pred_all <- data.frame(original = df_temp_proc[,i],prediction = pred,variable = colnames(df)[i])   }
  else {     
    pred_all <- rbind(pred_all, data.frame(original = df_temp_proc[,i],prediction = pred,variable = colnames(df)[i]))   
  } 
} 
rc <- pred_all
head(rc)
ggplot(rc)+   
  geom_point(aes(x = original, y = .pred_1))+
  facet_wrap(~variable, scales = "free")

ggplot(rc)+   
  geom_smooth(aes(x = original, y = .pred_1))+
  facet_wrap(~variable, scales = "free")

#Sample random data or use the model data? 
#Sample random values for our environmental variables
# df <- data.frame(temp = rnorm(5000, 10, 4),
#                  sal = rnorm(5000, 32, 3),
#                  npp = rnorm(5000, 1000, 300),
#                  bathy=-rlnorm(5000,3.7,1)) 



#All the possible values of the model
df <- data%>%dplyr::select(-occurrenceStatus)

head(df) 

#Make a temporary dataframe with a column for each variable
df_temp <- data.frame(matrix(ncol = ncol(df), nrow = 100)) 
head(df_temp)
colnames(df_temp) <- colnames(df) 
#Fill each column of this dataframe with the mean value of each variable
df_temp[] <- rep(apply(df, 2, mean, na.rm = T), each = 100) 
df_temp
#In each iteration we keep all the variables at the mean value except for one
#This one variable we give 100 different values between the min and max value we used for the model
#This way we can see how the response changes for different values of this variable, when the others are kept at an average level
for (i in 1:ncol(df)) {      
  df_temp_proc <- df_temp
  #we change one of the columns to show the whole range of values, rest remain the mean
  df_temp_proc[,i] <- seq(min(df[,i]), max(df[,i]), length.out = 100)
  #for each member and the stack we make a prediction on this data
  pred <- stats::predict(model, df_temp_proc,type="prob",members=TRUE)%>%
    dplyr::select(starts_with(".pred_1"))
  if (i == 1) {     
    pred_all <- data.frame(original = df_temp_proc[,i],prediction = pred,variable = colnames(df)[i])   }
  else {     
    pred_all <- rbind(pred_all, data.frame(original = df_temp_proc[,i],prediction = pred,variable = colnames(df)[i]))   
  } 
  
} 
rc <- pred_all%>%
  dplyr::mutate(ID=seq(1,nrow(pred_all)))%>%
  pivot_longer(cols=starts_with("prediction..pred_1"),names_to="model",values_to="response")
head(rc)
ggplot(rc)+   
  geom_smooth(aes(x = original, y = response,colour=model),se=FALSE)+
  facet_wrap(~variable, scales = "free")



# threshold metrics -------------------------------------------------------

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

#testen op de stack data
stack_test <- stack_data[,1:2]
threshold <- optiPair(pred=stack_test$.pred_1_ranger_fit_1_2,obs=as.numeric(as.character((stack_test$occurrence_status))),measures = c("Sensitivity", "Specificity"), main = "Optimal balance")$ThreshMean

new_pred <- stack_test%>%mutate(binary_pred = ifelse(.pred_1_ranger_fit_1_2 >= threshold, 1, 0))%>%
  select(binary_pred,occurrence_status)
new_pred
sens_vec(estimate=factor(new_pred$binary_pred,levels=c("1","0")),truth=new_pred$occurrence_status)
spec_vec(estimate=factor(new_pred$binary_pred,levels=c("1","0")),truth=new_pred$occurrence_status)


#Might need to re-scale
# Misschien probleem dat we moeten rescalen want is relatief 
testrf <- rf_opt_fit$.predictions[[1]]%>%filter(splitrule=="hellinger")
normalized <- function(x) (x- min(x))/(max(x) - min(x))
rf_rescale <- data.frame(pred1=normalized(testrf$.pred_1),
                         pred0=normalized(testrf$.pred_0),
                         testrf$occurrence_status)
rf_rescale
rf_rescale_diff <- rf_rescale%>%group_by(testrf.occurrence_status)%>%summarize(gem1=median(pred1),gem0=median(pred0))
rf_rescale_diff


# Checking the CV folds ---------------------------------------------------
#Checking outer folds decadal
### Checking these folds
table(pback_decad[outer_decad$splits[[1]]$in_id,4])

ggplot(spatial_extent)+
  geom_sf()+
  geom_point(data = pres_decad[-(outer_decad$splits[[4]]$in_id),], aes(x = longitude, y = latitude, colour = decade))

table(pback_decad[outer_decad$splits[[2]]$in_id,3])

#Checking the monthly folds.

