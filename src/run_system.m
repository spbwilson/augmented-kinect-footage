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


%% The briefcase coordinates.
debug = 1;

[UVs, XY] = get_briefcase_coords(frames, debug);

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
for i = 1 : length(frames)
    i
    image = permute(reshape(frames{i}, [640 480 6]), [2 1 3]);

    first_three = image(:, :, 1:3);
    last_three = uint8(image(:, :, 4:6));

    % Attempt to fix the non-existant z values in the image.
    image = fix_z(image, plane_equation, 0.1);

    % Try and extract only plane pixels.
    for col = 157 : 452
        for row = 40 : 475
            t = image(row, col, 1:3);
            pt = [t(:)', 1];

            h_image = homo_image(row - 39, col - 156, :);
            if abs(pt * plane_equation) < 0.08 && sum(h_image) > 0
                image(row, col, 4:6) = h_image;
            end
        end
    end

    % If the briefcase is showing, project the previous frame onto it.
    if ~isempty(UVs{i})
        image = show_briefcase(image, UVs{i}, XY, output_images{i - 1});
    end

    % Draw it!
    %imshow(uint8(image(:, :, 4:6)))
    %pause

    output_images{i} = image;
end

%% Save it!

vw = VideoWriter('AV_movie.avi');
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

%% Briefcase testing!

% Works for frames 14-28, which are the frames where it's totally in view.
image = permute(reshape(frames{16}, [640 480 6]), [2 1 3]);
old_image = permute(reshape(frames{15}, [640 480 6]), [2 1 3]);
imshow(uint8(image(:, :, 4:6)));
pause

[TL, BL, BR, TR, plane_eq, results] = get_planar(image, 100);

% Find the dimensions of briefcase
topY    = norm(TL(1) - TR(1));
topX    = norm(TL(2) - TR(2));
bottomY = norm(BL(1) - BR(1));
bottomX = norm(BL(2) - BR(2));
leftY   = norm(TL(1) - BL(1));
leftX   = norm(TL(2) - BL(2));
rightY  = norm(TR(1) - BR(1));
rightX  = norm(TR(2) - BR(2));

topLen      = sqrt(topY^2 + topX^2)
bottomLen   = sqrt(bottomY^2 + bottomX^2)
leftLen     = sqrt(leftY^2 + leftX^2)
rightLen    = sqrt(rightY^2 + rightX^2)

%%

% Briefcase projection.
UV = [TL([2 1]), BL([2 1]), BR([2 1]), TR([2 1])]';
XY = [[1, 1]', [480, 1]', [480, 640]', [1, 640]']';
image2 = show_briefcase(image, UV, XY, old_image);

imshow(uint8(image2(:, :, 4:6)));
pause