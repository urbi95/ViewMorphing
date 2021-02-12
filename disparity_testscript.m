clear
close all

% rect_L = imread('img/cones/im2_2.png');
% rect_R = imread('img/cones/im6_2.png');

rect_L = imread('img/img_rect_L_small.png');
rect_R = imread('img/img_rect_R_small.png');

rect_L = imresize(rect_L, 0.3);
rect_R = imresize(rect_R, 0.3);

% rect_L = imread('img/teddy_left_2.png');
% rect_R = imread('img/teddy_right_2.png');

%% Erstes Testbild
r = 7;    % ungerade und positiv
window_range = 201; % ungerade und positiv
Methode = 4;

disparity_parameter = {r, window_range, Methode};

tic
[disparity_map1] = disparity(rect_L, rect_R, disparity_parameter);
toc

figure;
imagesc(disparity_map1);
axis('equal');
axis off

%% Zweites Testbild
r = 5;    % ungerade und positiv
%window_range = 61; % ungerade und positiv
% Methode = 1;

disparity_parameter = {r, window_range, Methode};

tic
disparity_map = disparity(rect_R, rect_L, disparity_parameter);
toc

disparity_map = abs(disparity_map - max(max(max(disparity_map))));

figure
imagesc(disparity_map);
axis('equal');
axis off

disparity_map3 = -disparity_map1 + disparity_map;

figure
imagesc(disparity_map3);
axis('equal');
axis off

threshold = 6;

disparity_map4 = abs(disparity_map3) > threshold;
figure
imagesc(disparity_map4);
axis('equal');
axis off;

%% Entferne Punkte > threshold aus der disparity map

betterDisparity1 = zeros(size(disparity_map3));
betterDisparity2 = zeros(size(disparity_map3));
oldPixelPositionsX = meshgrid(1:size(disparity_map,2),1:size(disparity_map,1));
for row = 1:size(rect_L,1)
    
    cleanedPixelPositionsX = oldPixelPositionsX(row,disparity_map4(row,:)==0);
    cleanedDisparity1ValuesX = disparity_map(row,cleanedPixelPositionsX);
    cleanedDisparity2ValuesX = disparity_map1(row,cleanedPixelPositionsX);
    
    if length(cleanedPixelPositionsX) > 1
        % do extrapolation by hand by adding the first and last pixels in each
        % row with the extrapolated values
        minPixelNumber = min(cleanedPixelPositionsX);
        maxPixelNumber = max(cleanedPixelPositionsX);
        maxPixelImage = max(oldPixelPositionsX(row,:));
        % for the extrapolated values, take the the last X
        % pixels and then take the Y lowest values of them and perform
        % mean. This shall filter big values at the borders.
        extrapolateSmoothingPixel = 10;
        takeLowestPixels = 4;
        
        extrapValDisparity1L = sort(disparity_map(row,minPixelNumber:(minPixelNumber+extrapolateSmoothingPixel-1)));
        extrapValDisparity1L = mean(extrapValDisparity1L(1:takeLowestPixels));
        extrapValDisparity1R = sort(disparity_map(row,(maxPixelNumber-(extrapolateSmoothingPixel-1)):maxPixelNumber));
        extrapValDisparity1R = mean(extrapValDisparity1R(1:takeLowestPixels));
        extrapValDisparity2L = sort(disparity_map1(row,minPixelNumber:(minPixelNumber+extrapolateSmoothingPixel-1)));
        extrapValDisparity2L = mean(extrapValDisparity2L(1:takeLowestPixels));
        extrapValDisparity2R = sort(disparity_map1(row,(maxPixelNumber-(extrapolateSmoothingPixel-1)):maxPixelNumber));
        extrapValDisparity2R = mean(extrapValDisparity2R(1:takeLowestPixels));
        
        cleanedPixelPositionsX = [1:minPixelNumber-1 cleanedPixelPositionsX maxPixelNumber+1:maxPixelImage];
        cleanedDisparity1ValuesX = [extrapValDisparity1L.*ones(1,minPixelNumber-1) cleanedDisparity1ValuesX extrapValDisparity1R.*ones(1,maxPixelImage-maxPixelNumber)];
        cleanedDisparity2ValuesX = [extrapValDisparity2L.*ones(1,minPixelNumber-1) cleanedDisparity2ValuesX extrapValDisparity2R.*ones(1,maxPixelImage-maxPixelNumber)];
        
        betterDisparity1(row,:) = interp1(cleanedPixelPositionsX, cleanedDisparity1ValuesX, oldPixelPositionsX(row,:),'linear');
        betterDisparity2(row,:) = interp1(cleanedPixelPositionsX, cleanedDisparity2ValuesX, oldPixelPositionsX(row,:),'linear');
    end
    
end


figure
%imshow(uint8(betterDisparity1))
imagesc(betterDisparity1);
colorbar
axis('equal');
figure
imagesc(betterDisparity2);
%imshow(uint8(betterDisparity2))
colorbar
axis('equal');


%% drittes Testbild

% r = 7;    % ungerade und positiv
% %window_range = 61; % ungerade und positiv
% % Methode = 1;
% 
% disparity_parameter = {r, window_range, Methode};
% tic
% disparity_map = disparity(rect_L, rect_R, disparity_parameter);
% toc
% 
% %figure;
% subplot(1,3,3);
% imshow(disparity_map);