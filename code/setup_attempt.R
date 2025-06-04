# Install and load packages-------------------------------------------
# Description: Download and install R packages, setup work environment
# Input: None
# Returns: Loaded libraries, working directory and yaml files.
# Requires: parameters.yml file with user-defined paths
# Written By: Nir, Ziv

# List of required packages
pkg_list <- c("terra", "rOPTRAM", "CDSE", "yaml", "here", "sf", "here", "stars", "ggplot2", "ggspatial", "viridis")

# Load packages
invisible(lapply(pkg_list, library, character.only = TRUE))

# Install 'rOPTRAM' from GitHub if not already installed
if (!requireNamespace("rOPTRAM", quietly = TRUE)) {
  remotes::install_github("ropensci/rOPTRAM")
}

# Setup directories
work_dir <- getwd()
output_dir <- file.path(work_dir, "Output")

# Read individual user parameters (assumes YAML format)
params <- read_yaml("parameters.yaml")


# Create output directory if it doesn't exist
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Optional: print confirmation
message("Setup complete. Working directory: ", work_dir)

