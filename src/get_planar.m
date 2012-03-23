function planar = get_planar(pixel_list, threshold)

%This function will take a list form of image (NumPixels, 6) and return
%the corner pixels of the planar [TL, BL, BR, TR] (y,x)
%Threshold is thresh level of RGB (R,G,B)
%Last known is the last known centre of the planar, used to find in the next frame

%---------------------PRE-PROCESS LIST---------------------
%% Find the pixels that are not suitable and remove
pixel_list(any(pixel_list > threshold, 2), :) = [];

% Remove RGB values, only need xyz
pixel_list = pixel_list(:, 1:3);

disp('Pre-processed.');

%--------------------------GET PLANE-----------------------
%% Randomly select point and grow, continue until grows no more or too large
num_points = size(pixel_list, 1);

% Fit plane to the patch so far, if error to large, not planar
remaining = pixel_list;

%Expected size of planar surface.
min = 9000;
max = 12000;

potential = 0;
while ~potential
    disp('~potential');
    
    % Select a random surface patch.
    [patch_points, other_points, plane] = select_patch(remaining);
    
    plot(other_points(:, 1), other_points(:, 2), 'k.');
    hold on
    plot(patch_points(:, 1), patch_points(:, 2), 'r.');
    title('select_path finished (patch in red).');
    pause
    
    % Grow the patch.
    stillgrowing = 1;
    while stillgrowing
        disp('stillgrowing');
        stillgrowing = 0;
        
        % Find other points that lie on the plane.
        old_patch_points = patch_points;
        [patch_points, other_points] = get_all_points(plane, ...,
            patch_points, other_points, num_points);
        
        plot(other_points(:, 1), other_points(:, 2), 'k.');
        hold on
        plot(patch_points(:, 1), patch_points(:, 2), 'r.');
        title('get_all_points finished (patch in red).');
        pause
        
        old_size = size(old_patch_points, 1);
        new_size = size(patch_points, 1);
        
        if new_size > (old_size + 50)
            % Refit the plane.
            [plane, fit] = fit_plane(patch_points);
            fit
            % Bad fit, see if we were actually done.
            if fit > 0.35
                disp('Bad fit!');
                break
            end
            
            disp('Keepgrowing!');
            stillgrowing = 1;
        end
    
        % Early termination criteria.
        if size(patch_points, 1) > max
            disp('Early termination!');
            break;
        end
    end
    disp('Done growing');
    
    %Check if plane size is right
    size(patch_points)
    if (size(patch_points, 1) < max) && (size(patch_points, 1) > min)
        potential = 1;
    end
end

planar = plane;

% The final plane tends to be accurate with a 0.015 threshold (parts of leg
% captured around 0.02), which is a bit close for the general case. Perhaps
% we should take the output of the above code (the patch_points), which
% should be the briefcase, and use those for RANSAC? 
%   If so, we should erode/grow the final image to clear the fluff, and
%   then select only the largest connected component.

%-------------------------RANSAC---------------------------
%% Use RANSAC to get lines


%-----------------------GET CORNERS------------------------
%% Get intersections of lines and return as planar corners

end
