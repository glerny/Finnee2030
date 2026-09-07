function myProfile = mkProfile_parallel(obj, dts, MzLim, opts)
%MKPROFILE_PARALLEL Create an extracted ion profile from a dataset (parallel version).
%
% myProfile = mkProfile_parallel(obj, dts, MzLim)
% myProfile = mkProfile_parallel(obj, dts, MzLim, TmLim=[0 inf])
% myProfile = mkProfile_parallel(obj, dts, MzLim, CodeScan="")
% myProfile = mkProfile_parallel(obj, dts, MzLim, FastMode=true)
% myProfile = mkProfile_parallel(obj, dts, MzLim, ShowProgress=true)
%
% This function attempts parallel execution when available. If parallel
% execution is unavailable, it falls back to the serial implementation
% with a warning.
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

canUseParallel = isfield(obj.Options, 'canUseParallel') && obj.Options.canUseParallel;
if ~canUseParallel
    warning('mkProfile_parallel:ParallelUnavailable', ...
        'Parallel execution is unavailable. Falling back to serial mkProfile().');
    myProfile = mkProfile(obj, dts, MzLim, ...
        TmLim = opts.TmLim, ...
        CodeScan = opts.CodeScan, ...
        FastMode = opts.FastMode, ...
        ShowProgress = opts.ShowProgress);
    myProfile.AdditionalInformation.ExecutionModeRequested = 'parallel';
    myProfile.AdditionalInformation.ExecutionModeUsed = 'serial';
    return
end

[dts, dtsIdx] = iNormalizeDataset(obj, dts);
MzLim = iNormalizeInterval(MzLim, 'mkProfile_parallel:InvalidMzSelection', ...
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

if nScans <= 20
    warning('mkProfile_parallel:SmallWorkload', ...
        'Only %d scans selected. Falling back to serial mkProfile().', nScans);
    myProfile = mkProfile(obj, dts, MzLim, ...
        TmLim = TmLim, ...
        CodeScan = CodeScan, ...
        FastMode = FastMode, ...
        ShowProgress = ShowProgress);
    myProfile.AdditionalInformation.ExecutionModeRequested = 'parallel';
    myProfile.AdditionalInformation.ExecutionModeUsed = 'serial';
    return
end

XYZ = zeros(nScans, 3);
XYZ(:,1) = myData.ScanTime;
XYZ(:,3) = NaN;

scanFolder = fullfile(obj.Path2Fin, dts, 'Scans');
hWait = [];
tStart = tic;

if ShowProgress && nScans > 0 && usejava('desktop')
    hWait = waitbar(0, sprintf('Building profile... 0/%d (parallel)', nScans), ...
        'Name', 'mkProfile_parallel');
end

q = [];
completedCount = 0;

if ShowProgress && ~isempty(hWait) && isgraphics(hWait)
    q = parallel.pool.DataQueue;
    afterEach(q, @updateParallelWaitbar);
end

parfor ii = 1:nScans
    XYZ(ii,:) = iExtractProfileRow( ...
        myData.ScanTime(ii), ...
        myData.ScanIndex(ii), ...
        myData.ScanSize{ii}, ...
        scanFolder, ...
        MzLim, ...
        isCentroid, ...
        minPointPerPeaks, ...
        FastMode);

    if ~isempty(q) && ShowProgress && usejava('desktop')
        send(q, 1);
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
    "parallel", "parallel", ...
    isInterpolated, isCentroid, ...
    elapsedTotal, XYZ);

    function updateParallelWaitbar(~)
        completedCount = completedCount + 1;
        if isempty(hWait) || ~isgraphics(hWait)
            return
        end

        elapsed = toc(tStart);
        frac = completedCount / nScans;
        if frac > 0
            eta = elapsed * (1 - frac) / frac;
        else
            eta = inf;
        end

        msg = sprintf(['Building profile... %d/%d (%.1f%%%%)\n' ...
            'Elapsed: %s | Remaining: %s | Mode: parallel'], ...
            completedCount, nScans, 100 * frac, ...
            iFormatDuration(elapsed), iFormatDuration(eta));
        waitbar(frac, hWait, msg);
    end
end

% =========================================================================
function [dts, dtsIdx] = iNormalizeDataset(obj, dts)
if isnumeric(dts) && isscalar(dts)
    dts = "Dataset" + string(dts);
elseif ischar(dts) || isstring(dts)
    dts = string(dts);
else
    error('mkProfile_parallel:InvalidDataset', ...
        'dts must be a dataset name or a numeric scalar.');
end

datasetNames = string(obj.Datasets.Name);
dtsIdx = find(datasetNames == dts, 1, 'first');
if isempty(dtsIdx)
    error('mkProfile_parallel:DatasetNotFound', ...
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

error('mkProfile_parallel:MissingInfoFile', ...
    'No dataset info file was found for dataset "%s".', dts);
end

% =========================================================================
function CodeScan = iResolveScanCode(scanCodes, CodeScan, validPlotCodes, dts)
if strlength(CodeScan) == 0
    canBePlot = ismember(scanCodes, validPlotCodes);
    nMatches = nnz(canBePlot);

    if nMatches == 0
        error('mkProfile_parallel:NoValidScanType', ...
            'No compatible scan code was found in dataset "%s".', dts);
    elseif nMatches > 1
        error('mkProfile_parallel:AmbiguousScanType', ...
            ['Several compatible scan codes were found in dataset "%s". ' ...
             'Please specify CodeScan explicitly.'], dts);
    end

    CodeScan = scanCodes(canBePlot);
else
    CodeScan = string(CodeScan);
end

if numel(CodeScan) ~= 1
    error('mkProfile_parallel:InvalidScanType', ...
        'CodeScan must resolve to a single scan code.');
end

if ~any(scanCodes == CodeScan)
    error('mkProfile_parallel:MissingScanType', ...
        'The scan type "%s" was not found in dataset "%s".', CodeScan, dts);
end
end

% =========================================================================
function xyzRow = iExtractProfileRow(scanTime, scanIdx, scanSize, scanFolder, ...
    MzLim, isCentroid, minPointPerPeaks, FastMode)

xyzRow = [scanTime, 0, NaN];
scanName = fullfile(scanFolder, ['Scan#', num2str(scanIdx), '.dat']);

if ~FastMode && ~isfile(scanName)
    error('mkProfile_parallel:MissingScanFile', ...
        'Scan file not found: %s', scanName);
end

fidRead = fopen(scanName, 'rb');
if fidRead < 0
    error('mkProfile_parallel:OpenScanFileFailed', ...
        'Unable to open scan file: %s', scanName);
end

cleaner = onCleanup(@() fclose(fidRead));
myMS = fread(fidRead, scanSize, 'double');
clear cleaner

if ~FastMode && isempty(myMS)
    error('mkProfile_parallel:EmptySpectrum', ...
        'No spectral data were read from scan file: %s', scanName);
end

if isvector(myMS) && mod(numel(myMS), 2) == 0
    myMS = reshape(myMS, [], 2);
end

if ~isempty(myMS) && size(myMS, 2) ~= 2
    error('mkProfile_parallel:InvalidSpectrumShape', ...
        'Spectrum data must contain two columns: [m/z intensity].');
end

if isempty(myMS)
    return
end

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