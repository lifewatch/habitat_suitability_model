#' Create K-Nearest Neighbor (KNN) Disaggregated Model (KNNDM) Folds
#'
#' This function generates cross-validation folds using the KNNDM approach. It partitions the training data into folds based on the feature space of the environmental predictors, leveraging hierarchical clustering and the KNN disaggregation method.
#'
#' @param train_data A data frame containing training data, including `occurrence_status` and the environmental covariates.
#' @param prediction_layers A `SpatRasterDataset` (SDS) object representing the environmental layers used for prediction.
#' @param n_folds An integer specifying the number of folds for cross-validation. Default is 5.
#' @return A list containing:
#' \itemize{
#'   \item \code{knndm_folds}: The KNNDM object, including the indices of training and testing points for each fold.
#'   \item \code{rsample_folds}: A `rsample` object with manual resampling folds.
#' }
#' @details This function:
#'          1. Calculates the mean feature space of the environmental layers to construct a predictive space.
#'          2. Uses the KNNDM approach to cluster data points in the feature space.
#'          3. Creates `rsample` folds with training and assessment splits for each fold.
#' 
#' The KNNDM approach leverages hierarchical clustering (`ward.D2`) in feature space and Fibonacci sampling to ensure balanced data partitions.
#'
#' @examples
#' # Example usage:
#' prediction_layers <- terra::sds(thetao_avg_m, so_avg_m, npp_avg_m, bathy)
#' names(prediction_layers) <- c("thetao", "so", "npp", "bathy")
#' 
#' monthly_folds <- knndm_fold(
#'   train_data = training_data,
#'   prediction_layers = prediction_layers
#' )
#' @export
#Function to make rsample folds based on KNNDM
knndm_fold <- function(train_data, prediction_layers, n_folds = 5){
  
  # We need an indication of the predictive space
  #For this we calculate the mean of the layers we want to predict on
  feature_space <- c()
  for(variable in names(prediction_layers)){
    feature_space[[variable]] <- terra::mean(prediction_layers[[variable]])
  }
  feature_space <- terra::rast(feature_space)
  
  #Run the knndm_folds approach
  knndm_folds <- CAST::knndm(
    dplyr::select(train_data,-occurrence_status),
    modeldomain = feature_space,
    space = "feature",
    k = n_folds,
    maxp = 0.6,
    clustering = "hierarchical",
    linkf = "ward.D2",
    samplesize = 2000,
    sampling = "Fibonacci",
    useMD = FALSE)
  
  
  #Make rsample folds
  splits_pre <- c()
  for(i in 1:n_folds){
    splits_pre[[i]] <- list(analysis = knndm_folds$indx_train[[i]],
                            assessment = knndm_folds$indx_test[[i]])
  }
  
  splits <- lapply(splits_pre, FUN= make_splits, data = train_data)
  rsample_folds <- manual_rset(splits,paste0("Fold",1:n_folds))
  total_output <- list(knndm_folds = knndm_folds,
                       rsample_folds = rsample_folds)
  return(total_output)
}