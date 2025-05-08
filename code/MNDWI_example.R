#-- Sample code to download mNDWI --
# Can be run in a loop over a list of image dates ("time_range" parameter)
# Obtain a list of available images with the function:
# CDSE::SearchCatalog()
# Each item in the list includes:
# image date, cloud cover, full name, Sentinel tile, acquisition time

result_rast <- CDSE::GetImage(aoi = aoi,  
                              # your AOI, as sf object
                              time_range = time_range,
                              script = "MNDWI_masked.js",
                              collection = "sentinel-2-l2a",
                              format = "image/tiff",
                              mask = TRUE,
                              resolution = getOption("optram.resolution"), 
                              # your desired output resolution
                              token = tok)  
                              # Your access token for dataspace.copernicus.eu
terra::writeRaster(result_rast, raster_file, overwrite = TRUE)
# raster_file is name of new raster in your output directory