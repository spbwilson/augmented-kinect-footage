function [patch_points, other_points, plane] = select_patch(points)
%SELECT_PATCH Selects a random patch of planar points from a list.
%    Returns the list of points on the patch, the points off the patch,
%    and the equation of the plane.

[num_points, ~] = size(points);

% Temporary storage for points on the patch. Pre-allocate more than we
% (probably) need for speed.
patch_points = zeros(num_points, 3);
other_points = zeros(num_points, 3);

% The size of the neighbourhood - any points within distance_threshold
% units of the randomly chosen point are assumed to be in the patch.
distance_threshold = 0.03;

% Pick a random point until a successful plane is found.
success = 0;
while ~success    
    % Select a random point.
    patch_center = points(floor(num_points * rand), :);
    
    % Find points in the neighborhood of the selected point.
    fit_count = 0;
    other_count = 0;
    distances = zeros(1, num_points);
    for i = 1 : num_points
        distance = norm(points(i,:) - patch_center);
        distances(i) = distance;
        if distance < distance_threshold
            fit_count = fit_count + 1;
            patch_points(fit_count, :) = points(i, :);
        else
            other_count = other_count + 1;
            other_points(other_count, :) = points(i, :);
        end
    end
    
    % If we manage to find at least 10 neighbours, attempt to fit
    % a plane.
    if fit_count > 10
        [plane, error] = fit_plane(patch_points(1:fit_count, :));
        
        if error < 0.1
            patch_points = patch_points(1:fit_count, :);
            other_points = other_points(1:other_count, :);
            success = 1;
        end
    end
    
    if ~success
        disp('Patch fail, start over.');
    end
end