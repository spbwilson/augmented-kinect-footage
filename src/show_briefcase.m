function [ image ] = show_briefcase( image, UV, XY, source_image )
%SHOW_BRIEFBASE Places the source image onto the briefcase.
%    The coordinates for the project are given in UV and XY.

image_height = size(image, 1);

% The actual coordinates are smaller than the image coordinates.
scene_left = 18;
scene_right = 604;

maxs = max(UV);
mins = min(UV);

% Normalize the UV coordinates.
UV = UV - repmat(min(UV) - 1, 4, 1);

% Homographise the source image.
homo_image = homographise(UV, XY, source_image(:, :, 4:6));

max_x = maxs(2) - 2;
min_x = mins(2);
max_y = maxs(1) - 2;
min_y = mins(1);

for r = min_y : max_y
    for c = min_x : max_x
        if (r < 1 || c < scene_left || r > image_height || c > scene_right)
            continue
        end

        r_i = r - (min_y - 1);
        c_i = c - (min_x - 1);
        if sum(homo_image(r_i, c_i, :)) > 0
            image(r, c, 4:6) = homo_image(r_i, c_i, :);
        end
    end
end

end

