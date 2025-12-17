# Image Cropping Scripts

This project contains a collection of Python scripts for cropping images. Each script provides a different method for automated image cropping.

## Scripts

*   **`crop.py`**: This script crops a fixed number of pixels from the bottom of the image, with different amounts for landscape and portrait orientations. It then trims the remaining transparent areas.
*   **`cc.py`**: This script crops the image by finding the bounding box of all pixels that are not dark (above a certain threshold).
*   **`cl.py`**: This script crops the image by finding the bounding box of non-zero pixels in a grayscale version of the image. It also attempts to create a mask for the upper contour of the object.
*   **`cr.py`**: This script uses OpenCV to find the contours of the main object in the image and crops to the bounding box of the largest contour.

## Usage

Each script can be run directly from the command line:

```bash
python crop.py
python cc.py
python cl.py
python cr.py
```

The scripts are configured to read images from the `images/` directory and save the cropped images to a new directory (e.g., `images/cropped/`, `output/`). Please see the individual scripts for specific input and output paths.

## Dependencies

The scripts use the following Python libraries:

*   Pillow (PIL)
*   NumPy
*   OpenCV (for `cr.py`)

You can install these dependencies using pip:

```bash
pip install Pillow numpy opencv-python
```
