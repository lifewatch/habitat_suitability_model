normalize_dataframe <- function(df) {
  return(as.data.frame(lapply(df, function(x) (x - min(x, na.rm = TRUE)) / 
                                (max(x, na.rm = TRUE) - min(x, na.rm = TRUE)))))
}

#df_normalized <- normalize_dataframe(train_data[,-1])
