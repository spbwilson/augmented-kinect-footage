function [TL, BL, BR, TR, planar, results] = get_planar(image, threshold)

% Get the pixel_list from the image.
mid = size(image, 1) / 2;
pixel_list = image(mid:end, :, :); % Lower half.
pixel_list = reshape(pixel_list, size(pixel_list, 1) * size(pixel_list, 2), 6);
pixel_list(pixel_list(:, 3) == 0, :) = []; % Remove zero-depth data.

%This function will take a list form of image (NumPixels, 6) and return
%the corner pixels of the planar [TL, BL, BR, TR] (y,x)
%Threshold is thresh level of RGB (R,G,B)
%Last known is the last known centre of the planar, used to find in the next frame

%---------------------PRE-PROCESS LIST---------------------
%% Find the pixels that are not suitable and remove
pixel_list(any(pixel_list > threshold, 2), :) = [];

% Remove RGB values, only need xyz
pixel_list = pixel_list(:, 1:3);

disp('Pre-processed.');

%--------------------------GET PLANE-----------------------
%% Randomly select point and grow, continue until grows no more or too large
num_points = size(pixel_list, 1);

% Fit plane to the patch so far, if error to large, not planar
remaining = pixel_list;

%Expected size of planar surface.
min_size = 9000;
max_size = 13500;

potential = 0;
while ~potential
    disp('Searching for a potential plane...');
    
    % Select a random surface patch.
    [patch_points, other_points, plane] = select_patch(remaining);
    
    plot(other_points(:, 1), other_points(:, 2), 'k.');
    hold on
    plot(patch_points(:, 1), patch_points(:, 2), 'r.');
    title('The chosen start patch, in red.');
    %disp('Found patch. Please press enter.');
    %pause
    
    % Grow the patch.
    stillgrowing = 1;
    while stillgrowing
        disp('Growing the plane...');
        stillgrowing = 0;
        
        % Find other points that lie on the plane.
        old_patch_points = patch_points;
        [patch_points, other_points] = get_all_points(plane, ...,
            patch_points, other_points, num_points);
        
        plot(other_points(:, 1), other_points(:, 2), 'k.');
        hold on
        plot(patch_points(:, 1), patch_points(:, 2), 'r.');
        title('The grown patch (in red).');
        drawnow
        
        old_size = size(old_patch_points, 1);
        new_size = size(patch_points, 1);
        
        if new_size > (old_size + 50)
            % Refit the plane.
            [plane, fit] = fit_plane(patch_points);
            % Bad fit, see if we were actually done.
            if fit > 0.35
                disp('Bad fit!');
                break
            end
            
            stillgrowing = 1;
        end
        
        % Early termin_sizeation criteria.
        if size(patch_points, 1) > max_size
            disp('Size too big, terminating!');
            break;
        end
    end
    disp('Done growing');
    
    %Check if plane size is right
    size(patch_points)
    if (size(patch_points, 1) < max_size) && (size(patch_points, 1) > min_size)
        potential = 1;
    end
end

planar = plane;

%% Post processing.

% Convert image to greyscale.
grey_image = rgb2gray(uint8(image(:, :, 4:6)));
imshow(grey_image);
pause

