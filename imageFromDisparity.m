function [outputImage] = imageFromDisparity(imageRectL, imageRectR, disparityMapL, disparityMapR, position, debugActive)
% imageFromDisparity berechnet aus den beiden rektifizieren Bildern
% imageRectL und imageRectR das rektifizierte flying viewpoint Bild. Die
% Position [0..1] legt dabei fest wo sich der flying viewpoint befindet.
% Die Berechnung basiert auf den Daten der Disparity Map und liefert das
% Viewpoint Bild als Ausgabe.
%
% Inputs:
%    imageRectL - linkes rektifiziertes Bild
%    imageRectR - rechtes rektifiziertes Bild
%    disparityMap - Matrix mit Verschiebung jedes Pixels
%    position - Kameraposition zwischen den beiden Bildern (0 = links, 1 =
%               rechts)
%
% Outputs:
%    outputImage - rektifiziertes Flying viewpoint Bild

methode = 1; % linear interpolation
%methode = 2; % patch interpolation with dynamic patch size

%% preprocess disparity map 1
% if the disparity map does not match with the size of the images
% (e.g. disparity map has been resized for calculation performance), the
% disparity map will be scaled up to the size of the images by using linear
% interpolation for every row.
disparityMap = disparityMapL;

if sum(size(disparityMap) ~= [size(imageRectL,1) size(imageRectL,2)])
    [disparityXMesh, disparityYMesh] = meshgrid(1:size(disparityMap,2),1:size(disparityMap,1));
    % scaling to size of images
    disparityXMesh = disparityXMesh.*(size(imageRectL,2)/size(disparityMap,2));
    disparityYMesh = disparityYMesh.*(size(imageRectL,1)/size(disparityMap,1));

    [disparityXMeshUpscale, disparityYMeshUpscale] = meshgrid(1:size(imageRectL,2),1:size(imageRectL,1));
    disparityMap = interp2(disparityXMesh,disparityYMesh,disparityMap,disparityXMeshUpscale,disparityYMeshUpscale);
end

disparityMapL = disparityMap;


%% preprocess disparity map 2
% if the disparity map does not match with the size of the images
% (e.g. disparity map has been resized for calculation performance), the
% disparity map will be scaled up to the size of the images by using linear
% interpolation for every row.
disparityMap = disparityMapR;

if sum(size(disparityMap) ~= [size(imageRectL,1) size(imageRectL,2)])
    [disparityXMesh, disparityYMesh] = meshgrid(1:size(disparityMap,2),1:size(disparityMap,1));
    % scaling to size of images
    disparityXMesh = disparityXMesh.*(size(imageRectL,2)/size(disparityMap,2));
    disparityYMesh = disparityYMesh.*(size(imageRectL,1)/size(disparityMap,1));

    [disparityXMeshUpscale, disparityYMeshUpscale] = meshgrid(1:size(imageRectL,2),1:size(imageRectL,1));
    disparityMap = interp2(disparityXMesh,disparityYMesh,disparityMap,disparityXMeshUpscale,disparityYMeshUpscale);
end

disparityMapR = disparityMap;
    
%% show upscaled disparities
if debugActive
    figure;
    imagesc(disparityMapL);
    title('Upscaled disparity from left image');
    figure;
    imagesc(disparityMapR);
    title('Upscaled disparity from right image');
end

%% Choose disparity map due to free viewpoint position
if position <= 1
    disparityMap = disparityMapL;
    imageRect = imageRectL;
else
    disparityMap = disparityMapR;
    position = 0;
    imageRect = imageRectR;
end

%% calculate output image from disparity map
oldPixelPositionsX = meshgrid(1:size(imageRect,2),1:size(imageRect,1));
newPixelPositionsX = meshgrid(1:size(imageRect,2),1:size(imageRect,1));
outputImage = zeros(size(imageRect));
outputImage(:,:,:) = -1;

% update new pixel positions with disparity map
newPixelPositionsX = int16(newPixelPositionsX + disparityMap.*position);
% ignore negative pixel values and pixel values that exceed the picture
newPixelPositionsX(newPixelPositionsX<=0) = 1;
newPixelPositionsX(newPixelPositionsX>size(imageRect,2)) = size(imageRect,2);
% output image shall shatter all new pixels
%outputImage = zeros(size(imageL,1), max(max(newPixelPositionsX)), size(imageL,3));
%outputImage(:,:,:) = -1;

% assign pixels in outputImage to the according pixels in the input image
% iterate through rows
for row = 1:size(imageRect,1)
    outputImage(row,newPixelPositionsX(row,:),1) = imageRect(row,oldPixelPositionsX(row,:),1);
    outputImage(row,newPixelPositionsX(row,:),2) = imageRect(row,oldPixelPositionsX(row,:),2);
    outputImage(row,newPixelPositionsX(row,:),3) = imageRect(row,oldPixelPositionsX(row,:),3);
end

%% Display output image before filling holes
% figure;
% imshow(uint8(outputImage));

%% fill holes in output image
% holes result because when using disparity  map not all pixels in the new
% output image will be served
% Concept: Linear interpolation for every row

switch methode
 
    case 1
        %% Linear interpolation
        % für jede Zeile
        for row = 1:size(imageRect,1)
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

if debugActive
% Display output image
figure;
ax1 = subplot(1,3,1)
imshow(uint8(imageRectL))
title('Left image');
ax2 = subplot(1,3,2)
imshow(outputImage)
title('Flying viewpoint image');
ax3 = subplot(1,3,3)
imshow(uint8(imageRectR))
title('Right image');
linkaxes([ax1,ax2,ax3],'xy')

figure;
imshow(outputImage);
title('Flying viewpoint image');
end

