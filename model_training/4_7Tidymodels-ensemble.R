#For the model without maxent and before normalization of predictors
stack_data <- 
  stacks() %>%
  add_candidates(ranger_fit) %>%
  add_candidates(mars_fit)%>%
  add_candidates(gam_fit)%>%
  add_candidates(xgb_fit)%>% add_candidates(rf_randForest_fit)

stack_data

start_time <- Sys.time()
stack_mod <-
  blend_predictions(stack_data, metric= yardstick::metric_set(boyce_cont))
end_time <- Sys.time()
print(end_time)
#+- 3min
stack_mod

#Now fit the whole model on the training set
stack_fit <-
  stack_mod %>%
  fit_members()
#16h30 - 16h33
stack_fit

#Saving the model
saveRDS(stack_fit,file.path(datadir,"stacked_model_137117.rds"))
