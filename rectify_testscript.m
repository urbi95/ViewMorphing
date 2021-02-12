img_L = imread('img/L2.JPG');
img_R = imread('img/R2.JPG');
[img_rect_L, img_rect_R] = rectify_images(T, R, img_R, img_L);