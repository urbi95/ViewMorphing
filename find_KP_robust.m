function [KP_robust_all] = find_KP_robust(E, KP_paare, epi_parameter)
    K = epi_parameter{1};
    tolerance = 0.0001;
    
    [x1, x2] = calibrate_hom(KP_paare, K);
    
    distances = sampson_dist(E, x1, x2);
    
    KP_robust_all = KP_paare(:,abs(distances) < tolerance);   
end