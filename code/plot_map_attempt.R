# Prepare map plot --------------------------------------------------
# Description: Plot a raster layer using stars and ggplot2, with cartographic elements
# Input: raster_file (character) – path to a raster file (e.g., GeoTIFF)
# Returns: A ggplot map (also displayed)
# Requires: stars, ggplot2, ggspatial, viridis
# Written By: Nir, Shay, May

Plot_raster <- function(raster_file, title = "Raster Map", legend_title = "Value") {
  # Load required packages
  library(stars)
  library(ggplot2)
  library(ggspatial)
  library(viridis)  # for color scale
  
  # Start timing
  t0 <- Sys.time()
  
  # Read the raster file
  rast <- read_stars(raster_file)
  
  # Generate plot
  p <- ggplot() +
    geom_stars(data = rast) +
    scale_fill_viridis_c(name = legend_title) +
    labs(title = title) +
    annotation_scale(location = "bl", width_hint = 0.5) +
    annotation_north_arrow(location = "tr", which_north = "true", 
                           style = north_arrow_fancy_orienteering) +
    theme_minimal()
  
  # Print the plot
  print(p)
  
  # Log message
  message(t0, " | Plot of ", raster_file, " complete.")
}


## How to use: 
# Plot_raster("-raster path here-", title = "-insert title here-", legend_title = "-insert relevant legend name here-")
