function [P1, P2] = rekonstruktion_Weltkoord(T, R, KP_paare, K)
% rekonstruktion rekonstruiert aus möglichen euklidischen Transformationen
% die Koordinaten der Punkte im Raum und gibt die physikalisch plausible
% Transformation, zusammen mit Tiefeninformationen und Weltkoordinaten der
% Korrespondenzpunkte, zurück.
% Inputs:
%    T - Translationsvektor
%    R - Rotationsmatrix
%    KP_paare - Korrespondenzpunktpaare
%    K - Kalibrierungsmatrix
%
% Outputs:
%    P1, P2 - Weltkoordinaten der Punkte in KP_paare

% Vorbereitung:
N = size(KP_paare, 2);

[x1, x2] = calibrate_hom(KP_paare, K);

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

lambda = [d1, d2];

% Berechne Weltkoordinaten der Korrespondenzpunkte:
P1 = [lambda(:,1) .* x1(1,:)', lambda(:,1) .* x1(2,:)', lambda(:,1) .* x1(3,:)']';
P2 = [lambda(:,2) .* x2(1,:)', lambda(:,2) .* x2(2,:)', lambda(:,2) .* x2(3,:)']';


end