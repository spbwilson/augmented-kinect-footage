%% Setup.

% Load in the frame files.
load '../frames/frames.mat'

%% Test.

% Test the reshape. Not working.
tmp = reshape(frames{20}, [480 640 6]);

imshow(tmp(:, :, 4:6));
