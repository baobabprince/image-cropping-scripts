from PIL import Image
import os

# Input and output directories
input_dir = 'images'
output_dir = 'images/crop2'

# Create the output directory if it doesn't exist
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Loop through all images in the input directory
for filename in os.listdir(input_dir):
    if filename.endswith(('.jpg', '.jpeg', '.png', ".JPG")):  # Check for image files
        img_path = os.path.join(input_dir, filename)
        
        # Load the image using Pillow
        img = Image.open(img_path)
        width_original, height_original = img.size

        # Determine if the image is landscape or portrait
        is_landscape = width_original > height_original

        # Remove pixels from the bottom based on orientation
        if is_landscape:
            img = img.crop((0, 0, width_original, height_original - 1661))
        else:
            img = img.crop((0, 0, width_original, height_original - 1580))

        # Find the bounding box of the non-transparent area (assuming transparency indicates background)
        bbox = img.getbbox()

        # Crop the image based on the bounding box
        if bbox:
            cropped_img = img.crop(bbox)

            # Save the cropped image with reduced quality (JPEG compression)
            output_path = os.path.join(output_dir, filename)
            cropped_img.save(output_path, quality=70, optimize=True)  # Adjust quality (0-100)
            print(f'Saved cropped image to: {output_path}')
