function [ img ] = unrectify( img_rect, K, K_inv, rot_matrix, offset, factor, img_size, debugActive )
%unrectify generiert aus einem rektifizierten Bild das Ursprungsbild.
% unrectify.m ist in etwa das Inverse zu rectify_images.m und wird dazu
% genutzt, aus einem rektifizierten Bild das zugehörige Ursprungsbild zu
% berechnen.
%
% Inputs:
%    img_rect - rektifiziertes flying viewpoint Bild
%    K - Kalibrierungsmatrix
%    K_inv - Inverse von K
%    rot_matrix - Matrix, mit der rektifiziert wurde (z.B. R_L, R_neu*R_L,
%                 R*R_L)
%    offset, factor - Parameter der affinen Transformation aus
%                     rectify_images.m, bzw. für flying viewpoint über
%                     calc_affine_part.m zu bestimmen
%    img_size - Größe des Ausgabebildes/Ursprungsbildes
% Outputs:
%    img - Ursprungsbild (nicht rektifiziert)


img_rect = double(img_rect);
% Korrigiere Spiegelung
img_rect = flip(flip(img_rect,1),2);

% Sehr ähnlich zu rectify_step2

% Erstelle meshgrid für Interpolation später
[y, x, ~] = size(img_rect);
[X_rect, Y_rect] = meshgrid(1:x, 1:y);

% Erstelle meshgrid um Pixel von img_rect zu repräsentieren
size_x = img_size(2); size_y = img_size(1);
[X, Y] = meshgrid(1:size_x, 1:size_y);

% Transformiere Pixel zurück
comb_matrix = K * rot_matrix * K_inv;

X_temp = X * comb_matrix(1) + Y * comb_matrix(4) + comb_matrix(7);
Y_temp = X * comb_matrix(2) + Y * comb_matrix(5) + comb_matrix(8);
Z_temp = X * comb_matrix(3) + Y * comb_matrix(6) + comb_matrix(9);
X = X_temp ./ Z_temp; Y = Y_temp ./ Z_temp;

% In dieser Richtung kommt affine Transformation nach Matrix-Multiplikation
X = (X - offset(1)) * factor + 1;
Y = (Y - offset(2)) * factor + 1;

% Interpoliere img an den Stellen X_rect, Y_rect
img(:,:,1) = interp2(X_rect, Y_rect, img_rect(:,:,1), X, Y);
img(:,:,2) = interp2(X_rect, Y_rect, img_rect(:,:,2), X, Y);
img(:,:,3) = interp2(X_rect, Y_rect, img_rect(:,:,3), X, Y);

if debugActive
    figure;
    imshow(uint8(img));
    title('Unrectified free viewpoint image')
end

end

