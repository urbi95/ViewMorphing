function s = get_ransac_iterations(p, p_aus, k)
    % get_ransac_iterations berechnet, wie viele Iterationen der
    % RanSaC-Algorithmus mindestens braucht, um mit einer
    % Wahrscheinlichkeit von mind. p eine Konsensmenge ohne Ausrei�er
    % zur�ckzugeben.
    %
    % Inputs:
    %   p - Wahrscheinlichkeit, siehe Beschreibung oben
    %   p_aus - Wahrscheinlichkeit f�r ein KP-Paar, ein Ausrei�er zu sein
    %   k - Anzahl an Punkten, die f�r eine Iteration des
    %       RanSaC-Algorithmus verwendet werden
    % Outputs:
    %   s - Mindestanzahl an Iterationen
    
    s = ceil(log(1 - p) / log(1 - (1 - p_aus)^k));
end