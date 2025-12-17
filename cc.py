from PIL import Image
import numpy as np
import os

def crop_image(input_path, upper_threshold=50):
    # Load the image using Pillow with the specified path
    image = Image.open(input_path)

    # Get the original image size
    original_size = image.size

    # Convert the image to a NumPy array
    image_np = np.array(image)

    # Create a mask to identify pixels that are not in the dark range
    mask = np.any(image_np > upper_threshold, axis=-1)

    # Find the coordinates of non-dark pixels (which should be the object)
    coords = np.argwhere(mask)

    if coords.size > 0:
        # Get the bounding box coordinates of the object
        y0, x0 = coords.min(axis=0)
        y1, x1 = coords.max(axis=0) + 1  # +1 to include the last pixel

        # Crop the image using the bounding box coordinates
        cropped_image_np = image_np[y0:y1, x0:x1]

        # Convert back to a Pillow Image
        cropped_image = Image.fromarray(cropped_image_np)

        # Get the cropped image size
        cropped_size = cropped_image.size

        # Check if the cropped image size is smaller than the original size
        if cropped_size < original_size:
            # Generate output path based on the input path
            # Example: "images/00001.JPG" -> "images/cropped/00001_cropped.JPG"
            input_dir, input_filename = os.path.split(input_path)
            filename_wo_ext, ext = os.path.splitext(input_filename)
            cropped_dir = os.path.join(input_dir, "cropped")
            output_path = os.path.join(cropped_dir, f"{filename_wo_ext}_cropped{ext}")
            
            # Ensure the output directory exists
            os.makedirs(cropped_dir, exist_ok=True)

            # Save the cropped image to the specified output path
            cropped_image.save(output_path)
            
            print(f"Image cropped successfully and saved to {output_path}.")
        else:
            print("Image was not cropped (same size as original).")
    else:
        print("No object found to crop.")

# Example usage:
input_path = "images/00003.JPG"
crop_image(input_path)
