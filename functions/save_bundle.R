#based on: https://stackoverflow.com/questions/64396504/is-there-a-method-to-serialize-a-machine-learning-model-in-within-tidymodels-si
save_bundle <- function(model, filepath){
  mod_bundle <- bundle(model)
  saveRDS(mod_bundle, file = filepath)
}
