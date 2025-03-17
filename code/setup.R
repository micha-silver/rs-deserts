# Install and load packages-------------------------------------------

# Description: Download and install R packages, setup  work environment
# Input: 
# Returns:
# Requires:
# Written By:

# Install/Load packages------------------------------------
remotes::install_github("ropensci/rOPTRAM")
pkg_list <- c("terra", "rOPTRAM", "CDSE", "yaml")
invisible(lapply(pkg_list, library, character.only = TRUE))

# Read individual user parameters
params <- read_yaml("parameters.yml")

# Setup directories----------------------------------------
