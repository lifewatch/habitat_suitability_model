# We need an indication of the predictive space
#For this we calculate the mean of the layers we want to predict on
#Given a SpatRasterDataset
create_feature_space <- function(){

feature_space <- c()
for(variable in names(prediction_layers)){
  feature_space[[variable]] <- terra::mean(prediction_layers[[variable]])
}
feature_space <- terra::rast(feature_space)

}