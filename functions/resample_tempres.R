resample_tempres <- function(spatrasters,average_over = "monthly"){
  tempres_levels <- c("daily", "weekly", "monthly", "yearly","decadely" ,"none")
  tempres_current <- lapply(spatrasters,determine_tempres)
  if(!(any(tempres_current %in% tempres_levels)) || !(average_over %in% tempres_levels)){
    stop("Invalid temporal resolution provided.")
  }
  if(any(match(average_over, tempres_levels) < match(tempres_current, tempres_levels))){
    stop("Cannot resample over a lower temporal resolution.")
  }
  if(average_over == "monthly"){
    split_list <- lapply(spatrasters, function(x) month(time(x)))
  }
  else if(average_over == "yearly"){
    split_list <- lapply(spatrasters, function(x) year(time(x)))
  }
  else if(average_over == "decadely"){
    split_list <- lapply(spatrasters, function(x) year(time(x)) - year(time(x)) %% 10)
  }
  #Split every variable based on this split_list
  var_split <- lapply(seq_along(spatrasters), function(x) split(spatrasters[[x]], f = split_list[[x]]))

  #Apply averaging over the subcollections of every variable for every time
  var_avg <- lapply(var_split,
                    function(y) terra::rast(lapply(y, function(x) terra::app(x,fun=mean))))

  named_var_avg <- lapply(seq_along(var_avg), function(i) {
    names(var_avg[[i]]) <- unique(unlist(split_list))
    # varnames(var_avg[[i]]) <- varnames(spatrasters[[i]])
    terra::varnames(var_avg[[i]]) <- terra::varnames(spatrasters[[i]])[1]
    return(var_avg[[i]])
  })

  return(named_var_avg)
}