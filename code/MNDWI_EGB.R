

## תוריד את החבילות האלה אם אין לך אותם 
pkg_list <- c("terra", "sf", "CDSE", "here")

invisible(lapply(pkg_list, library, character.only = TRUE))


# 🔹 Read the config as key-value pairs
work_dir <- here::here('parameters.yaml')
params <- yaml::read_yaml(work_dir)

aoi_path <- here::here(params$aoi_file)
aoi <- sf::read_sf(aoi_path)
aoi <- st_zm(aoi, drop = TRUE)
aoi <- st_transform(aoi, 4326)

# 🔹 Get your token from Copernicus
tok <- CDSE::GetOAuthToken(id = params$clientid, secret = params$secret)

# 🔹 Prepare output directory
Output_dir <- params$output_dir
if (!dir.exists(Output_dir)) dir.create(Output_dir, recursive = TRUE)

# ✅ Confirm setup
message("AOI loaded from: ", aoi_path)
message("Output directory: ", Output_dir)


collection <- "sentinel-2-l2a"

image_list <- CDSE::SearchCatalog(aoi = aoi,
                                  from = params$from_date,
                                  to = params$to_date,
                                  token = tok,
                                  collection = collection)
# How many images are available -------------------------
message("Number of available images: ", nrow(image_list))

# Filter out high cloud cover
max_cloud <- 5
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
    script = "MNDWI_masked.js",
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
message("✅ Downloaded ", length(raster_list), " images.")


time_range = '2024-02-14'
                                  ## אם הכל רץ לך טוב אז זה השלב הבא, עוד לא סיימתי איתו 
result_rast <- CDSE::GetImage(aoi = aoi,  
                              # your AOI, as sf object
                              time_range = time_range,
                              script = "MNDWI_masked.js",
                              collection = "sentinel-2-l2a",
                              format = "image/tiff",
                              mask = TRUE,
                              resolution = 10,
                              token = tok)  
# Your access token for dataspace.copernicus.eu
raster_file <- file.path(Output_dir, paste0("time_range_", time_range, ".tiff"))
terra::writeRaster(result_rast, raster_file, overwrite = TRUE)
# raster_file is name of new raster in your output directory

r <- terra::rast(raster_file)
plot(r, main = "time_range.tiff")

#### not relevant-------------###
val_script <- file.path(work_dir, "RGB.js")

# Make sure output directory exists (do this ONCE, not in the loop)
if (!dir.exists(Output_dir/folder)) {
  dir.create(Output_dir/folder, recursive = TRUE)
}

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
      script = eval_script,
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
message("✅ Done! Downloaded ", length(raster_list), " image(s).")
