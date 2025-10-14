read_arguments <- function() {

    aphia_ids <- readRDS(file = "assets/aphia_ids.RDS")

    option_list <- list(
        optparse::make_option("--start_date", type="character", default=NULL, help="End date of the period of interest"),
        optparse::make_option("--end_date", type="character", default=NULL, help="End date of the period of interest"),
        optparse::make_option("--aphia_id", type="integer", default=NULL, help="Aphiad ID"),
        optparse::make_option("--copernicus_marine_username", type="character", default=NULL, help="CopernicusMarine username used to download datasets"),
        optparse::make_option("--copernicus_marine_password", type="character", default=NULL, help="CopernicusMarine password used to download datasets")
    )
    parser <- optparse::OptionParser(option_list = option_list)
    args <- optparse::parse_args(parser)

    parse_date_arg <- function(x, name) {
        value = x[[name]]
        if (is.null(value) || anyNA(value)) {
            stop(paste("Missing date", name, sep=": "))
        } else {
            result <- lubridate::as_datetime(value)
            if (is.na(result)) {
                stop(paste("Invalid date", name, sep=": "))
            } else {
                return(result)
            }
        }
    }

    parse_float_list_arg <- function(x, name) {
        value = x[[name]]
        if (is.null(value)) {
            stop(paste("Missing parameter:", name, sep=": "))
        } else {
            result <- as.numeric(unlist(strsplit(value, ",")))
            if (0 == length(result) || anyNA(result)) {
                stop(paste("Invalid list", name, sep=": "))
            } else {
                return(result)
            }
        }
    }

    parse_float_arg <- function(x, name) {
        value = x[[name]]
        if (is.null(value) || is.na(value)) {
            stop(paste("Missing parameter:", name, sep=": "))
        } else if (!is.numeric(value)) {
            stop(paste("Invalid parameter:", name, sep=": "))
        } else {
            return(value)
        }
    }

    parse_integer_arg <- function(x, name) {
        value = x[[name]]
        if (is.null(value) || is.na(value)) {
            stop(paste("Missing parameter:", name, sep=": "))
        } else if (!is.integer(value)) {
            stop(paste("Invalid parameter:", name, sep=": "))
        } else {
            return(value)
        }
    }

    aphia_id <- parse_integer_arg(args, "aphia_id")
    if (!(aphia_id %in% aphia_ids$ID)) {
        stop(paste("Aphia ID is not valid. Possible values", paste(aphia_ids$ID, collapse = ", "), sep = ": "))
    }

    start_date <- parse_date_arg(args, "start_date")
    end_date <- parse_date_arg(args, "end_date")
    if (start_date >= end_date) {
        stop("start_date must precede end_date")
    }

    # get_decades <- function(start_date, end_date) {
    #     # Ensure dates are Date objects
    #     start_date <- lubridate::as_date(start_date)
    #     end_date <- lubridate::as_date(end_date)

    #     # Swap if dates are in wrong order
    #     if (start_date > end_date) {
    #         tmp <- start_date
    #         start_date <- end_date
    #         end_date <- tmp
    #     }

    #     # Extract starting and ending years
    #     start_year <- lubridate::year(start_date)
    #     end_year <- lubridate::year(end_date)

    #     # Compute the starting and ending decades (floor to nearest decade)
    #     start_decade <- floor(start_year / 10) * 10
    #     end_decade <- floor(end_year / 10) * 10

    #     # Generate sequence of decades
    #     decades <- seq(start_decade, end_decade, by = 10)

    #     return(decades)
    # }
    # if (3 > length(get_decades(start_date, end_date))) {
    #     stop("This model requires a temporal extent spanning at least three different decades.")
    # }

    copernicus_username <- args$copernicus_marine_username
    copernicus_password <- args$copernicus_marine_password
    is_nonempty_string <- function(x) (is.character(x) && length(x) == 1 && !is.na(x) && nzchar(x))
    if (!is_nonempty_string(copernicus_username)) {
        stop("A valid Copernicus Marine username is required")
    }
    if (!is_nonempty_string(copernicus_password)) {
        stop("A valid Copernicus Marine password is required")
    }

    return(list(
        aphia_id = aphia_id,
        temporal_extent = lubridate::interval(start_date, end_date),
        copernicus_credentials = list(username = copernicus_username, password = copernicus_password)
    ))
}


args <- read_arguments()
aphiaid <- args$aphia_id
temporal_extent <- args$temporal_extent
copernicus_marine_username <- args$copernicus_credentials$username
copernicus_marine_password <- args$copernicus_credentials$password
rm(args)

ospar <- readRDS("assets/ospar_area.RDS")
study_area <- ospar$area
bbox <- ospar$bbox
rm(ospar)

variables_to_keep <- c("clean_variables", "variables_to_keep", "aphiaid", "temporal_extent", "copernicus_marine_username", "copernicus_marine_password", "study_area", "bbox")

clean_variables <- function() {
  rm(list = setdiff(ls(envir = .GlobalEnv), variables_to_keep), envir = .GlobalEnv)
}

# for future
options(future.globals.maxSize = 5 * 1024^3)  # 5 GB



# actual workflow
scripts <- c(
    "code/02_download_presences.R",
    "code/03_download_environment.R",
    "code/04_preprocess_presences.R",
    "code/05a_sample_background.R",
    "code/05b_sample_background.R",
    "code/06_extract_environment.R",
    "code/07_PAExploration.R",
    "code/08_decade_evaluation.R",
    "code/08_decade_training.R",
    "code/08_month_evaluation.R",
    "code/08_month_training.R",
    "code/09_mapping_predictions.R"
)
for (script in scripts) {
    clean_variables()
    source(script)
}
clean_variables()
rmarkdown::render("code/10_report.Rmd")


# build the output

output_result_folder <- function(zip_path, source_path) {
    zip(zipfile = zip_path, files = list.files(source_path, full.names = TRUE))
    if (!dir.exists("/mnt/outputs")) {
        dir.create("/mnt/outputs", recursive = TRUE)
    }
    target_path <- file.path("/mnt/outputs", basename(name(zip_path, target_path)
    file.rename(zip_path, target_path)
}
output_result_folder("hsm_data.zip", "data");
output_result_folder("hsm_results.zip", "results");
