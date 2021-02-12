function [x1, x2] = calibrate_hom(KP_paare, K)
% Funktion zur Kalibrierung/Homogenisierung
    num_points = size(KP_paare,2);
    x1 = [KP_paare(1:2, :); ones(1,num_points)];
    x2 = [KP_paare(3:4, :); ones(1,num_points)];
    
    x1 = K \ x1;    %opt6: nur inv(K) übergeben
    x2 = K \ x2;
end