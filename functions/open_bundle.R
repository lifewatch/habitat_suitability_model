#based on: https://stackoverflow.com/questions/64396504/is-there-a-method-to-serialize-a-machine-learning-model-in-within-tidymodels-si
open_bundle <- function(filepath){
  mod_bundle <- readRDS(filepath)
  mod_new <- unbundle(mod_bundle)
  return(mod_new)
}
