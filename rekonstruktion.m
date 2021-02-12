function [T, R, lambda] = rekonstruktion(T1, T2, R1, R2, KP_paare, K)
%rekonstruktion rekonstruiert aus möglichen euklidischen Transformationen
%die Koordinaten der Punkte im Raum und gibt die physikalisch plausible
%Transformation, zusammen mit Tiefeninformationen und Weltkoordinaten der
%Korrespondenzpunkte, zurück.
% Inputs:
%    T1, T2 - mögliche Translationsvektoren
%    R1, R2 - mögliche Rotationsmatrizen
%    KP_paare - Korrespondenzpunktpaare
%    K - Kalibrierungsmatrix
%
% Outputs:
%    T - Verschiebungsvektor (3x1)
%    R - Rotationsmatrix (3x3)
%    lambda - Tiefeninformationen [d1, d2] der Korrespondenzpunkte

% Vorbereitung:
N = size(KP_paare, 2);

T_cell = {T1, T2, T1, T2};
R_cell = {R1, R1, R2, R2};
d_cell = {zeros(N, 2), zeros(N, 2), zeros(N, 2), zeros(N, 2)};

[x1, x2] = calibrate_hom(KP_paare, K);

% Bestimmung der 
positives_count = 0;
positives_ind = 0;

for i=1:4
    T = T_cell{i};
    R = R_cell{i};
    M1 = zeros(3*N, N+1); M2 = zeros(3*N, N+1);
    
    for k=1:N
        x1_hat = [0 -x1(3,k) x1(2,k);
            x1(3,k) 0 -x1(1,k);
            -x1(2,k) x1(1,k) 0];
        x2_hat = [0 -x2(3,k) x2(2,k);
            x2(3,k) 0 -x2(1,k);
            -x2(2,k) x2(1,k) 0];
        
        M1(3*(k-1) + (1:3), k) = x2_hat * R * x1(:,k);
        M1(3*(k-1) + (1:3), N+1) = cross(x2(:,k), T);
        
        M2(3*(k-1) + (1:3), k) = x1_hat * R' * x2(:,k);
        M2(3*(k-1) + (1:3), N+1) = -cross(x1(:,k), R' * T);
    end
    
    [~, ~, V1] = svd(M1);
    [~, ~, V2] = svd(M2);
    d1 = V1(1:end - 1, end) / V1(end);
    d2 = V2(1:end - 1, end) / V2(end);
    
    d_cell{i} = [d1, d2];
    positives_here = sum(d1 > 0) + sum(d2 > 0);
    if positives_here > positives_count
        positives_count = positives_here;
        positives_ind = i;
    end
end
T = T_cell{positives_ind};
R = R_cell{positives_ind};
lambda = d_cell{positives_ind};

end