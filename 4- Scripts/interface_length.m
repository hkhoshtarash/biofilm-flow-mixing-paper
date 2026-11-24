function result = interface_length(C, dx, dy, reference_length, level)
%INTERFACE_LENGTH Total arc length of all C=level contours and L*=L/L0.
% Rows follow y and columns follow x; dx, dy and L0 use the same length units.
% Uses contour (not contourc) to preserve the supplied legacy MATLAB method.
% NaN/Inf nodes are masked. No smoothing or clipping is applied.
if nargin < 5, level = 0.5; end
validateattributes(C, {'numeric'}, {'real','2d'});
if any(size(C) < 2) || ~any(isfinite(C(:)))
    error('Concentration must be at least 2x2 with some finite data.');
end
validateattributes(dx, {'numeric'}, {'real','scalar','finite','positive'});
validateattributes(dy, {'numeric'}, {'real','scalar','finite','positive'});
validateattributes(reference_length, {'numeric'}, {'real','scalar','finite','positive'});
validateattributes(level, {'numeric'}, {'real','scalar','finite'});
Z = double(C); Z(~isfinite(Z)) = NaN;
x = (1:size(C,2))*dx; y = (1:size(C,1))*dy;
f = figure('Visible','off');
cleanup = onCleanup(@() close(f)); %#ok<NASGU>
ax = axes('Parent', f);
contours = contour(ax, x, y, Z, [level level]);
k = 1; lengths = zeros(0,1);
while k <= size(contours,2)
    n = contours(2,k);
    if n < 1 || n ~= floor(n) || k+n > size(contours,2)
        error('Invalid contour header.');
    end
    points = contours(:,k+(1:n));
    delta = diff(points,1,2);
    lengths(end+1,1) = sum(sqrt(sum(delta.^2,1))); %#ok<AGROW>
    k = k+n+1;
end
result.length = sum(lengths);
result.L_star = result.length/reference_length;
result.n_contours = numel(lengths);
result.segment_lengths = lengths;
end
