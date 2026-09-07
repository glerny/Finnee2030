function result = PeakPicking(XY, opts)
%PEAKPICKING Detect peaks in a profile trace without plotting.
%
% result = PeakPicking(XY)
% result = PeakPicking(XY, opts)
%
% XY(:,1) = x axis
% XY(:,2) = intensity
% XY(:,3) = m/z (optional)
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
    XY (:,:) double
    opts.SampleScanRate (1,1) string {mustBeMember(opts.SampleScanRate, ["low","normal","high","ultra"])} = "normal"
    opts.XLimits (1,2) double = [0 inf]
    opts.BaselineDegree (1,1) double {mustBeInteger, mustBeNonnegative} = 1
    opts.BaselinePenalty (1,1) double {mustBePositive, mustBeFinite} = 4
    opts.BaselineMaxFitIterations (1,1) double {mustBeInteger, mustBePositive} = 3
    opts.BaselineMaxOutlierIters (1,1) double {mustBeInteger, mustBePositive} = 3
    opts.MinValleyDropFraction (1,1) double {mustBeGreaterThanOrEqual(opts.MinValleyDropFraction,0), mustBeLessThan(opts.MinValleyDropFraction,1)} = 0.20
    opts.CorrectedSignalFloor (1,1) double {mustBeFinite} = 0
    opts.MinPeakWidthPoints (1,1) double {mustBeInteger, mustBePositive} = 3
end

if size(XY,2) < 2
    error('PeakPicking:InvalidInput', ...
        'XY must have at least two columns: x and intensity.');
end

hasMz = size(XY,2) >= 3;

preset = getScanRatePreset(opts.SampleScanRate);

result = struct();
result.Options = opts;
result.Options.PointsPerPeak = preset.PointsPerPeak;
result.Options.GaussianWindowPoints = preset.GaussianWindowPoints;
result.Options.LocalMaxHalfWindow = preset.LocalMaxHalfWindow;
result.Options.MinSegmentLength = ceil(preset.PointsPerPeak / 2);
result.HasMz = hasMz;

XY = XY(XY(:,1) >= opts.XLimits(1) & XY(:,1) <= opts.XLimits(2), :);
XY(~isfinite(XY(:,2)), 2) = 0;

if hasMz
    XY(~isfinite(XY(:,3)), 3) = NaN;
end

result.Input = XY;
result.Segments = {};
result.Peaks = emptyPeakTable(hasMz);

if size(XY,1) < 3
    return
end

segmentList = splitTraceIntoSegments(XY, result.Options.MinSegmentLength);

if isempty(segmentList)
    return
end

segmentResult = cell(numel(segmentList), 1);
allPeakRows = [];

