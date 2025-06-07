##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-04-02
# Script Name: ~/habitat_suitability_model/code/11_static_plot.R
# Script Description: In this script, the xarray python package is used via R to
# plot the monthly trend in the chosen bounding box.
# SETUP ------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space

path = list(
  code = "./code",
  setup = "/mnt/inputs/01_setup.json",
  nc = "/mnt/inputs/nc",
  monthly_bbox = "/mnt/outputs/monthly_bbox.png"
)

setup <- jsonlite::read_json(path$setup)
aphiaid = as.integer(setup$aphiaid)
##################################################################################
##################################################################################
lapply(list.files("functions", full.names = TRUE),source)
sapply(list.files(path$code, full.names = T), source)
lapply(list.files("/wrp/utils", full.names = TRUE, pattern = "\\.R$"), source)

args = args_parse(commandArgs(trailingOnly = TRUE))

library(reticulate)
py_install("copernicusmarine",envname = "mbo-proj")
py_install("matplotlib", envname = "mbo-proj")
use_virtualenv("mbo-proj") #Load the environment
# Import xarray
xr <- import("xarray")
plt <- import("matplotlib.pyplot")
plt$ion()  # Enable interactive mode

# Open the dataset
suitability <- xr$open_dataset(file.path(path$nc, paste0("HSM_",aphiaid,"_ensemble_monthly_v0_1.nc")))

# Extract the HS variable
hs <- suitability$HS



# Subset the data
area <- hs$sel(longitude = py_eval("slice")(min_lon, max_lon),
                latitude = py_eval("slice")(max_lat, min_lat))
s
# Compute the mean over latitude and longitude
mean_area <- area$mean(dim = list("latitude", "longitude"))

# Plot the time series
mean_area$plot()

plt$show(block=TRUE)

# Save the plot as a PNG file
plt$savefig(file.path(path$monthly_bbox), dpi = 300)
