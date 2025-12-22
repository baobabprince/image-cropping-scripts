# image_cropping.R

# Load necessary libraries
library(magick)
library(dplyr)
library(purrr)

# --- Main Cropping Function ---

#' @title Apply a series of cropping methods to images
#'
#' @description This function reads all images from an input directory, applies a
#' specified cropping method, and saves the cropped images to an output directory.
#'
#' @param input_dir The directory containing the original images.
#' @param output_dir The directory where the cropped images will be saved.
#' @param method A string specifying the cropping method to use.
#'   - "fixed": Crops a fixed number of pixels from the bottom.
#'   - "dark_trim": Crops based on a bounding box of non-dark pixels.
#'   - "grayscale_trim": Crops based on a bounding box of non-zero pixels in a grayscale image.
#'   - "contour_trim": Simulates contour-based cropping by finding the bounding box of the main object.
#'
#' @return Invisibly returns NULL. The function saves cropped images to the output directory.
#'
apply_cropping <- function(input_dir = "images", output_dir = "output", method = "fixed") {

  # Create the output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Get a list of image files
  image_files <- list.files(input_dir, pattern = "\\.(jpg|jpeg|png|JPG)$", full.names = TRUE)

  # Define the cropping function based on the selected method
  crop_fn <- switch(method,
    "fixed" = crop_fixed,
    "dark_trim" = crop_dark_trim,
    "grayscale_trim" = crop_grayscale_trim,
    "contour_trim" = crop_contour_trim,
    stop("Invalid cropping method specified.")
  )

  # Process each image
  walk(image_files, ~{
    tryCatch({
      img <- image_read(.x)
      cropped_img <- crop_fn(img)

      # Save the cropped image
      output_path <- file.path(output_dir, basename(.x))
      image_write(cropped_img, path = output_path, format = "jpg", quality = 70)

      cat("Successfully cropped and saved:", output_path, "\n")

      # Clean up memory to prevent resource exhaustion
      rm(img, cropped_img)
      gc()

    }, error = function(e) {
      cat("Error processing", .x, ":", e$message, "\n")
    })
  })

  invisible(NULL)
}

# --- Cropping Method Implementations ---

#' @description Crops a fixed number of pixels from the bottom of the image.
crop_fixed <- function(img) {

  # Get image dimensions
  info <- image_info(img)
  width_original <- info$width
  height_original <- info$height

  # Determine if the image is landscape or portrait
  is_landscape <- width_original > height_original

  # Define the crop geometry
  if (is_landscape) {
    # Crop 1661 pixels from the bottom
    geometry <- paste0(width_original, "x", height_original - 1661, "+0+0")
  } else {
    # Crop 1580 pixels from the bottom
    geometry <- paste0(width_original, "x", height_original - 1580, "+0+0")
  }

  # Crop the image and then trim the transparent areas
  img %>%
    image_crop(geometry = geometry) %>%
    image_trim()
}

#' @description Crops the image based on a bounding box of non-dark pixels.
crop_dark_trim <- function(img) {

  # The "fuzz" parameter in image_trim creates a bounding box around pixels
  # that are dissimilar to the corner pixels. By setting fuzz to a percentage,
  # we can effectively trim the dark areas. A fuzz of 20% is a good starting
  # point to replicate the Python script's threshold of 50.
  img %>%
    image_trim(fuzz = 0.2)
}

#' @description Crops the image based on a bounding box of non-zero pixels in a grayscale version.
crop_grayscale_trim <- function(img) {

  # Convert to grayscale and then trim the black areas.
  # A small fuzz factor helps to avoid trimming pixels that are almost black.
  img %>%
    image_convert(type = "Grayscale") %>%
    image_trim(fuzz = 0.01)
}

#' @description Simulates contour-based cropping by identifying the main object's bounding box.
crop_contour_trim <- function(img) {

  # This is a more complex task to replicate without a direct equivalent of
  # OpenCV's findContours. A good approach in magick is to:
  # 1. Convert the image to a color space that isolates the main object.
  # 2. Use color-based thresholding to create a binary mask.
  # 3. Trim the image based on this mask.
  #
  # A simple approach for this particular use case is to trim the image with a
  # high fuzz factor, which will effectively crop to the largest contiguous
  # non-background area.
  img %>%
    image_trim(fuzz = 0.5)
}

# --- Example Usage ---
#
# To run this script, you would call the main function with your desired method, e-g.:
#
# apply_cropping(method = "fixed")
# apply_cropping(method = "dark_trim", output_dir = "output/dark_trim")
#
