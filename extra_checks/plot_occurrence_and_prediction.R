library(cmocean)
library(terra)
library(lubridate)
env_month <- readRDS(file.path(datadir,"env_month.RDS"))
monthly_hsm <- terra::rast(file.path(datadir, "HSM_137117_ensemble_monthly_v0_1.nc"))
monthly_hsm <- terra::mask(monthly_hsm,study_area)

#Monthly plot occurrenceson top of predictions
pdf("monthly_maps.pdf", width = 8, height = 6)
for(i in 1:12){
  monthly_pts <- vect(env_month%>%
                        dplyr::filter(occurrence_status == 1, month == i), geom = c("longitude","latitude"),
                      crs = crs(monthly_hsm))
  terra::plot(monthly_hsm[[i]],col = cmocean('algae')(256), alpha = 1, main = lubridate::month(i,label=TRUE))
  points(monthly_pts, col = "red", pch = 16, cex = 0.6, alpha = 0.3)
}
dev.off()

#Same for background points
pdf("monthly_maps_background.pdf", width = 8, height = 6)
for(i in 1:12){
  monthly_pts <- vect(env_month%>%
                        dplyr::filter(occurrence_status == 0, month == i), geom = c("longitude","latitude"),
                      crs = crs(monthly_hsm))
  terra::plot(monthly_hsm[[i]],col = cmocean('algae')(256), alpha = 1, main = lubridate::month(i,label=TRUE))
  points(monthly_pts, col = "blue", pch = 16, cex = 0.6, alpha = 0.3)
}
dev.off()