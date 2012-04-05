function [ fixed_image ] = fix_z( image, plane, plane_thresh )
%FIX_Z Attempts to fix zero-depth pixels in the image.
%    Pixels are fixed using the neighbour algorithm described in our
%    report.

% Find any pixels with no z information.
% The cut-off is done to remove the black border which has no depth data.
[row, col] = find(image(40:474, 16:604, 3) == 0);

% Offset the values to bring them back to full image coordinates.
row = row + 39;
col = col + 15;

% Used to track infinite loops.
old_length = length(row);

% Keep trying to fix pixels until there are none left or we enter an
% infinite loop.
while (~isempty(row))
    [colors, zs] = fix_pixels(image, row, col, plane, plane_thresh, 3);
    for i = 1 : length(row)
        image(row(i), col(i), 3) = zs(i);
        image(row(i), col(i), 4:6) = colors(i);
    end
    
    % Check if there are any pixels left with no z information.
    [row, col] = find(image(40:474, 16:604, 3) == 0);
    row = row + 39;
    col = col + 15;
    
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

