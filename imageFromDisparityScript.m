%close all;
clear;

%diparity map for following images
% load disparityMap.mat
% imageL = imread('img/tsuL.png');
% imageR = imread('img/tsuR.png');
% disparity = d;

load disparityMapL2R2.mat
imageL = imread('img/L2.jpg');
imageR = imread('img/R2.jpg');

%import disparity from Max Schreil
% load R2L2_rect_disp.mat
% disparity = -disparityMap_1;
% imageL = uint8(255*image1);
% imageR = uint8(255*image2);

%figure;
%for i=1:10
%p = i/10;

% flying viewpoint position in percent
p = 0.5;
methode = 2;

%% preprocess disparity map
% if the disparity map does not match with the size of the images
% (e.g. disparity map has been resized for calculation performance), the
% disparity map will be scaled up to the size of the images by using linear
% interpolation for every row.
[disparityXMesh, disparityYMesh] = meshgrid(1:size(disparity,2),1:size(disparity,1));
% scaling to size of images
disparityXMesh = disparityXMesh.*(size(imageL,2)/size(disparity,2));
disparityYMesh = disparityYMesh.*(size(imageL,1)/size(disparity,1));

[disparityXMeshUpscale, disparityYMeshUpscale] = meshgrid(1:size(imageL,2),1:size(imageL,1));
disparity = interp2(disparityXMesh,disparityYMesh,disparity,disparityXMeshUpscale,disparityYMeshUpscale);

% show upscaled disparity
figure;
imagesc(disparity);

%% calculate output image from disparity map
oldPixelPositionsX = meshgrid(1:size(imageL,2),1:size(imageL,1));
newPixelPositionsX = meshgrid(1:size(imageL,2),1:size(imageL,1));
outputImage = zeros(size(imageL));
outputImage(:,:,:) = -1;

% update new pixel positions with disparity map
newPixelPositionsX = int16(newPixelPositionsX + disparity.*p);
% ignore negative pixel values and pixel values that exceed the picture
newPixelPositionsX(newPixelPositionsX<=0) = 1;
newPixelPositionsX(newPixelPositionsX>size(imageL,2)) = size(imageL,2);
% output image shall shatter all new pixels
%outputImage = zeros(size(imageL,1), max(max(newPixelPositionsX)), size(imageL,3));
%outputImage(:,:,:) = -1;

% assign pixels in outputImage to the according pixels in the input image
% iterate through rows
for row = 1:size(imageL,1)
    outputImage(row,newPixelPositionsX(row,:),1) = imageL(row,oldPixelPositionsX(row,:),1);
    outputImage(row,newPixelPositionsX(row,:),2) = imageL(row,oldPixelPositionsX(row,:),2);
    outputImage(row,newPixelPositionsX(row,:),3) = imageL(row,oldPixelPositionsX(row,:),3);
end

%% Display output image before filling holes
figure;
imshow(uint8(outputImage));

%% fill holes in output image
% holes result because when using disparity  map not all pixels in the new
% output image will be served
% Concept: Linear interpolation for every row

