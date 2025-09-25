##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-04-01
# Script Name: ~/habitat_suitability_model/code/10_mapping_predictions.R
# Script Description: Using the final decadal and monthly model, make predictions.
# SETUP ------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
source("code/01_setup.R")

##################################################################################
##################################################################################


# FUNCTIONS ---------------------------------------------------------------
#Make a custom function that can be used with the terra::predict function
predprob <- function(...) predict(...,type="prob")$.pred_1
predmem <- function(...) predict(..., type="prob", members= TRUE)%>%dplyr::select(starts_with(".pred_1"))

# INPUT -------------------------------------------------------------------
model_decade <- open_bundle(file.path(datadir, "modelling_decade","final","fitted_stack.RDS"))
model_month <- open_bundle(file.path(datadir, "modelling_month","final", "fitted_stack.RDS"))
thetao_avg_m <- terra::rast(file.path(datadir, "thetao_avg_m.tif"))
so_avg_m <- terra::rast(file.path(datadir, "so_avg_m.tif"))
npp_avg_m <- terra::rast(file.path(datadir, "npp_avg_m.tif"))
bathy <- terra::rast(file.path(envdir, "bathy.tif"))
thetao_avg_d <- terra::rast(file.path(datadir, "thetao_avg_d.tif"))
so_avg_d <- terra::rast(file.path(datadir, "so_avg_d.tif"))
npp_avg_d <- terra::rast(file.path(datadir, "npp_avg_d.tif"))
# WORKFLOW ----------------------------------------------------------------

# MONTHLY PREDICTIONS -----------------------------------------------------

monthly_predictors <- c()
for(i in 1:nlyr(thetao_avg_m)){
monthly_predictors[[i]] <- c(thetao_avg_m[[i]],so_avg_m[[i]],npp_avg_m[[i]],bathy)
mask <- !is.na(monthly_predictors[[i]])
monthly_predictors[[i]] <- terra::mask(monthly_predictors[[i]], mask)
names(monthly_predictors[[i]]) <- c("thetao","so","npp","bathy")
}

monthly_prediction <- lapply(monthly_predictors, \(x) terra::predict(object = x,
                                            model = model_month,
                                            fun = predprob,
                                            na.rm = TRUE))

monthly_raster <- terra::mask(terra::rast(monthly_prediction),vect(study_area))
monthly_raster_norm <- normalize_raster(monthly_raster)
#Write into netcdf file
names(monthly_raster_norm)<- lubridate::month(1:12,label=TRUE)
terra::time(monthly_raster_norm) <- as.POSIXct(seq(ymd("1999-01-01"), by = "month",length.out=12))
terra::writeCDF(x = monthly_raster_norm,
                filename = file.path(mapsdir,paste0("HSM_",aphiaid,"_ensemble_","monthly",".nc")),
                varname = "HS",
                longname = "Normalized habitat suitability monthly mean (1999-2023)",
                overwrite = TRUE)

# DECADAL PREDICTIONS PRESENT ---------------------------------------------
decad_predictors <- c()
for(i in 1:nlyr(thetao_avg_d)){
  decad_predictors[[i]] <- c(thetao_avg_d[[i]],so_avg_d[[i]],npp_avg_d[[i]],bathy)
  mask <- !is.na(decad_predictors[[i]])
  decad_predictors[[i]] <- terra::mask(decad_predictors[[i]], mask)
  names(decad_predictors[[i]]) <- c("thetao","so","npp","bathy")
}

pres_decad_prediction <- lapply(decad_predictors, \(x) terra::predict(object = x,
                                                                        model = model_decade,
                                                                        fun = predprob,
                                                                        na.rm = TRUE))
pres_decad_prediction_norm <- lapply(pres_decad_prediction, \(x) normalize_raster(x))
pres_decad_raster_norm <- terra::mask(terra::rast(pres_decad_prediction_norm), vect(study_area))

# DECADAL PREDICTIONS FUTURE ----------------------------------------------
#devtools::install_github("bio-oracle/biooracler")
library(biooracler)
if(!file.exists(file.path(envdir,"bio_oracle","thetao_ssp585_2020_2100_depthsurf.tif"))){
  interest_layers <- biooracler::list_layers()%>%
    dplyr::select(dataset_id)%>%
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
                                                         fmt = "raster"),cbind(NaN,NA)),thetao_avg_d[[1]]), #resample so that they have same extent and resolution as CMEMS layers
        filename=file.path(envdir,"bio_oracle",paste0(gsub("phyc","npp",dataset_id) #makes it easier as npp is used as a name for the rest of the workflow
                                                      ,".tif")),overwrite=TRUE)

  )
}  else {
  cat("Bio_oracle ssp rasters already exists")
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
    names(predictors) <- c("thetao","so","npp","bathy")
    prediction[[d]] <-terra::predict(object = predictors,
                                              model = model_decade,
                                              fun = predprob,
                                              na.rm = TRUE)
  }
  future_pred[[s]] <- terra::mask(terra::rast(prediction), vect(study_area))}

# WRITING TO netcdf ---------------------------------------------------------


terra::time(pres_decad_raster_norm) <- as.POSIXct(seq(ymd("2000-01-01"), by = "10 year",length.out=nlyr(pres_decad_raster_norm)))
terra::writeCDF(x = pres_decad_raster_norm,
                filename = file.path(mapsdir,paste0("HSM_",aphiaid,"_ensemble_","decade_present",".nc")),
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
                  filename = file.path(mapsdir,paste0("HSM_",aphiaid,"_ensemble_","decade_future",name,".nc")),
                  varname = "HS",
                  longname = "Future decadal habitat suitability under predicted climate scenario",
                  overwrite = TRUE)
}

# OUTPUT ------------------------------------------------------------------
# monthly predictions
# decadal predictions past
# decadal predictions future scenarios