for iSeg = 1:numel(segmentList)
    segmentXY = segmentList{iSeg};

    if size(segmentXY,1) < 3
        segmentResult{iSeg} = emptySegmentResult(hasMz);
        continue
    end

    baselineResult = doPF_HRMS( ...
        segmentXY(:,1:2), ...
        PolynomialDegree = opts.BaselineDegree, ...
        NegativeResidualPower = opts.BaselinePenalty, ...
        MaxFitIterations = opts.BaselineMaxFitIterations, ...
        MaxOutlierIterations = opts.BaselineMaxOutlierIters, ...
        Display = "off");

    baseline = baselineResult.Baseline;
    polyCoeff = baselineResult.PolynomialCoefficients;

    residual = segmentXY(:,2) - baseline;

    corrected = residual;
    corrected(corrected < opts.CorrectedSignalFloor) = opts.CorrectedSignalFloor;

    smoothed = smoothdata(corrected, "gaussian", preset.GaussianWindowPoints);

    candidatePeaks = detectLocalMaxima(segmentXY(:,1), smoothed, preset.LocalMaxHalfWindow);
    candidatePeaks = mergeWeaklySeparatedPeaks(candidatePeaks, smoothed, opts.MinValleyDropFraction);

    acceptedRows = [];
    peakBounds = [];
    peakCounter = 0;

    for iPeak = 1:size(candidatePeaks,1)
        apexX = candidatePeaks(iPeak,1);
        apexY = candidatePeaks(iPeak,2);
        apexIdx = round(candidatePeaks(iPeak,4));

        [leftIdx, rightIdx] = findPeakBounds(candidatePeaks, iPeak, smoothed);

        if rightIdx <= leftIdx
            continue
        end

        if (rightIdx - leftIdx + 1) < opts.MinPeakWidthPoints
            continue
        end

        peakCounter = peakCounter + 1;

        peakXY = [segmentXY(leftIdx:rightIdx,1), corrected(leftIdx:rightIdx)];
        moment = ChrMoment(peakXY, 4);

        if hasMz
            [accurateMass, mzStd, mzStdUnbiased, mzMin, mzMax, nMz] = calcPeakMzStats( ...
                segmentXY(leftIdx:rightIdx,3), ...
                corrected(leftIdx:rightIdx));
        else
            accurateMass = NaN;
            mzStd = NaN;
            mzStdUnbiased = NaN;
            mzMin = NaN;
            mzMax = NaN;
            nMz = 0;
        end

        acceptedRows(end+1,:) = [ ... %#ok<AGROW>
            iSeg, peakCounter, ...
            apexX, apexY, apexIdx, ...
            segmentXY(leftIdx,1), segmentXY(rightIdx,1), ...
            leftIdx, rightIdx, ...
            moment, ...
            accurateMass, mzStd, mzStdUnbiased, mzMin, mzMax, nMz];
        
        peakBounds(end+1,:) = [ ... %#ok<AGROW>
            peakCounter, leftIdx, rightIdx, ...
            segmentXY(leftIdx,1), segmentXY(rightIdx,1)];
    end

    peakBoundsTable = peakBoundsToTable(peakBounds);
    [noiseSigma, noiseMask] = estimateSegmentNoise(residual, peakBoundsTable);

    if ~isempty(acceptedRows)
        if isfinite(noiseSigma) && noiseSigma > 0
            apexSNR = acceptedRows(:,4) ./ noiseSigma;
        else
            apexSNR = NaN(size(acceptedRows,1), 1);
        end
        acceptedRows = [acceptedRows, apexSNR];
    end

    acceptedTable = peakRowsToTable(acceptedRows, hasMz);

    segmentResult{iSeg} = buildSegmentResult( ...
        segmentXY, baselineResult, residual, corrected, smoothed, ...
        polyCoeff, candidatePeaks, acceptedTable, peakBoundsTable, ...
        noiseSigma, noiseMask, hasMz);

    allPeakRows = [allPeakRows; acceptedRows]; %#ok<AGROW>
end

result.Segments = segmentResult;
result.Peaks = peakRowsToTable(allPeakRows, hasMz);

end

function preset = getScanRatePreset(sampleScanRate)
switch sampleScanRate
    case "low"
        preset.PointsPerPeak = 6;
        preset.GaussianWindowPoints = 6;
        preset.LocalMaxHalfWindow = 2;
    case "normal"
        preset.PointsPerPeak = 10;
        preset.GaussianWindowPoints = 10;
        preset.LocalMaxHalfWindow = 3;
    case "high"
        preset.PointsPerPeak = 20;
        preset.GaussianWindowPoints = 20;
        preset.LocalMaxHalfWindow = 5;
    case "ultra"
        preset.PointsPerPeak = 50;
        preset.GaussianWindowPoints = 50;
        preset.LocalMaxHalfWindow = 10;
    otherwise
        error('PeakPicking:InvalidSampleScanRate', ...
            'Unsupported SampleScanRate "%s".', sampleScanRate);
end
end

function segments = splitTraceIntoSegments(XY, minSegmentLength)
x = XY(:,1);
y = XY(:,2);

positiveMask = y > 0;
dMask = diff([false; positiveMask; false]);
startIdx = find(dMask == 1);
endIdx = find(dMask == -1) - 1;

keep = (endIdx - startIdx + 1) >= minSegmentLength;
startIdx = startIdx(keep);
endIdx = endIdx(keep);

segments = cell(numel(startIdx), 1);
for ii = 1:numel(startIdx)
    segments{ii} = XY(startIdx(ii):endIdx(ii), :);
end
end

function candidatePeaks = detectLocalMaxima(x, y, halfWindow)
n = numel(y);

if n < 3
    candidatePeaks = zeros(0,4);
    return
end

isMax = false(n,1);

for ii = 2:n-1
    leftIdx = max(1, ii - halfWindow);
    rightIdx = min(n, ii + halfWindow);

    if y(ii) >= max(y(leftIdx:rightIdx))
        isMax(ii) = true;
    end
end

peakIdx = find(isMax);

if isempty(peakIdx)
    candidatePeaks = zeros(0,4);
    return
end

keep = true(size(peakIdx));
for ii = 2:numel(peakIdx)
    if peakIdx(ii) == peakIdx(ii-1) + 1
        if y(peakIdx(ii)) > y(peakIdx(ii-1))
            keep(ii-1) = false;
        else
            keep(ii) = false;
        end
    end
