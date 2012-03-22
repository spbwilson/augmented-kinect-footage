function planar = get_planar(pixel_list, threshold)

%This function will take a list form of image (NumPixels, 6) and return
%the corner pixels of the planar [TL, BL, BR, TR] (y,x)
%Threshold is thresh level of RGB (R,G,B)

%% Remove all pixels in the top half of the image
mid = size(pixel_list, 1) / 2;
pixel_list = pixel_list(mid:end, :);

%% Find the pixels that are not suitable and remove
for i = 1 : size(pixel_list,1)
	if (pixel_list(i,4) > threshold(1) && pixel_list(i,5) > threshold(2) && pixel_list(i,6) > threshold(3))
		pixel_list(i, :) = [];
	end
end	

%% Randomly select point and grow, continue until grows no more or too large


%% Fit plane to the patch so far, if error to large, not planar


%% Use RANSAC to get lines


%% Get intersections of lines and return as planar corners
