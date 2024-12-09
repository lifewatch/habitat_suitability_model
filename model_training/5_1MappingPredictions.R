model <- readRDS(file.path(datadir,model_object))



set.seed(222)
#Put 4/5 in the training set
data_split<- initial_split(data, prop=4/5)

#Create data frames for the two sets:
train_data <- training(data_split)
test_data <- testing(data_split)



# Make predictions using the final model

model #this is the model
library(caret) #without this it might give an error trying to use a predict function from another package

prediction <- predict(model,test_data)%>%
  bind_cols(predict(model,test_data, type="prob")) %>%
  bind_cols(test_data %>%
              dplyr::select(occurrenceStatus))
prediction
accuracy_vec(prediction$occurrenceStatus,prediction$.pred_class)

terra::rast()[[1]]

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

monthly_predictors <- c()
for(i in 1:length(thetao_avg)){
monthly_predictors[[i]] <- c(thetao_avg[[i]],so_avg[[i]],npp_avg[[i]],bathy)
mask <- !is.na(monthly_predictors[[i]])
monthly_predictors[[i]] <- terra::mask(monthly_predictors[[i]], mask)
names(monthly_predictors[[i]]) <- c("thetao","so","npp","bathymetry")
}

monthly_prediction <- lapply(monthly_predictors, \(x) terra::predict(object = rastnorm(x),
                                            model = stack_fit,
                                            fun = predprob,
                                            na.rm = TRUE))
monthly_raster <- terra::rast(monthly_prediction)
monthly_raster_norm <- rastnorm(monthly_raster)

#Write into netcdf file
names(monthly_raster_norm)<- lubridate::month(1:12,label=TRUE)
terra::time(monthly_raster_norm) <- as.POSIXct(seq(ymd("1999-01-01"), by = "month",length.out=12))
terra::writeCDF(x = monthly_raster_norm,
                filename = file.path(datadir,paste0("HSM_",aphia_id,"_ensemble_","monthly_","v0_1",".nc")),
                varname = "HS",
                longname = "Normalized habitat suitability monthly mean (1999-2023)",
                overwrite = TRUE)

# DECADAL PREDICTIONS PRESENT ---------------------------------------------
# have the decadal environmental layers ready to predict on. 
decad_predictors <- c()
for(i in 1:length(thetao_avg_decad)){
  decad_predictors[[i]] <- c(thetao_avg_decad[[i]],so_avg_decad[[i]],npp_avg_decad[[i]],bathy)
  mask <- !is.na(decad_predictors[[i]])
  decad_predictors[[i]] <- terra::mask(decad_predictors[[i]], mask)
  names(decad_predictors[[i]]) <- c("thetao","so","npp","bathymetry")
}
pres_decad_prediction <- lapply(decad_predictors, \(x) terra::predict(object = rastnorm(x),
                                                                        model = stack_fit,
                                                                        fun = predprob,
                                                                        na.rm = TRUE))
rastnorm <- function(x)(x-minmax(x)[1,])/(minmax(x)[2,]-minmax(x)[1,])
pres_decad_prediction_norm <- lapply(pres_decad_prediction, \(x) rastnorm(x))
pres_decad_raster_norm <- terra::rast(pres_decad_prediction_norm)

# DECADAL PREDICTIONS FUTURE ----------------------------------------------
#devtools::install_github("bio-oracle/biooracler")
library(biooracler)
if(!dir.exists(file.path(envdir,"bio_oracle"))){
  dir.create(file.path(envdir, "bio_oracle"))
  interest_layers <- biooracler::list_layers()%>%
    select(dataset_id)%>%
    filter(
      str_detect(dataset_id, "so|thetao|phyc") &
        str_detect(dataset_id, "depthsurf") &
        str_detect(dataset_id, "ssp")
    )%>%
    arrange(dataset_id)%>%
    mutate(variables = paste0(str_extract(dataset_id, "^[^_]+"),"_mean"))
  
  constraints <- list("longitude" = c(bbox[[1]],bbox[[3]]),"latitude" = c(bbox[[2]],bbox[[4]]))
  
  pwalk(interest_layers, \(dataset_id,variables) terra::writeRaster(terra::resample(terra::classify(biooracler::download_layers(dataset_id = dataset_id,
                                                         variables = variables,
                                                         constraints = constraints,
                                                         fmt = "raster"),cbind(NaN,NA)),thetao_avg_decad[[1]]), #resample so that they have same extent and resolution as CMEMS layers
        filename=file.path(envdir,"bio_oracle",paste0(gsub("phyc","npp",dataset_id) #makes it easier as npp is used as a name for the rest of the workflow
                                                      ,".tif")),overwrite=TRUE)

  )
}  else {
  cat("Bio_oracle folder already exists")
}
future_scenarios <- c("ssp119","ssp126","ssp245","ssp370","ssp460","ssp585")
future_path <- file.path(envdir,"bio_oracle")
future_rasterlist <- list()
for(i in future_scenarios){
  file_list <- list.files(file.path(envdir,"bio_oracle"),pattern = paste0(i, ".*\\.tif$"))
  future_rasterlist[[i]] <- list(thetao = terra::rast(file.path(future_path,str_subset(file_list,"thetao"))),
                               so = terra::rast(file.path(future_path,str_subset(file_list,"so"))),
                               npp = terra::rast(file.path(future_path,str_subset(file_list,"npp"))))
}


future_pred <- c()
for(s in future_scenarios){
  scenario <- future_rasterlist[[s]]
  prediction <- c()
  for(d in 1:8){
    predictors <- c(scenario$thetao[[d]],scenario$so[[d]],scenario$npp[[d]],bathy)
    names(predictors) <- c("thetao","so","npp","bathymetry")
    prediction[[d]] <-rastnorm(terra::predict(object = rastnorm(predictors),
                                              model = stack_fit,
                                              fun = predprob,
                                              na.rm = TRUE))
  }
  future_pred[[s]] <- terra::rast(prediction)}

# WRITING TO netcdf ---------------------------------------------------------

pres_decad_raster_norm
names(pres_decad_raster_norm)<- unique(sort(decades_list))
terra::time(pres_decad_raster_norm) <- as.POSIXct(seq(ymd("1990-01-01"), by = "10 year",length.out=3))
terra::writeCDF(x = pres_decad_raster_norm,
                filename = file.path(datadir,paste0("HSM_",aphia_id,"_ensemble_","decade_present_","v0_1",".nc")),
                varname = "HS",
                longname = "Normalized decadal habitat suitability",
                overwrite = TRUE)
for(i in 1:length(future_pred)){
  name <- names(future_pred)[i]
  raster <- future_pred[[i]]
  decade_time <- as.POSIXct(seq(ymd("2020-01-01"), by = "10 year",length.out=8))
  names(raster) <- year(decade_time)
  terra::time(raster) <- decade_time
  terra::writeCDF(x = raster,
                  filename = file.path(datadir,paste0("HSM_",aphia_id,"_ensemble_","decade_future_",name,"_v0_1",".nc")),
                  varname = "HS",
                  longname = "Future decadal habitat suitability under predicted climate scenario",
                  overwrite = TRUE)
}

future_pred
