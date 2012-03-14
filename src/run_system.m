%% Setup.

% Load in the frame files.
load '../frames/frames.mat'

%% Test.

for i = 20 : 20 %1 : length(frames)
    tmp = reshape(frames{i}, [640 480 6]);

    first_three = tmp(:, :, 1:3);
    last_three = uint8(tmp(:, :, 4:6));

    correct_image = zeros(480, 640, 3, 'uint8');
    correct_image(:, :, 1) = last_three(:, :, 1)';
    correct_image(:, :, 2) = last_three(:, :, 2)';
    correct_image(:, :, 3) = last_three(:, :, 3)';

    imshow(correct_image);
    pause(0.2);

%     z_values = first_three(:,:,3);
% 
%     grey_out = z_values - min(z_values(:));
% 
%     maximum = max(grey_out(:));
%     minimum = min(grey_out(:));
% 
%     grey_out = (grey_out / (maximum - minimum)) * (1 - 0);
% 
%     im = mat2gray(grey_out)';
% 
%     imshow(im);
%     pause(0.2);
end

%% Lets try and graph it.

x_vals = first_three(:, :, 1);
x_vals = x_vals(:);
y_vals = first_three(:, :, 2);
y_vals = y_vals(:);

%%

colors = last_three;
a = colors(:, :, 1);
b = colors(:, :, 2);
c = colors(:, :, 3);
a = a(:);
b = b(:);
c = c(:);

%%

new_colors = zeros(480 * 640, 3);
new_colors(:, 1) = a;
new_colors(:, 2) = b;
new_colors(:, 3) = c;

%%

new_colors(:, 1) = new_colors(:, 1) / 255;
new_colors(:, 2) = new_colors(:, 2) / 255;
new_colors(:, 3) = new_colors(:, 3) / 255;

%% FUUUUU

scatter(x_vals, y_vals, 1, new_colors);