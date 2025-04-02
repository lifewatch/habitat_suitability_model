#based on https://machinelearningmastery.com/robust-scaler-transforms-for-machine-learning/#:~:text=One%20approach%20to%20standardizing%20input%20variables%20in%20the,is%20called%20robust%20standardization%20or%20robust%20data%20scaling.
robustscaler_dataframe <- function(df) {
  return(as.data.frame(lapply(df, function(x) (x - median(x, na.rm = TRUE)) / 
                                IQR(x, na.rm = TRUE))))
}

#df_normalized <- normalize_dataframe(train_data[,-1])
