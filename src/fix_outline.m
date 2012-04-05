function [ image ] = fix_outline( image, background_z, intensity )
%FIX_OUTLINE Attempts to correct the area of incorrect depth pixels around
%the man.
%   Correct is attempted by thresholding the colour.
%
%   This function does *not* currently work.


% Remove all z-pixels with a 'background' depth from the image.
background_indices = image(:, :, 3) < (background_z + 0.4);
gray_image = rgb2gray(uint8(image(:, :, 4:6)));
gray_image(background_indices) = 0;

% Filter the image to only have the person.
bwimage = im2bw(gray_image, 0);
label = bwlabel(bwimage, 4);
properties = regionprops(label, 'Area'); %#ok<MRPBW>
biggest_area = max([properties.Area]);
index = find([properties.Area] == biggest_area);
other_pixels = ~ismember(label, index);

% Remove the non-person pixels.
image2 = image(:, :, 4:6);
image2(repmat(other_pixels, [1, 1, 3])) = 0;

% Filter for values above 100 in the blue colour space.
b = all(uint8(image2) > 100);

% Correct these pixels' z-value.
tmp = image(:, :, 3);
tmp(b) = z;
image(:, :, 3) = tmp;

end