end
peakIdx = peakIdx(keep);

candidatePeaks = NaN(numel(peakIdx), 4);
nKeep = 0;

for ii = 1:numel(peakIdx)
    idx = peakIdx(ii);

    x1 = x(idx-1); x2 = x(idx); x3 = x(idx+1);
    y1 = y(idx-1); y2 = y(idx); y3 = y(idx+1);

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

    [~, closestIdx] = min(abs(x - refinedX));

    nKeep = nKeep + 1;
    candidatePeaks(nKeep,:) = [refinedX, refinedY, idx, closestIdx];
end

candidatePeaks = candidatePeaks(1:nKeep,:);
candidatePeaks = sortrows(candidatePeaks, 1);
end

function mergedPeaks = mergeWeaklySeparatedPeaks(candidatePeaks, smoothedSignal, minValleyDropFraction)
if size(candidatePeaks,1) <= 1
    mergedPeaks = candidatePeaks;
    return
end

keep = true(size(candidatePeaks,1),1);

for ii = 1:size(candidatePeaks,1)-1
    if ~keep(ii)
        continue
    end

    idx1 = round(candidatePeaks(ii,4));
    idx2 = round(candidatePeaks(ii+1,4));

    if idx2 <= idx1 + 1
        if candidatePeaks(ii,2) >= candidatePeaks(ii+1,2)
            keep(ii+1) = false;
        else
            keep(ii) = false;
        end
        continue
    end

    valleyValue = min(smoothedSignal(idx1:idx2));
    smallerApex = min(candidatePeaks(ii,2), candidatePeaks(ii+1,2));
    valleyDrop = (smallerApex - valleyValue) / max(smallerApex, eps);

    if valleyDrop < minValleyDropFraction
        if candidatePeaks(ii,2) >= candidatePeaks(ii+1,2)
            keep(ii+1) = false;
        else
            keep(ii) = false;
        end
    end
end

mergedPeaks = candidatePeaks(keep,:);
end

function [leftIdx, rightIdx] = findPeakBounds(candidatePeaks, peakNumber, smoothedSignal)
apexIdx = round(candidatePeaks(peakNumber,4));

if peakNumber == 1
    leftIdx = 1;
else
    prevIdx = round(candidatePeaks(peakNumber-1,4));
    [~, relIdx] = min(smoothedSignal(prevIdx:apexIdx));
    leftIdx = prevIdx + relIdx - 1;
end

if peakNumber == size(candidatePeaks,1)
    rightIdx = numel(smoothedSignal);
else
    nextIdx = round(candidatePeaks(peakNumber+1,4));
    [~, relIdx] = min(smoothedSignal(apexIdx:nextIdx));
    rightIdx = apexIdx + relIdx - 1;
end

leftIdx = max(1, min(leftIdx, apexIdx));
rightIdx = min(numel(smoothedSignal), max(rightIdx, apexIdx));
end

function [noiseSigma, bgMask] = estimateSegmentNoise(residual, peakBoundsTable)
valid = isfinite(residual);

if ~any(valid)
    noiseSigma = NaN;
    bgMask = false(size(residual));
    return
end

rValid = residual(valid);
sigma0 = 1.4826 * median(abs(rValid - median(rValid)));

peakMask = false(size(residual));
if istable(peakBoundsTable) && ~isempty(peakBoundsTable)
    for ii = 1:height(peakBoundsTable)
        i1 = peakBoundsTable.LeftIndex(ii);
        i2 = peakBoundsTable.RightIndex(ii);
        i1 = max(1, min(numel(residual), i1));
        i2 = max(1, min(numel(residual), i2));
        if i2 >= i1
            peakMask(i1:i2) = true;
        end
    end
end

bgMask = valid & ~peakMask;

if isfinite(sigma0) && sigma0 > 0
    bgMask = bgMask & (abs(residual) <= 3 * sigma0);
end

if nnz(bgMask) < 5
    bgMask = valid & ~peakMask;
end

if nnz(bgMask) < 5
    bgMask = valid;
end

rBg = residual(bgMask);

if numel(rBg) < 3
    noiseSigma = NaN;
    return
end

noiseSigma = 1.4826 * median(abs(rBg - median(rBg)));
end

function [accurateMass, mzStd, mzStdUnbiased, mzMin, mzMax, nMz] = calcPeakMzStats(mzValues, weights)
valid = isfinite(mzValues) & isfinite(weights) & weights > 0;

