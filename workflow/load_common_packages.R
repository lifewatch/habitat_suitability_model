load_common_packages <- function() {
    packages <- c(
        "arrow",
        "biooracler",
        "bundle",
        "CAST",
        "cmocean",
        "CoordinateCleaner",
        "dismo",
        "doFuture",
        "doParallel",
        "downloader",
        "earth",
        "foreach",
        "future",
        "GeoThinneR",
        "mgcv",
        "ows4R",
        "randomForest",
        "ranger",
        "raster",
        "sdm",
        "sf",
        "sp",
        "spatialEco",
        "spatstat",
        "stacks",
        "stats",
        "terra",
        "tidymodels",
        "tidysdm",
        "tidyverse",
        "utils",
        "worrms",
        "xgboost"
    )
    packates_to_load <- packages[!paste0("package:", packages) %in% search()]
    load_status <- sapply(packates_to_load, function(pkg) {
        suppressPackageStartupMessages(require(pkg, character.only = TRUE))
    })
    if (any(!load_status)) {
        stop("Failed to load some packages: ",
             paste(packages[!load_status], collapse = ", "))
    }
    if (!"package:imis" %in% search()) {
        suppressPackageStartupMessages(library(imis))
    }
    invisible(TRUE)
}

tuned_imis_request <- function(parameters, verbose = FALSE) {
    if (!is.list(parameters) || is.null(names(parameters))) {
        stop("`parameters` must be a named list.")
    }
    url <- "https://www.vliz.be/en/imis"
    user_agent <- httr::user_agent("IMIS R client")

    response <- tryCatch({
        httr::GET(url, user_agent, query = parameters)
    }, error = function(e) {
        stop("HTTP request failed: ", e$message)
    })
    if (httr::http_error(response)) {
        warning_msg <- paste0(
            "Request failed [",
            httr::status_code(response),
            "]: ",
            httr::http_status(response)$message
        )
        if (verbose)
            message(warning_msg)
        stop(warning_msg)
    } else {
        if (verbose) {
            print(httr::http_status(response))
            print(httr::headers(response))
        }
        return(response)
    }
}

tune_imis_request <- function() {
    imis_namespace <- asNamespace("imis")
    unlockBinding("imis_request", imis_namespace)

    assign("imis_request", tuned_imis_request, envir = imis_namespace)
    lockBinding("imis_request", imis_namespace)
}

downloaddir <- "data/raw_data"
datadir     <- "data/derived_data"
mapsdir     <- "results/geospatial_layers"
modeldir   <- "results/models"
figdir    <- "results/figures_tables"
envdir <- "data/raw_data/environmental_layers"
occdir <- "data/raw_data/occurrences"
spatdir <- "data/raw_data/spatial_layers"
scriptsdir <- "code/"

load_common_packages()
tune_imis_request()
invisible(lapply(list.files("functions", full.names = TRUE), source))