function [ image ] = show_briefcase( image, UV, XY, source_image )
%SHOW_BRIEFBASE Summary of this function goes here
%   Detailed explanation goes here

image_height = size(image, 1);
image_width  = size(image, 2);

maxs = max(UV);
mins = min(UV);

% Normalize it.
UV = UV - repmat(min(UV) - 1, 4, 1);
homo_image = homographise(UV, XY, source_image(:, :, 4:6));

max_x = maxs(2) - 2;
min_x = mins(2);
max_y = maxs(1) - 2;
min_y = mins(1);

for r = min_y : max_y
    for c = min_x : max_x
        if (r < 1 || c < 18 || r > image_height || c > 604)
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

