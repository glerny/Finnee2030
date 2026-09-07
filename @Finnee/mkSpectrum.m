function mySpectrum = mkSpectrum(obj, dts, TmLim, opts)
%MKSPECTRUM Create a Spectrum object from a dataset and time selection (serial version).
%
% mySpectrum = mkSpectrum(obj, dts, TmLim)
% mySpectrum = mkSpectrum(obj, dts, TmLim, CodeScan="")
% mySpectrum = mkSpectrum(obj, dts, TmLim, mzInt=[0 inf])
% mySpectrum = mkSpectrum(obj, dts, TmLim, FastMode=false)
% mySpectrum = mkSpectrum(obj, dts, TmLim, ShowProgress=true)
%
% Inputs
% ------
% obj   : Finnee object
% dts   : dataset name or numeric scalar
% TmLim : scalar time value or [tStart tEnd]
%
% Name-value options
% ------------------
% CodeScan     : optional scan code, default ""
% mzInt        : optional m/z interval [mzMin mzMax], default [0 inf]
% FastMode     : logical scalar, default false
% ShowProgress : logical scalar, default true
%
% Output
% ------
% mySpectrum : Spectrum object
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
    TmLim
    opts.CodeScan = ""
    opts.mzInt (1,2) double = [0 inf]
    opts.FastMode (1,1) logical = false
    opts.ShowProgress (1,1) logical = true
end

validPlotCodes = [ ...
    "0000000111", "0000000110", "0000000101", "0000000100", ...
    "1000000111", "1000000110", "1000000101", "1000000100" ];

[dts, dtsIdx] = iNormalizeDataset(obj, dts);
TmLim = iNormalizeInterval(TmLim, 'mkSpectrum:InvalidTimeSelection', ...
    'TmLim must be a numeric scalar or a 2-element numeric vector.');
mzInt = sort(opts.mzInt(:)).';
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
scanMask = string(scanList.ScanCode) == CodeScan;
myData = scanList(scanMask, :);

if isempty(myData)
    error('mkSpectrum:EmptyScanSelection', ...
        'No scans found for scan code "%s" in dataset "%s".', CodeScan, dts);
end

[IdS, IdE] = iResolveScanRange(myData, TmLim);
nSelectedScans = IdE - IdS + 1;

hWait = [];
tStart = tic;
if ShowProgress && usejava('desktop')
    hWait = waitbar(0, sprintf('Building spectrum... 0/%d (serial)', nSelectedScans), ...
        'Name', 'mkSpectrum');
end

cleanupWaitbar = onCleanup(@() iCloseWaitbar(hWait));

if nSelectedScans == 1
    myMS = iReadOneScan( ...
        fullfile(obj.Path2Fin, dts, 'Scans'), ...
        myData.ScanIndex(IdS), ...
        myData.ScanSize{IdS}, ...
        mzInt, ...
        FastMode, ...
        'mkSpectrum');
else
    masterMz = iLoadMasterMzAxis(obj, dts);
    myMS = iAverageScansSerial( ...
        fullfile(obj.Path2Fin, dts, 'Scans'), ...
        myData, IdS, IdE, masterMz, mzInt, ...
        FastMode, hWait, tStart, 'serial');
end

elapsedTotal = toc(tStart);

if ShowProgress && ~isempty(hWait) && isgraphics(hWait)
    waitbar(1, hWait, sprintf('Spectrum built in %s', iFormatDuration(elapsedTotal)));
end

mySpectrum = iBuildSpectrumObject( ...
    obj, dts, dtsIdx, TmLim, mzInt, CodeScan, ...
    myData, IdS, IdE, ...
    FastMode, ShowProgress, ...
    "serial", "serial", ...
    isInterpolated, isCentroid, ...
    elapsedTotal, myMS);
end

% =========================================================================
function [dts, dtsIdx] = iNormalizeDataset(obj, dts)
if isnumeric(dts) && isscalar(dts)
    dts = "Dataset" + string(dts);
elseif ischar(dts) || isstring(dts)
    dts = string(dts);
else
    error('mkSpectrum:InvalidDataset', ...
        'dts must be a dataset name or a numeric scalar.');
end

