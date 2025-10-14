evaluate_model <- function(occurrences,
                           time = "month",
                           file_path_general){

  ifelse(!dir.exists(file_path_general), dir.create(file_path_general), FALSE)
  # Creating folds and preparing data
  n_folds <- 5
  ## stratify based on a combination of the occurrence status and either month or decade
  ## this way all the months/decades are represented and also the ratio of presence/absence is kept
  if(time == "month"){
    strat <- paste0(as.character(occurrences$occurrence_status),"-",
                    as.character(month(ym(occurrences$year_month))))
  } else if (time == "decade") {
    strat <- paste0(as.character(occurrences$occurrence_status),"-",
                    as.character(occurrences$decade))
  }
  strat <- paste0(as.character(occurrences$occurrence_status),"-",
                  as.character(month(ym(occurrences$year_month))))
  strat <- factor(strat)
  occurrences <- occurrences%>%
    dplyr::mutate(strat = strat)
  #stratified cross-validation
  cv_folds <- vfold_cv(data = occurrences,
                       v = n_folds,
                       strata = "strat")
  occurrences <- occurrences%>%
    dplyr::select(-strat)

  indices <- list()
  ## For each of the folds train the model and assess the performance
  for(i in 1:nrow(cv_folds)){
    indices <- list(analysis = as.integer(cv_folds$splits[[i]]$in_id), #training data
                    assessment = as.integer(setdiff(1:nrow(occurrences),cv_folds$splits[[i]]$in_id))) #test data
    train_set <- occurrences[indices$analysis,]
    test_set <- occurrences[indices$assessment,]

    ### Run train_model
    train_model(occurrences = train_set,
                time = "month",
                file_path = file.path(file_path_general,
                                      paste0("fold",i)))
    ### Run stack_model
    stack_model(file_path = file.path(file_path_general,
                                      paste0("fold",i)))
    ### Run performance_metrics on the test set

    performance <- performance_metrics(model_fit = open_bundle(file.path(file_path_general,
                                                                         paste0("fold",i),
                                                                         "fitted_stack.RDS")),
                                       predict_data = test_set,
                                       response_variable = "occurrence_status")
    saveRDS(performance,
            file.path(file_path_general,
                      paste0("fold",i),
                      "performance.RDS"))
  }
}