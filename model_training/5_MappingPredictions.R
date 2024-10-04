model <- readRDS(file.path(datadir,model_object))



set.seed(222)
#Put 4/5 in the training set
data_split<- initial_split(data, prop=4/5)

#Create data frames for the two sets:
train_data <- training(data_split)
test_data <- testing(data_split)






model #this is the model
library(caret) #without this it might give an error trying to use a predict function from another package

prediction <- predict(model,test_data)%>%
  bind_cols(predict(model,test_data, type="prob")) %>%
  bind_cols(test_data %>%
              dplyr::select(occurrenceStatus))
prediction
accuracy_vec(prediction$occurrenceStatus,prediction$.pred_class)



# Prepare environmental data

#Make a custom function that can be used with the terra::predict function
predprob <- function(...) predict(...,type="prob")$.pred_1
#Try out how to make this one work as well
predmem <- function(...) predict(..., type="prob",members=TRUE)


#For monthly maps using the same rasters as it was build on


#Load the different layers (see environmental clean script)

#Different layers, crop them to the same extent of bathy
thetao <- crop(thetao,bathy) #layer1: 1999-01-01 -> layer270: 2021-06-01
so <- crop(so,bathy)#layer1: 1999-01-01 -> layer270: 2021-06-01
mean_npp <- crop(mean_npp,bathy)#layer1: 1999-01-01 -> layer288: 2022-12-31
ext(bathy) <- ext(thetao) #because there where small differences and then we can't combine them
bathy <- resample(bathy, thetao) #because after the change in extent we couldn't combine them without resampling bathy as its resolution changed
monthly_prediction <- list()
#Loop over every monthy layer (Takes +-1 min for 12 months)
for(i in 1:nlyr(thetao)){
  #Get out the right monthly layer and combine them together in a new spatraster that contains one layer for each predictor
  monthly_info <- c(thetao[[i]],so[[i]],mean_npp[[i]],bathy)
  #Delete the NA values
  mask <- !is.na(monthly_info)
  monthly_info <- terra::mask(monthly_info,mask)
  #To make sure the names of the layers correpond to the names the model was trained on
  names(monthly_info) <- c(
    "thetao",
    "so","npp","bathy")
  monthly_prediction[[i]] <- predict(monthly_info,model,fun=predprob,na.rm=TRUE)
}
#To turn it into a raster layer  
monthly_prediction <- rast(monthly_prediction)

writeCDF(monthly_prediction,file.path(datadir,paste0("monthly_predictions_",aphia_id,".nc")))
