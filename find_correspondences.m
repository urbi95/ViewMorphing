function [KP_paare] = find_correspondences(merkmale_L, merkmale_R, image_L, image_R, corres_parameter, debugActive)
% find_correspondences - Ordnet Merkmalen Korrespondenzen zu.
% Berechnungsvorschrift: NCC
% Inputs:
%    merkmale_L - Merkmale des linken Bildes
%    merkmale_R - Merkmale des rechten Bildes
%    image_L - linkes Originalbild
%    image_R - rechtes Originalbild
%    corres_parameter - Parameter für die Korrespondenzpunktschätzung
%           window_length - Größe des Bildausschnitts zum Vergleichen
%           min_corr - Schwellwert für die Korrelation
%
% Outputs:
%    KP_paare - [x,y] Koorinaten der gefundenen Korrespondenzpunktpaare in der Form
%               [x1, ... ;
%                y1, ... ;
%                x2, ... ;
%                y2, ... ]

window_length = corres_parameter{1};
min_corr = corres_parameter{2};

% Sicherstellen, dass der Abstand zum Rand eingehalten wird % opt4: In
% eigene Funktion packen mit merkmale_L/R als Parameter und Rückgabe
dist = (window_length-1)/2;
merkmale_L(merkmale_L <= [dist; dist]) = 0;
merkmale_L(merkmale_L >= [size(image_L,2) - dist; size(image_L,1) - dist]) = 0;
merkmale_R(merkmale_R <= [dist; dist]) = 0;
merkmale_R(merkmale_R >= [size(image_R,2) - dist; size(image_R,1) - dist]) = 0;
merkmale_L = merkmale_L(:, all(logical(merkmale_L),1));
merkmale_R = merkmale_R(:, all(logical(merkmale_R),1));

% Normierung der Fenster
Mat_feat_1  = zeros(window_length^2, size(merkmale_L,2));
Mat_feat_2  = zeros(window_length^2, size(merkmale_R,2));

for i = 1:size(merkmale_L,2)
    x = merkmale_L(1,i);
    y = merkmale_L(2,i);
    w = double(image_L(y-dist:y+dist, x-dist:x+dist));
    w = w - sum(w(:)) / window_length^2;
    w = w/sqrt(var(w(:)));
    
    Mat_feat_1(:,i) = w(:);
end

for i = 1:size(merkmale_R,2)
    x = merkmale_R(1,i);
    y = merkmale_R(2,i);
    w = double(image_R(y-dist:y+dist, x-dist:x+dist));
    w = w - sum(w(:)) / window_length^2;
    w = w/sqrt(var(w(:)));
    
    Mat_feat_2(:,i) = w(:);
end

% NCC Berechnung
NCC_matrix = 1/(window_length^2 - 1)*(Mat_feat_2'*Mat_feat_1);
NCC_matrix(NCC_matrix < min_corr) = 0;

v = NCC_matrix(:);
v(v==0) = [];

[~,sorted_index] = sort(NCC_matrix(:),'descend');
sorted_index = sorted_index(1:length(v));

% Zuordnung der Korrespondenzen nach NCC
KP_paare = zeros(4, min(size(merkmale_L,2),size(merkmale_R,2)));

i = 1;
count_corr = 1;
size_corr = size(NCC_matrix,1);

while any(any(NCC_matrix ~= 0))
    index = sorted_index(i);
    if NCC_matrix(index) ~= 0
        x = ceil(index/size_corr);
        y = index - (x-1)*size_corr;
        NCC_matrix(:,x) = 0;
        KP_paare(:,count_corr) = [merkmale_L(:,x);merkmale_R(:,y)];
        count_corr = count_corr + 1;
    end
    i = i + 1;
end

KP_paare = KP_paare(:,1:count_corr - 1);

%% debugging
if debugActive
figure;
hold on
title('Gefundene KP-Paare');
Image = image_L./2 + image_R./2;
imshow(Image);
hold on;
for i = 1:size(KP_paare, 2)
    plot(KP_paare(1,i),KP_paare(2,i), 'o', 'MarkerEdgeColor', 'r');
    hold on;
    plot(KP_paare(3,i),KP_paare(4,i), 'o', 'MarkerEdgeColor', 'b');
    hold on;
    line([KP_paare(1,i),KP_paare(3,i)], [KP_paare(2,i),KP_paare(4,i)],'Color', 'green');
    hold on;
end
end

end