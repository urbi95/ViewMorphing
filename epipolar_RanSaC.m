function [E, KP_robust] = epipolar_RanSaC(KP_paare, epi_parameter, K)
% epipolar_RanSaC - Berechnet Essentielle Matrix mit RanSaC-Methode
% (Manuelle Korrespondenzpaarüberprüfung)
% Inputs:
%    KP_paare - Korrespondenzpunktpaare
%    epi_parameter - Parameter für RanSaC-Schätzung der Essentiellen Matrix
%
% Outputs:
%    E - Essentielle Matrix
%    KP_robust - robuste KP-Paare aus RanSaC Methode

s = epi_parameter{2};
k = epi_parameter{3};
tolerance = epi_parameter{4};


largest_set_size = 0;
largest_set_dist = Inf;
largest_set_E = zeros(3);

num_points = size(KP_paare, 2);

% Kalibriere Punkte
[x1, x2] = calibrate_hom(KP_paare, K);

for i = 1:s
    
    samples = randperm(num_points, k);
    
    x1_test = x1(:,samples);
    x2_test = x2(:,samples);
    
    E = achtpunktalgorithmus(x1_test, x2_test);
    
    distances = sampson_dist(E, x1_test, x2_test);
    
    consensus_set = distances < tolerance;
    
    set_dist = sum(distances(consensus_set));
    set_size = sum(consensus_set);
    
    if set_size > largest_set_size
        KP_robust = KP_paare(:, samples(consensus_set));
        largest_set_size = set_size;
        largest_set_dist = set_dist;
        largest_set_E = E;
    elseif set_size == largest_set_size && set_dist < largest_set_dist
        KP_robust = KP_paare(:, samples(consensus_set));
        largest_set_dist = set_dist;
        largest_set_E = E;
    end
    
end

E = largest_set_E;

end

% Berechnet die Essentielle Matrix
function [E] = achtpunktalgorithmus(x1, x2)

%     num_points = size(Korrespondenzen,2);
%     x1 = [Korrespondenzen(1:2, :); ones(1,num_points)];
%     x2 = [Korrespondenzen(3:4, :); ones(1,num_points)];
%     
%     x1 = K \ x1;
%     x2 = K \ x2;
    
    num_points = size(x1, 2);
    A = zeros(num_points, 9);
    
    for i = 1:num_points
        A(i,:) = kron(x1(:,i),x2(:,i))';
    end
    
    [~,~,V] = svd(A);
    
    G = V(:,end);
    G = reshape(G, [3,3]);
    
    [U, S, V] = svd(G);
    
    S(1,1) = 1;
    S(2,2) = 1;
    
    S(end) = 0;
    
    E = U * S * V';
end