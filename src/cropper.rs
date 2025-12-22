use image::{DynamicImage, GenericImageView};
use anyhow::{Result, anyhow};
use opencv::{
    prelude::*,
    core,
    imgproc,
    imgcodecs,
};

#[derive(clap::ValueEnum, Clone, Debug)]
pub enum CropMethod {
    Fixed,
    DarkTol,
    Grayscale,
    Contour,
}

pub fn crop_image(img: &mut DynamicImage, method: &CropMethod, output_path: &str) -> Result<()> {
    match method {
        CropMethod::Fixed => crop_fixed(img, output_path),
        CropMethod::DarkTol => crop_dark_tol(img, output_path),
        CropMethod::Grayscale => crop_grayscale(img, output_path),
        CropMethod::Contour => crop_contour(img, output_path),
    }
}

fn crop_fixed(img: &mut DynamicImage, output_path: &str) -> Result<()> {
    let (width, height) = img.dimensions();
    let is_landscape = width > height;

    let crop_amount = if is_landscape { 1661 } else { 1580 };
    let new_height = height - crop_amount;

    let cropped_img = img.crop_imm(0, 0, width, new_height);
    let cropped_img_rgba = cropped_img.to_rgba8();

    // Find bounding box (trim transparency)
    let mut min_x = width;
    let mut min_y = new_height;
    let mut max_x = 0;
    let mut max_y = 0;

    for (x, y, pixel) in cropped_img_rgba.enumerate_pixels() {
        if pixel[3] > 0 { // Check alpha channel
            if *x < min_x { min_x = *x; }
            if *y < min_y { min_y = *y; }
            if *x > max_x { max_x = *x; }
            if *y > max_y { max_y = *y; }
        }
    }

    if max_x > min_x && max_y > min_y {
        let final_img = cropped_img.crop_imm(min_x, min_y, max_x - min_x, max_y - min_y);
        final_img.save(output_path)?;
    } else {
        return Err(anyhow!("No content found after initial crop"));
    }

    Ok(())
}

fn crop_dark_tol(img: &mut DynamicImage, output_path: &str) -> Result<()> {
    let (width, height) = img.dimensions();
    let upper_threshold = 50;

    let mut min_x = width;
    let mut min_y = height;
    let mut max_x = 0;
    let mut max_y = 0;

    for (x, y, pixel) in img.pixels() {
        if pixel[0] > upper_threshold || pixel[1] > upper_threshold || pixel[2] > upper_threshold {
            if x < min_x { min_x = x; }
            if y < min_y { min_y = y; }
            if x > max_x { max_x = x; }
            if y > max_y { max_y = y; }
        }
    }

    if max_x > min_x && max_y > min_y {
        let cropped_img = img.crop_imm(min_x, min_y, max_x - min_x, max_y - min_y);
        cropped_img.save(output_path)?;
    } else {
        return Err(anyhow!("No object found to crop"));
    }

    Ok(())
}

fn crop_grayscale(img: &mut DynamicImage, output_path: &str) -> Result<()> {
    let gray_img = img.grayscale();
    let (width, height) = gray_img.dimensions();

    let mut min_x = width;
    let mut min_y = height;
    let mut max_x = 0;
    let mut max_y = 0;

    for (x, y, pixel) in gray_img.pixels() {
        if pixel[0] > 0 {
            if x < min_x { min_x = x; }
            if y < min_y { min_y = y; }
            if x > max_x { max_x = x; }
            if y > max_y { max_y = y; }
        }
    }

    if max_x > min_x && max_y > min_y {
        let cropped_img = img.crop_imm(min_x, min_y, max_x - min_x, max_y - min_y);
        cropped_img.save(output_path)?;
    } else {
        return Err(anyhow!("No object found to crop"));
    }

    Ok(())
}

fn crop_contour(img: &mut DynamicImage, output_path: &str) -> Result<()> {
    let rgb_img = img.to_rgb8();
    let (width, height) = rgb_img.dimensions();

    let src_mat = unsafe {
        Mat::new_rows_cols_with_data(
            height as i32,
            width as i32,
            core::CV_8UC3,
            rgb_img.as_raw().as_ptr() as *mut _,
            core::Mat_AUTO_STEP,
        )?
    };

    let mut gray = Mat::default();
    imgproc::cvt_color(&src_mat, &mut gray, imgproc::COLOR_BGR2GRAY, 0)?;

    let mut thresh = Mat::default();
    imgproc::threshold(&gray, &mut thresh, 10.0, 255.0, imgproc::THRESH_BINARY)?;

    let mut contours = core::Vector::<core::Vector<core::Point>>::new();
    imgproc::find_contours(&thresh, &mut contours, imgproc::RETR_EXTERNAL, imgproc::CHAIN_APPROX_SIMPLE, core::Point::new(0, 0))?;

    if let Some(largest_contour) = contours.iter().max_by_key(|c| (imgproc::contour_area(c, false).unwrap_or(0.0) * 1000.0) as i32) {
        let rect = imgproc::bounding_rect(&largest_contour)?;
        let cropped_image = Mat::roi(&src_mat, rect)?;
        imgcodecs::imwrite(output_path, &cropped_image, &core::Vector::new())?;
    } else {
        return Err(anyhow!("No contours found"));
    }

    Ok(())
}
