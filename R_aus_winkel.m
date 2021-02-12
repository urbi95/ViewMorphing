function [ R ] = R_aus_winkel( winkel_x, winkel_y, winkel_z )
% R_aus_winkel berechnet aus drei gegebenen Winkeln die zugehörige
% Rotationsmatrix. Diese Funktion ist das Gegenstück zu 'winkel_aus_R.m',
% für genauere Erklärungen der Variablen sei deshalb auf diese verwiesen.
%
% Inputs:
%    winkel_x, winkel_y, winkel_z - Winkel um die jeweiligen Achsen
% Outputs:
%    R - Rotationsmatrix

% Rotationsmatrizen um die einzelnen Achsen:
R_x = [1, 0, 0;
    0, cos(winkel_x), -sin(winkel_x);
    0, sin(winkel_x), cos(winkel_x)];
R_y = [cos(winkel_y), 0, -sin(winkel_y);
    0, 1, 0;
    sin(winkel_y), 0, cos(winkel_y)];
R_z = [cos(winkel_z), -sin(winkel_z), 0;
    sin(winkel_z), cos(winkel_z), 0;
    0, 0, 1];
% alles zusammen:
R = R_z * R_y' * R_x;

end

