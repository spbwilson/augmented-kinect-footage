function [ color, avg_z ] = fix_z( image, row, col, plane, threshold, lol)
%FIX_Z Summary of this function goes here
%   Detailed explanation goes here

on_plane = 0;
off_plane = 0;
% Z R G B
on_average = [0, 0, 0, 0];
off_average = [0, 0, 0, 0];
for r = -1 : 1
    for c = -1 : 1
        t = image(row + r, col + c, :);
        
        % Skip the centre pixel and any zero depth pixels.
        if (r == 0 && c == 0) || t(1, 1, 3) == 0
            continue
        end
    
        a = t(:, :, 1:3);
        pt = [a(:)', 1];
        if (pt * plane) < threshold
            on_plane = on_plane + 1;
            a = t(:, :, 3:6);
            on_average = on_average + a(:)';
        else
            a = t(:, :, 3:6);
            off_average = off_average + a(:)';
            off_plane = off_plane + 1;
        end
    end
end

if on_plane + off_plane < (8 - lol)
    avg_z = 0;
    color = image(row + r, col + c, 4:6);
elseif on_plane > off_plane
    avg_z = on_average(1) / on_plane;
    color = image(row + r, col + c, 4:6);
else
    avg_z = off_average(1) / off_plane;
    color = off_average(2:4) ./ off_plane;
end

end

