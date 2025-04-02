normalize_raster <- function(x){
  (x-minmax(x)[1,])/(minmax(x)[2,]-minmax(x)[1,])}