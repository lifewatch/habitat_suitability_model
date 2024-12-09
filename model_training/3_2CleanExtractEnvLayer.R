# Loading the required packages
library(terra)

#Read in the PA data
load(file.path(datadir,'pback.RData'))

#Load in environmental layers
#To get it into a SpatRaster object
tempsal <- terra::rast(file.path(envdir,"tempsal.nc"))
layer <- nlyr(tempsal)/2
splitlist <- c(rep(1,layer),rep(2,layer))
tempsal_dataset <- split(tempsal,splitlist)
so <- tempsal_dataset[[1]]
so
thetao <- tempsal_dataset[[2]]
thetao

#NPP
if(!file.exists(file.path(envdir,"mean_npp.nc"))){
  npp <- terra::rast(file.path(envdir,"npp.nc"))
  npp
  tijd <- time(npp)
  ym_tijd <- format(tijd, "%Y-%m")
  ym_tijd <- factor(ym_tijd, levels = unique(ym_tijd), ordered = TRUE)
  splitlijst <- as.numeric(ym_tijd)
  yearmon <- seq(from=tijd[1],to=tijd[length(tijd)],by="months")
  npp_dataset <- split(npp,splitlijst)
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



#Now for the bathymetry layer


## general data handling
library(XML)
library(dplyr)
library(tidyr)
library(reshape2)
library(downloader)

library(raster)
library(sp)
library(mapdata)
library(maptools)
library(ncdf4)
library(tiff)
if(!file.exists(file.path(envdir,"bathy.nc"))){
  
  ifelse(!dir.exists(file.path(envdir, "bathy_sliced")), dir.create(file.path(envdir, "bathy_sliced")), FALSE)
  #xmin etc are described in 3_1
  stepsize <- 0.8
  number_of_slices <- (xmax-xmin)/stepsize
  for(i in 1:number_of_slices){
    beginslice <- xmin + (i-1)*stepsize
    endslice <- xmin + i*stepsize
    #We get an error because the file is too big, will split up in horizontal slices, and then merge together later 
    con <-paste0("https://ows.emodnet-bathymetry.eu/wcs?service=wcs&version=1.0.0&request=getcoverage&coverage=emodnet:mean&crs=EPSG:4326&BBOX=",beginslice,",",ymin,",",endslice,",",ymax,"&format=image/tiff&interpolation=nearest&resx=0.08333333&resy=0.08333333")
    nomfich <- file.path(envdir,paste0("bathy_sliced/","slice_",i, "_img.tiff"))
    download(con, nomfich, quiet = TRUE, mode = "wb")
    
  }
  
  
  #merge them together
  bathyrasters <- list()
  for(file in list.files(file.path(envdir,"bathy_sliced"))){
    bathyrasters[[file]] <- rast(file.path(envdir,paste0("bathy_sliced/",file))) 
  }
  #Put the different spatrasters together in a spatrastercollection
  bathy_coll <- sprc(bathyrasters)
  
  #Merge the spatrastercollection
  bathy <- merge(bathy_coll)
  bathy[bathy>0] <- NA
  names(bathy) <-"bathymetry"
  varnames(bathy) <- "bathymetry"
  writeCDF(bathy,file.path(envdir,"bathy.nc"))
} else{
  cat("Bathymetry layer already exists")
  bathy <- terra::rast(file.path(envdir,"bathy.nc"))
  bathy <- resample(bathy,thetao)
}



# Extraction of values related to the occurrence points

# Now that we have the environmental layers loaded as spatial rasters, we need to extract the right values.
# It is easiest to download them first for all the months and then just select the right monthly value for each point.


#For temperature
rastertemp <- terra::extract(x=thetao, y=pback[,c("longitude","latitude")], method="bilinear", na.rm=TRUE,df=T,ID=FALSE)
#takes 20seconds
resulttemp <- data.frame(thetao = rastertemp[cbind(1:nrow(pback),as.numeric(pback$year_month))])

#For NPP
rasternpp <- terra::extract(x=mean_npp, y=pback[,c("longitude","latitude")], method="bilinear", na.rm=TRUE,df=T,ID=FALSE)
#takes 20seconds
resultnpp <- data.frame(npp = rasternpp[cbind(1:nrow(pback),as.numeric(pback$year_month))])


#For salinity
rastersal <- terra::extract(x=so, y=pback[,c("longitude","latitude")], method="bilinear", na.rm=TRUE,df=T,ID=FALSE)
#takes 20seconds

resultsal <- data.frame(so = rastersal[cbind(1:nrow(pback),as.numeric(pback$year_month))])

#For bathymetry
resultbathy <- terra::extract(x=bathy, y=pback[,c("longitude","latitude")], method="bilinear", na.rm=TRUE,df=T,ID=FALSE)
#don't need to choose the right month, because bathy info is the same over the different months, only have one value



# Generate prediction area months------------------------------------------------

#Want to predict on the monthly averages, so need to calculate them:
thetao
so
mean_npp

#Pseudo-code

##for each predictor layer:
##Group the information per month
### assign a month identifier
month_list <- rep(1:12, length.out = nlyr(thetao))

### split them based on this identifier
thetao_month <- split(thetao, month_list)

so_month <- split(so, month_list)

npp_month <- split(mean_npp, month_list)

##Take the average value
thetao_avg <-purrr::map(thetao_month, .f = \(x) terra::app(x,fun=mean))
so_avg <-purrr::map(so_month, .f = \(x) terra::app(x,fun=mean))
npp_avg <-purrr::map(npp_month, .f = \(x) terra::app(x,fun=mean))

##Name the rasters appropriately
names(thetao_avg)<- lubridate::month(1:12,label=TRUE)
names(so_avg)<- lubridate::month(1:12,label=TRUE)
names(npp_avg)<- lubridate::month(1:12,label=TRUE)


# Generate prediction area decades ----------------------------------------
decades_list <- year(time(thetao)) - year(time(thetao)) %% 10
thetao_decad <- split(thetao, decades_list)
so_decad <- split(thetao, decades_list)
npp_decad <- split(mean_npp, decades_list)

#Take the average value
thetao_avg_decad <- purrr::map(thetao_decad, .f = \(x) terra::app(x,fun=mean))
so_avg_decad <- purrr::map(so_decad, .f = \(x) terra::app(x,fun=mean))
npp_avg_decad <- purrr::map(npp_decad, .f = \(x) terra::app(x,fun=mean))

#Name the rasters appropriately
names(thetao_avg_decad) <- unique(sort(decades_list))
names(so_avg_decad) <- unique(sort(decades_list))
names(npp_avg_decad) <- unique(sort(decades_list))


# SAVE OUTPUT -------------------------------------------------------------
pback_env <- cbind(pback,resulttemp,resultsal,resultnpp,resultbathy)%>%drop_na()
save(pback_env,file=file.path(datadir,"pback_env.RData"))

