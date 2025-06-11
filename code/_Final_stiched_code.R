# Remote Sensing of Deserts and Desertification Process
# BGU 2025

# Install and load packages-------------------------------------------
pkg_list <- c("terra", "rOPTRAM", "CDSE", "yaml", "here", "sf", "sfc", "stars", "ggplot2", "ggspatial", "viridis")
new.packages <- pkg_list[!(pkg_list %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

if (!requireNamespace("rOPTRAM", quietly = TRUE)) {
  remotes::install_github("ropensci/rOPTRAM")
}
invisible(lapply(pkg_list, library, character.only = TRUE))

# Setup directories
work_dir <- getwd()
Output_dir <- file.path(work_dir, "Output")

params <- read_yaml("parameters.yaml")
cloud_cover = params$cloud_cover

aoi_path <- here::here(params$aoi_file)
aoi <- sf::read_sf(aoi_path)
aoi <- st_zm(aoi, drop = TRUE)
aoi <- st_transform(aoi, 4326)

if (!dir.exists(Output_dir)) {
  dir.create(Output_dir, recursive = TRUE)
}

message("Setup complete. Working directory: ", work_dir)

# Calculate MNDWI----------------------------------------------------
tok <- CDSE::GetOAuthToken(id = params$clientid, secret = params$secret)

Output_dir <- params$Output_dir
if (!dir.exists(Output_dir)) dir.create(Output_dir, recursive = TRUE)

message("AOI loaded from: ", aoi_path)
message("Output directory: ", Output_dir)

collection <- "sentinel-2-l2a"

image_list <- CDSE::SearchCatalog(aoi = aoi,
                                  from = params$from_date,
                                  to = params$to_date,
                                  token = tok,
                                  collection = collection)

message("Number of available images: ", nrow(image_list))

max_cloud <- cloud_cover
image_list <- image_list[image_list$tileCloudCover < max_cloud,]
message("Number of images after filtering for clouds: ", nrow(image_list))

raster_list <- lapply(1:nrow(image_list), function(i) {
  date <- as.character(image_list$acquisitionDate[i])
  message("Downloading image for: ", date)
  
  result_rast <- CDSE::GetImage(
    aoi = aoi,
    time_range = date,
    script = "MNDWI_masked_EGB.js",
    collection = collection,
    format = "image/tiff",
    mask = TRUE,
    resolution = 10,
    token = tok
  )
  
  raster_file <- file.path(Output_dir, paste0("time_range_", date, ".tiff"))
  terra::writeRaster(result_rast, raster_file, overwrite = TRUE)
  message("Saved: ", raster_file)
})

message("Downloaded ", length(raster_list), " images.")

# Run OPTRAM---------------------------------------------------------
Prepare_OPTRAM_Model <- function() {
  t0 <- Sys.time()
  message(t0, " - OPTRAM Initialize")
  
  from <- params$from_date
  to <- params$to_date
  
  dir.create(file.path(tempdir(), "OPTRAM"))
  tmp <- file.path(tempdir(), "OPTRAM")
  
  tryCatch({
    acquire_scihub(save_creds = TRUE, clientid = params$clientid, secret = params$secret)
  }, error = function(e) {
    message(e, "\n")
  }, finally = {
    
    if (!dir.exists(file.path(Output_dir, "OPTRAM"))) {
      dir.create(file.path(Output_dir, "OPTRAM"))
      message('Creating "OPTRAM" directory in output directory...')
    }
    if (!dir.exists(file.path(Output_dir, "OPTRAM/data"))) {
      dir.create(file.path(Output_dir, "OPTRAM/data"))
    }
    
    optram_dir <- file.path(Output_dir, "OPTRAM")
    data_dir <- file.path(Output_dir, "OPTRAM/data")
    
    message("Downloading...\n")
    optram_options("scm_mask", TRUE, show_opts = FALSE)
    optram_options("max_cloud", cloud_cover, show_opts = FALSE)
    optram_options("rm.hi.str", FALSE, show_opts = FALSE)
    optram(aoi, from, to, tmp, data_dir)
    
    message(Sys.time(), " - Creating soil moisture rasters...\n")
    
    l <- list.files(file.path(tmp,"STR"), pattern = "STR")
    dates <- substr(l, 5, 14)
    dates <- unique(dates)
    
    Create_rasters <- function(d) {
      optram_calculate_soil_moisture(d, VI_dir = file.path(tmp,"NDVI"), 
                                     STR_dir = file.path(tmp,"STR"), 
                                     data_dir = data_dir, 
                                     output_dir = optram_dir)
    }
    lapply(dates, Create_rasters)
    
    t1 <- Sys.time()
    message("\n", t1, " - OPTRAM complete")
    message("Runtime: ", round(difftime(t1,t0, units = "mins"), 2), " mins\n")
  })
}

Prepare_OPTRAM_Model()

# Prepare map plot --------------------------------------------------
Plot_raster <- function(raster_file, title = "Raster Map", legend_title = "Soil Moisture (0-1)") {
  t0 <- Sys.time()
  rast <- read_stars(raster_file)
  
  base <- tools::file_path_sans_ext(basename(raster_file))
  date_match <- regmatches(base, regexpr("\\d{4}-\\d{2}-\\d{2}", base))
  date_string <- if (length(date_match) > 0) date_match else ""
  plot_title <- paste("Soil Moisture -", date_string)
  
  p <- ggplot() +
    geom_stars(data = rast) +
    scale_fill_gradientn(
      name = legend_title,
      colours = c("#00FF00", "#66CC99", "#3399CC", "#0033CC", "#000066"),
      limits = c(0, 1),
      oob = scales::squish,
      breaks = c(0, 1),
      labels = c("0", "1")
    ) +
    labs(title = plot_title) +
    annotation_scale(location = "bl", width_hint = 0.5) +
    annotation_north_arrow(location = "tr", which_north = "true",
                           style = north_arrow_fancy_orienteering) +
    theme_minimal()
  
  print(p)
  
  out_file <- file.path(Output_dir, paste0(base, "_soilmoisture_plot.png"))
  ggsave(out_file, plot = p, width = 8, height = 6)
  message("Plot saved to: ", out_file)
  message(t0, " | Plot of ", raster_file, " complete.")
}

raster_files <- list.files(file.path(Output_dir, "OPTRAM"), pattern = "\\.tif$", full.names = TRUE)
for (f in raster_files) {
  Plot_raster(f)
}

