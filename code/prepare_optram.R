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

# optram_options()
# checked that scm_mask is set to TRUE

##------------------------- Test section --------------------------
# ?optram_safe

# optram_options()
# optram_options("overwrite", TRUE, FALSE)
# optram_options("plot_colors", TRUE, FALSE)



# getwd()
# work_dir = getwd()
# 
# ## read parameters
# params <- read_yaml(file.path(work_dir, "parameters.yml"))
# 
# ## this is to set client ID and secret
# # acquire_scihub(save_creds = TRUE, clientid = params$clientid, secret = params$secret)
# 
# aoi <- sf::read_sf(file.path(work_dir, params$aoi_file))
# from = params$from_date
# to = params$to_date
# Output_dir <- params$Output_dir
# 
# 
# optram(aoi, from, to, Output_dir, Output_dir)
# print("OPTRAM done")
# 
# readRDS("Output/VI_STR_data.rds")




## ------------------------ Code section -------------------------


  
Prepare_OPTRAM_Model <- function() {

  t0 <- Sys.time() # measure run time
  message(t0, "OPTRAM Initialize")
  
  work_dir = getwd()
  

  ## read parameters
  params <- read_yaml(file.path(work_dir, "parameters.yml"))
  aoi <- sf::read_sf(file.path(work_dir, params$aoi_file))

  from <- params$from_date
  to <- params$to_date
  Output_dir <- params$Output_dir
  
  ## use tryCatch as temporal solution for using "save_creds = TRUE"
  #  for saving client ID and secret
  tryCatch({
    acquire_scihub(save_creds = TRUE, clientid = params$clientid, secret = params$secret)
  }, error = function(e) {
    message(e,"\n")
  }, finally = {
    message("downloading...")
    
    ## insert MNDWI mask?
    # aoi_masked <- <mask out water surfaces>
    # aoi_masked <- aoi[mask_MNDWI]
    
    ## or just remove high values?
    # optram_options("rm.hi.str", TRUE, FALSE) ## STR, affects only the model
    # # optram_options("rm.low.vi", TRUE, FALSE) ## VI, affects only the model
    
    ## for masking each raster, less suitable?
    # mask(<ras>, <mask>, maskvalues=TRUE) ## terra library
  
  
    ## scm_mask and run optram
    optram_options("scm_mask", TRUE, show_opts = FALSE) ## just to make sure
    optram(aoi, from, to, Output_dir, Output_dir) ## run optram wrapper function
    
    ## finish
    t1 <- Sys.time() 
    message(t1, "OPTRAM complete") 
    message("Runtime: ", round(difftime(t1,t0, units = "mins"), 2), " mins") ## print runtime duration in seconds
  })
  
}

Prepare_OPTRAM_Model()

