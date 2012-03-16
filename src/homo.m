XY = zeros(4,2);
UV = zeros(4,2);

%In order of x,y - topLeft, topRight, bottomLeft, bottomRight
%XY = [[131, 41]', [428, 40]', [92, 476]', [452, 474]']'; %Going to
%UV = [[1, 1]', [338, 1]', [1, 450]', [338, 450]']'; %Current

P = esthomog(UV,XY,4);

% get input image and sizes
cd ..
original_image = imread('field.jpg','jpg');
cd src
[IR,IC,D]=size(original_image);

homo_image = zeros(450,338,3);  % destination image
v = zeros(3,1);

% loop over all pixels in the destination image, finding
% corresponding pixel in source image
for r = 1 : 450
	for c = 1 : 338
	  v = P*[r,c,1]';        % project destination pixel into source
	  y = round(v(1)/v(3));  % undo projective scaling and round to nearest integer
	  x = round(v(2)/v(3));
	  if (x >= 1) & (x <= IC) & (y >= 1) & (y <= IR)
		homo_image(r,c,:) = original_image(y,x,:);   % transfer colour
	  end
	end
end

figure(1)
imshow(homo_image/255)

% save transfered image
cd ..
imwrite(uint8(homo_image),'homo.png','png');
cd src
