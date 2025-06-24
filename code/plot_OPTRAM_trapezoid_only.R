# OPTRAM - trapezoid plot only
# load packages
library(sf)
library(yaml)
library(ggplot2)
library(rOPTRAM)

## set dir paths & variables
params <- read_yaml("parameters.yaml")
Output_dir <- params$Output_dir
data_dir <- file.path(Output_dir, "OPTRAM/data")

full_df <- readRDS(file.path(data_dir, "VI_STR_data.rds")) # read data
edges_df <- read.csv(file.path(data_dir, "trapezoid_edges_lin.csv")) # read data
optram_options("plot_colors", "density", show_opts = FALSE) # graphical represent as density
aoi_name <- tools::file_path_sans_ext(basename(params$aoi_file)) ## extract AOI file name

pl <- plot_vi_str_cloud(full_df = full_df, edges_df = edges_df) + 
  ggplot2::ggtitle(paste("OPTRAM Model for:", aoi_name)) + 
  ggplot2::theme(legend.position = "right")
ggsave(filename = file.path(Output_dir, "Plots",paste0("Trapezoid_", aoi_name, ".png")), width = 8, height = 6)

message(paste("OPTRAM Model saved to:", file.path(Output_dir, "Plots")))

