function s = get_ransac_iterations(p, p_aus, k)
    % get_ransac_iterations berechnet, wie viele Iterationen der
    % RanSaC-Algorithmus mindestens braucht, um mit einer
    % Wahrscheinlichkeit von mind. p eine Konsensmenge ohne Ausreißer
    % zurückzugeben.
    %
    % Inputs:
    %   p - Wahrscheinlichkeit, siehe Beschreibung oben
    %   p_aus - Wahrscheinlichkeit für ein KP-Paar, ein Ausreißer zu sein
    %   k - Anzahl an Punkten, die für eine Iteration des
    %       RanSaC-Algorithmus verwendet werden
    % Outputs:
    %   s - Mindestanzahl an Iterationen
    
    s = ceil(log(1 - p) / log(1 - (1 - p_aus)^k));
end