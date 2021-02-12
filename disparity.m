function [disparity_mapL, disparity_mapR] = disparity(rect_L, rect_R, disparity_parameter, debugActive)

% Entpacken der Parameter aus challenge.m
thresholdDisparityDifference = disparity_parameter{4};


%% Disparity based on left image
disparity_mapL = singleDisparity(rect_L, rect_R, disparity_parameter);

%% Disparity based on right image
disparity_mapR = singleDisparity(rect_R, rect_L, disparity_parameter);
% value correction
disparity_mapR = abs(disparity_mapR - max(max(max(disparity_mapR))));

%% Difference between those two disparity maps
disparity_mapDifference = -disparity_mapL + disparity_mapR;

%% Entferne Punkte > thresholdDisparityDifference aus der Disparity Map
disparity_mapInconsistentPoints = abs(disparity_mapDifference) > thresholdDisparityDifference;

%% Entferne Punkte > threshold aus der disparity map
betterDisparity1 = zeros(size(disparity_mapDifference));
betterDisparity2 = zeros(size(disparity_mapDifference));
oldPixelPositionsX = meshgrid(1:size(disparity_mapR,2),1:size(disparity_mapR,1));
for row = 1:size(rect_L,1)
    
    cleanedPixelPositionsX = oldPixelPositionsX(row,disparity_mapInconsistentPoints(row,:)==0);
    cleanedDisparity1ValuesX = disparity_mapR(row,cleanedPixelPositionsX);
    cleanedDisparity2ValuesX = disparity_mapL(row,cleanedPixelPositionsX);
    
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
        
        extrapValDisparity1L = sort(disparity_mapL(row,minPixelNumber:(minPixelNumber+extrapolateSmoothingPixel-1)));
        extrapValDisparity1L = mean(extrapValDisparity1L(1:takeLowestPixels));
        extrapValDisparity1R = sort(disparity_mapL(row,(maxPixelNumber-(extrapolateSmoothingPixel-1)):maxPixelNumber));
        extrapValDisparity1R = mean(extrapValDisparity1R(1:takeLowestPixels));
        extrapValDisparity2L = sort(disparity_mapR(row,minPixelNumber:(minPixelNumber+extrapolateSmoothingPixel-1)));
        extrapValDisparity2L = mean(extrapValDisparity2L(1:takeLowestPixels));
        extrapValDisparity2R = sort(disparity_mapR(row,(maxPixelNumber-(extrapolateSmoothingPixel-1)):maxPixelNumber));
        extrapValDisparity2R = mean(extrapValDisparity2R(1:takeLowestPixels));
        
        cleanedPixelPositionsX = [1:minPixelNumber-1 cleanedPixelPositionsX maxPixelNumber+1:maxPixelImage];
        cleanedDisparity1ValuesX = [extrapValDisparity1L.*ones(1,minPixelNumber-1) cleanedDisparity1ValuesX extrapValDisparity1R.*ones(1,maxPixelImage-maxPixelNumber)];
        cleanedDisparity2ValuesX = [extrapValDisparity2L.*ones(1,minPixelNumber-1) cleanedDisparity2ValuesX extrapValDisparity2R.*ones(1,maxPixelImage-maxPixelNumber)];
        
        betterDisparity1(row,:) = interp1(cleanedPixelPositionsX, cleanedDisparity1ValuesX, oldPixelPositionsX(row,:),'linear');
        betterDisparity2(row,:) = interp1(cleanedPixelPositionsX, cleanedDisparity2ValuesX, oldPixelPositionsX(row,:),'linear');
    end
    
end

%% Debugging
if debugActive
figure
imagesc(betterDisparity1);
colorbar
axis('equal');
title('Disparity based on left image');
figure
imagesc(betterDisparity2);
colorbar
axis('equal');
title('Disparity based on right image');
end
    
end





