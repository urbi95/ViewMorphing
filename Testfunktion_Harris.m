segment_length = 15;
k = 0.05;
epsilon = 1e5;
min_dist = 20;
tile_size = [200,200];
N = 10;

harris_merkmale = {segment_length, k, epsilon, min_dist, tile_size, N};

img1 = imread('Testbilder/Test_L.png');
img2 = imread('img/L1.JPG');

img1 = rgb_to_gray(img1);

imshow(img1);
hold on
tic
[merkmale] = harris_detector(img1, harris_merkmale);
toc
plot(merkmale(1,:),merkmale(2,:),'o');


function gray_image = rgb_to_gray(input_image)
% Konvertiert das input_image in ein Schwarzweiﬂbild im uint8-Format
    
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