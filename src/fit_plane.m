function [ plane, fit_error ] = fit_plane( pointlist )
%FIT_PLANE Fits a plane to a set of three dimensional input points.
%   Pointlist should be an n-by-3 matrix, where each row is a point on 
%   the required plane (or close to). Pointlist may also be given as a 
%   3-by-n matrix, with n ~= 3.
%
%   The plane is returned as a 4 element vector [N, d], consisting of the
%   normal to the plane, N, and the plane constant d. Any point p on the
%   plane then satisfies N.p + d == 0.
%
%   This code is adapted from that found on the AV webpage.

[number_points, dimensionality] = size(pointlist);

if dimensionality ~= 3
    % Perhaps the user just gave pointlist the wrong way round.
    if number_points == 3
        pointlist = pointlist';
        [number_points, ~] = size(pointlist);
    else
        error = MException('FitPlane:BadInput', ...
            'Input pointlist must be n-by-3, not %d-by-%d', ...
            number_points, dimensionality);
        throw(error);
    end
end

plane = zeros(4,1);

% Translate the plane points to be centered at (0, 0, 0).
% Use a scale factor of 100 to balance the value sizes.
m = mean(pointlist);
centered_pointlist = pointlist - repmat(m, number_points, 1);
D = [centered_pointlist, repmat(100, number_points, 1)];

% The plane normal is given by the smallest eigenvector of the scatter
% matrix (the non-normalized estimate of the covariance matrix.)
scatter = D'*D;
[~, S, V] = svd(scatter);
plane_normal = V(1:3, 4);

% Use the unit normal.
plane(1:3) = plane_normal' / norm(plane_normal);

% Recompute d to fit N.p + d == 0.
plane(4) = 100 * V(4, 4) / norm(plane_normal) - (m * plane(1:3));

% The normal should face the sensor.
if plane(3) < 0
    plane = -plane;
end

% The fitting error is given by the last entry of the sigma matrix.
fit_error = S(4, 4);

end