if ~any(valid)
    accurateMass = NaN;
    mzStd = NaN;
    mzStdUnbiased = NaN;
    mzMin = NaN;
    mzMax = NaN;
    nMz = 0;
    return
end

mzValues = mzValues(valid);
weights = weights(valid);
nMz = numel(mzValues);

wSum = sum(weights);
accurateMass = sum(weights .* mzValues) / wSum;

if nMz == 1 || wSum <= 0
    mzStd = 0;
    mzStdUnbiased = NaN;
else
    ssw = sum(weights .* (mzValues - accurateMass).^2);
    mzStd = sqrt(ssw / wSum);

    denom = wSum - sum(weights.^2) / wSum;
    if denom > 0
        mzStdUnbiased = sqrt(ssw / denom);
    else
        mzStdUnbiased = NaN;
    end
end

mzMin = min(mzValues);
mzMax = max(mzValues);
end

function segmentResult = buildSegmentResult(segmentXY, baselineResult, residual, corrected, smoothed, polyCoeff, candidatePeaks, acceptedPeaks, peakBounds, noiseSigma, noiseMask, hasMz)
segmentResult = struct();
segmentResult.X = segmentXY(:,1);
segmentResult.Raw = segmentXY(:,2);

if hasMz
    segmentResult.Mz = segmentXY(:,3);
else
    segmentResult.Mz = [];
end

segmentResult.Baseline = baselineResult.Baseline;
segmentResult.Residual = residual;
segmentResult.Corrected = corrected;
segmentResult.Smoothed = smoothed;
segmentResult.BaselineResult = baselineResult;
segmentResult.BaselineOutlier = baselineResult.IsBaselineOutlier;
segmentResult.PolynomialCoefficients = polyCoeff;
segmentResult.CandidatePeaks = array2table(candidatePeaks, ...
    'VariableNames', {'ApexTime','ApexIntensity','ApexIndexRaw','ApexIndexClosest'});
segmentResult.AcceptedPeaks = acceptedPeaks;
segmentResult.PeakBounds = peakBounds;
segmentResult.NoiseSigma = noiseSigma;
segmentResult.NoiseMask = noiseMask;
end

function segmentResult = emptySegmentResult(hasMz)
segmentResult = struct();
segmentResult.X = [];
segmentResult.Raw = [];
segmentResult.Mz = [];
segmentResult.Baseline = [];
segmentResult.Residual = [];
segmentResult.Corrected = [];
segmentResult.Smoothed = [];
segmentResult.BaselineResult = struct();
segmentResult.BaselineOutlier = [];
segmentResult.PolynomialCoefficients = [];
segmentResult.CandidatePeaks = array2table(zeros(0,4), ...
    'VariableNames', {'ApexTime','ApexIntensity','ApexIndexRaw','ApexIndexClosest'});
segmentResult.AcceptedPeaks = emptyPeakTable(hasMz);
segmentResult.PeakBounds = emptyPeakBoundsTable();
segmentResult.NoiseSigma = NaN;
segmentResult.NoiseMask = false(0,1);
end

function peakTable = peakRowsToTable(rows, hasMz)
baseVarNames = {'SegmentNumber','PeakNumber','ApexTime','ApexIntensity', ...
    'ApexIndex','StartTime','EndTime','StartIndex','EndIndex', ...
    'M0','M1','M2','M3'};

snrVarNames = {'ApexSNR'};
mzVarNames = {'AccurateMass','MzStd','MzStdUnbiased','MzMin','MzMax','NMz'};

if hasMz
    varNames = [baseVarNames, mzVarNames, snrVarNames];
else
    varNames = [baseVarNames, snrVarNames];
end

if isempty(rows)
    peakTable = array2table(zeros(0, numel(varNames)), 'VariableNames', varNames);
else
    peakTable = array2table(rows(:, 1:numel(varNames)), 'VariableNames', varNames);
end
end

function peakBoundsTable = peakBoundsToTable(rows)
varNames = {'PeakNumber','LeftIndex','RightIndex','LeftTime','RightTime'};

if isempty(rows)
    peakBoundsTable = array2table(zeros(0, numel(varNames)), 'VariableNames', varNames);
else
    peakBoundsTable = array2table(rows, 'VariableNames', varNames);
end
end

function peakTable = emptyPeakTable(hasMz)
peakTable = peakRowsToTable([], hasMz);
end

function peakBoundsTable = emptyPeakBoundsTable()
peakBoundsTable = peakBoundsToTable([]);
end