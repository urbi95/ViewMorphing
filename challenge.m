%% Computer Vision Challenge
clear
close all
% Groupnumber:
group_number = 56;

% Groupmembers:
% members = {'Max Mustermann', 'Johannes Daten'};
members = {'Fabian Kapfer', 'Simon Urbainczyk', 'Maximilian Zimmer', 'David Zeltsperger', 'Johannes Limmer'};

% Email-Adress (from Moodle!):
% mail = {'ga99abc@tum.de', 'daten.hannes@tum.de'};
mail = {'ga65qah@tum.de', 'ga38rim@mytum.de', 'ga53fok@mytum.de', 'ga97rin@mytum.de', 'ga54neg@mytum.de'};

%% Load images
% img_L = imread('img/img_L3.jpg');
% img_R = imread('img/img_R3.jpg');
img_L = imread('img/L1.JPG');
img_R = imread('img/R1.JPG');
% img_L = imread('img/img_mucklas_L.jpg');
% img_R = imread('img/img_mucklas_R.jpg');

% img_L = imread('Testbilder/Test_L.png');
% img_R = imread('Testbilder/Test_R2.png');

%% Harrisparameter initialisieren (GUI-Abfrage)
segment_length = 9;
k = 0.05;
epsilon = 0.5e6;
min_dist = 20;
tile_size = [25,25];
N = 10;

harris_parameter = {segment_length, k, epsilon, min_dist, tile_size, N};

%% Korrespondenzpunktschätzung-Parameter
window_length = 25;
min_corr = 0.95;
plot_corr = false;


corres_parameter = {window_length, min_corr, plot_corr};

%% Parameter für RanSaC-Schätzung der Essentiellen Matrix
f = 3.957623257412620e+03; % Brennweite aus Angabe
k = 12;
s = get_ransac_iterations(0.5, 0.5, k);
tolerance = 0.01;
epi_parameter = {f, s, k, tolerance};

%% Parameter für die Disparitymap
r = 7;    % positiv
window_range = 301; % ungerade und positiv
Methode = 4;
thresholdDisparityDifference = 4;

disp_parameter = {r, window_range, Methode, thresholdDisparityDifference};

%% Free Viewpoint Rendering
% start execution timer
tic;
p = 0.5;
output_image = free_viewpoint(img_L, img_R, p, harris_parameter, ...
   corres_parameter, epi_parameter, disp_parameter, f);

% stop execution timer
elapsed_time = toc;


%% Display Output
% Display Virtual View


