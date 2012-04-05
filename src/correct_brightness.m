function [ corrected_image ] = correct_brightness( image, homo_image )
%CORRECT_HOMO_IMAGE Corrects the brightness of the homographised image.
%   The brightness is corrected by adjusting the mean HSV value parameter
%   for the homographised image to that of the scene.

hsv_image = rgb2hsv(image(:, :, 4:6));
hsv_homo  = rgb2hsv(homo_image);

image_mean = mean(mean(hsv_image(:, :, 3)));
homo_mean  = mean(mean(hsv_homo(:, :, 3)));

mean_difference = image_mean - homo_mean;

hsv_homo(:, :, 3) = hsv_homo(:, :, 3) + mean_difference;
corrected_image = hsv2rgb(hsv_homo);

end