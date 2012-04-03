function [ corrected_image ] = correct_homo_image( image, homo_image )
%CORRECT_HOMO_IMAGE Summary of this function goes here
%   Detailed explanation goes here

hsv_image = rgb2hsv(image(:, :, 4:6));
hsv_homo = rgb2hsv(homo_image);

i_mean = mean(mean(hsv_image(:, :, 3)));
h_mean = mean(mean(hsv_homo(:, :, 3)));
diff = i_mean - h_mean;

hsv_homo(:, :, 3) = hsv_homo(:, :, 3) + diff;
corrected_image = hsv2rgb(hsv_homo);

end