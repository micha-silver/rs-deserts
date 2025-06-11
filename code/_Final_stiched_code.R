# Remote Sensing of Deserts and Desertification Process
# BGU 2025

# Install and load packages-------------------------------------------
# Description: Download and install R packages, setup work environment
# Input: None
# Returns: Loaded libraries, working directory and yaml files.
# Requires: parameters.yml file with user-defined paths
# Written By: Nir, Ziv

# List of required packages, check and install missing
pkg_list <- c("terra", "rOPTRAM", "CDSE", "yaml", "here", "sf", "sfc", "stars", 'patchwork', 'stringr', "ggplot2", "ggspatial", "viridis")
new.packages <- pkg_list[!(pkg_list %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

## Install 'rOPTRAM' from GitHub if not already installed
if (!requireNamespace("rOPTRAM", quietly = TRUE)) {
  remotes::install_github("ropensci/rOPTRAM")
}
# Load packages
invisible(lapply(pkg_list, library, character.only = TRUE))


# Setup directories
work_dir <- getwd()
Output_dir <- file.path(work_dir, "Output")

# Read individual user parameters (assumes YAML format)
params <- read_yaml("parameters.yaml")

cloud_cover = params$cloud_cover

aoi_path <- here::here(params$aoi_file)
aoi <- sf::read_sf(aoi_path)
aoi <- st_zm(aoi, drop = TRUE)
aoi <- st_transform(aoi, 4326)

# Create output directory if it doesn't exist
if (!dir.exists(Output_dir)) {
  dir.create(Output_dir, recursive = TRUE)
}


# Optional: print confirmation
message("Setup complete. Working directory: ", work_dir)



# Calculate MNDWI----------------------------------------------------
# Description: Prepare water surface raster
# Input: 
# Returns:
# Requires:
# Written By: Eran Tsur, Bar Rudman and Guy Israeli


# # Read the config as key-value pairs
# work_dir <- here::here('parameters.yaml')
# params <- yaml::read_yaml(work_dir)


# Get your token from Copernicus
tok <- CDSE::GetOAuthToken(id = params$clientid, secret = params$secret)

# Prepare output directory
Output_dir <- params$Output_dir
if (!dir.exists(Output_dir)) dir.create(Output_dir, recursive = TRUE)

# Confirm setup
message("AOI loaded from: ", aoi_path)
message("Output directory: ", Output_dir)


collection <- "sentinel-2-l2a"

image_list <- CDSE::SearchCatalog(aoi = aoi,
                                  from = params$from_date,
                                  to = params$to_date,
                                  token = tok,
                                  collection = collection)
## How many images are available -------------------------
message("Number of available images: ", nrow(image_list))

# Filter out high cloud cover
max_cloud <- cloud_cover
image_list <- image_list[image_list$tileCloudCover < max_cloud,]
# How many images are left
message("Number of images after filtering for clouds: ", nrow(image_list))

# Loop over each filtered image date
raster_list <- lapply(1:nrow(image_list), function(i) {
  date <- as.character(image_list$acquisitionDate[i])
  message("Downloading image for: ", date)
  
  # Get the image
  result_rast <- CDSE::GetImage(
    aoi = aoi,
    time_range = date,
    script = "code/MNDWI_masked_EGB.js",
    collection = collection,
    format = "image/tiff",
    mask = TRUE,
    resolution = 10,
    token = tok
  )
  
  # Define output filename
  raster_file <- file.path(Output_dir, paste0("time_range_", date, ".tiff"))
  
  # Save it
  terra::writeRaster(result_rast, raster_file, overwrite = TRUE)
  message("Saved: ", raster_file)
  
})

# Done!
message("Downloaded ", length(raster_list), " images.")



# Download each image and save it as a raster
raster_list <- lapply(1:nrow(image_list), function(x) {
  img_date <- as.character(image_list$acquisitionDate[x])
  raster_file <- file.path(Output_dir, paste0("RGB_", img_date, ".tif"))
  
  if (!file.exists(raster_file)) {
    message("Downloading image for: ", img_date)
    
    r <- CDSE::GetImage(
      aoi = aoi,
      time_range = img_date,
      collection = collection,
      script = "code/RGB.js",
      resolution = 10,
      format = "image/tiff",
      token = tok
    )
    
    terra::writeRaster(r, raster_file, overwrite = TRUE)
    message("Saved: ", raster_file)
  } else {
    message("Already exists, skipping: ", raster_file)
  }
  
  return(raster_file)
})

# After the loop
message("Done! Downloaded ", length(raster_list), " image(s).")


# Run OPTRAM---------------------------------------------------------
# Description: Use rOPTRAM package to prepare soil moisture rasters
# Input: Parameter.yaml file contains all necessary information
# Returns:
# Requires: rOPTRAM, CDSE, yaml, sf
# Written By: Hagar Boneh, Noa Cohen and Gill Tsemach

## loading packages
library(sf)
library(sfc)
library(CDSE)
library(yaml)
library(rOPTRAM)


Prepare_OPTRAM_Model <- function() {
  
  t0 <- Sys.time() # measure run time
  message(t0, " - OPTRAM Initialize")
  
  work_dir = getwd()
  
  ## read parameters
  # params <- read_yaml(file.path(work_dir, "parameters.yaml"))
  # aoi <- sf::read_sf(file.path(work_dir, params$aoi_file))
  
  from <- params$from_date
  to <- params$to_date
  # Output_dir <- params$Output_dir
  
  ## for storing files temporarily to not bloat the storage
  dir.create(file.path(tempdir(), "OPTRAM")) # separate from rest temp files
  tmp <- file.path(tempdir(), "OPTRAM") 
  
  ## use tryCatch as temporary solution for using "save_creds = TRUE"
  #  for saving client ID and secret
  tryCatch({
    acquire_scihub(save_creds = TRUE, clientid = params$clientid, secret = params$secret)
  }, error = function(e) {
    message(e,"\n")
  }, finally = {
    
    ## insert MNDWI mask?
    # aoi_masked <- <mask out water surfaces>
    # aoi_masked <- aoi[mask_MNDWI]
    
    ## or just remove high values?
    # optram_options("rm.hi.str", TRUE, FALSE) ## STR, affects only the model
    # # optram_options("rm.low.vi", TRUE, FALSE) ## VI, affects only the model
    
    ## for masking each raster, less suitable?
    # mask(<ras>, <mask>, maskvalues=TRUE) ## terra library
    
    ## create dir for the soil moisture product
    if (!dir.exists(file.path(Output_dir, "OPTRAM"))) {
      dir.create(file.path(Output_dir, "OPTRAM"))
      message('Creating "OPTRAM" directory in output directory...')
    }
    if (!dir.exists(file.path(Output_dir, "OPTRAM/data"))) {dir.create(file.path(Output_dir, "OPTRAM/data"))} # for data
    
    ## save as variables
    optram_dir <- file.path(Output_dir, "OPTRAM")
    data_dir <- file.path(Output_dir, "OPTRAM/data")
    
    message("Downloading...\n")
    
    ## scm_mask and run optram
    optram_options("scm_mask", TRUE, show_opts = FALSE) ## just to make sure
    optram_options("max_cloud", cloud_cover, show_opts = FALSE) ## just to make sure
    optram_options("rm.hi.str", FALSE, show_opts = FALSE) ## removing high STR values
    optram(aoi, from, to, tmp, data_dir) ## run optram wrapper function
    
    message(Sys.time(), " - Creating soil moisture rasters...\n")
    
    
    ## get dates with available data
    l <- list.files(file.path(tmp,"STR"), pattern = "STR") # list of tiles file names
    dates <- substr(l, 5, 14) # get the date part from the string
    dates <- unique(dates) ## remove duplicate dates
    
    ## calculate the soil moisture with acquired data
    Create_rasters <- function(d) {
      optram_calculate_soil_moisture(d, VI_dir = file.path(tmp,"NDVI"), 
                                     STR_dir = file.path(tmp,"STR"), 
                                     data_dir = data_dir, 
                                     output_dir = optram_dir)
    }
    lapply(dates, Create_rasters) # create for each unique date
    
    
    ## finish
    t1 <- Sys.time() 
    message("\n", t1, " - OPTRAM complete") 
    message("Runtime: ", round(difftime(t1,t0, units = "mins"), 2), " mins\n") ## print runtime duration in seconds
  })
  
}

## run function
Prepare_OPTRAM_Model()

# Prepare map plot --------------------------------------------------
# Description: Plot a raster layer using stars and ggplot2, with cartographic elements
# Input: raster_file (character) – path to a raster file (e.g., GeoTIFF)
# Returns: A ggplot map (also displayed)
# Requires: stars, ggplot2, ggspatial, viridis
# Written By: Nir, Shay, May

Plot_combined <- function(rgb_file, mndwi_file, sm_file) {
  # Load rasters
  rgb_rast <- read_stars(rgb_file)
  mndwi_rast <- read_stars(mndwi_file)
  sm_rast <- read_stars(sm_file)
  
  # Extract date and tile
  date_string <- stringr::str_extract(basename(sm_file), "\\d{4}-\\d{2}-\\d{2}")
  tile_id <- stringr::str_extract(basename(sm_file), "T[0-9A-Z]{5}")
  
  # Create folder for this date
  plot_dir <- file.path(Output_dir, "Plots", date_string)
  if (!dir.exists(plot_dir)) dir.create(plot_dir, recursive = TRUE)
  
  # RGB plot
  rgb_plot <- ggplot() +
    geom_stars(data = rgb_rast) +
    labs(title = paste("RGB -", date_string, "-", tile_id)) +
    annotation_scale(location = "bl", width_hint = 0.5) +
    annotation_north_arrow(location = "tr", which_north = "true", style = north_arrow_fancy_orienteering) +
    theme_minimal()
  ggsave(filename = file.path(plot_dir, paste0("RGB_", tile_id, ".png")),
         plot = rgb_plot, width = 6, height = 6)
  
  # MNDWI plot
  mndwi_plot <- ggplot() +
    geom_stars(data = mndwi_rast) +
    scale_fill_gradient2(name = "MNDWI", low = "saddlebrown", mid = "beige", high = "blue",
                         midpoint = 0, limits = c(-1, 1), oob = scales::squish) +
    labs(title = paste("MNDWI -", date_string, "-", tile_id)) +
    annotation_scale(location = "bl", width_hint = 0.5) +
    annotation_north_arrow(location = "tr", which_north = "true", style = north_arrow_fancy_orienteering) +
    theme_minimal()
  ggsave(filename = file.path(plot_dir, paste0("MNDWI_", tile_id, ".png")),
         plot = mndwi_plot, width = 6, height = 6)
  
  # Soil Moisture plot
  sm_plot <- ggplot() +
    geom_stars(data = sm_rast) +
    scale_fill_gradientn(name = "Soil Moisture",
                         colours = c("#00FF00", "#66CC99", "#3399CC", "#0033CC", "#000066"),
                         limits = c(0, 1), oob = scales::squish,
                         breaks = c(0, 1), labels = c("0", "1")) +
    labs(title = paste("Soil Moisture -", date_string, "-", tile_id)) +
    annotation_scale(location = "bl", width_hint = 0.5) +
    annotation_north_arrow(location = "tr", which_north = "true", style = north_arrow_fancy_orienteering) +
    theme_minimal()
  ggsave(filename = file.path(plot_dir, paste0("SoilMoisture_", tile_id, ".png")),
         plot = sm_plot, width = 6, height = 6)
  
  message("Saved RGB, MNDWI, and Soil Moisture plots to: ", plot_dir)
}
# Match files and generate combined plots ----------------------------
rgb_files <- list.files(Output_dir, pattern = "^RGB_\\d{4}-\\d{2}-\\d{2}\\.tif$", full.names = TRUE)
mndwi_files <- list.files(Output_dir, pattern = "^time_range_\\d{4}-\\d{2}-\\d{2}\\.tiff$", full.names = TRUE)
soil_files <- list.files(file.path(Output_dir, "OPTRAM"), pattern = "^soil_moisture_\\d{4}-\\d{2}-\\d{2}_T.*\\.tif$", full.names = TRUE)

# Extract all available dates from filenames
all_dates <- unique(stringr::str_extract(
  c(basename(rgb_files), basename(mndwi_files), basename(soil_files)),
  "\\d{4}-\\d{2}-\\d{2}"
))
all_dates <- all_dates[!is.na(all_dates)]  # remove NAs if any

# Loop over each date and plot only if all 3 file types exist
for (date_part in all_dates) {
  rgb_match <- grep(paste0("RGB_", date_part), rgb_files, value = TRUE)
  mndwi_match <- grep(paste0("time_range_", date_part), mndwi_files, value = TRUE)
  sm_matches <- grep(paste0("soil_moisture_", date_part), soil_files, value = TRUE)
  
  if (length(rgb_match) > 0 && length(mndwi_match) > 0 && length(sm_matches) > 0) {
    for (sm_file in sm_matches) {
      Plot_combined(rgb_match[1], mndwi_match[1], sm_file)
    }
  } else {
    missing <- c()
    if (length(rgb_match) == 0) missing <- c(missing, "RGB")
    if (length(mndwi_match) == 0) missing <- c(missing, "MNDWI")
    if (length(sm_matches) == 0) missing <- c(missing, "Soil Moisture")
    message("Skipping date ", date_part, " — missing: ", paste(missing, collapse = ", "))
  }
}

