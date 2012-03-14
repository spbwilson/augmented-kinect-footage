%Projection should be [131 41; 428 40; 92 476; 452 474]
function fliphomog = homographise(projection,image,show)
    [IR,IC,D]=size(image);

homog=zeros(IC,IR);   % destination image
v=zeros(3,1);

% loop over all pixels in the destination image, finding
% corresponding pixel in source image
for r = 1 : IC
    for c = 1 : IR
        v=projection*[r,c,1]';        % project destination pixel into source
        x=round(v(1)/v(3));  % undo projective scaling and round to nearest integer
        y=round(v(2)/v(3));
        if (y >= 1) && (y <= IR) && (x >= 1) && (x <= IC)
          homog(r,c,:)=image(y,x,:);   % transfer colour
        end
    end
end

fliphomog = flipdim(homog,2);

if show > 0
    figure(show)
    imshow(fliphomog) % /255 if colour image
end

% save transfered image
imwrite(uint8(fliphomog),'Homographised.jpg','jpg');
