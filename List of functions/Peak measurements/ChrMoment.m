function M = ChrMoment(XY, n)
%CHRMOMENT Compute chromatographic moments from an [X Y] signal.
%
% M = ChrMoment(XY)
% M = ChrMoment(XY, n)
%
% Inputs
% ------
% XY : N-by-2 numeric array, first column X, second column Y
% n  : number of moments to return, integer from 1 to 4, default 4
%
% Output
% ------
% M  : row vector containing:
%      M(1) = zeroth moment / area
%      M(2) = first normalized moment / centroid
%      M(3) = second central moment / variance-like term
%      M(4) = third central moment
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

if nargin < 2 || isempty(n)
    n = 4;
end

if ~isnumeric(XY) || ndims(XY) ~= 2 || size(XY, 2) ~= 2
    error('ChrMoment:InvalidInput', ...
        'XY must be an N-by-2 numeric array.');
end

if ~isnumeric(n) || ~isscalar(n) || ~ismember(n, 1:4)
    error('ChrMoment:InvalidOrder', ...
        'n must be an integer scalar between 1 and 4.');
end

if isempty(XY)
    M = NaN(1, n);
    return
end

X = XY(:, 1);
Y = XY(:, 2);

if ~isreal(X) || ~isreal(Y) || any(~isfinite(X)) || any(~isfinite(Y))
    M = NaN(1, n);
    return
end

if numel(X) < 2
    M = NaN(1, n);
    return
end

A = trapz(X, Y);
M = NaN(1, n);
M(1) = A;

if n == 1
    return
end

if ~isfinite(A) || A == 0
    return
end

mu = trapz(X, X .* Y) / A;
M(2) = mu;

if n == 2
    return
end

c2 = trapz(X, (X - mu).^2 .* Y) / A;
M(3) = c2;

if n == 3
    return
end

c3 = trapz(X, (X - mu).^3 .* Y) / A;
M(4) = c3;
end