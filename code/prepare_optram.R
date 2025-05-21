# Run OPTRAM---------------------------------------------------------
# Description: Use rOPTRAM package to prepare soil moisture rasters
# Input: Parameter.yaml file contains all necessary information
# Returns:
# Requires: eOPTRAM, CDSE, yaml, sf
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
?optram_safe

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

## this is to set client ID and secret
acquire_scihub(save_creds = TRUE, clientid = params$clientid, secret = params$secret)
  
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


  optram(aoi, from, to, Output_dir, Output_dir)
  t1 <- Sys.time() 
  message(t1, "OPTRAM complete") 
  message("Runtime: ", round(t1-t0), " seconds") ## print runtime duration in seconds
}
