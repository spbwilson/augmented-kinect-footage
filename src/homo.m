XY = zeros(4,2);
UV = zeros(4,2);

%In order of y,x - topLeft, bottomLeft, bttomRight, topRight
UV = [[2, 28]',[436, 1]', [435, 296]', [1, 272]']'; %Target
XY = [[1, 1]', [450, 1]', [450, 338]', [1, 338]']'; %Original

P = esthomog(UV,XY,4);

%Get input image and sizes
cd ..
original_image = imread('field.jpg','jpg');
cd src
[IR,IC,D] = size(original_image);

homo_image = zeros(436,296,3);  % destination image
v = zeros(3,1);

% loop over all pixels in the destination image, finding
% corresponding pixel in source image
for r = 1 : 436
	for c = 1 : 296
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
