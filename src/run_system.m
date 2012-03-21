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

%% Planar extraction.

% Use the first frame to find the equation of the plane.
% TODO: Use the first n frames?
tmp = permute(reshape(frames{1}, [640 480 6]), [2 1 3]);
tmp = tmp(41:474, 184:426, :); % Select only the plane.
planelist = reshape(tmp(:, :, 1:3), size(tmp, 1) * size(tmp, 2), 3);
planelist(planelist(:, 3) == 0, :) = [];
[plane_equation, ~] = fit_plane(planelist);

% For each frame, do... something.
for i = 1 : length(frames)
    image = permute(reshape(frames{i}, [640 480 6]), [2 1 3]);

    first_three = image(:, :, 1:3);
    last_three = uint8(image(:, :, 4:6));

%     imshow(last_three);
%     pause

%     z_values = first_three(:,:,3);
% 
%     grey_out = z_values - min(z_values(:));
% 
%     maximum = max(grey_out(:));
%     minimum = min(grey_out(:));
% 
%     grey_out = (grey_out / (maximum - minimum)) * (1 - 0);
% 
%     im = mat2gray(grey_out);
% 
%     imshow(im);
%     pause
    
    % Attempt to fix the non-existant z values in the image.
    image = fix_z(image, plane_equation, 0.1);
    
    % Try and extract only plane pixels.
    for col = 157 : 452
        for row = 40 : 475
            t = image(row, col, 1:3);
            pt = [t(:)', 1];
            
            h_image = homo_image(row - 39, col - 156, :);
            if pt * plane_equation < 0.1 && sum(h_image) > 0
                image(row, col, 4:6) = h_image;
            end
        end
    end
    
    imshow(uint8(image(:, :, 4:6)))
    drawnow
    
%     first_three = image(:, :, 1:3);
%     z_values = first_three(:,:,3);
% 
%     grey_out = z_values - min(z_values(:));
% 
%     maximum = max(grey_out(:));
%     minimum = min(grey_out(:));
% 
%     grey_out = (grey_out / (maximum - minimum)) * (1 - 0);
% 
%     im = mat2gray(grey_out);
% 
%     imshow(im);
%     pause
end

%% Lets try and graph it.

x_vals = first_three(:, :, 1);
x_vals = x_vals(:);
y_vals = first_three(:, :, 2);
y_vals = y_vals(:);

colors = last_three;
a = colors(:, :, 1); 
b = colors(:, :, 2);
c = colors(:, :, 3);
a = a(:);
b = b(:);
c = c(:);

new_colors = zeros(480 * 640, 3);
new_colors(:, 1) = a;
new_colors(:, 2) = b;
new_colors(:, 3) = c;

new_colors(:, 1) = new_colors(:, 1) / 255;
new_colors(:, 2) = new_colors(:, 2) / 255;
new_colors(:, 3) = new_colors(:, 3) / 255;

%% FUUUUU

scatter(x_vals, y_vals, 1, new_colors);
