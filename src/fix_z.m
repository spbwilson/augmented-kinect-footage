function [ fixed_image ] = fix_z( image, plane, plane_thresh )
%FIX_Z_2 Summary of this function goes here
%   Detailed explanation goes here
% TODO: Current this erodes too much.

% Find any pixels with no z information.
[row, col] = find(image(40:475, 157:452, 3) == 0);

% Offset the values to bring them back to image coordinates.
row = row + 39;
col = col + 156;

% Used to track infinite loops.
old_length = length(row);

% Attempt to fix the z-values.
while (~isempty(row))
    % Attempt to fix the pixels!
    [colors, zs] = fix_pixels(image, row, col, plane, plane_thresh, 3);
    for i = 1 : length(row)
        image(row(i), col(i), 3) = zs(i);
        image(row(i), col(i), 4:6) = colors(i);
    end
    
    % Check if there are any pixels left with no z information.
    [row, col] = find(image(40:475, 157:452, 3) == 0);
    row = row + 39;
    col = col + 156;
    
    % If no more progress can be made, try one more pass which ignores
    % all 'bad' neighbours (instead of failing if there are too many),
    % then finish.
    if length(row) == old_length
        [colors, zs] = fix_pixels(image, row, col, plane, plane_thresh, 8);
        for i = 1 : length(row)
            image(row(i), col(i), 3) = zs(i);
            image(row(i), col(i), 4:6) = colors(i);
        end
        break
    end
    
    old_length = length(row);
end

fixed_image = image;

end

