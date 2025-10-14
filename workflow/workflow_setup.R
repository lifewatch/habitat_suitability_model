# restore the environment
if (!file.exists("renv.lock")) {
    stop(
        "The required environment file 'renv.lock' is missing. I cannot install the workflow."
    )
}
install.packages("renv", repos = "https://cloud.r-project.org")
renv::restore(prompt = FALSE)
install.packages("optparse", repos = "https://cloud.r-project.org")

# optional
# devtools::install_deps(dependencies = TRUE)

# create the folder struct
downloaddir <- "data/raw_data"
datadir     <- "data/derived_data"
mapsdir     <- "results/geospatial_layers"
modeldir   <- "results/models"
figdir    <- "results/figures_tables"
envdir <- "data/raw_data/environmental_layers"
occdir <- "data/raw_data/occurrences"
spatdir <- "data/raw_data/spatial_layers"
scriptsdir <- "code/"
folderstruc <- c(downloaddir,
                 datadir,
                 mapsdir,
                 modeldir,
                 figdir,
                 envdir,
                 occdir,
                 spatdir,
                 scriptsdir)

for (folder in folderstruc) {
    if (!dir.exists(folder)) {
        dir.create(folder, recursive = TRUE)
        cat("Folder created:", folder, "\n")
    } else {
        cat("Folder already exists:", folder, "\n")
    }
}

# directory for common assets
dir.create("assets", recursive = TRUE)


# for cases where the user does not provide a shapefile for defining the study area

load_ospar <- function(regions = c("I", "II", "III", "IV", "V"),
                       filepath) {
    # Ensure required package is available
    if (!requireNamespace("sf", quietly = TRUE)) {
        stop("The 'sf' package is required but not installed.")
    }

    # Download OSPAR data if file doesn't exist
    if (!file.exists(filepath)) {
        message("OSPAR region file not found. Downloading from official source...")

        url <- "https://odims.ospar.org/public/submissions/ospar_regions/regions/2017-01/002/ospar_regions_2017_01_002-gis.zip"
        zip_path <- file.path(dirname(filepath), "ospar_REGIONS.zip")

        tryCatch({
            utils::download.file(url, zip_path, mode = "wb")
            utils::unzip(zipfile = zip_path, exdir = dirname(filepath))
            message("Download and extraction completed.")
        }, error = function(e) {
            stop("Failed to download or unzip OSPAR regions file: ",
                 e$message)
        })
    }

    # Read spatial file
    ospar_regions <- sf::st_read(filepath, quiet = TRUE)

    # Check if expected 'Region' column exists
    if (!"Region" %in% names(ospar_regions)) {
        stop("The 'Region' column is missing in the input shapefile.")
    }

    # Filter and combine selected regions
    study_area <- ospar_regions[ospar_regions$Region %in% regions, ]
    study_area <- sf::st_make_valid(study_area)
    study_area <- sf::st_union(study_area)

    return(study_area)
}


# get OSPAR regions II, III, IV for use when no study area shapefile is given
ospar_area <- load_ospar(c("II", "III", 'IV'),
                         filepath = file.path(spatdir, "ospar_regions_2017_01_002.shp"))
ospar_area <- list(area = ospar_area, bbox = sf::st_bbox(ospar_area))

saveRDS(ospar_area, file = "assets/ospar_area.RDS")


# save the valid aphia ids
aphia_ids <- tibble::tribble(
    ~ ID, ~ Name,
    137117, "Phocoena phocoena",
    137084, "Phoca vitulina",
    137094, "Delphinus delphis",
    137111, "Tursiops truncatus"
)
saveRDS(aphia_ids, file = "assets/aphia_ids.RDS")


# create the python environment
if (!requireNamespace("reticulate", quietly = TRUE)) {
    stop("The required package <reticulate> is not installed")
}
reticulate::install_python(version = "3.10")
reticulate::virtualenv_create("marcobolo", force = FALSE)
reticulate::py_install("copernicusmarine", envname = "marcobolo", ignore_installed = FALSE)

