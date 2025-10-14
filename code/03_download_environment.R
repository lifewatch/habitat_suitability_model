##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-19
# Script Name: ~/habitat_suitability_model/code/03_download_environment.R
# Script Description: Download the environmental variables from CMEMS using the
# CopernicuMarine toolbox via python.


source("load_common_packages.R")


# INPUT -------------------------------------------------------------------

# ** envdir **
# bbox
# temporal_extent
# copernicus_marine_username
# copernicus_marine_password


# OUTPUT ------------------------------------------------------------------

# data
# └── raw_data
#     ├── environmental_layers
#     │   ├── bio_oracle
#     │   │   ├── npp_baseline_2000_2020_depthsurf.tif
#     │   │   ├── npp_baseline_2000_2020_depthsurf.tif.aux.json
#     │   │   ├── so_baseline_2000_2019_depthsurf.tif
#     │   │   ├── so_baseline_2000_2019_depthsurf.tif.aux.json
#     │   │   ├── thetao_baseline_2000_2019_depthsurf.tif
#     │   │   └── thetao_baseline_2000_2019_depthsurf.tif.aux.json
#     │   ├── npp.nc
#     │   └── tempsal.nc


# WORKFLOW ----------------------------------------------------------------

reticulate::use_virtualenv("marcobolo")

# More information on the reticulate package on: https://rstudio.github.io/cheatsheets/reticulate.pdf
# Overview of the functions can be found at: https://help.marine.copernicus.eu/en/collections/9080063-copernicus-marine-toolbox
# How to configure the credentials can be found at: https://help.marine.copernicus.eu/en/articles/8185007-copernicus-marine-toolbox-credentials-configuration
# Works in the terminal. Needs to be done only once.

xmin <- bbox[[1]]
xmax <- bbox[[3]]
ymin <- bbox[[2]]
ymax <- bbox[[4]]

cm <- reticulate::import("copernicusmarine")
start <- as.POSIXct(lubridate::int_start(temporal_extent), format = "%Y-%m-%d %Z") %>% format("%Y-%m-%dT%H:%M:%S")
end <- as.POSIXct(lubridate::int_end(temporal_extent), format = "%Y-%m-%d %Z") %>% format("%Y-%m-%dT%H:%M:%S")
#cm$login()
cm$subset(
    dataset_id = "cmems_mod_glo_phy_my_0.083deg_P1M-m",
    variables = c("so", "thetao"),
    minimum_longitude = xmin,
    maximum_longitude = xmax,
    minimum_latitude = ymin,
    maximum_latitude = ymax,
    start_datetime = start,
    end_datetime = end,
    minimum_depth = 0.49402499198913574,
    maximum_depth = 0.49402499198913574,
    output_directory = envdir,
    output_filename = "tempsal.nc",
    overwrite = TRUE,
    username = copernicus_marine_username,
    password = copernicus_marine_password
)

cm$subset(
    dataset_id = "cmems_mod_glo_bgc_my_0.083deg-lmtl_PT1D-i",
    variables = list("npp"),
    minimum_longitude = xmin,
    maximum_longitude = xmax,
    minimum_latitude = ymin,
    maximum_latitude = ymax,
    start_datetime = start,
    end_datetime = end,
    minimum_depth = 0.5057600140571594,
    maximum_depth = 0.5057600140571594,
    output_directory = envdir,
    output_filename = "npp.nc",
    overwrite = TRUE,
    username = copernicus_marine_username,
    password = copernicus_marine_password
)

tempsal <- terra::rast(file.path(envdir, "tempsal.nc"))
ifelse(!dir.exists(file.path(envdir, "bio_oracle")), dir.create(file.path(envdir, "bio_oracle")), FALSE)
#Download decadal bio-oracle layers
interest_layers <- biooracler::list_layers() %>%
    dplyr::select(dataset_id) %>%
    filter(
        str_detect(dataset_id, "so|thetao|phyc") &
            str_detect(dataset_id, "depthsurf") &
            str_detect(dataset_id, "baseline")
    ) %>%
    arrange(dataset_id) %>%
    mutate(variables = paste0(str_extract(dataset_id, "^[^_]+"), "_mean"))
constraints <- list("longitude" = c(bbox[[1]], bbox[[3]]),
                    "latitude" = c(bbox[[2]], bbox[[4]]))
pwalk(
    interest_layers,
    \(dataset_id, variables) terra::writeRaster(
        terra::resample(
            terra::classify(
                biooracler::download_layers(
                    dataset_id = dataset_id,
                    variables = variables,
                    constraints = constraints,
                    fmt = "raster"
                ),
                cbind(NaN, NA)
            ),
            tempsal[[1]]
        ),
        #resample so that they have same extent and resolution as CMEMS layers
        filename =
            file.path(envdir, "bio_oracle", paste0(
                gsub("phyc", "npp", dataset_id) #makes it easier as npp is used as a name for the rest of the workflow
                ,
                ".tif"
            )),
        overwrite = TRUE
    )
)

# OUTPUT ------------------------------------------------------------------
#tempsal.nc
#npp.nc