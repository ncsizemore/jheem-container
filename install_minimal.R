#!/usr/bin/env Rscript

# Minimal package installation for JHEEM container
# Based on first_time_setup/install_packages.R but container-optimized

cat("Installing minimal JHEEM dependencies...\n")

# Essential system packages first
essential_cran <- c(
  "devtools",     # For GitHub installs
  "renv",         # Environment management  
  "pak",          # Fast package installation
  "deSolve",      # Differential equations (core to jheem2)
  "plotly",       # Plot generation
  "ggplot2",      # Plotting backend
  "jsonlite",     # JSON output
  "argparse",     # CLI parsing
  "yaml",         # Config files
  "htmlwidgets"   # Plot saving (might be needed)
)

cat("Installing CRAN packages...\n")
install.packages(essential_cran, repos = "https://cran.rstudio.com/")

# Load devtools for GitHub installs
library(devtools)

# Essential GitHub packages (custom dependencies)
cat("Installing custom GitHub packages...\n")
devtools::install_github('tfojo1/distributions')
devtools::install_github('tfojo1/bayesian.simulations') 
devtools::install_github('tfojo1/locations')

# Install jheem2 from dev branch
cat("Installing jheem2 from dev branch...\n")
devtools::install_github('tfojo1/jheem2@dev')

cat("✅ Minimal installation complete!\n")

# Test core functionality
cat("Testing core imports...\n")
library(jheem2)
library(plotly)
library(locations)
library(jsonlite)

cat("✅ Core packages loaded successfully!\n")
