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
% Fit plane to the patch so far, if error to large, not planar
remaining = pixel_list;

%Expected size of planar
min = 9000;
max = 13000;

potential = 0;
while ~potential
    disp('~potential');

    % select a random small surface patch
    size(remaining)
    [oldlist, plane] = select_patch(remaining);

    % grow patch
    stillgrowing = 1;
    while stillgrowing
        disp('stillgrowing');

        % find neighbouring points that lie in plane
        stillgrowing = 0;
        [newlist,remaining] = getallpoints(plane, oldlist, remaining, size(pixel_list, 1));
        a = size(newlist)
        [NewL,W] = size(newlist);
        [OldL,W] = size(oldlist);

        if NewL > OldL + 50
            % refit plane
            [newplane,fit] = fit_plane(newlist);
            planelist(i,:) = newplane';
            if fit > 0.04*NewL       % bad fit - stop growing
                break
            end
            stillgrowing = 1;
            oldlist = newlist;
            plane = newplane;
        end
    end

    %Check if plane size is right
    if (size(oldlist, 1) < max) && (size(oldlist, 1) > min)
        potential = 1;
    end
end

planar = plane;

%-------------------------RANSAC---------------------------
%% Use RANSAC to get lines


%-----------------------GET CORNERS------------------------
%% Get intersections of lines and return as planar corners

