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

%% The briefcase coordinates. Total hack-code atm.

[UVs, XY] = get_briefcase_coords();

% %%
%
% original = permute(reshape(frames{21}, [640 480 6]), [2 1 3]);
%
% UV = [[317, 319]',[418, 312]', [429, 423]', [330, 425]']';
% UV_prime = [[1, 8]',[102, 1]', [113, 112]', [14, 114]']';
% XY = [[1, 1]', [480, 1]', [480, 640]', [1, 640]']';
% hom_im = homographise(UV_prime, XY, original(:, :, 4:6));
%
% image2 = permute(reshape(frames{22}, [640 480 6]), [2 1 3]);
% for r = 312 : 423
%     for c = 317 : 427
%         r_i = r - 311;
%         c_i = c - 316;
%         if sum(hom_im(r_i, c_i, :)) > 0
%             image2(r, c, 4:6) = hom_im(r_i, c_i, :);
%         end
%     end
% end
%
% imshow(uint8(image2(:, :, 4:6)));
% pause

%% Planar extraction.

% Use the first frame to find the equation of the plane.
% TODO: Use the first n frames?
tmp = permute(reshape(frames{1}, [640 480 6]), [2 1 3]);
tmp = tmp(41:474, 184:426, :); % Select only the plane.
planelist = reshape(tmp(:, :, 1:3), size(tmp, 1) * size(tmp, 2), 3);
planelist(planelist(:, 3) == 0, :) = [];
[plane_equation, ~] = fit_plane(planelist);

% For each frame, do... something.
output_images = cell(length(frames), 1);
for i = 13 : length(frames)
    i
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
            if abs(pt * plane_equation) < 0.08% && sum(h_image) > 0
                image(row, col, 4:6) = h_image;
            end
        end
    end
    
    % If the briefcase is showing, project the previous frame onto it.
    if ~isempty(UVs{i})
        image = show_briefbase(image, UVs{i}, XY, output_images{i - 1});
    end
    
    % Draw it!
    imshow(uint8(image(:, :, 4:6)))
    pause
    %drawnow
    
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
    %     pause#
    
    output_images{i} = image;
end

%% Save it!
% Image is currently skewed/distorted and greyscale. Seems to be a known
% 'thing' with matlab...

vw = VideoWriter('AV_movie.avi');
vw.FrameRate = 6;
vw.open();

for i = 1 : length(output_images)
    image = output_images{i};
    image = image(:, :, 4:6);
    imshow(uint8(image));
    
    writeVideo(vw, getframe(gcf));
end

close(vw);

%%

% Works for frames 14-28, which are the frames where it's totally in view.
image = permute(reshape(frames{15}, [640 480 6]), [2 1 3]);
imshow(uint8(image(:, :, 4:    6)));
pause

[plane_eq, results] = get_planar(image, 100);

%%

% Theta = [a; b; c] where a*column + b*row + c = 0
% TODO: Check this definition.
theta1 = results{1}.Theta;
theta2 = results{2}.Theta;
theta3 = results{3}.Theta;
theta4 = results{4}.Theta;

% To rewrite as y = mx + d, do: "/ b", negate "a" and "c".
theta1 = theta1 ./ theta1(2);
theta1(1) = -theta1(1);
theta1(3) = -theta1(3);

theta2 = theta2 ./ theta2(2);
theta2(1) = -theta2(1);
theta2(3) = -theta2(3);

theta3 = theta3 ./ theta3(2);
theta3(1) = -theta3(1);
theta3(3) = -theta3(3);

theta4 = theta4 ./ theta4(2);
theta4(1) = -theta4(1);
theta4(3) = -theta4(3);

% Similar 'm's mean that they are parallel, so take the dot product (??)
% of the non-parallel line sets to get 4 intersection points.

%%

image2 = image;
for r = 1 : size(image2, 1)
    for c = 1 : size(image2, 2)
        t = image2(r, c, 1:3);
        pt = [t(:)', 1];
        if abs(pt * plane_eq) < 0.015
            image2(r, c, 4:6) = [255, 0 0];
        end
    end
end

imshow(uint8(image2(:, :, 4:6)));

%%

tmp = image;
tmp = tmp(324:378, 194:285, :); % Select only the plane.
planelist = reshape(tmp(:, :, 1:3), size(tmp, 1) * size(tmp, 2), 3);
planelist(planelist(:, 3) == 0, :) = [];
[plane_equation, ~] = fit_plane(planelist);
imshow(uint8(tmp(:, :, 4:6)));

%%

image2 = image;
for r = 287 : 450
    for c = 108 : 342
        t = image2(r, c, 1:3);
        pt = [t(:)', 1];
        
        if abs(pt * plane_equation) < 0.01
            image2(r, c, 4:6) = [255 0 0];
        end
    end
end

imshow(uint8(image2(:, :, 4:6)));

%%

% 
% %% Lets try and graph it.
% 
% x_vals = first_three(:, :, 1);
% x_vals = x_vals(:);
% y_vals = first_three(:, :, 2);
% y_vals = y_vals(:);
% 
% colors = last_three;
% a = colors(:, :, 1);
% b = colors(:, :, 2);
% c = colors(:, :, 3);
% a = a(:);
% b = b(:);
% c = c(:);
% 
% new_colors = zeros(480 * 640, 3);
% new_colors(:, 1) = a;
% new_colors(:, 2) = b;
% new_colors(:, 3) = c;
% 
% new_colors(:, 1) = new_colors(:, 1) / 255;
% new_colors(:, 2) = new_colors(:, 2) / 255;
% new_colors(:, 3) = new_colors(:, 3) / 255;
% 
% %% FUUUUU
% 
% scatter(x_vals, y_vals, 1, new_colors);
