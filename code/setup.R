# Install packages-------------------------------------------
remotes::install_github("ropensci/rOPTRAM")

# Load packages----------------------------------------------
pkg_list <- c("terra", "rOPTRAM", "CDSE")
invisible(lapply(pkg_list, library))

# Setup directories------------------------------------------