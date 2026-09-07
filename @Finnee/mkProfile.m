function myProfile = mkProfile(obj, dts, MzLim, opts)
%MKPROFILE Create an extracted ion profile from a dataset (serial version).
%
% myProfile = mkProfile(obj, dts, MzLim)
% myProfile = mkProfile(obj, dts, MzLim, TmLim=[0 inf])
% myProfile = mkProfile(obj, dts, MzLim, CodeScan="")
% myProfile = mkProfile(obj, dts, MzLim, FastMode=true)
% myProfile = mkProfile(obj, dts, MzLim, ShowProgress=true)
%
% Inputs
% ------
% obj   : Finnee object
% dts   : dataset name or numeric scalar
% MzLim : scalar m/z or [mzMin mzMax]
%
% Name-value options
% ------------------
% TmLim        : 2-element numeric vector [tStart tEnd], default [0 inf]
% CodeScan     : optional scan code, default ""
% FastMode     : logical scalar, default true
% ShowProgress : logical scalar, default true
%
% Output
% ------
% myProfile : Profile object
%
% BSD 3-Clause License
%
% Copyright (c) 2026, G. Erny
% All rights reserved.
%
% Author: G. Erny
% Email: guillaume.erny@gmail.com

arguments
    obj
    dts
    MzLim
    opts.TmLim (1,2) double = [0 inf]
    opts.CodeScan = ""
    opts.FastMode (1,1) logical = true
    opts.ShowProgress (1,1) logical = true
end

minPointPerPeaks = 4;
validPlotCodes = [ ...
    "0000000111", "0000000110", "0000000101", "0000000100", ...
    "1000000111", "1000000110", "1000000101", "1000000100" ];

[dts, dtsIdx] = iNormalizeDataset(obj, dts);
MzLim = iNormalizeInterval(MzLim, 'mkProfile:InvalidMzSelection', ...
    'MzLim must be a numeric scalar or a 2-element numeric vector.');
TmLim = sort(opts.TmLim(:)).';
CodeScan = string(opts.CodeScan);
FastMode = opts.FastMode;
ShowProgress = opts.ShowProgress;

InfoDataset = iLoadInfoDataset(obj, dts);
scanCodes = string(unique(InfoDataset.ScanList.ScanCode));
CodeScan = iResolveScanCode(scanCodes, CodeScan, validPlotCodes, dts);

code = char(CodeScan);
isInterpolated = code(1) == '1';
isCentroid = code(10) == '0';

scanList = InfoDataset.ScanList;
scanMask = string(scanList.ScanCode) == CodeScan & ...
           scanList.ScanTime >= TmLim(1) & ...
           scanList.ScanTime <= TmLim(2);

myData = scanList(scanMask, :);
nScans = height(myData);

XYZ = zeros(nScans, 3);
if nScans > 0
    XYZ(:,1) = myData.ScanTime;
end
XYZ(:,3) = NaN;

scanFolder = fullfile(obj.Path2Fin, dts, 'Scans');
hWait = [];
tStart = tic;

if ShowProgress && nScans > 0 && usejava('desktop')
    hWait = waitbar(0, sprintf('Building profile... 0/%d (serial)', nScans), ...
        'Name', 'mkProfile');
end

updateStep = max(1, floor(max(nScans,1) / 200));

for ii = 1:nScans
    XYZ(ii,:) = iExtractProfileRow( ...
        myData.ScanTime(ii), ...
        myData.ScanIndex(ii), ...
        myData.ScanSize{ii}, ...
        scanFolder, ...
        MzLim, ...
        isCentroid, ...
        minPointPerPeaks, ...
        FastMode);

    if ShowProgress && ~isempty(hWait) && isgraphics(hWait) && ...
            (mod(ii, updateStep) == 0 || ii == nScans)
        elapsed = toc(tStart);
        frac = ii / nScans;
        if frac > 0
            eta = elapsed * (1 - frac) / frac;
        else
            eta = inf;
        end
        msg = sprintf(['Building profile... %d/%d (%.1f%%%%)\n' ...
            'Elapsed: %s | Remaining: %s | Mode: serial'], ...
            ii, nScans, 100 * frac, ...
            iFormatDuration(elapsed), iFormatDuration(eta));
        waitbar(frac, hWait, msg);
    end
end

elapsedTotal = toc(tStart);

if ShowProgress && ~isempty(hWait) && isgraphics(hWait)
    waitbar(1, hWait, sprintf('Profile built in %s', iFormatDuration(elapsedTotal)));
    pause(0.05);
    if isgraphics(hWait)
        close(hWait);
    end
end

myProfile = iBuildProfileObject( ...
    obj, dts, dtsIdx, MzLim, TmLim, CodeScan, ...
    FastMode, ShowProgress, ...
    "serial", "serial", ...
    isInterpolated, isCentroid, ...
    elapsedTotal, XYZ);
end

% =========================================================================
function [dts, dtsIdx] = iNormalizeDataset(obj, dts)
if isnumeric(dts) && isscalar(dts)
    dts = "Dataset" + string(dts);
elseif ischar(dts) || isstring(dts)
    dts = string(dts);
else
    error('mkProfile:InvalidDataset', ...
        'dts must be a dataset name or a numeric scalar.');
end

datasetNames = string(obj.Datasets.Name);
dtsIdx = find(datasetNames == dts, 1, 'first');
if isempty(dtsIdx)
    error('mkProfile:DatasetNotFound', ...
        'Dataset "%s" does not exist.', dts);
end
end

% =========================================================================
function lim = iNormalizeInterval(lim, errId, errMsg)
if ~isnumeric(lim) || isempty(lim) || numel(lim) > 2
    error(errId, errMsg);
end

if isscalar(lim)
    lim = [lim lim];
