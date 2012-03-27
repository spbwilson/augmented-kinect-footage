function [ UVs, XY ] = get_briefcase_coords(frames, debug)
%GET_BRIEFCASE_COORDS Summary of this function goes here
%   Detailed explanation goes here

UVs = cell(36, 1);

% We have known data for 14 to 28.
for i = 14 : 28
    image = permute(reshape(frames{i}, [640 480 6]), [2 1 3]);

    [TL, BL, BR, TR, ~, ~] = get_planar(image, 100, debug);

    UVs{i} = [TL([2 1]), BL([2 1]), BR([2 1]), TR([2 1])]';
end

XY = [[1, 1]', [480, 1]', [480, 640]', [1, 640]']';

end

