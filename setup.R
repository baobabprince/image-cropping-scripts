# setup.R

# Function to install a single package
install_if_missing <- function(package_name) {
  if (!require(package_name, character.only = TRUE)) {
    install.packages(package_name, repos = "https://cloud.r-project.org/")
  }
}

# Install core tidyverse and other necessary packages one by one
install_if_missing("dplyr")
install_if_missing("purrr")
install_if_missing("magrittr")
install_if_missing("httr2")
install_if_missing("jsonlite")
install_if_missing("magick")
install_if_missing("remotes")
install_if_missing("rlang")
install_if_missing("lifecycle")
install_if_missing("vctrs")
install_if_missing("tibble")
install_if_missing("promises")
install_if_missing("later")
install_if_missing("coro")
install_if_missing("pillar")
install_if_missing("stringr")
install_if_missing("base64enc")

# Install ellmer from GitHub
if (!require("ellmer", character.only = TRUE)) {
  remotes::install_github("tidyverse/ellmer")
}

print("All required packages are installed.")
