# transcribe_and_translate.R

# Load necessary libraries
library(ellmer)
library(dplyr)
library(purrr)
library(stringr)
library(base64enc)

# --- Configuration ---
IMAGE_DIR <- "images"
STATE_FILE <- ".last_processed_image"
OUTPUT_FILE <- "transcriptions.txt"
API_KEY_ENV_VAR <- "GEMINI_API_KEY"
MODEL_NAME <- "gemini-1.5-flash"
PROMPT <- "
Describe this image in detail, focusing on the main subjects and any text present.
After the description, provide a direct translation of that description into Hebrew.
Format the output exactly like this, without any extra formatting or markdown:
Description: [Your detailed description here]
Hebrew: [The Hebrew translation here]
"

# --- Main Function ---

#' @title Transcribe and translate the next image in a directory
#'
#' @description This function identifies the next image to process from a directory,
#' sends it to the Google Gemini API for transcription and translation, and saves the
#' result to a file.
#'
#' @return Invisibly returns NULL. The function writes the transcription to the
#' output file and updates the state file.
#'
run_transcription <- function() {

  # Create output and state files if they don't exist
  if (!file.exists(OUTPUT_FILE)) {
    file.create(OUTPUT_FILE)
  }
  if (!file.exists(STATE_FILE)) {
    file.create(STATE_FILE)
  }

  # 1. Get API Key and configure the model
  api_key <- Sys.getenv(API_KEY_ENV_VAR)
  if (api_key == "") {
    stop(str_glue("API key not found. Please set the '{API_KEY_ENV_VAR}' environment variable."))
  }

  # 2. Determine the next image to process
  next_image_filename <- get_next_image()
  if (is.null(next_image_filename)) {
    return(invisible(NULL))
  }

  cat("Processing image:", next_image_filename, "\n")
  image_path <- file.path(IMAGE_DIR, next_image_filename)

  # 3. Call the Gemini API
  tryCatch({
    # The ellmer package will automatically use the GEMINI_API_KEY env var
    model <- genai_model(MODEL_NAME)

    cat("Sending request to Gemini API...\n")
    response <- model$generate_content(
      list(
        list(text = PROMPT),
        list(inline_data = list(
          mime_type = "image/jpeg",
          data = base64enc::base64encode(image_path)
        ))
      )
    )

    # 4. Process the response and save it
    if (!is.null(response) && length(response$candidates) > 0) {

      content <- response$candidates[[1]]$content$parts[[1]]$text

      cat("Received response. Saving to file.\n")

      # Append the result to the output file
      write(
        str_glue(
          "---\nFile: {next_image_filename}\n{content}\n"
        ),
        file = OUTPUT_FILE,
        append = TRUE
      )

      # Update the state file
      write(next_image_filename, file = STATE_FILE)

      cat("Successfully processed and saved transcription for", next_image_filename, "\n")

    } else {
      cat("Received an empty response from the API.\n")
    }

  }, error = function(e) {
    cat("An error occurred during the API call:", e$message, "\n")
  })

  invisible(NULL)
}

# --- Helper Function ---

#' @description Determines the next image to process based on a state file.
get_next_image <- function() {

  if (!dir.exists(IMAGE_DIR)) {
    cat("Error: The directory '", IMAGE_DIR, "' was not found.\n")
    return(NULL)
  }

  image_files <- list.files(IMAGE_DIR, pattern = "\\.(png|jpg|jpeg)$", ignore.case = TRUE)
  if (length(image_files) == 0) {
    cat("No images found in the 'images' directory.\n")
    return(NULL)
  }

  last_processed <- readLines(STATE_FILE, warn = FALSE)

  if (length(last_processed) == 0) {
    return(image_files[1])
  }

  last_index <- match(last_processed, image_files)
  if (is.na(last_index)) {
    cat("Warning: State file contains an image not found in the directory. Starting from the first image.\n")
    return(image_files[1])
  }

  if (last_index + 1 <= length(image_files)) {
    return(image_files[last_index + 1])
  } else {
    cat("All images have been processed.\n")
    return(NULL)
  }
}

# --- Example Usage ---
#
# To run this script, you would call the main function:
#
# run_transcription()
#
