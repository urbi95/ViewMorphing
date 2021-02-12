function [merkmale] = harris_detector(image, harris_parameter, debugActive)
% harris_detector - Extrahiert Merkmale nach dem Harris-Kriterium
% Inputs:
%    image - Bild in dem Merkmale erkannt werden sollen
%    harris_parameter - Cell-Array {segment_length, k, epsilon}
%        segment_length - steuert die Groesse des Bildsegments
%        (Standardwert: 15)
%        k - Parameter innerhalb von ]0, 0.5[ (Standardwert: 0,05)
%        epsilon - Schwellwert für kleine Werte (Standardwert: 1e6)
%        min_dist - minimaler Pixelabstand zweier Merkmale (Standardwert: 20)
%        tile_size - Kachelgröße (1x2 Vektor, Standardwert: [200, 200])
%        N - maximale Anzahl an Merkmalen innerhalb einer Kachel (Standardwert: 5)
%
% Outputs:
%    merkmale - [x,y] Koorinaten der gefundenen Merkmalspunkte in der Form
%               [x1, x2, ... ;
%                y1, y2, ... ]


% "Entpacken" der harris_parameter
segment_length = harris_parameter{1};
k = harris_parameter{2};
epsilon = harris_parameter{3};
min_dist = harris_parameter{4};
tile_size = harris_parameter{5};
N = harris_parameter{6};

% Falls 'image' kein Schwarzweißbild -> konvertieren
gray_image = rgb_to_gray(image);    %opt 7: Aufteilen der Bilder in 3-Grundfarben

gray_image = double(gray_image);    %opt 2: konvertierung in double nötig? bzw. rgb_to_gray ausgabe in double

% Approximation des Bildgradienten
[Ix,Iy] = sobel_xy(gray_image);

% Gewichtung innerhalb des Bildausschnitts
var = ((segment_length - 1)^2)/12;
i = -(segment_length - 1)/2 : 1 : (segment_length - 1)/2;
w = exp(-((i.^2)/(2*var)));
w = w/sum(w);

% Harris Matrix G
G11 = conv2(Ix.^2, w'*w, 'same');
G22 = conv2(Iy.^2, w'*w, 'same');
G12 = conv2(Ix.*Iy, w'*w, 'same');

% Merkmalsextraktion über das Harris-Kriterium
H = G11.*G22 - G12.^2 - k*(G11 + G22).^2;
% Finde Werte größer als Schwellwert
corners = H.*(H > epsilon);

% Kreisförmiger Abstandsfilter zum Pixel im Mittelpunkt
[X,Y] = meshgrid(-min_dist:min_dist, -min_dist:min_dist);
cake_matrix = X.^2 + Y.^2 > min_dist^2;
% Nullrand einfügen
corners = [zeros(size(corners, 1), min_dist), corners, zeros(size(corners, 1), min_dist)];
corners = [zeros(min_dist, size(corners, 2)); corners; zeros(min_dist, size(corners, 2))];
% Merkmale der Größe nach sortieren
[~,sorted_index] = sort(corners(:), 'descend');
sorted_index(sum(sum(corners ~= 0)) + 1 : end) = [];

% zählt Merkmale pro Kachel
AKKA = zeros(ceil(size(gray_image,1)/tile_size(1)), ceil(size(gray_image,2)/tile_size(2)));
merkmale = zeros(2, min(N*size(AKKA,1)*size(AKKA,2), length(sorted_index)));
% Indexumrechnung in Spalten und Zeilen
x = ceil(sorted_index/size(corners,1));
y = sorted_index - (x-1)*size(corners,1);
% Gibt an in welcher Kachel der Punkt liegt
field = [ceil((y-min_dist)/tile_size(1)), ceil((x-min_dist)/tile_size(2))];
% Zähler für die Anzahl der Merkmale
nr_merkmal = 1;

for k = 1:length(sorted_index)
    if corners(sorted_index(k)) > 0 %opt 3: if-Schleife notwendig?
%         x = ceil(sorted_index(k)/size(corners,1));
%         y = sorted_index(k) - (x-1)*size(corners,1);        
%         field = [ceil((y-min_dist)/tile_size(1)), ceil((x-min_dist)/tile_size(2))];
        
        if AKKA(field(k,1),field(k,2)) < N
            merkmale(:,nr_merkmal) = [x(k)-min_dist;y(k)-min_dist];
            prev_value = corners(sorted_index(k));
            corners(y(k)-min_dist:y(k)+min_dist, x(k)-min_dist:x(k)+min_dist) = ...
                corners(y(k)-min_dist:y(k)+min_dist, x(k)-min_dist:x(k)+min_dist) .* cake_matrix;
            corners(sorted_index(k)) = prev_value;
            AKKA(field(k,1),field(k,2)) = AKKA(field(k,1),field(k,2)) + 1;
            nr_merkmal = nr_merkmal + 1;
        else
            corners(y(k),x(k)) = 0;
        end
        
    end
end

merkmale = merkmale(:, 1:nr_merkmal-1);

%% debugging
if debugActive
    figure;
    hold on;
    title('Merkmale Harrisdetektor')
    imshow(image);
    hold on;
    scatter(merkmale(1,:),merkmale(2,:),'g');
end

end


function gray_image = rgb_to_gray(input_image)
% Konvertiert das input_image in ein Schwarzweißbild im uint8-Format
    
    imsize = size(input_image);
    
    if length(imsize) == 2
        gray_image = input_image;
        return;
    end
    
    input_image = double(input_image);
    
    R = input_image(:,:,1);
    G = input_image(:,:,2);
    B = input_image(:,:,3);
    
    gray_image = double(0.299)*R+double(0.587)*G+double(0.114)*B;
    gray_image = uint8(gray_image);  

end

function [Fx, Fy] = sobel_xy(input_image)
% Berechnet den horizontalen und vertikalen Bildgradienten

    sobel = [1,2,1;0,0,0;-1,-2,-1]; %opt 1: variable Größe des Filters

    Fx = conv2(input_image, sobel','same');
    Fy = conv2(input_image, sobel,'same');
    
end