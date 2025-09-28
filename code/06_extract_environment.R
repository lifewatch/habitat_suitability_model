##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-28
# Script Name: ~/habitat_suitability_model/code/06_extract_environment.R
# Script Description: Script to couple the CMEMS and EMODnet environmental data to 
# the presence-background points
# SETUP ------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
source("code/01_setup.R")

##################################################################################
##################################################################################


# FUNCTIONS ---------------------------------------------------------------
#couple_env
#determine_tempres
#resample_tempres

# INPUT ------------------------------------------------------------------

pback_month <- readRDS(file.path(datadir, "pback_month.RDS"))
pback_decade <- readRDS(file.path(datadir, "pback_decade.RDS"))
# WORKFLOW ----------------------------------------------------------------

#Load in environmental layers

#Load temperature and salinity out of the same object
#Salinity is first and then temperature
tempsal <- terra::rast(file.path(envdir,"tempsal.nc"))
layer <- nlyr(tempsal)/2

splitlist <- c(rep(1,layer),rep(2,layer))
tempsal_dataset <- split(tempsal,splitlist)

so <- tempsal_dataset[[1]]
so
thetao <- tempsal_dataset[[2]]
thetao

# We also load NPP, this is daily so we need to take the mean ourselves, or just load the object
if(!file.exists(file.path(envdir,"mean_npp.nc"))){
  npp <- terra::rast(file.path(envdir,"npp.nc"))
  npp
  timepoints <- time(npp)
  ym_time <- format(timepoints, "%Y-%m")
  ym_time <- factor(ym_time, levels = unique(ym_time), ordered = TRUE)
  splitlist <- as.numeric(ym_time)
  yearmon <- seq(from=timepoints[1],to=timepoints[length(timepoints)],by="months")
  npp_dataset <- split(npp,splitlist)
  npp_dataset
  mean_npp <- list()
  for(i in 1:length(npp_dataset)){
    mean_npp[[i]]<-  terra::app(npp_dataset[[i]],fun=mean)
  }
  mean_npp <-rast(mean_npp)
  terra::time(mean_npp)<- yearmon
  writeCDF(mean_npp,file.path(envdir,"mean_npp.nc"))
  cat("Mean npp layer created")
} else {
  cat("Mean npp layer already exists")
  mean_npp <- terra::rast(file.path(envdir,"mean_npp.nc"))
  mean_npp <- terra::resample(mean_npp, thetao)
}

# Bathymetry data is a bit different as it is coming from EMODnet
## general data handling
library(XML)
library(dplyr)
library(tidyr)
library(reshape2)
library(downloader)

library(raster)
library(sp)
library(mapdata)
library(ncdf4)
library(tiff)

if(!file.exists(file.path(envdir,"bathy.tif"))){
  
  ifelse(!dir.exists(file.path(envdir, "bathy_sliced")), dir.create(file.path(envdir, "bathy_sliced")), FALSE)
  #xmin etc are described in 3_1
  stepsize <- 0.4
  number_of_slices <- ceiling((bbox[[3]]-bbox[[1]])/stepsize)
  for(i in 1:number_of_slices){
    beginslice <- bbox[[1]] + (i-1)*stepsize
    endslice <- bbox[[1]] + i*stepsize
    #We get an error because the file is too big, will split up in horizontal slices, and then merge together later 
    con <-paste0("https://ows.emodnet-bathymetry.eu/wcs?service=wcs&version=1.0.0&request=getcoverage&coverage=emodnet:mean&crs=EPSG:4326&BBOX=",beginslice,",",bbox[[2]],",",endslice,",",bbox[[4]],"&format=image/tiff&interpolation=nearest&resx=0.08333333&resy=0.08333333")
    nomfich <- file.path(envdir,paste0("bathy_sliced/","slice_",i, "img_.tiff"))
    download(con, nomfich, quiet = TRUE, mode = "wb")
    
  }
  
  
  #merge them together
  bathyrasters <- list()
  for(file in list.files(file.path(envdir,"bathy_sliced"))){
    bathyrasters[[file]] <- terra::rast(file.path(envdir,paste0("bathy_sliced/",file))) 
  }
  #Put the different spatrasters together in a spatrastercollection
  bathy_coll <- sprc(bathyrasters)
  
  #Merge the spatrastercollection
  bathy <- merge(bathy_coll)
  bathy[bathy>0] <- NA
  bathy <- terra::resample(bathy, tempsal[[1]])
  names(bathy) <-"bathy"
  writeRaster(bathy,file.path(envdir,"bathy.tif"), overwrite=TRUE)
} else{
  cat("Bathymetry layer already exists")
  bathy <- terra::rast(file.path(envdir,"bathy.tif"))
  bathy <- resample(bathy,tempsal[[1]])
}

# Average layers per month ------------------------------------------------

monthly_averages <- resample_tempres(spatrasters = list(thetao, so, mean_npp), average_over="monthly")
thetao_avg_m <- monthly_averages[[1]]
so_avg_m <- monthly_averages[[2]]
npp_avg_m <- monthly_averages[[3]]


# Load decadal layers -----------------------------------------------

thetao_avg_d <- terra::rast(file.path(envdir, "bio_oracle", "thetao_baseline_2000_2019_depthsurf.tif"))
so_avg_d <- terra::rast(file.path(envdir, "bio_oracle", "so_baseline_2000_2019_depthsurf.tif"))
npp_avg_d <- terra::rast(file.path(envdir, "bio_oracle", "npp_baseline_2000_2020_depthsurf.tif"))

# Extraction of values related to occurrence points -----------------------

env_month <- couple_env(data = pback_month,
                        thetao_rast = thetao,
                        npp_rast = mean_npp,
                        so_rast = so,
                        bathy_rast = bathy,
                        timescale = "month_year")

env_decade <- couple_env(data = pback_decade,
                         thetao_rast = thetao_avg_d,
                         npp_rast = npp_avg_d,
                         so_rast = so_avg_d,
                         bathy_rast = bathy,
                         timescale = "decade")

# OUTPUT -------------------------------------------------------------

saveRDS(env_month,file=file.path(datadir,"env_month.RDS"))
saveRDS(env_decade,file=file.path(datadir,"env_decade.RDS"))
terra::writeRaster(thetao_avg_m, file.path(datadir, "thetao_avg_m.tif"), overwrite=TRUE)
terra::writeRaster(so_avg_m, file = file.path(datadir, "so_avg_m.tif"), overwrite = TRUE)
terra::writeRaster(npp_avg_m, file = file.path(datadir, "npp_avg_m.tif"), overwrite = TRUE)
terra::writeRaster(thetao_avg_d,file.path(datadir,"thetao_avg_d.tif"), overwrite=TRUE)
terra::writeRaster(so_avg_d, file = file.path(datadir, "so_avg_d.tif"), overwrite = TRUE)
terra::writeRaster(npp_avg_d, file = file.path(datadir, "npp_avg_d.tif"), overwrite = TRUE)
