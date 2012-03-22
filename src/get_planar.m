function planar = get_planar(pixel_list, threshold, last_known)

%This function will take a list form of image (NumPixels, 6) and return
%the corner pixels of the planar [TL, BL, BR, TR] (y,x)
%Threshold is thresh level of RGB (R,G,B)
%Last known is the last known centre of the planar, used to find in the next frame

%---------------------PRE-PROCESS LIST---------------------
%% Remove all pixels in the top half of the image
mid = size(pixel_list, 1) / 2;
pixel_list = pixel_list(mid:end, :);

% Find the pixels that are not suitable and remove
for i = 1 : size(pixel_list,1)
	if (pixel_list(i,4) > threshold(1) && pixel_list(i,5) > threshold(2) && pixel_list(i,6) > threshold(3))
		pixel_list(i, :) = [];
	end
end

% Remove RGB values, only need xyz
pixel_list = pixel_list(:, 1:3);	


%--------------------------GET PLANE-----------------------
%% Randomly select point and grow, continue until grows no more or too large
% Fit plane to the patch so far, if error to large, not planar
remaining = pixel_list;

%Expected size of planar
min = 9000;
max = 13000;

while ~potential

  % select a random small surface patch
  [oldlist,plane] = select_patch(remaining);

  % grow patch
  stillgrowing = 1;
  while stillgrowing

	% find neighbouring points that lie in plane
	stillgrowing = 0;
	[newlist,remaining] = get_all_points(plane,oldlist,remaining,NPts);
	[NewL,W] = size(newlist);
	[OldL,W] = size(oldlist);


	if NewL > OldL + 50
		% refit plane
		[newplane,fit] = fit_plane(newlist);
	[newplane',fit,NewL]
		planelist(i,:) = newplane';
		if fit > 0.04*NewL       % bad fit - stop growing
			break
		end
		stillgrowing = 1;
		oldlist = newlist;
		plane = newplane;
	end

	%Check if plane size is right
	if size(oldlist) < max && size(oldlist) > min
		potential = 1;
	end
end

%-------------------------RANSAC---------------------------
%% Use RANSAC to get lines


%-----------------------GET CORNERS------------------------
%% Get intersections of lines and return as planar corners