datasetNames = string(obj.Datasets.Name);
dtsIdx = find(datasetNames == dts, 1, 'first');
if isempty(dtsIdx)
    error('mkSpectrum:DatasetNotFound', ...
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

error('mkSpectrum:MissingInfoFile', ...
    'No dataset info file was found for dataset "%s".', dts);
end

% =========================================================================
function CodeScan = iResolveScanCode(scanCodes, CodeScan, validPlotCodes, dts)
if strlength(CodeScan) == 0
    canBePlot = ismember(scanCodes, validPlotCodes);
    nMatches = nnz(canBePlot);

    if nMatches == 0
        error('mkSpectrum:NoValidScanType', ...
            'No compatible scan code was found in dataset "%s".', dts);
    elseif nMatches > 1
        error('mkSpectrum:AmbiguousScanType', ...
            ['Several compatible scan codes were found in dataset "%s". ' ...
            'Please specify CodeScan explicitly.'], dts);
    end

    CodeScan = scanCodes(canBePlot);
else
    CodeScan = string(CodeScan);
end

if numel(CodeScan) ~= 1
    error('mkSpectrum:InvalidScanType', ...
        'CodeScan must resolve to a single scan code.');
end

if ~any(scanCodes == CodeScan)
    error('mkSpectrum:MissingScanType', ...
        'The scan type "%s" was not found in dataset "%s".', CodeScan, dts);
end
end

% =========================================================================
function [IdS, IdE] = iResolveScanRange(myData, TmLim)
tStart = TmLim(1);
tEnd = TmLim(2);

if tStart == tEnd
    IdS = findCloser(tStart, myData.ScanTime);
    IdE = IdS;

else

    IdS = find(myData.ScanTime <= tStart, 1, 'last');
    if isempty(IdS)
        IdS = 1;
    end

    IdE = find(myData.ScanTime >= tEnd, 1, 'first');
    if isempty(IdE)
        IdE = height(myData);
    end

    if IdE < IdS
        tmp = IdS;
        IdS = IdE;
        IdE = tmp;
    end
end
end

% =========================================================================
function masterMz = iLoadMasterMzAxis(obj, dts)
tgtFile = fullfile(obj.Path2Fin, dts, 'InfoSpectra.mat');
if isfile(tgtFile)
    S = load(tgtFile, 'InfoSpectra');
    InfoSpectra = S.InfoSpectra;
else
    error('mkSpectrum:MissingInfoSpectraFile', ...
        'No InfoSpectra.mat file was found for dataset "%s".', dts);
end

masterMz = InfoSpectra.Spectra.mz;
if isempty(masterMz) || size(masterMz,2) < 1
    error('mkSpectrum:InvalidMasterMzAxis', ...
        'InfoSpectra.Spectra.mz is missing or invalid.');
end

if size(masterMz,2) > 1
    masterMz = masterMz(:,1);
end
end

% =========================================================================
function myMS = iReadOneScan(scanFolder, scanIdx, scanSize, mzInt, FastMode, errPrefix)
scanName = fullfile(scanFolder, ['Scan#', num2str(scanIdx), '.dat']);

if ~FastMode && ~isfile(scanName)
    error('%s:MissingScanFile', errPrefix, ...
        'Scan file not found: %s', scanName);
end

fidRead = fopen(scanName, 'rb');
if fidRead < 0
    error('%s:OpenScanFileFailed', errPrefix, ...
        'Unable to open scan file: %s', scanName);
end

cleaner = onCleanup(@() fclose(fidRead));
myMS = fread(fidRead, scanSize, 'double');
clear cleaner

if isvector(myMS) && mod(numel(myMS), 2) == 0
    myMS = reshape(myMS, [], 2);
end

if ~isempty(myMS) && size(myMS,2) ~= 2
    error('%s:InvalidSpectrumShape', errPrefix, ...
        'Spectrum data must contain two columns: [m/z intensity].');
end

if isempty(myMS)
    myMS = zeros(0,2);
    return
end

myMS(myMS(:,1) < mzInt(1) | myMS(:,1) > mzInt(2), :) = [];
end

% =========================================================================
function myMS = iAverageScansSerial(scanFolder, myData, IdS, IdE, masterMz, mzInt, ...
    FastMode, hWait, tStart, modeLabel)

nScans = IdE - IdS + 1;
acc = zeros(numel(masterMz), 1);

for k = 1:nScans
    iScan = IdS + k - 1;
    scanName = fullfile(scanFolder, ['Scan#', num2str(myData.ScanIndex(iScan)), '.dat']);

    if ~FastMode && ~isfile(scanName)
        error('mkSpectrum:MissingScanFile', ...
            'Scan file not found: %s', scanName);
    end

    fidRead = fopen(scanName, 'rb');
    if fidRead < 0
        error('mkSpectrum:OpenScanFileFailed', ...
            'Unable to open scan file: %s', scanName);
    end

    cleaner = onCleanup(@() fclose(fidRead));
    myMS_c = fread(fidRead, myData.ScanSize{iScan}, 'double');
    clear cleaner

    if isvector(myMS_c) && mod(numel(myMS_c), 2) == 0
        myMS_c = reshape(myMS_c, [], 2);
    end

    if isempty(myMS_c)
        vector = zeros(size(masterMz));
    else
        vector = completeSpectra(myMS_c(:,1), myMS_c(:,2), masterMz);
    end

    acc = acc + vector;

    if ~isempty(hWait) && isgraphics(hWait)
        waitbar(k / nScans, hWait, ...
            iProgressMessage(k, nScans, tStart, ...
            sprintf('Building spectrum... (%s)', modeLabel)));
    end
end

acc = acc / nScans;
myMS = [masterMz(:), acc(:)];
myMS(myMS(:,1) < mzInt(1) | myMS(:,1) > mzInt(2), :) = [];
end

% =========================================================================
function mySpectrum = iBuildSpectrumObject(obj, dts, dtsIdx, TmLim, mzInt, CodeScan, ...
    myData, IdS, IdE, FastMode, ShowProgress, ...
    execRequested, execUsed, isInterpolated, isCentroid, ...
    elapsedTotal, myMS)

infoSpc = struct();
infoSpc.FigureTitle = sprintf('%s', obj.FileID);

if IdS == IdE
    infoSpc.Title = {sprintf('%s', dts); ...
        sprintf('MS Spectrum at %.2f min', myData.ScanTime(IdS))};
else
    infoSpc.Title = {sprintf('%s', dts); ...
        sprintf('MS Spectrum from %.2f to %.2f min', ...
        myData.ScanTime(IdS), myData.ScanTime(IdE))};
end

infoSpc.CodeScan = CodeScan;
infoSpc.IsCentroid = isCentroid;

infoSpc.MzAxis.label = 'm/z';
infoSpc.MzAxis.Unit = '';
infoSpc.MzAxis.Precision = obj.Options.Precisions.MZ;

infoSpc.IntensityAxis.label = 'Intensity';
infoSpc.IntensityAxis.Unit = 'a.u.';
infoSpc.IntensityAxis.Precision = obj.Options.Precisions.Intensity;

infoSpc.Interpolated = isInterpolated;

Adi = struct();
Adi.Finnee = obj;
Adi.Dataset = dts;
Adi.DatasetIndex = dtsIdx;
Adi.TimeSelection = TmLim;
Adi.MzInterval = mzInt;
Adi.ScanIndexStart = myData.ScanIndex(IdS);
Adi.ScanIndexEnd = myData.ScanIndex(IdE);
Adi.CodeScan = CodeScan;
Adi.FastMode = FastMode;
Adi.ShowProgress = ShowProgress;
Adi.ExecutionModeRequested = char(execRequested);
Adi.ExecutionModeUsed = char(execUsed);
Adi.ProcessingTime_s = elapsedTotal;

infoSpc.AdditionalInformation = Adi;
mySpectrum = Spectrum(infoSpc, myMS);
end

% =========================================================================
function msg = iProgressMessage(doneCount, totalCount, tStartClock, taskText)
elapsedSec = toc(tStartClock);

if doneCount > 0
    estTotalSec = elapsedSec * totalCount / doneCount;
    remainingSec = max(0, estTotalSec - elapsedSec);
else
    remainingSec = NaN;
end

msg = sprintf('%s\nCompleted: %d/%d | Elapsed: %s | Remaining: %s', ...
    taskText, doneCount, totalCount, ...
    iFormatDuration(elapsedSec), iFormatDuration(remainingSec));
end

% =========================================================================
function txt = iFormatDuration(sec)
if ~isfinite(sec)
    txt = '--:--';
    return
end

sec = max(0, round(sec));
hh = floor(sec / 3600);
mm = floor(mod(sec, 3600) / 60);
ss = mod(sec, 60);

if hh > 0
    txt = sprintf('%02d:%02d:%02d', hh, mm, ss);
else
    txt = sprintf('%02d:%02d', mm, ss);
end
end

% =========================================================================
function iCloseWaitbar(hWait)
if ~isempty(hWait) && isgraphics(hWait)
    close(hWait);
end
end