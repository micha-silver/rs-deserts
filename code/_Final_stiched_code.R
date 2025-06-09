# Remote Sensing of Deserts and Desertification Process
# BGU 2025

# Install and load packages-------------------------------------------
# Description: Download and install R packages, setup work environment
# Input: None
# Returns: Loaded libraries, working directory and yaml files.
# Requires: parameters.yml file with user-defined paths
# Written By: Nir, Ziv

# List of required packages, check and install missing
pkg_list <- c("terra", "rOPTRAM", "CDSE", "yaml", "here", "sf", "sfc", "stars", "ggplot2", "ggspatial", "viridis")
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
    script = "MNDWI_masked_EGB.js",
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


# time_range = '2024-02-14'
# ## אם הכל רץ לך טוב אז זה השלב הבא, עוד לא סיימתי איתו 
# result_rast <- CDSE::GetImage(aoi = aoi,  
#                               # your AOI, as sf object
#                               time_range = time_range,
#                               script = "MNDWI_masked.js",
#                               collection = "sentinel-2-l2a",
#                               format = "image/tiff",
#                               mask = TRUE,
#                               resolution = 10,
#                               token = tok)  
# # Your access token for dataspace.copernicus.eu
# raster_file <- file.path(Output_dir, paste0("time_range_", time_range, ".tiff"))
# terra::writeRaster(result_rast, raster_file, overwrite = TRUE)
# # raster_file is name of new raster in your output directory
# 
# r <- terra::rast(raster_file)
# plot(r, main = "time_range.tiff")
# 
# #### not relevant-------------###
# val_script <- file.path(work_dir, "RGB.js")
# 
# # Make sure output directory exists (do this ONCE, not in the loop)
# if (!dir.exists(Output_dir/folder)) {
#   dir.create(Output_dir/folder, recursive = TRUE)
# }

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
      script = "MNDWI_masked_EGB.js",
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
# library(sf)
# library(sfc)
# library(CDSE)
# library(yaml)
# library(rOPTRAM)

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

Plot_raster <- function(raster_file, title = "Raster Map", legend_title = "Value") {
  # Load required packages
  
  
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
raster_files <- list.files("Output/OPTRAM", pattern = "\\.tif$", full.names = TRUE)

# Loop through and plot
for (f in raster_files) {
  Plot_raster(f, title = basename(f), legend_title = "Soil Moisture")
}



