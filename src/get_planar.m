function [TL, BL, BR, TR, planar, results] = get_planar(image, threshold, debug)
%GET_PLANAR Attempts to find the quadilateral in the image.
%    The image is initially thresholded to the lower half of the image and
%    pixels that are darker than threshold.
%
%    The debug variable controls how much information is output from the
%    finding of the briefcase. A value of 0 means no information. A value
%    of 1 means text-only information. A value above 1 turns on graphical
%    output, and means that the user is required to press space to make 
%    the system continue.

%% ---------------------PRE-PROCESS IMAGE---------------------

image_width  = size(image, 2);
image_height = size(image, 1);

% Get the pixel_list from the image, removing the lower half and any
% zero-depth data.
mid = size(image, 1) / 2;
pixel_list = image(mid:end, :, :);
pixel_list = reshape(pixel_list, ...
    size(pixel_list, 1) * size(pixel_list, 2), 6);
pixel_list(pixel_list(:, 3) == 0, :) = [];

% Colour-threshold the list.
pixel_list(any(pixel_list > threshold, 2), :) = [];

% Remove the RGB values; we only need xyz.
pixel_list = pixel_list(:, 1:3);

if debug > 0
    disp('Pre-processed.');
end

%% --------------------------GET PLANE-----------------------
remaining = pixel_list;
num_points = size(pixel_list, 1);

% Expected size of the planar surface.
min_size = 9000;
max_size = 13500;

% The number of new neighbours required to continue growing.
min_new_neighbours = 50;

% The maximum allowed fit error.
max_fit_error = 0.35;

% The maximum height of the quadilateral over all frames (plus an error
% margin.)
max_height = 0.51;

potential = 0;
while ~potential
    if debug > 0
        disp('Searching for a potential plane...');
    end
    
    % Select a random surface patch.
    [patch_points, other_points, plane] = select_patch(remaining, debug);
    
    if debug > 1
        plot(other_points(:, 1), other_points(:, 2), 'k.');
        hold on
        plot(patch_points(:, 1), patch_points(:, 2), 'r.');
        title('The chosen start patch, in red.');
        drawnow
    end
    
    % Grow the patch.
    stillgrowing = 1;
    while stillgrowing
        if debug > 0
            disp('Growing the plane...');
        end
        
        stillgrowing = 0;
        
        % Find other points that lie on the plane.
        old_patch_points = patch_points;
        [patch_points, other_points] = get_all_points(plane, ...,
            patch_points, other_points, num_points);
        
        if debug > 1
            plot(other_points(:, 1), other_points(:, 2), 'k.');
            hold on
            plot(patch_points(:, 1), patch_points(:, 2), 'r.');
            title('The grown patch (in red).');
            drawnow
        end
        
        old_size = size(old_patch_points, 1);
        new_size = size(patch_points, 1);
        
        if new_size > (old_size + min_new_neighbours)
            % Refit the plane.
            [plane, fit] = fit_plane(patch_points);
            
            % Bad fit, see if we were actually done.
            if fit > max_fit_error
                if debug > 0
                    disp('Bad fit!');
                end
                break
            end
            
            stillgrowing = 1;
        end
        
        % Early termination criteria.
        height = max(patch_points(:, 2)) - min(patch_points(:,2));
        if size(patch_points, 1) > max_size || height > max_height
            if debug > 0
                disp('Size too big, terminating!');
            end
            break;
        end
    end

    if debug > 0
        disp('Done growing');
    end
    
    % The plane must be the correct size to be accepted.
    if (size(patch_points, 1) < max_size) && ...
            (size(patch_points, 1) > min_size)
        potential = 1;
    end
end

planar = plane;

%% --------------------------POST-PROCESS IMAGE-----------------------

% The allowable plane error.
max_plane_error = 0.015;

% Select only the pixels on the briefcase plane.
grey_image = rgb2gray(uint8(image(:, :, 4:6)));
for r = 1 : size(grey_image, 1)
    for c = 1 : size(grey_image, 2)
        t = image(r, c, 1:3);
        pt = [t(:)', 1];
        if abs(pt * planar) >= max_plane_error
            grey_image(r, c) = 0;
        end
    end
end
bwimage = im2bw(grey_image, 0);

if debug > 1
    imshow(bwimage);
    title('The bw image.');
    pause
end

% Erode/refill the image to clean it.
struct_elem = strel('square', 3);
bwimage = imerode(bwimage, struct_elem);
bwimage = imdilate(bwimage, struct_elem);
bwimage = imdilate(bwimage, struct_elem);
bwimage = imerode(bwimage, struct_elem);

if debug > 1
    imshow(bwimage);
    title('The bw image (after erode).');
    pause
end

% Locate the biggest item.
label = bwlabel(bwimage, 4);
properties = regionprops(label, 'Area'); %#ok<MRPBW>
biggest_area = max([properties.Area]);
index = find([properties.Area] == biggest_area);

bwimage = ismember(label, index);

if debug > 1
    imshow(bwimage);
    title('The bw image (after biggest item selection).');
    pause
end

%% --------------------------EDGE DETECTION-----------------------

% Use a Canny edge detector to find the edges.
edges = edge(bwimage, 'canny');

if debug > 1
    imshow(edges);
    title('The edges.');
    pause
end

%% -------------------------RANSAC---------------------------

% Path stuff.
path(path, 'RANSAC-Toolbox');
path(path, 'RANSAC-Toolbox/Common');
path(path, 'RANSAC-Toolbox/Models');
path(path, 'RANSAC-Toolbox/Models/Line');
path(path, 'RANSAC-Toolbox/Models/Common');

% RANSAC options.
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

% Extract the edge pixels.
i = 1;
for c = 1 : image_width
    for r = 1 : image_height
        if edges(r, c) ~= 0
            X(:, i) = [c; r]; %#ok<AGROW>
            i = i + 1;
        end
    end
end

% Find the four lines.
results = cell(4,1);
for i = 1 : 4
    [results{i}, options] = RANSAC(X, options);
    
    ind = results{i}.CS;
    
    if debug > 1
        hold on
        plot(X(1, ind), X(2, ind), '.g')
        plot(X(1, ~ind), X(2, ~ind), '.r')
        xlabel('x')
        ylabel('y')
        hold off
        pause
    end
    
    % Remove the found points from the list.
    X = X(:, ~ind);
end

%% -----------------------GET CORNERS------------------------

% Find the intersections of the lines, which are the quadilateral corners.

% RANSAC gives the equation of the line as [a; b; c] such that 
% a * column + b * row + c = 0.
thetas = zeros(3, 4);
thetas(:, 1) = results{1}.Theta;
thetas(:, 2) = results{2}.Theta;
thetas(:, 3) = results{3}.Theta;
thetas(:, 4) = results{4}.Theta;

% Rewrite the equation in 'y = mx + d' form.
for i = 1 : 4
    thetas(:, i) = thetas(:, i) ./ thetas(2, i);
    thetas(1, i) = -thetas(1, i);
    thetas(3, i) = -thetas(3, i);
end

% The parallel lines are those with similar gradients.
parallels = [1 2];
min_difference = abs(thetas(1, 1) - thetas(1, 2));
for i = 3 : 4
    difference = abs(thetas(1, 1) - thetas(1, i));
    if (difference < min_difference)
        parallels(2) = i;
        min_difference = difference;
    end
end

% The corners are given by the intersections of the non-parallel lines.
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
