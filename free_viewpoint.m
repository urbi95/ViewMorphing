function [ output_image ] = free_viewpoint(image_L, image_R, p, harris_parameter, corres_parameter, epi_parameter, disp_parameter, f)
% This function generates an image from a virtual viewpoint between two
% real images. The output image has the same size as the input images.

%% See debugging outputs
close all;
debugActive = true;

%% Merkmale aus Stereobilden extrahieren
% load parameter from challenge.m
f = epi_parameter{1};
K = [f,0, (size(image_L,2)-1)/2;
    0, f, (size(image_R,1)-1)/2;
    0, 0, 1];

merkmale_L = harris_detector(image_L, harris_parameter, debugActive);
merkmale_R = harris_detector(image_R, harris_parameter, debugActive);

%% Korrespondenzen zu Merkmalen finden
KP_paare = find_correspondences(merkmale_L, merkmale_R, image_L, image_R, corres_parameter, debugActive);

%% Essentielle Matrix berechnen
[E, KP_robust] = epipolar_RanSaC(KP_paare, epi_parameter, K);
%% debugging
if debugActive || corres_parameter{3}
    figure;
    Image = image_L./2 + image_R./2;
    imshow(Image);
    hold on;
    for i = 1:size(KP_robust, 2)
        plot(KP_robust(1,i),KP_robust(2,i), 'o', 'MarkerEdgeColor', 'r');
        hold on;
        plot(KP_robust(3,i),KP_robust(4,i), 'o', 'MarkerEdgeColor', 'b');
        hold on;
        line([KP_robust(1,i),KP_robust(3,i)], [KP_robust(2,i),KP_robust(4,i)],'Color', 'green');
        hold on;
    end
    title('Robuste KP-Paare nach RanSaC');
end

%% Euklidische Transformation aus E berechnen
[T, R] = eukl_transformation(E, KP_robust, K);

%% Zugehörige Winkel und neue Transformation mit p berechnen
[winkel_x, winkel_y, winkel_z] = winkel_aus_R(R);
T_neu = p * T;
R_neu = R_aus_winkel(p * winkel_x, p * winkel_y, p * winkel_z);
% E_neu = calc_dach(T_neu)*R_neu;

%% Rectify: Richtet die Bilder so aus, dass die Merkmale auf einer horizontalen Geraden liegen
K_inv = inv(K);
[img_rect_L, img_rect_R, R_L, offset_L, factor_L] = rectify_images(T, R, K, K_inv, image_L, image_R, KP_robust, debugActive);

%% Berechnung der Disparitymap
% use smaller images for disparity calculation as this needs high computing
% performance
scalingFactor = 0.25;
img_rect_L_disparityCalculation = imresize(img_rect_L, scalingFactor);
img_rect_R_disparityCalculation = imresize(img_rect_R, scalingFactor);
[disparity_mapL,disparity_mapR] = disparity(img_rect_L_disparityCalculation, img_rect_R_disparityCalculation, disp_parameter, debugActive);



%% Berechnung des neuen Bildes basierend auf Disparity

flyingViewpointImageRect = imageFromDisparity(img_rect_L, img_rect_R, disparity_mapL, disparity_mapR, p, debugActive);

%% Unrectify: Endgültiges Bild berechnen
% Transformiere robuste KP-paare in das neue Kameraframe
% Berechne Weltkoordinaten von allen robusten KP-paaren
[P1, ~] = rekonstruktion_Weltkoord(T, R, KP_robust, K);    %opt8: Brauchen eig nur P1, P2 braucht Zeit
% Neue Transformation auf KP-paare anwenden
P_neu = R_neu * P1 + T_neu;
% Projizieren der transformierten Weltkoordinaten auf die Bildebene
merkmale_neu = K * P_neu; 
merkmale_neu = merkmale_neu(1:2,:) ./ merkmale_neu(3,:);
[offset_neu, factor_neu] = calc_affine_part(R_L, R_neu, K, K_inv, offset_L, factor_L, merkmale_neu, KP_robust(1:2,:));

output_image = unrectify(flyingViewpointImageRect, K, K_inv, R_neu * R_L, offset_neu, factor_neu, size(image_L), debugActive);
output_image = uint8(output_image);

end