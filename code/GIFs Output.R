# === Load library ===
library(magick)

# === Set the root directory containing subfolders ===
root_dir <- "rs-deserts\\Output\\Plots"  # change to your actual path

# === Recursively list all UFS PNG files ===
all_ufs_files <- list.files(path = root_dir, pattern = "UFS\\.png$", 
                            full.names = TRUE, recursive = TRUE)

# === Filter by type (adjust keywords if needed) ===
ndwi_files   <- grep("NDWI|MNDWI", all_ufs_files, value = TRUE)
rgb_files    <- grep("RGB", all_ufs_files, value = TRUE)
optram_files <- grep("SoilMoisture|OPTRAM", all_ufs_files, value = TRUE)

# === Sort files to maintain chronological order ===
ndwi_files <- sort(ndwi_files)
rgb_files  <- sort(rgb_files)
optram_files <- sort(optram_files)

# === Function to create GIF ===
create_gif <- function(image_paths, output_name, delay = 100) {
  if (length(image_paths) == 0) {
    message(paste("No images found for", output_name))
    return(NULL)
  }
  imgs <- image_read(image_paths)
  gif <- image_animate(image_join(imgs), delay = delay)
  image_write(gif, path = file.path(root_dir, output_name))
  message(paste("GIF created:", output_name))
}

# === Create GIFs ===
create_gif(ndwi_files,   "NDWI.gif")
create_gif(rgb_files,    "RGB.gif")
create_gif(optram_files, "OPTRAM.gif")
