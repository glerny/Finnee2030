function mySpectrum = getSpectrum(obj, dts, TargetSpectrum)
%GETSPECTRUM Build a spectrum object from InfoSpectra metadata.
%
% mySpectrum = getSpectrum(obj, dts, TargetSpectrum)
%
% Inputs
% ------
% obj : parent object containing Paths, Datasets and Options
% dts : dataset name or numeric scalar (converted to "DatasetN")
% TargetSpectrum : "Total Ion Spectrum", "TIS", ...
%                  "Background Noise Spectrum", or "BNS"
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
%
% This file was developed with assistance from Perplexity AI and then
% reviewed, adapted, and integrated by G. Erny.


arguments
    obj
    dts
    TargetSpectrum {mustBeMember(TargetSpectrum, ...
        ["Total Ion Spectrum", "TIS", "Background Noise Spectrum", "BNS"])}
end

mySpectrum = Spectrum();

if isnumeric(dts) && isscalar(dts)
    dts = "Dataset" + string(dts);
elseif ischar(dts) || isstring(dts)
    dts = string(dts);
else
    error('getSpectrum:InvalidDataset', ...
        'dts must be a dataset name or a numeric scalar.');
end

datasetNames = string(obj.Datasets.Name);
if ~any(datasetNames == dts)
    error('getSpectrum:DatasetNotFound', ...
        'Dataset "%s" does not exist.', dts);
end

tgtFile = fullfile(obj.Path2Fin, dts, 'InfoSpectra.mat');
if ~isfile(tgtFile)
    error('getSpectrum:MissingInfoSpectraFile', ...
        'File not found: %s', tgtFile);
end

S = load(tgtFile, 'InfoSpectra');
if ~isfield(S, 'InfoSpectra')
    error('getSpectrum:InvalidInfoSpectraFile', ...
        'The file does not contain InfoSpectra.');
end

InfoSpectra = S.InfoSpectra;
if ~isfield(InfoSpectra, 'Spectra') || ~istable(InfoSpectra.Spectra)
    error('getSpectrum:InvalidSpectraTable', ...
        'InfoSpectra.Spectra must be a table.');
end

T = InfoSpectra.Spectra;

requiredVars = ["mz", "SumIntensities", "NoiseEstimated"];
missingVars = requiredVars(~ismember(requiredVars, string(T.Properties.VariableNames)));
if ~isempty(missingVars)
    error('getSpectrum:MissingVariables', ...
        'InfoSpectra.Spectra is missing required variable(s): %s', ...
        strjoin(cellstr(missingVars), ', '));
end

switch lower(string(TargetSpectrum))
    case {"total ion spectrum", "tis"}
        XY = [T.mz, T.SumIntensities];
        titleText = 'Total Ion Spectrum';
        targetMode = "TIS";

    case {"background noise spectrum", "bns"}
        XY = [T.mz, T.NoiseEstimated];
        titleText = 'Background Noise Spectrum';
        targetMode = "BNS";
end

infoSpc.FigureTitle = sprintf('%s', obj.FileID);
infoSpc.Title = {sprintf('%s', dts); titleText};

infoSpc.CodeScan = "";
infoSpc.IsCentroid = false;

infoSpc.MzAxis.label = 'm/z';
infoSpc.MzAxis.Unit = '';
infoSpc.MzAxis.Precision = obj.Options.Precisions.MZ;

infoSpc.IntensityAxis.label = 'Intensity';
infoSpc.IntensityAxis.Unit = 'a.u.';
infoSpc.IntensityAxis.Precision = obj.Options.Precisions.Intensity;

infoSpc.Interpolated = true;

infoSpc.AdditionalInformation.Finnee = obj;
infoSpc.AdditionalInformation.Dataset = dts;
infoSpc.AdditionalInformation.TargetSpectrum = targetMode;
infoSpc.AdditionalInformation.Source = 'InfoSpectra';

mySpectrum = Spectrum(infoSpc, XY);
end