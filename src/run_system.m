%% Setup.

% Load in the frame files.
load '../frames/frames.mat'

%% Planar extraction.

% Use the first frame to find the equation of the plane.
% TODO: Use the first n frames?
tmp = permute(reshape(frames{1}, [640 480 6]), [2 1 3]);
planelist = reshape(tmp(:, :, 1:3), size(tmp, 1) * size(tmp, 2), 3);
planelist(planelist(:, 3) == 0, :) = [];
[plane, ~] = fitplane(planelist);

for i = 1 : length(frames)
    tmp = permute(reshape(frames{i}, [640 480 6]), [2 1 3]);

    first_three = tmp(:, :, 1:3);
    last_three = uint8(tmp(:, :, 4:6));

%     imshow(last_three);
%     pause

    z_values = first_three(:,:,3);

    grey_out = z_values - min(z_values(:));

    maximum = max(grey_out(:));
    minimum = min(grey_out(:));

    grey_out = (grey_out / (maximum - minimum)) * (1 - 0);

    im = mat2gray(grey_out);

%     imshow(im);
%     pause
    
    % Try and extract only plane pixels.
    tmp2 = tmp;
    for col = 157 : 452
        for row = 40 : 475
            t = tmp2(row, col, 1:3);
            pt = [t(:)', 1];
            if pt * plane < 0.1 || tmp2(row, col, 3) == 0
                tmp2(row, col, 4:6) = [255 0 0];
            end
        end
    end
    
    imshow(uint8(tmp2(:, :, 4:6)))
    drawnow
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