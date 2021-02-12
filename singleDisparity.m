function [disparity_map] = singleDisparity(img_L, img_R, disp_parameter)
% disparity - Berechnet die Disparitymap zweier Stereobilder (Methode
% wählbar)
%
% Inputs:
%   img_L - Linkes Stereobild
%   img_R - Rechtes Stereobild
%   disp_parameter - Cell-Array {r, window_range, Methode}
%        r - Radius des Vergleichsfensters (Standardwert: 3)
%        window_range - Um diese Breite wird das Vergleichsfenster verschoben (Standardwert: 101)
%        Methode - Methode mit der die Fenster verglichen werden (Standardwert: 2)
%           1 - Zeilenvergleich
%           2 - quadratisches Vergleichsfenster
%           3 - Vergleichsfenster mit 2D-Gaußfunktion
%           4 - Radius des Vergleichsfensters wird angepasst
%
% Outputs:
%    disparity_map - Abstand des Vergleichsfensters mit der höchsten
%                    Übereinstimmung

% Sicherstellen, dass Bilder im double Format sind
img_L = double(img_L);
img_R = double(img_R);

% Bildbreite und Bildhöhe (Für R&L gleich)
img_width = size(img_L,2);
img_height = size(img_L,1);

% Disparityparameter aus Cell-Array auslesen
r = disp_parameter{1};
Verschiebung = disp_parameter{2};
Methode = disp_parameter{3};
% Abstand des Mittelpunktes von den Rändern der Verschiebung
border_dist = (Verschiebung-1)/2;

% 3D-Matrix in der die quadratischen Differenzen der beiden Bilder, bei
% unterschiedlichen Verschiebungen gespeichert werden.
disparities = NaN(img_height, img_width, Verschiebung);

% In dieser Schleife wird die Matrix disparities berechnet
for i = 1:1:Verschiebung
    % Fall, dass linkes Bild durch die Verschiebung am linken Rand übersteht
    if i <= border_dist + 1
        a = img_L(:,1:1:end - border_dist - 1 + i, :);
        b = img_R(:,border_dist +2 - i:1:end,:);
        c = nansum((a-b).^2,3);
        
        disparities(:,1:1:end - border_dist - 1 + i, i) = c;
    % Fall, dass linkes Bild durch die Verschiebung am rechten Rand übersteht    
    else
        a = img_L(:,i - border_dist:1:end,:);
        b = img_R(:,1:1:end - (i - border_dist - 1), :);
        c = nansum((a-b).^2,3);
        
        disparities(:,i - border_dist:1:end, i) = c;
        
    end
    
end

% Methoden Auswahl mit der die disparity-Matrix ausgewertet wird
switch Methode
    
    % Methode 1: Zeilenvergleich
    case 1
        
        NaN_Rand = NaN(size(disparities,1),size(disparities,2) + 2*r,size(disparities,3));
        NaN_Rand(:, 1+r:1:end-r, :) = disparities;
        disparities = NaN_Rand;
        
        disparity_map = zeros(img_height, img_width);
        
        for i = 1+r:1:img_width-r
            
            disp_balken = disparities(:, i-r:1:i+r, :);
            disp_balken = sum(disp_balken,2);
            % Gibt den Index des minimalen Wertes in disp zurück
            [~, I] = min(disp_balken,[],3);
           
            disparity_map(:,i-r) = Verschiebung-I;
            
        end
        
    % Methode 2: quadratisches Vergleichsfenster
    case 2

        disparity_map = zeros(img_height, img_width);
        
        for x = 1+r:1:img_width-r
            for y = 1+r:1:img_height-r
                
                % Vergleichsfenster ausschneiden
                disp = disparities(y-r:1:y+r,x-r:1:x+r,:);
                % Alle Werte eines Fensters aufsummieren
                disp = sum(sum(disp,1),2);
                % Gibt den Index des minimalen Wertes in disp zurück
                [~, I] = min(disp,[],3);
                
                disparity_map(y,x) = Verschiebung - I;
                
            end
        end
        
        
    % Methode 3: quadratisches Vergleichsfenster mit 2D-Gaußfunktion
    case 3
        [X,Y] = meshgrid(-r:r, -r:r);
        EW = 0;
        sigma = 0.5;
        PI = 3.1415;
        g = @(x) (1/sqrt(2*PI*sigma^2))*exp(-((x-EW).^2)/2*sigma^2);
        % Maske mit Gaußfilter
        mask = g(X).*g(Y);
        
        disparity_map = zeros(img_height, img_width);
        
        for x = 1+r:1:img_width-r
            for y = 1+r:1:img_height-r
                
                disp = disparities(y-r:1:y+r,x-r:1:x+r,:);
                disp = disp.*mask;
                % Alle Werte eines Fensters aufsummiere
                disp = sum(sum(disp,1),2);
                % Gibt den Index des minimalen Wertes in disp zurück
                [~, I] = min(disp,[],3);
                
                disparity_map(y,x) = Verschiebung-I;
                
            end
        end
        
        
    % Methode 4: variabler Radius
    case 4        
         % Approximation der Bildgradienten jedes Farbkanals in x-Richtung
        Ix_r = sobel_xy(img_L(:,:,1));
        Ix_g = sobel_xy(img_L(:,:,2));
        Ix_b = sobel_xy(img_L(:,:,3));
        
        % Addition der einzelnen Bildgradienten der drei Grundfarben
        Kanten = abs(Ix_r) + abs(Ix_g) + abs(Ix_b);
        
        % Beeinflusst die Wahl des Fensterradius
        threshold = 5000;
        
        disparity_map = zeros(img_height, img_width);
        
        rmax = r;
        
        for x = 1+rmax:1:img_width-rmax
            for y = 1+rmax:1:img_height-rmax
                                
                for i = 1:1:rmax
                r = i;
                if sum(sum(Kanten(y-i:1:y+i,x-i:1:x+i))) > threshold
                break
                end 
               
                end
                
                disp = disparities(y-r:1:y+r,x-r:1:x+r,:);
                % Alle Werte eines Fensters aufsummieren
                disp = sum(sum(disp,1),2);
                % Gibt den Index des minimalen Wertes in disp zurück
                [~, I] = min(disp,[],3);
                
                disparity_map(y,x) = Verschiebung - I;
                
            end
        end
end
end


function [Fx] = sobel_xy(input_image)
% Berechnet den horizontalen und vertikalen Bildgradienten

    sobel = [1,2,1;0,0,0;-1,-2,-1]; %opt 1: variable Größe des Filters

    Fx = conv2(input_image, sobel','same');    
end





