determine_tempres <- function(spatraster){
  #Take the difference between first and last timepoint, divide by number of timepoints to have approximate time jump per rasterlayer
  time_diff <- spatraster |> 
    time() |>
    range() |>
    diff() |>
    as.numeric() |>
    (\(x) x/nlyr(spatraster))() |>
    round()
  
  #Handling the NA case (e.g. bathymetry)
  if(is.na(time_diff)){
    return("none")
  }
  
  # Determining temporal resolution
  if(time_diff == 1){
    return("daily")
  }
  else if(time_diff == 7){
    return("weekly")
  }
  else if(time_diff %in% 28:31){
    return("monthly")
  }
  else if(time_diff %in% 365:366){
    return("yearly")
  }
  else {
    stop("Not supported time resolution")
  }
}
