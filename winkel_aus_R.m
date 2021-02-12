function [ winkel_x, winkel_y, winkel_z ] = winkel_aus_R( R )
% winkel_aus_R berechnet aus einer Rotationsmatrix R die Winkel, durch die R
% wie folgt rekonstruiert werden kann:
% Es seien M_x, M_y und M_z die Rotationsmatrizen zur Rotation um die x-,
% y- bzw. z-Achse um den Winkel winkel_x, winkel_y bzw. winkel_z. Dann gilt
% R = M_z * M_y' * M_x (man achte auf das Transponieren von M_y!).
% Z.B. M_x definiere ich als
%       [1 0              0;
%        0 cos(winkel_x) -sin(winkel_x);
%        0 sin(winkel_x)  cos(winkel_x)],
% M_y und M_z analog.
% Der nachfolgende Code ist aus
% 'http://www.gregslabaugh.net/publications/euler.pdf' übernommen.
%
% Inputs:
%    R - beliebige Rotationsmatrix
%
% Outputs:
%    winkel_x, winkel_y, winkel_z - Winkel um die jeweiligen Achsen mit
%                                   obiger Eigenschaft


if (abs(R(3,1)) ~= 1)
    % In diesem Fall erhält man zwei mögliche Ergebnisse, deshalb jeweils
    % eins auskommentiert.
    theta_1 = -asin(R(3,1));
    %theta_2 = pi - theta_1;
    psi_1 = atan2(R(3,2) / cos(theta_1), R(3,3) / cos(theta_1));
    %psi_2 = atan2(R(3,2) / cos(theta_2), R(3,3) / cos(theta_2));
    phi_1 = atan2(R(2,1) / cos(theta_1), R(1,1) / cos(theta_1));
    %phi_2 = atan2(R(2,1) / cos(theta_2), R(1,1) / cos(theta_2));
    winkel_x = psi_1; winkel_y = theta_1; winkel_z = phi_1;
    %winkel_x = psi_2; winkel_y = theta_2; winkel_z = phi_2;
else
    phi = 0;
    if (R(3,1) == -1)
        theta = pi/2;
        psi = atan2(R(1,2), R(1,3));
    else
        theta = -pi/2;
        psi = atan2(-R(1,2), -R(1,3));
    end
    winkel_x = psi; winkel_y = theta; winkel_z = phi;
end

end

