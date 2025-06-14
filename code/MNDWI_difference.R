
library(terra)
library(ggplot2)
library(stars)
library(viridis)

# Paths to the input MNDWI rasters (change as needed)
r1_path <- "C:\\Users\\gura1\\rs-deserts\\Output\\time_range_2021-06-01.tiff"
r2_path <- "C:\\Users\\gura1\\rs-deserts\\Output\\time_range_2021-10-09.tiff"

# Load rasters
r1 <- rast(r1_path)
r2 <- rast(r2_path)

# Calculate difference
diff_r <- r2 - r1

# Save the difference raster
writeRaster(diff_r, "Output/mndwi_diff.tif", overwrite = TRUE)

# Convert to stars for plotting
diff_stars <- st_as_stars(diff_r)
diff_stars <- st_set_crs(diff_stars, 4326)

# Plot the difference with ggplot2
p <- ggplot() +
  geom_stars(data = diff_stars) +
  scale_fill_gradient2(low = "red", mid = "white", high = "blue",
                       midpoint = 0, limits = c(-1, 1), name = "MNDWI Diff") +
  labs(title = "MNDWI Difference (2025-02-23 - 2025-02-03)") +
  theme_minimal()

# Save plot
ggsave("Output/mndwi_diff_plot.png", plot = p, width = 7, height = 6)