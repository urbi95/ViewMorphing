function [img_rect_L, img_rect_R, R_L, offset_L, factor_L] = rectify_images(T, R, K, K_inv, img_L, img_R, KP, debugActive)
%rectify_images rektifiziert Bilder.
% Über eine Transformation (R,T) werden aus zwei Bildern die rektifizierten
% Versionen dieser Bilder berechnet, d.h. Merkmalspunkte in diesen Bildern
% liegen auf der gleichen y-Koordinate.
% Inputs:
%    T, R - euklidische Transformation (T ist 3x1, R 3x3-Rotationsmatrix)
%    K, K_inv - Kalibrierungsmatrix, bzw ihre Inverse
%    img_L, img_R - linkes und rechtes Bild, die rektifiziert werden sollen
%    KP - Korrespondenzpunktpaare, mit denen img_rect_L und img_rect_R
%         später derart aneinander angeglichen werden, dass sie die gleiche
%         Skalierung und den gleichen Offset haben
% Outputs:
%    img_rect_L, img_rect_R - rektifizierte Bilder

img_L = double(img_L); img_R = double(img_R);
% Berechne R_rect
e1 = T/norm(T);
e2 = 1/sqrt(T(1)^2 + T(2)^2)*[-T(2), T(1), 0]';
e3 = cross(e1,e2);

R_rect = [e1';e2';e3'];

R_L = R_rect;
R_R = R * R_rect;

[size_y, size_x, ~] = size(img_L);
% Größe der rektifizierten Bilder hier anpassen, z.B. 2 * size(img_L).
% Durch größeres Bild gehen weniger Informationen bei der Interpolation
% verloren.
size_rect_x = size_x; size_rect_y = size_y;
img_rect_size = [size_rect_y, size_rect_x];

% Erster Schritt zur Berechnung
[KP_rect_L, corners_L] = rectify_step1( R_L, K, K_inv, img_L, KP(1:2,:) );
[KP_rect_R, corners_R] = rectify_step1( R_R, K, K_inv, img_R, KP(3:4,:) );

% Berechne offsets and factors der affinen Transformation
% Wenn im plot keine corners angezeigt werden, müssen schon ab hier keine
% corners mehr ausgegeben werden
[offset_L, factor_L, offset_R, factor_R] = calc_affine( KP_rect_L, KP_rect_R, corners_L, corners_R, img_rect_size );

% Endgültige Berechnung der rektifizierten Bilder
img_rect_L = rectify_step2( offset_L, factor_L, R_L, K, K_inv, img_L, img_rect_size );
img_rect_R = rectify_step2( offset_R, factor_R, R_R, K, K_inv, img_R, img_rect_size );

%% debugging
if debugActive
figure;
imshow(uint8(img_rect_L));
title('Left image rectified');

figure;
imshow(uint8(img_rect_R));
title('Right image rectified');
end

end

function [ merkmale_rect, corners ] = rectify_step1( rot_matrix, K, K_inv, img, merkmale )
%rectify_step1 berechnet über die Transformation der Ecken von img in das
% rektifizierte Bild und zurück Offset und Skalierung für rectify_step2,
% ebenso wie die Auswirkung der Transformation auf die Merkmalspunkte in KP

% Finde transformierte Eckpunkte (brauchen wir, um später sicherzustellen,
% dass alle Interpolationspunkte im Inneren des Bildes liegen
[size_y, size_x, ~] = size(img);
% Transformiere Merkmale
merkmale = K * rot_matrix * K_inv * [merkmale; ones(1, size(merkmale,2))];
merkmale_rect = merkmale(1:2,:) ./ merkmale(3,:);
% Transformiere corners
corners = K * rot_matrix * K_inv * [1 1 1; size_x 1 1; size_x size_y 1; 1 size_y 1]';
corners = corners(1:2, :) ./ corners(3, :);

end

function [ offset_L, factor_L, offset_R, factor_R ] = calc_affine( merkmale_L, merkmale_R, corners_L, corners_R, img_rect_size )

% finde Parameter um merkmale_R an merkmale_L anzupassen
M = [merkmale_R(2,:)', ones(size(merkmale_R, 2), 1)];
[least_squares] = (M'*M) \ (M' * merkmale_L(2,:)');
offset_R(2) = least_squares(2); factor_R = least_squares(1);
offset_R(1) = sum(merkmale_L(1,:) - merkmale_R(1,:)) / size(merkmale_R, 2);
offset_R = offset_R';

% transformiere corners_R mit offset & factor
corners_R = factor_R * corners_R + repmat(offset_R, 1, 4);

corners = [corners_L, corners_R];

% Passe corners in ein Bild der Größe img_rect_size ein
size_x = img_rect_size(2); size_y = img_rect_size(1);
offset_L = min(corners, [], 2);
% merkmale = merkmale - offset;
corners = corners - offset_L;
factor_L = min((size_x - 1) / max(corners(1,:)), ...
    (size_y - 1) / max(corners(2,:)));
% merkmale_rect = factor * merkmale + 1;
% corners = factor_L * corners + 1;
% corners_L = corners(:,1:4); corners_R = corners(:,5:8);

offset_R = (offset_L - offset_R) / factor_R;
factor_R = factor_L * factor_R;

end

function [ img_rect ] = rectify_step2( offset, factor, rot_matrix, K, K_inv, img, img_rect_size )

% Erstelle meshgrid für Interpolation später
[y, x, ~] = size(img);
[X, Y] = meshgrid(1:x, 1:y);

% Transformiere corners zurück
% corners = (corners - 1) / factor + offset;
% Erstelle meshgrid um Pixel von img_rect zu repräsentieren
size_rect_x = img_rect_size(2); size_rect_y = img_rect_size(1);
[X_rect, Y_rect] = meshgrid(1:size_rect_x, 1:size_rect_y);
X_rect = (X_rect - 1) / factor + offset(1);
Y_rect = (Y_rect - 1) / factor + offset(2);

% Transformiere corners und Pixel zurück
comb_matrix = K * rot_matrix' * K_inv;
% corners = comb_matrix * [corners; ones(1,4)];
% corners = corners(1:2,:) ./ corners(3,:);   % Debugging um zu sehen ob corners = (corners wie ganz am Anfang)
X_rect_temp = X_rect * comb_matrix(1) + Y_rect * comb_matrix(4) + comb_matrix(7);
Y_rect_temp = X_rect * comb_matrix(2) + Y_rect * comb_matrix(5) + comb_matrix(8);
Z_rect_temp = X_rect * comb_matrix(3) + Y_rect * comb_matrix(6) + comb_matrix(9);
X_rect = X_rect_temp ./ Z_rect_temp; Y_rect = Y_rect_temp ./ Z_rect_temp;

% Interpoliere img an den Stellen X_rect, Y_rect
img_rect(:,:,1) = interp2(X, Y, img(:,:,1), X_rect, Y_rect);
img_rect(:,:,2) = interp2(X, Y, img(:,:,2), X_rect, Y_rect);
img_rect(:,:,3) = interp2(X, Y, img(:,:,3), X_rect, Y_rect);

% Korrigiere Spiegelung
img_rect = flip(flip(img_rect,1),2);

end