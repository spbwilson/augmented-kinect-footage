%% Setup.

% Tidy
clear all
close all

% Load in the frame files.
load '../frames/frames.mat'

% Create the homographised image.
UV = [[2, 28]',[437, 1]', [435, 297]', [1, 272]']'; %Target
XY = [[1, 1]', [450, 1]', [450, 338]', [1, 338]']'; %Original

original_image = imread('../field.jpg','jpg');
homo_image = homographise(UV, XY, original_image);

% Image height and width;
image_height = 480;
image_width = 640;

% The outer plane is an area of the scene that contains all of the
% background plane and some other background.
background_outer_plane_top    = 40;
background_outer_plane_bottom = 475;
background_outer_plane_left   = 157;
background_outer_plane_right  = 452;

% The inner plane is an area of the scene that is purely the background
% plane.
background_inner_plane_top    = 41;
background_inner_plane_bottom = 474;
background_inner_plane_left   = 184;
background_inner_plane_right  = 426;

%% The briefcase coordinates.

debug = 1;
[UVs, XY] = get_briefcase_coords(frames, image_width, image_height, debug);

%% Planar extraction.

% Use the first frame to find the equation of the plane.
tmp = permute(reshape(frames{1}, [image_width image_height 6]), [2 1 3]);
tmp = tmp(background_inner_plane_top:background_inner_plane_bottom, ...
          background_inner_plane_left:background_inner_plane_right, :);
planelist = reshape(tmp(:, :, 1:3), size(tmp, 1) * size(tmp, 2), 3);
planelist(planelist(:, 3) == 0, :) = [];
[plane_equation, ~] = fit_plane(planelist);

% Calc a 'good' z value, from the point (0, 0, ?). Used when cleaning
% the image.
z = -plane_equation(4) / plane_equation(3);

output_images = cell(length(frames), 1);
for i = 1 : length(frames)
    disp(strcat('Frame: ', int2str(i)));
    
    image = permute(reshape(frames{i}, [image_width image_height 6]), ...
        [2 1 3]);

    % Correct the homographised image for the current image brightness.
    current_homo_image = correct_brightness(image, homo_image);

    % Attempt to fix the non-existant z values in the image.
    image = fix_z(image, plane_equation, 0.1);
    
    % Attempt to fix the outline around the man. Does not currently work.
    % image = fix_outline(image, z, intensity);

    % Try and extract only plane pixels.
    for col = background_outer_plane_left : background_outer_plane_right
        for row = background_outer_plane_top : background_outer_plane_bottom
            t = image(row, col, 1:3);
            pt = [t(:)', 1];

            offset_row = row - (background_outer_plane_top - 1);
            offset_col = col - (background_outer_plane_left - 1);
            
            % Use the non-altered homographised image to allow for a colour
            % check. (The altered image has a non-black off-image area.)
            h_pixel = homo_image(offset_row, offset_col, :);

            % Check both that the point is on the plane, and that the
            % equivalent homographised point is non-black.
            if abs(pt * plane_equation) < 0.08 && sum(h_pixel) > 0
                image(row, col, 4:6) = current_homo_image(offset_row, ...
                    offset_col, :);
            end
        end
    end

    % If the briefcase is showing, project the previous frame onto it.
    if ~isempty(UVs{i})
        image = show_briefcase(image, UVs{i}, XY, output_images{i - 1});
    end

    output_images{i} = image;
end

%% Save the video.

vw = VideoWriter('../AV_movie.avi');
vw.FrameRate = 6;
vw.open();

for i = 1 : length(output_images)
    image = output_images{i};
    image = image(:, :, 4:6);

    % Smooth the output image.
    filter = fspecial('gaussian');
    image = imfilter(image, filter,'replicate');

    imshow(uint8(image));
    
    writeVideo(vw, getframe(gcf));
end

close(vw);