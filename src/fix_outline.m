function [ image ] = fix_outline( image, z )
%FIX_OUTLINE Summary of this function goes here
%   Detailed explanation goes here

figure(1)
imshow(uint8(image(:,:,4:6)));

% Find all z-pixels with a 'background' depth.
background_indices = image(:, :, 3) < -2.08;

% Remove them from the image.
gray_image = rgb2gray(uint8(image(:, :, 4:6)));
gray_image(background_indices) = 0;

% Filter image to only have the person.
bwimage = im2bw(gray_image, 0);
label = bwlabel(bwimage, 4);
properties = regionprops(label, 'Area'); %#ok<MRPBW>
biggest_area = max([properties.Area]);
index = find([properties.Area] == biggest_area);
other_pixels = ~ismember(label, index);

image2 = image(:, :, 4:6);
image2(repmat(other_pixels, [1, 1, 3])) = 0;

figure(2)
imshow(uint8(image2(:, :, 1)));

figure(3)
imshow(uint8(image2(:, :, 2)));

figure(4)
imshow(uint8(image2(:, :, 3)));

a = uint8(image2(:, :, 3));
figure(5)
imshow(a > 100);

bwimage = im2bw(a, graythresh(a));
figure(6)
imshow(bwimage);

figure(7)
imhist(a);
pause

% THIS DOES NOT WORK.
b = a > 100;
tmp = image(:, :, 3);
tmp(b) = z;
image(:, :, 3) = tmp;

end

