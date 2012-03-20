function [ colors, avg_zs ] = fix_pixels( image, rows, cols, plane, plane_thresh, bad_neighbour_thresh)
%FIX_Z Corrects a 'no-depth' pixel to have the average depth of it's
%neighbours.
%   The neighbours are split into three groups: those on a plane that
%   is passed to the function, those that are not, and those that also
%   have no depth data.
%
%   If enough neighbours have non-zero depth, the average is computed as
%   the average of the larger group of neighbours (on-plane or off-plane).
%
%   Also sets the pixel's color value as the average of the neighbours.

colors = zeros(length(rows), 3);
avg_zs = zeros(length(rows), 1);

for i = 1 : length(rows)
    row = rows(i);
    col = cols(i);
    
    % Counts of the neighbours on the plane and off the plane.
    num_on_plane = 0;
    num_off_plane = 0;
    
    % The averages are (Z, R, G, B).
    on_plane_avg = [0, 0, 0, 0];
    off_plane_avg = [0, 0, 0, 0];
    
    % Check each pixel in the 8-neighbourhood,
    for r = -1 : 1
        for c = -1 : 1
            neighbour = image(row + r, col + c, :);
            
            % Skip the centre pixel and any zero depth pixels.
            if (r == 0 && c == 0) || neighbour(1, 1, 3) == 0
                continue
            end
            
            % Check if the nieghbour is on the plane.
            xyz = neighbour(:, :, 1:3);
            pt = [xyz(:)', 1];
            if (pt * plane) < plane_thresh
                num_on_plane = num_on_plane + 1;
                
                zrgb = neighbour(:, :, 3:6);
                on_plane_avg = on_plane_avg + zrgb(:)';
            else
                num_off_plane = num_off_plane + 1;
                
                zrgb = neighbour(:, :, 3:6);
                off_plane_avg = off_plane_avg + zrgb(:)';
            end
        end
    end
    
    on_plane_avg = on_plane_avg / num_on_plane;
    off_plane_avg = off_plane_avg / num_off_plane;
    
    % If not enough of the neighbours were non-zero depth, just do
    % nothing - we will come back and fix this on another pass. Otherwise,
    % assign the pixel the average z-value and colour of the on or off plane
    % neighbours.
    if num_on_plane + num_off_plane < (8 - bad_neighbour_thresh)
        avg_z = 0;
        color = image(row + r, col + c, 4:6);
    elseif num_on_plane > num_off_plane
        avg_z = on_plane_avg(1);
        color = on_plane_avg(2:4);
    else
        avg_z = off_plane_avg(1);
        color = off_plane_avg(2:4);
    end
    
    avg_zs(i) = avg_z;
    colors(i, :) = color(:)';
end

end