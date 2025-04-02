#' Filter or Flag Datasets Based on Keywords
#'
#' This function filters or flags datasets based on the presence of specific keywords in the dataset columns.
#'
#' @param dataset A data frame containing the dataset to be filtered or flagged.
#' @param method A string specifying the operation to perform: "filter" to remove rows containing keywords, 
#'        or "flag" to retain only rows containing keywords. Default is "filter".
#' @param filter_words A string or list of strings specifying the words used to filter out certain datasets.
#' @details The function searches for specified keywords (stored in `filter_words`) across all columns except 
#'          the `description` column. Rows that match any keyword are either discarded or retained, depending 
#'          on the `method` argument.
#' @examples
#' # Filter out rows with specific keywords
#' cleaned_dataset <- filter_dataset(my_dataset, method = "filter", filter_words = c("stranding", "museum"))
#'
#' # Flag rows with specific keywords
#' flagged_dataset <- filter_dataset(my_dataset, method = "flag", filter_words = c("stranding", "museum"))
#'
#' @export
filter_dataset <- function(dataset,method="filter",filter_words){
  dataset <- dataset %>%
    rowwise() %>%
    mutate("discard"=any(across(-description, # because in the description of SCANS, the word stranding is also mentioned, wrongly discarding this dataset
                                ~grepl(paste(filter_words, collapse = "|"),
                                       .,ignore.case=TRUE))))
  if(method == "filter"){
    dataset_selection <- filter(dataset,discard==FALSE)
  }
  else if(method == "flag"){
    dataset_selection <- filter(dataset,discard==TRUE)
  }
  return(dataset_selection)
}