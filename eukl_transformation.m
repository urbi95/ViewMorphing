function [ T, R ] = eukl_transformation( E, KP_robust, K )
% eukl_transformation berechnet aus gegebener Essentieller Matrix E die
% zugehörige, physikalisch sinnvolle Euklidische Transformation [R, T].
%
% Inputs:
%    E - Essentielle Matrix
%    KP_robust - Punkte, mit denen E bestimmt wurde
%    K - Kalibrierungsmatrix
%
% Outputs:
%    R - Rotationsmatrix (3x3)
%    T - Verschiebungsvektor (3x1)

[U, S, V] = svd(E);
if abs(det(U) + 1) < 0.5
    U(:,3) = -U(:,3);
end
if abs(det(V) + 1) < 0.5
    V(:,3) = -V(:,3);
end

RZ = [0 -1 0; 1 0 0; 0 0 1];
R1 = U * RZ' * V';
T1 = U * RZ * S * U';
T1 = [T1(6); -T1(3); T1(2)];

RZ = -RZ; RZ(end) = 1;
R2 = U * RZ' * V';
T2 = U * RZ * S * U';
T2 = [T2(6); -T2(3); T2(2)];

[T, R, ~] = rekonstruktion(T1, T2, R1, R2, KP_robust, K);

end

