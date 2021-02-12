clc
clear

img_L = imread('img/cones_left.png');
img_R = imread('img/cones_right.png');


% Bilder in Graubilder konvertieren
% img_Lg = rgb_to_gray(img_L);
% img_Rg = rgb_to_gray(img_R);

window_size = 7;    %Fenstergröße des Vergleichfensters (Window-Size)
cloud_size = 7;
max_disp = 701;
border = (window_size - 1) / 2;
verschiebung = 39;
hom_value = 100;
disp = 0;

img_L = img_L(:, verschiebung + 1:end,:);
img_R = img_R(:, 1:size(img_L,2),:);

width = floor(size(img_R,2)/cloud_size);
height = floor(size(img_R,1)/cloud_size);

% speichert die Abstände der zugeordneten Fenster
disparity = zeros(height, width);

width = width*cloud_size;
height = height*cloud_size;

img_R = img_R(1:1:height, 1:1:width,:);
img_L = img_L(1:1:height, 1:1:width,:);

figure;
Image = img_L./2 + img_R./2;
imshow(Image);
hold on;


% img_Lg = [zeros(size(img_Lg,1),border), img_Lg, zeros(size(img_Lg,1),border)];
% img_Lg = [zeros(border, size(img_Lg,2)); img_Lg; zeros(border, size(img_Lg,2))];
% 
% img_Rg = [zeros(size(img_Rg,1),border), img_Rg, zeros(size(img_Rg,1),border)];
% img_Rg = [zeros(border, size(img_Rg,2)); img_Rg; zeros(border, size(img_Rg,2))];

for y = 1+border:window_size:size(img_L,1)-border
   for x = 1+border:window_size:size(img_L, 2)-border
       
       window_search = img_L(y-border:1:y+border,x-border:1:x+border,:);   %Referenzfenster
       
       lim_low = x - (max_disp-1)/2;
       lim_high = x + (max_disp-1)/2;
       if lim_low < 1
           lim_low = 1+border;
       end
       if lim_high > size(img_L,2)
           lim_high = size(img_L,2)-border;
       end
       
       window_compare = Inf(1, lim_high - lim_low+1);
       k = 1;
   
       for i = lim_low:1:lim_high
          window_compare(k) = sum(sum(sum(abs(window_search - img_R(y-border:1:y+border, i-border:1:i+border,:)))));
          k = k+1;
       end
       
       [~,ys] = find(window_compare == min(window_compare));
       
       if x < (max_disp-1)/2
           center = x-border;
       else
           center = ((max_disp-1)/2) + 1;
       end
       
       ys = ys - center;
      
       disp = min(abs(ys));
             
       disparity((y+border)/window_size,(x+border)/window_size) = disp;
       
   end
end

figure
normalizedImage = uint8(255*mat2gray(disparity));
imshow(normalizedImage);

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