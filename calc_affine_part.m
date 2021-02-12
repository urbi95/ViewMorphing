function [ offset_neu, factor_neu ] = calc_affine_part( R_L, R_neu, K, K_inv, offset_L, factor_L, merkmale_neu, merkmale_L )
%calc_affine_part berechnet Offset und Skalierung.
% Nachdem beide rektifizierten Bilder über die disparity map kombiniert
% wurden, ist das Ergebnis immer noch rektifiziert.
% Um die Rektifizierung rückgängig zu machen, wird die korrekte affine
% Transformation benötigt. Diese Funktion liefert die zugehörigen Parameter
% Offset und Skalierung zur Verwendung in unrectify.m.
% Inputs:
%    R_L - Matrix, die in rectify_images.m zum Rektifizieren von image_L
%          benutzt wird
%    R_neu - Rotationsmatrix der Transformation zwischen image_L und
%            output_image
%    K, K_inv - Kalibrierungsmatrix und ihre Inverse
%    offset_L, factor_L - affine Transformation für image_L aus
%                         rectify_images.m
%    merkmale_neu, merkmale_L - Merkmalspunkte in output_image und image_L
% Outputs:
%    offset_neu, factor_neu - Parameter der affinen Transformation, die
%                             beim Umkehren der Rektifizierung in
%                             unrectify.m benötigt wird

% Dieser Teil stammt noch aus rectify_step1
merkmale_neu = K * R_neu * R_L * K_inv * [merkmale_neu; ones(1, size(merkmale_neu,2))];
merkmale_neu = merkmale_neu(1:2,:) ./ merkmale_neu(3,:);

merkmale_L = K * R_L * K_inv * [merkmale_L; ones(1, size(merkmale_L,2))];
merkmale_L = merkmale_L(1:2,:) ./ merkmale_L(3,:);

% Ab hier erster Teil von calc_affine.m
% finde Parameter um merkmale_R an merkmale_L anzupassen
M = [merkmale_neu(2,:)', ones(size(merkmale_neu, 2), 1)];
[least_squares] = (M'*M) \ (M' * merkmale_L(2,:)');
offset_neu(2) = least_squares(2); factor_neu = least_squares(1);
offset_neu(1) = sum(merkmale_L(1,:) - merkmale_neu(1,:)) / size(merkmale_neu, 2);
offset_neu = offset_neu';

offset_neu = (offset_L - offset_neu) / factor_neu;
factor_neu = factor_L * factor_neu;

end