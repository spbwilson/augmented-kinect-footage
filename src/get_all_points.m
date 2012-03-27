function [new_points, remaining_points] = get_all_points(plane, plane_points, other_points, total_number_points)
%GET_ALL_POINTS Grows a list of points to include other points on the same plane.
%    Returns the grown list of points on the plane, and the other,
%    non-plane points.

% The maximum error threshold allowed for a point to be on the plane.
DISTTOL = 0.01;

% The number of other points and the number of plane points.
[number_other_points, ~] = size(other_points);
[number_old_plane_points, ~] = size(plane_points);

% Temporary storage for each point.
point = ones(4,1);

% Temporary storage for the new list of new points and other points.
new_points = zeros(total_number_points, 3);
remaining_points = zeros(total_number_points, 3);

% Copy in the existing plane points.
new_points(1:number_old_plane_points, :) = plane_points;

% Keep track of how many plane/non-plane points there are.
countnew = number_old_plane_points;
countrem = 0;

% For each other point, check if it is on the plane.
for i = 1 : number_other_points
    point(1:3) = other_points(i,:);
    
    % To be accepted, a point must lie in the plane and be close to the
    % current plane points.
    accepted = 0;
    if abs(point'*plane) < DISTTOL
        distances = plane_points - ...
            repmat(point(1:3)', length(plane_points), 1);
        norms = sqrt(sum(distances.^2,2));
        if any(norms < 0.05)
            countnew = countnew + 1;
            new_points(countnew, :) = other_points(i,:);
            accepted = 1;
        end
    end
    
    if ~ accepted
        countrem = countrem + 1;
        remaining_points(countrem,:) = other_points(i,:);
    end
end

new_points = new_points(1:countnew, :);
remaining_points = remaining_points(1:countrem, :);

end