switch methode
 
    case 1
        %% Linear interpolation
        % für jede Zeile
        for row = 1:size(imageL,1)
            % entferne alle Pixel die nicht zugewiesen wurden und speichere x Werte in
            % einem Array
            pixelPositionsXWithoutHole = oldPixelPositionsX(row,outputImage(row,:,1)>=0);
            imageValuesWithoutHole = outputImage(row,outputImage(row,:,1)>=0,:);

            % Zeilenweise interpolieren, neue x Werte sind Pixel für eine Reihe (1:384), alte x
            % Werte sind x-Werte ohne fehlende Pixel (length < 384).
            % prevent errors when whole row is -1. e.g. disparity crappy
            if length(pixelPositionsXWithoutHole) > 1
                % option: do not extrapolate with 0 but with border pixel
                % value imageValuesWithoutHole(:,end,1)
                outputImage(row,:,1) = uint8(interp1(pixelPositionsXWithoutHole, imageValuesWithoutHole(:,:,1), oldPixelPositionsX(row,:),'linear',0));
                outputImage(row,:,2) = uint8(interp1(pixelPositionsXWithoutHole, imageValuesWithoutHole(:,:,2), oldPixelPositionsX(row,:),'linear',0));
                outputImage(row,:,3) = uint8(interp1(pixelPositionsXWithoutHole, imageValuesWithoutHole(:,:,3), oldPixelPositionsX(row,:),'linear',0));
                % probiere lineare Interpolation, kubisch etc.
            end

        end
        
    case 2
        %% Apply patch filtering to output image and see if result looks better
        patchSize = 3; % patch will be patchSize x patchSize
        minValidPointsInPatch = 4; % minimum number of assigned values in a patch,
                                    % otherwise increase patch size
         
        [holeY, holeX] = find(outputImage(:,:,1)==-1);
        holes = [holeX';holeY'];
        
        % ignore holes that are too close to the image borders  
        neighborPixels = floor(patchSize/2);
        holes(:,holes(1,:) < neighborPixels+1) = [];
        holes(:,holes(1,:) > size(outputImage,2)-neighborPixels) = [];
        holes(:,holes(2,:) < neighborPixels+1) = [];
        holes(:,holes(2,:) > size(outputImage,1)-neighborPixels) = [];
        
        % for every hole take a nxn patch. Remove all elements that are -1
        % from this patch and take the average of the remaining values.
        % Assign the hole to this average value.
        % If we do not have enough values for calculating the average the
        % patch size will be increased.
        % Idea for later testing: try weighted average?
        
        % do correction for every hole
        for index = 1:size(holes,2)
            % first try normal patch size
            patchSizeTemp = patchSize;
            neighborPixels = floor(patchSizeTemp/2);
            % use copy, can be modified with patch resize
            holesTemp = holes;
            while(true)
                patch = zeros(patchSizeTemp,patchSizeTemp,3);
                
                % extract patches (rgb)
                patch = outputImage(holesTemp(2,index)-neighborPixels : holesTemp(2,index)+neighborPixels, ...
                    holesTemp(1,index)-neighborPixels : holesTemp(1,index)+neighborPixels,:);
                % reshape as vector
                patch = reshape(patch,[],3)';
                % delete all non assigned values (-1)
                patch(:,patch(1,:) < 0) = [];

                % do average calculation only if enough points ~= -1. Otherwise
                % increase the patch size
                if size(patch,2) >= minValidPointsInPatch
                    % assign average value of patch to that specific pixel
                    outputImage(holesTemp(2,index),holesTemp(1,index),1) = mean(patch(1,:));
                    outputImage(holesTemp(2,index),holesTemp(1,index),2) = mean(patch(2,:));
                    outputImage(holesTemp(2,index),holesTemp(1,index),3) = mean(patch(3,:));
                    break;
                end
                % increase patchSize for next cycle
                patchSizeTemp = patchSizeTemp + 1;
                neighborPixels = floor(patchSizeTemp/2);
                
                % only use bigger patch if not too close to image borders.
                % Otherwise patch will be ignored.
                if((holesTemp(1,index) < neighborPixels+1) | ...
                        (holesTemp(1,index) > size(outputImage,2)-neighborPixels) | ...
                        (holesTemp(2,index) < neighborPixels+1) | ...
                        (holesTemp(2,index) > size(outputImage,1)-neighborPixels))
                    break;
                end
                
            end
        end
end


outputImage = uint8(outputImage);

%% Display output image
figure;
ax1 = subplot(1,3,1)
imshow(imageL)
title("Left image");
ax2 = subplot(1,3,2)
imshow(outputImage)
title("Flying viewpoint image");
ax3 = subplot(1,3,3)
imshow(imageR)
title("Right image");
linkaxes([ax1,ax2,ax3],'xy')

%end


