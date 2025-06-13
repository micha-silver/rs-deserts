library(terra)
library(stars)
library(ggplot2)
library(viridis)
library(ggspatial)

# Define file paths
r1_path <- "Output/pre-flood date of your choice.tif"
r2_path <- "Output/post-flood date of your choice.tif"

# Read rasters
r1 <- rast(r1_path)
r2 <- rast(r2_path)

# Calculate difference
diff_r <- r2 - r1

# Save difference raster
diff_path <- "Output/soil_moisture_post-date_minus_pre-date.tif"
writeRaster(diff_r, diff_path, overwrite=TRUE)

# Convert to stars object
diff_stars <- read_stars(diff_path)

# Set CRS if missing
if (is.na(st_crs(diff_stars))) {
  st_crs(diff_stars) <- 4326
}

# Plot
plot_path <- "Output/OPTRAM/soil_moisture_diff_plot1.png"
png(plot_path, width = 1000, height = 800)
print(
  ggplot() +
    geom_stars(data = diff_stars) +
    scale_fill_gradient2(name = "Δ Soil Moisture", low = "red", mid = "white", high = "blue",
                         midpoint = 0, limits = c(-1, 1), oob = scales::squish) +
    labs(title = "Difference in Soil Moisture (23 Feb - 03 Feb 2025)") +
    annotation_scale(location = "bl", width_hint = 0.5) +
    annotation_north_arrow(location = "tr", which_north = "true", style = north_arrow_fancy_orienteering) +
    theme_minimal() +
    theme(panel.grid = element_blank())
)
dev.off()

message("✅ Done: difference raster and plot saved.")




