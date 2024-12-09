
#For each month and decade we want to predict on we need to have an idea on the area of applicability

#newdata is our spatraster we want to predict on.
train_data
predictors_mean
variables <- c("thetao","so","npp","bathymetry")
AOA <- aoa(predictors_mean,train = train_data, variables = variables)

#### Plot results:
plot(AOA$DI)


plot(AOA$LPD)
plot(pts,zcol="ID",col="red",add=TRUE)

plot(prediction)

aoa(
  newdata,
  model = NA,
  trainDI = NA,
  train = NULL,
  weight = NA,
  variables = "all",
  CVtest = NULL,
  CVtrain = NULL,
  method = "L2",
  useWeight = TRUE,
  LPD = FALSE,
  maxLPD = 1,
  indices = FALSE,
  verbose = TRUE
)

library(modEvA)
??MESS
mess <- dismo::mess(x = raster::stack(predictors_mean),
            v = as.matrix(train_data[,-1]),
            full = FALSE)
plot(mess)
mess
