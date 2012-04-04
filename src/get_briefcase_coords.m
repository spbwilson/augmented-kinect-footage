function [ UVs, XY ] = get_briefcase_coords(frames, debug)
%GET_BRIEFCASE_COORDS Summary of this function goes here
%   Detailed explanation goes here

UVs = cell(36, 1);

% There is no briefcase in 1-8.

% 9-11 have been determined manually.
UVs{9}  = [[310, -49]', [408, -32]', [385, 81]', [287, 64]']';
UVs{10} = [[321, -57]', [414, -58]', [415, 57]', [322, 58]']';
UVs{11} = [[324, -64]', [407, -81]', [430, 32]', [347, 49]']';

% 12 does not have enough data.

% 13 has been determined manually.
UVs{13} = [[297, -29]', [401, -66]', [440, 42]', [336, 79]']';

% We have automatic computation for 14 to 28.
for i = 14 : 28
    image = permute(reshape(frames{i}, [640 480 6]), [2 1 3]);

    [TL, BL, BR, TR, ~, ~] = get_planar(image, 100, debug);

    UVs{i} = [TL([2 1]), BL([2 1]), BR([2 1]), TR([2 1])]';
end

% 29 has been determined manually.
UVs{29} = [[314, 550]', [408, 546]', [399, 661]', [305, 665]']';

XY = [[1, 1]', [480, 1]', [480, 640]', [1, 640]']';

end

