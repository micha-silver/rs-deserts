# Run OPTRAM---------------------------------------------------------
# Description: Use rOPTRAM package to prepare soil moisture rasters
# Input: 
# Returns:
# Requires:
# Written By: Hagar Boneh, Noa Cohen and Gill Tsemach

## loading packages
library(terra)
library(sf)
library(sfc)
library(CDSE)
library(yaml)
library(rOPTRAM)

# optram_options()
# checked that scm_mask is set to TRUE



work_dir = getwd()
params <- read_yaml(file.path(work_dir, "parameters.yml"))
acquire_scihub(save_creds = TRUE, clientid = params$clientid, 
               secret = params$secret)

optram_options()

getwd()
work_dir = getwd()

## read parameters
params <- read_yaml(file.path(work_dir, "parameters.yml"))

aoi <- sf::read_sf(file.path(work_dir, params$aoi_file))
from = params$from_date
to = params$to_date
Output_dir <- params$Output_dir


optram(aoi, from, to, Output_dir, Output_dir)
print("OPTRAM done")


# Prepare_OPTRAM_Model <- function() {
#   
#   getwd()
#   work_dir = getwd()
#   
#   ## read parameters
#   params <- read_yaml(file.path(work_dir, "parameters.yml"))
#   aoi <- sf::read_sf(file.path(work_dir, params$aoi_file))
#   
#   from = params$from_date
#   to = params$to_date
#   Output_dir <- params$Output_dir
#   
# 
#   optram(aoi, from, to, Output_dir, Output_dir)
#   t0 <- Sys.time()
#   message(t0, "OPTRAM complete")
# }
