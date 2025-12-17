import os
from PIL import Image
import numpy as np

def process_image(file_path):
    try:
        # Open the image
        img = Image.open(file_path)
        
        # Convert to grayscale
        img_gray = img.convert('L')
        
        # Convert to numpy array
        img_array = np.array(img_gray)
        
        # Find the bounding box of non-zero pixels
        non_zero = img_array > 0
        rows = np.any(non_zero, axis=1)
        cols = np.any(non_zero, axis=0)
        rmin, rmax = np.where(rows)[0][[0, -1]]
        cmin, cmax = np.where(cols)[0][[0, -1]]
        
        # Crop the image
        cropped = img.crop((cmin, rmin, cmax+1, rmax+1))
        
        # Create a mask for the upper contour
        mask = np.zeros_like(img_array)
        for x in range(cmin, cmax+1):
            y = np.argmax(img_array[:, x] > 0)
            if y > 0:
                mask[y:, x] = 255
        
        # Apply the mask to the cropped image
        mask_cropped = mask[rmin:rmax+1, cmin:cmax+1]
        result = Image.fromarray(np.bitwise_and(np.array(cropped), mask_cropped[:, :, np.newaxis]))
        
        return img, result

    except Exception as e:
        print(f"Error processing {file_path}: {str(e)}")
        return None, None

def main():
    input_folder = 'images'
    output_folder = 'output'
    
    # Check if input folder exists
    if not os.path.exists(input_folder):
        print(f"Error: Input folder '{input_folder}' does not exist.")
        return

    # Create output folder if it doesn't exist
    try:
        os.makedirs(output_folder, exist_ok=True)
    except Exception as e:
        print(f"Error creating output folder: {str(e)}")
        return
    
    # List all files in the input folder
    all_files = os.listdir(input_folder)
    jpg_files = [f for f in all_files if f.lower().endswith('.jpg')]
    
    if not jpg_files:
        print(f"No JPG files found in '{input_folder}'. Files found: {all_files}")
        return
    
    for filename in jpg_files:
        input_path = os.path.join(input_folder, filename)
        output_path = os.path.join(output_folder, f'cropped_{filename}')
        
        original, cropped = process_image(input_path)
        
        if original is None or cropped is None:
            continue
        
        print(f"Processing {filename}:")
        print(f"Original size: {original.size[0]}x{original.size[1]} pixels")
        print(f"Cropped size: {cropped.size[0]}x{cropped.size[1]} pixels")
        
        try:
            cropped.save(output_path)
            print(f"Saved cropped image to {output_path}")
        except Exception as e:
            print(f"Error saving {output_path}: {str(e)}")
        
        print()

if __name__ == "__main__":
    main()
