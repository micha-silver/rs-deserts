# Install and load packages-------------------------------------------

# Description: Download and install R packages, setup  work environment
# Input: 
# Returns:
# Requires:
# Written By:

# Install/Load packages------------------------------------
remotes::install_github("ropensci/rOPTRAM")
pkg_list <- c("terra", "rOPTRAM", "CDSE")
invisible(lapply(pkg_list, library))

# Read individual user parameters
params <- read.csv("parameters.csv")

# Setup directories----------------------------------------
