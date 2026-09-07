function peakList = LocalMaxima(XY, halfWindow)
%LOCALMAXIMA Detect local maxima and refine apex positions by quadratic interpolation.
%
% peakList = LocalMaxima(XY, halfWindow)
%
% Inputs
% ------
% XY         : N-by-2 numeric array [x intensity]
% halfWindow : nonnegative integer, number of neighbors on each side
%
% Output
% ------
% peakList   : M-by-4 numeric array
%              peakList(:,1) = refined apex position
%              peakList(:,2) = refined apex intensity
%              peakList(:,3) = index of detected discrete local maximum
%              peakList(:,4) = index of closest original sample to refined apex
%
% BSD 3-Clause License
%
% Copyright (c) 2026, G. Erny
% All rights reserved.
%
% Author: G. Erny
% Email: guillaume.erny@gmail.com
%
% This file was developed with assistance from Perplexity AI and then
% reviewed, adapted, and integrated by G. Erny.

if nargin < 2 || isempty(halfWindow)
    halfWindow = 1;
end

if ~isnumeric(XY) || ndims(XY) ~= 2 || size(XY, 2) ~= 2
    error('LocalMaxima:InvalidInput', ...
        'XY must be an N-by-2 numeric array.');
end

if ~isnumeric(halfWindow) || ~isscalar(halfWindow) || ...
        halfWindow < 0 || halfWindow ~= floor(halfWindow)
    error('LocalMaxima:InvalidWindow', ...
        'halfWindow must be a nonnegative integer scalar.');
end

x = XY(:, 1);
y = XY(:, 2);
nPoints = size(XY, 1);

if nPoints < 3
    peakList = zeros(0, 4);
    return
end

if any(~isfinite(x)) || any(~isfinite(y))
    error('LocalMaxima:NonFiniteData', ...
        'XY must contain only finite values.');
end

neighborMatrix = zeros(nPoints, 2 * halfWindow + 1);
for col = 1:(2 * halfWindow + 1)
    idxStart = max(1, halfWindow + 2 - col);
    idxEnd = min(nPoints, nPoints + halfWindow + 1 - col);
    neighborMatrix(nPoints - idxEnd + 1:nPoints - idxStart + 1, col) = y(idxStart:idxEnd);
end

isLocalMax = y >= max(neighborMatrix, [], 2);
isLocalMax(1) = false;
isLocalMax(end) = false;

candidateIndex = find(isLocalMax);

if isempty(candidateIndex)
    peakList = zeros(0, 4);
    return
end

keepCandidate = true(size(candidateIndex));
for ii = 2:numel(candidateIndex)
    if candidateIndex(ii) == candidateIndex(ii - 1) + 1
        if y(candidateIndex(ii)) > y(candidateIndex(ii - 1))
            keepCandidate(ii - 1) = false;
        else
            keepCandidate(ii) = false;
        end
    end
end
candidateIndex = candidateIndex(keepCandidate);

maxPeaks = numel(candidateIndex);
peakList = NaN(maxPeaks, 4);

nPeaks = 0;
for ii = 1:maxPeaks
    idx = candidateIndex(ii);

    x1 = x(idx - 1); x2 = x(idx); x3 = x(idx + 1);
    y1 = y(idx - 1); y2 = y(idx); y3 = y(idx + 1);

    if numel(unique([x1 x2 x3])) < 3
        continue
    end

    coeff = polyfit([x1 x2 x3], [y1 y2 y3], 2);
    a = coeff(1);
    b = coeff(2);

    if ~isfinite(a) || a >= 0
        continue
    end

    refinedX = -b / (2 * a);
    if refinedX < min([x1 x2 x3]) || refinedX > max([x1 x2 x3])
        continue
    end

    refinedY = polyval(coeff, refinedX);
    if ~isfinite(refinedY)
        continue
    end

    [~, idxClosest] = min(abs(x - refinedX));

    nPeaks = nPeaks + 1;
    peakList(nPeaks, :) = [refinedX, refinedY, idx, idxClosest];
end

peakList = peakList(1:nPeaks, :);
end