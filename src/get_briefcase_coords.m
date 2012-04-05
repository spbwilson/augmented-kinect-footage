function [ UVs, XY ] = get_briefcase_coords(frames, image_width, image_height, debug)
%GET_BRIEFCASE_COORDS Calculates the perspective projection coordinates for the
%briefcase for each frame.
%   The projection coordinates are placed in the cell array UVs. If the
%   briefcase is showing in a frame i, then UVs{i} is non-empty.
%
%   The coordinates are determined automatically where possible (frames 14
%   - 28) and manually in frames 9-11, 13, and 29.
%
%   The debug variable controls how much information is output from the
%   automatic finding of the briefcase. A value of 0 means no information.
%   A value of 1 means text-only information. A value above 1 turns on
%   graphical output, and means that the user is required to press space to
%   make the system continue.

UVs = cell(length(frames), 1);

% The threshold to pass to get_planar. Any pixels with a lighter colour
% than this (in any colour spectrum) are removed.
colour_threshold = 100;

% There is no briefcase in frames 1-8.

% The coordinates for frames 9-11 have been determined manually.
UVs{9}  = [[310, -49]', [408, -32]', [385, 81]', [287, 64]']';
UVs{10} = [[321, -57]', [414, -58]', [415, 57]', [322, 58]']';
UVs{11} = [[324, -64]', [407, -81]', [430, 32]', [347, 49]']';

% Frame 12 does not have enough data to find the briefcase (just one small
% corner is showing.)

% The coordinates for frame 13 have been determined manually.
UVs{13} = [[297, -29]', [401, -66]', [440, 42]', [336, 79]']';

% The coordinates for frames 14 to 28 can be determined automatically.
for i = 14 : 28
    image = permute(reshape(frames{i}, [image_width image_height 6]), ...
        [2 1 3]);

    [TL, BL, BR, TR, ~, ~] = get_planar(image, colour_threshold, debug);

    UVs{i} = [TL([2 1]), BL([2 1]), BR([2 1]), TR([2 1])]';
end

% 29 has been determined manually.
UVs{29} = [[314, 550]', [408, 546]', [399, 661]', [305, 665]']';

XY = [[1, 1]', [480, 1]', [480, 640]', [1, 640]']';

end

