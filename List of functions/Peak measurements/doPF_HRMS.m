function result = doPF_HRMS(XY, opts)
%DOPF_HRMS Estimate a baseline by asymmetric polynomial fitting.
%
% result = doPF_HRMS(XY)
% result = doPF_HRMS(XY, opts)
%
% Inputs
% ------
% XY   : N-by-2 numeric array [x signal]
% opts : name-value options
%
% Options
% -------
% PolynomialDegree       : degree of the polynomial baseline, default 2
% NegativeResidualPower  : exponent applied to residuals below the baseline,
%                          default 2
% MaxFitIterations       : maximum number of repeated fminsearch calls when
%                          convergence is not achieved, default 2
% MaxOutlierIterations   : maximum iterations for residual outlier removal,
%                          default 10
% Display                : optimset Display option, default "off"
%
% Output
% ------
% result : structure with fields
%   .Baseline
%   .IsBaselineOutlier
%   .PolynomialCoefficients
%   .Residual
%   .IsValid
%   .IsRetained
%   .UsedXY
%   .Options
%   .Optimization
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
arguments
    XY (:,2) double
    opts.PolynomialDegree (1,1) double {mustBeInteger, mustBeNonnegative} = 2
    opts.NegativeResidualPower (1,1) double {mustBePositive, mustBeFinite} = 2
    opts.MaxFitIterations (1,1) double {mustBeInteger, mustBePositive} = 3
    opts.MaxOutlierIterations (1,1) double {mustBeInteger} = 3
    opts.Display (1,1) string {mustBeMember(opts.Display, ["off","iter","notify","final"])} = "off"
end

x = XY(:, 1);
y = XY(:, 2);

isValid = isfinite(x) & isfinite(y);
fitXY = XY(isValid, :);

if size(fitXY, 1) < opts.PolynomialDegree + 1
    error('doPF_HRMS:NotEnoughPoints', ...
        'At least PolynomialDegree + 1 finite points are required.');
end

optimOptions = optimset('Display', char(opts.Display));

nInliersPrevious = -1;
initialCoeff = polyfit(fitXY(:, 1), fitXY(:, 2), opts.PolynomialDegree);
[polyCoeff, fval, exitflag, output] = fminsearch(@localObjective_DoPF_HRMS, initialCoeff, optimOptions);

iterFit = 1;
while exitflag == 0 && iterFit < opts.MaxFitIterations
    [polyCoeff, fval, exitflag, output] = fminsearch(@localObjective_DoPF_HRMS, polyCoeff, optimOptions);
    iterFit = iterFit + 1;
end

baseline = polyval(polyCoeff, x);
residual = y - baseline;

isBaselineOutlier = false(size(y));
isBaselineOutlier(~isValid) = true;

isRetained = isValid;
iterOutlier = 1;

while true
    currentIndex = find(isRetained);
    if isempty(currentIndex)
        break
    end

    currentOutlier = isoutlier(residual(currentIndex));
    if ~any(currentOutlier)
        break
    end

    isRetained(currentIndex(currentOutlier)) = false;
    iterOutlier = iterOutlier + 1;

    if iterOutlier > opts.MaxOutlierIterations
        break
    end
end

isBaselineOutlier(isValid) = ~isRetained(isValid);

result = struct();
result.Baseline = baseline;
result.IsBaselineOutlier = isBaselineOutlier;
result.PolynomialCoefficients = polyCoeff;
result.Residual = residual;
result.IsValid = isValid;
result.IsRetained = isRetained;
result.UsedXY = fitXY;
result.Options = opts;

result.Optimization = struct();
result.Optimization.ExitFlag = exitflag;
result.Optimization.ObjectiveValue = fval;
result.Optimization.Output = output;
result.Optimization.IterationsUsed = iterFit;
result.Optimization.OutlierIterationsUsed = iterOutlier;

    function objectiveValue = localObjective_DoPF_HRMS(coeff)
        currentBaseline = polyval(coeff, fitXY(:, 1));
        profileResidual = fitXY(:, 2) - currentBaseline;

        idxNegative = profileResidual < 0;
        profileResidual(idxNegative) = abs(profileResidual(idxNegative)) .^ opts.NegativeResidualPower;

        objectiveValue = sum(profileResidual);
    end
end