% Select only the pixels on the briefcase plane.
for r = 1 : size(grey_image, 1)
    for c = 1 : size(grey_image, 2)
        t = image(r, c, 1:3);
        pt = [t(:)', 1];
        if abs(pt * planar) >= 0.015
            grey_image(r, c) = 0;
        end
    end
end
bwimage = im2bw(grey_image, 0);

imshow(bwimage);
title('The bw image.');
pause

% Now erode/refill the image to clean it.
struct_elem = strel('square', 3);
bwimage = imerode(bwimage, struct_elem);
bwimage = imdilate(bwimage, struct_elem);
bwimage = imdilate(bwimage, struct_elem);
bwimage = imerode(bwimage, struct_elem);

imshow(bwimage);
title('The bw image (after erode).');
pause

% Locate the biggest item.
label = bwlabel(bwimage, 4);
properties = regionprops(label, 'Area'); %#ok<MRPBW>
biggest_area = max([properties.Area]);
index = find([properties.Area] == biggest_area);

bwimage = ismember(label, index);

imshow(bwimage);
title('The bw image (after biggest item selection).');
pause

%% Edge detection.

edges = edge(bwimage, 'canny');

imshow(edges);
title('The edges.');
pause

%-------------------------RANSAC---------------------------
%% Use RANSAC to get lines

% set RANSAC options
options.epsilon = 1e-6;
options.P_inlier = 0.99;
options.sigma = 1;
options.est_fun = @estimate_line;
options.man_fun = @error_line;
options.mode = 'MSAC';
options.Ps = [];
options.notify_iters = [];
options.min_iters = 100;
options.fix_seed = false;
options.reestimate = true;
options.stabilize = false;

% Extract the non-zero edge pixels.
i = 1;

for c = 1 : 640
    for r = 1 : 480
        if edges(r, c) ~= 0
            X(:, i) = [c; r];
            i = i + 1;
        end
    end
end

% Grab the four edges.
results = cell(4,1);

path(path, 'RANSAC-Toolbox');
path(path, 'RANSAC-Toolbox/Common');
path(path, 'RANSAC-Toolbox/Models');
path(path, 'RANSAC-Toolbox/Models/Line');
path(path, 'RANSAC-Toolbox/Models/Common');

for i = 1 : 4
       
    [results{i}, options] = RANSAC(X, options);
        
    hold on
    ind = results{i}.CS;
    plot(X(1, ind), X(2, ind), '.g')
    plot(X(1, ~ind), X(2, ~ind), '.r')
    xlabel('x')
    ylabel('y')
    hold off
    pause
    
    X = X(:, ~ind);
end

%-----------------------GET CORNERS------------------------
%% Get intersections of lines and return as planar corners

% Theta = [a; b; c] where a*column + b*row + c = 0
% TODO: Check this definition.
thetas = zeros(3, 4);
thetas(:, 1) = results{1}.Theta;
thetas(:, 2) = results{2}.Theta;
thetas(:, 3) = results{3}.Theta;
thetas(:, 4) = results{4}.Theta;

% To rewrite as y = mx + d, do: "/ b", negate "a" and "c".
for i = 1 : 4
    thetas(:, i) = thetas(:, i) ./ thetas(2, i);
    thetas(1, i) = -thetas(1, i);
    thetas(3, i) = -thetas(3, i);
end

% Find the parallel lines.
parallels = [1 2];
min_difference = abs(thetas(1, 1) - thetas(1, 2));
for i = 3 : 4
    difference = abs(thetas(1, 1) - thetas(1, i));
    if (difference < min_difference)
        parallels(2) = i;
        min_difference = difference;
    end
end

% Now get the corners.
corners = zeros(2, 4);
c = 1;
for p = 1 : 2
    line = thetas(:, parallels(p));
    for i = 1 : 4
        if i == parallels(1) || i == parallels(2)
            continue
        end
        
        other_line = thetas(:, i);
        
        x = round((line(3) - other_line(3)) / (other_line(1) - line(1)));
        y = round(line(1) * x + line(3));
        
        corners(:, c) = [round(x); round(y)];
        c = c + 1;
    end
end

% Finally, figure out the correct ordering. We assume that the leftmost
% two points are always the left corners.
[~, I] = sort(corners, 2);
corners_sorted = corners(:, I(1,:));

% Left side.
if corners_sorted(2, 1) < corners_sorted(2, 2)
    TL = corners_sorted(:, 1);
    BL = corners_sorted(:, 2);
else
    TL = corners_sorted(:, 2);
    BL = corners_sorted(:, 1);
end

% Right side.
if corners_sorted(2, 3) < corners_sorted(2, 4)
    TR = corners_sorted(:, 3);
    BR = corners_sorted(:, 4);
else
    TR = corners_sorted(:, 4);
    BR = corners_sorted(:, 3);
end

end
