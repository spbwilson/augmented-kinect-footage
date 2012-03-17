% UV = target coords, XY = original image coords
function homo_image = homographise(UV, XY, original_image)

%In order of y,x - topLeft, bottomLeft, bttomRight, topRight
%UV = [[2, 28]',[436, 1]', [435, 296]', [1, 272]']'; %Target
%XY = [[1, 1]', [450, 1]', [450, 338]', [1, 338]']'; %Original

P = esthomog(UV,XY,4);

%Get input image dimensions
[IR,IC,D] = size(original_image);

%Get output image dimensions
outH = max(UV(:,1)) - min(UV(:,1));
outW = max(UV(:,2)) - min(UV(:,2));

homo_image = zeros(outH,outW,3);  % destination image
v = zeros(3,1);

% loop over all pixels in the destination image, finding
% corresponding pixel in source image
for r = 1 : outH
	for c = 1 : outW
	  v = P*[r,c,1]';        % project destination pixel into source
	  y = round(v(1)/v(3));  % undo projective scaling and round to nearest integer
	  x = round(v(2)/v(3));
	  
	  if (x >= 1) & (x <= IC) & (y >= 1) & (y <= IR)
		homo_image(r,c,:) = original_image(y,x,:);   % transfer colour
	  end
	end
end

% save transfered image
cd ..
imwrite(uint8(homo_image),'homo.png','png');
cd src
