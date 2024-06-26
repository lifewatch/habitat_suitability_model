# script that reads yaml configuration and builds on the information provided.
# source this script and use settings to get config parameters.

library(yaml)

get_config = function(config){
  #' function that gets the configuration settings from a yaml file
  #' default config.yml is the one located in main dir. 
  #' 
  if (missing(config)){
    config = "config.yml"
  }
  ## ---------------------------------------------------------------------------
  # READ CONFIG FILE
  settings= yaml.load_file("config.yml")
  return(settings)
}

settings = get_config()

  