% UV = target coords, XY = original image coords
function homo_image = homographise( UV, XY, original_image )
%HOMOGRAPHISE Applies a perspective project on an input image based on the
%four points in UV and XY.
%    The points in UV and XY can be given in any order, but should be
%    given in the same order in both UV and XY.
%
%    Adapted from the code found on the IVR website.

P = esthomog(UV,XY,4);

% Get the input image dimensions.
[IR, IC, ~] = size(original_image);

% Get the output image dimensions.
outH = max(UV(:,1)) - min(UV(:,1));
outW = max(UV(:,2)) - min(UV(:,2));

homo_image = zeros(outH,outW,3);

% Loop over all pixels in the destination image, and find the corresponding
% pixel in the source image.
for r = 1 : outH
    for c = 1 : outW
        % Project the destination pixel onto the source image.
        v = P*[r,c,1]';
        y = round(v(1)/v(3));
        x = round(v(2)/v(3));

        % If the pixel exists, copy it over to the destination image.
        if (x >= 1) && (x <= IC) && (y >= 1) && (y <= IR)
            homo_image(r,c,:) = original_image(y,x,:);
        end
    end
end

end