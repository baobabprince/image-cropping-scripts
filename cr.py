import cv2
import numpy as np

# Load the image
image = cv2.imread("images/00001.jpg")

# Convert the image to grayscale
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# Apply a binary threshold to get the main object (white object on black background)
_, thresh = cv2.threshold(gray, 10, 255, cv2.THRESH_BINARY)

# Find contours of the main object
contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

# Get the bounding box of the largest contour (assuming it's the main object)
if contours:
    x, y, w, h = cv2.boundingRect(max(contours, key=cv2.contourArea))

    # Crop the image to the bounding box of the main object
    cropped_image = image[y:y+h, x:x+w]

    # Save or display the cropped image
    cv2.imwrite("cropped_00001.jpg", cropped_image)
    cv2.imshow("Cropped Image", cropped_image)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

else:
    print("No object found to crop.")