else
    lim = sort(lim(:)).';
end
end

% =========================================================================
function InfoDataset = iLoadInfoDataset(obj, dts)
tgtFile = fullfile(obj.Path2Fin, dts, 'InfoDataset.mat');
if isfile(tgtFile)
    S = load(tgtFile, 'InfoDataset');
    InfoDataset = S.InfoDataset;
    return
end

tgtFile = fullfile(obj.Path2Fin, dts, 'infoDataset.mat');
if isfile(tgtFile)
    S = load(tgtFile, 'infoDataset');
    InfoDataset = S.infoDataset;
    return
end

error('mkProfile:MissingInfoFile', ...
    'No dataset info file was found for dataset "%s".', dts);
end

% =========================================================================
function CodeScan = iResolveScanCode(scanCodes, CodeScan, validPlotCodes, dts)
if strlength(CodeScan) == 0
    canBePlot = ismember(scanCodes, validPlotCodes);
    nMatches = nnz(canBePlot);

    if nMatches == 0
        error('mkProfile:NoValidScanType', ...
            'No compatible scan code was found in dataset "%s".', dts);
    elseif nMatches > 1
        error('mkProfile:AmbiguousScanType', ...
            ['Several compatible scan codes were found in dataset "%s". ' ...
             'Please specify CodeScan explicitly.'], dts);
    end

    CodeScan = scanCodes(canBePlot);
else
    CodeScan = string(CodeScan);
end

if numel(CodeScan) ~= 1
    error('mkProfile:InvalidScanType', ...
        'CodeScan must resolve to a single scan code.');
end

if ~any(scanCodes == CodeScan)
    error('mkProfile:MissingScanType', ...
        'The scan type "%s" was not found in dataset "%s".', CodeScan, dts);
end
end

% =========================================================================
function xyzRow = iExtractProfileRow(scanTime, scanIdx, scanSize, scanFolder, ...
    MzLim, isCentroid, minPointPerPeaks, FastMode)

xyzRow = [scanTime, 0, NaN];
scanName = fullfile(scanFolder, ['Scan#', num2str(scanIdx), '.dat']);

if ~FastMode && ~isfile(scanName)
    error('mkProfile:MissingScanFile', ...
        'Scan file not found: %s', scanName);
end

fidRead = fopen(scanName, 'rb');
if fidRead < 0
    error('mkProfile:OpenScanFileFailed', ...
        'Unable to open scan file: %s', scanName);
end

cleaner = onCleanup(@() fclose(fidRead));
myMS = fread(fidRead, scanSize, 'double');
clear cleaner

if isempty(myMS)
    return

else

    mzMask = myMS(:,1) >= MzLim(1) & myMS(:,1) <= MzLim(2);
    myMS = myMS(mzMask, :);

    if isempty(myMS)
        return
    end

    if isCentroid
        if nnz(myMS(:,2)) >= minPointPerPeaks
            xyzRow(2:3) = ChrMoment(myMS, 2);
        end
    else
        intens = myMS(:,2);
        xyzRow(2) = sum(intens);
        [~, iMax] = max(intens);
        xyzRow(3) = myMS(iMax, 1);
    end
end
end

% =========================================================================
function myProfile = iBuildProfileObject(obj, dts, dtsIdx, MzLim, TmLim, CodeScan, ...
    FastMode, ShowProgress, execRequested, execUsed, ...
    isInterpolated, isCentroid, elapsedTotal, XYZ)

AdiPrm = struct();
AdiPrm.Finnee = obj;
AdiPrm.Dataset = dts;
AdiPrm.DatasetIndex = dtsIdx;
AdiPrm.Target = MzLim;
AdiPrm.TimeSelection = TmLim;
AdiPrm.CodeScan = CodeScan;
AdiPrm.FastMode = FastMode;
AdiPrm.ShowProgress = ShowProgress;
AdiPrm.ExecutionModeRequested = char(execRequested);
AdiPrm.ExecutionModeUsed = char(execUsed);
AdiPrm.ProcessingTime_s = elapsedTotal;

infoTrc = struct();
infoTrc.Type = 'Profile';
infoTrc.FigureTitle = sprintf('%s', obj.FileID);

mzFmt = "%" + string(obj.Options.Precisions.MZ);
formatSpec = 'Extracted ion profile m/z: %s:%s';
infoTrc.Title = { ...
    sprintf('%s', dts), ...
    sprintf(formatSpec, num2str(MzLim(1), mzFmt), num2str(MzLim(2), mzFmt))};

infoTrc.CodeScan = CodeScan;
infoTrc.IsCentroid = isCentroid;
infoTrc.HasMzData = true;

infoTrc.TimeAxis.label = 'Time';
infoTrc.TimeAxis.Unit = 'min';
infoTrc.TimeAxis.Precision = obj.Options.Precisions.Time;

infoTrc.IntensityAxis.label = 'Intensity';
infoTrc.IntensityAxis.Unit = 'a.u.';
infoTrc.IntensityAxis.Precision = obj.Options.Precisions.Intensity;

infoTrc.MzAxis.label = 'm/z';
infoTrc.MzAxis.Unit = '';
infoTrc.MzAxis.Precision = obj.Options.Precisions.MZ;

infoTrc.Interpolated = isInterpolated;
infoTrc.AdditionalInformation = AdiPrm;

myProfile = Profile(infoTrc, XYZ);
end

% =========================================================================
function txt = iFormatDuration(t)
if ~isfinite(t)
    txt = '--:--:--';
    return
end

t = max(0, round(t));
hh = floor(t / 3600);
mm = floor(mod(t, 3600) / 60);
ss = mod(t, 60);
txt = sprintf('%02d:%02d:%02d', hh, mm, ss);
end