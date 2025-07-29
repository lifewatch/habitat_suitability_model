# Function that takes a fitted model as input and provides a dataframe of metrics back. 
performance_metrics <- function(model_fit, predict_data, response_variable){
  
  
  predictions <- predict(model_fit, predict_data, type = "prob") %>%
    bind_cols(predict_data%>%dplyr::select({{response_variable}}))%>%
    mutate({{response_variable}} := factor(pull(., var = {{response_variable}}), levels= c(1,0)))
  
  # Threshold independent metrics
  ## CBI
  cbi <- tidysdm::boyce_cont(data = predictions, truth = {{response_variable}}, ".pred_1")$.estimate
  ##  PR-AUC
  pr_auc <- yardstick::pr_auc(predictions, truth = {{response_variable}}, .pred_1)$.estimate
  ## ROC-AUC
  roc_auc <- yardstick::roc_auc(predictions, truth = {{response_variable}}, .pred_1)$.estimate
  
  # Threshold dependent metrics
  
  ## Calculating optimal threshold and making predictions binary
  presence <- predictions$.pred_1[predictions[[{{response_variable}}]]==1]
  background <- predictions$.pred_1[predictions[[{{response_variable}}]]==0]
  
  evaluation <- dismo::evaluate(p = presence,
                                a = background)
  optim_thresh <- dismo::threshold(evaluation, stat = "spec_sens")
  predictions$pred_binary <- factor(ifelse(predictions$.pred_1 >= optim_thresh, 1, 0), levels = c(1,0))
  
  ## Sensitivity (Recall)
  recall <- yardstick::sens(predictions, truth = {{response_variable}}, estimate = pred_binary)$.estimate
  
  ## Precision
  precision <- yardstick::precision(predictions, truth = {{response_variable}}, estimate = pred_binary)$.estimate
  
  ## True Skill Statistic (TSS)
  tss <- tidysdm::tss(predictions, truth = {{response_variable}}, estimate = pred_binary)$.estimate
  
  ## Accuracy
  accuracy <- yardstick::accuracy(predictions, truth = {{response_variable}}, estimate = pred_binary)$.estimate
  
  # Collect everything together in a data.frame
  return(data.frame(cbi = cbi,
                    pr_auc = pr_auc,
                    roc_auc = roc_auc,
                    optim_thresh = optim_thresh,
                    recall = recall,
                    precision = precision,
                    tss = tss,
                    accuracy = accuracy))
}

# Example
# performance_metrics(model_fit = stack_fit, 
#                     predict_data = train_month,
#                     response_variable = "occurrence_status")
