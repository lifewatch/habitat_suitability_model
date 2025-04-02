#' Plot Spatial Distribution of Presence Data
#'
#' This function creates a spatial plot of presence data points over a given study area, with the option to facet by a temporal scale (e.g., monthly or decadal).
#'
#' @param study_area A spatial object (Simple Features) representing the study area boundaries.
#' @param presence_data A data frame containing cleaned presence data with `longitude` and `latitude` columns.
#' @param timescale A string specifying the temporal scale for faceting (e.g., "month", "decade"). Default is "monthly".
#' @return A ggplot object visualizing the spatial distribution of presence data.
#' @details The function overlays the presence data points on the study area map, faceting the plot by the specified temporal scale. It applies minimal themes and adjusts axis labels and title styles for clarity.
#' @examples
#' # Example usage:
#' plot_spatial(study_area, presence_data = cleaned_data, timescale = "decade")
#'
#' @export
plot_spatial <- function(study_area, presence_data, timescale) {
  p1 <- ggplot(data = study_area) +
    geom_sf() +
    theme_minimal() +
    geom_point(data = presence_data, aes(x = longitude, y = latitude), colour = "black", size = 0.01, show.legend = FALSE) +
    theme(
      plot.title = element_text(size = 14),
      axis.title = element_text(size = 12),
      text = element_text(size = 12)
    ) +
    labs(title = paste("spatial coverage AphiaID",aphiaid)) +
    coord_sf(xlim = c(bbox[1], bbox[3]), ylim = c(bbox[2], bbox[4]), expand = FALSE) +
    facet_wrap(as.formula(paste("~", timescale))) +
    theme_void() +
    theme(
      strip.background = element_blank(), # Remove background
      strip.text = element_text(size = 12)
    )
  return(p1)
}