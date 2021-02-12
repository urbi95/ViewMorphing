function sd = sampson_dist(F, x1_pixel, x2_pixel)

    Fx1 = F * x1_pixel;
    Fx2 = F' * x2_pixel;
    
    sd = dot(x2_pixel, F * x1_pixel, 1).^2 ./ (Fx1(1,:).^2 + Fx1(2,:).^2 + Fx2(1,:).^2 + Fx2(2,:).^2);    
end