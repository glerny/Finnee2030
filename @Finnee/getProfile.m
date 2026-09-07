function myProfile = getProfile(obj, dts, TargetProfile, CodeScan)
%GETPROFILE Build a profile object from dataset scan metadata.
%
%   myProfile = getProfile(obj, dts, TargetProfile)
%   myProfile = getProfile(obj, dts, TargetProfile, CodeScan)
%
%   Inputs
%   ------
%   obj           : parent object containing Paths, Datasets and Options
%   dts           : dataset name or numeric scalar (converted to "DatasetN")
%   TargetProfile : "Total Ion Profile", "TIP", "Base Peak Profile", or "BPP"
%   CodeScan      : optional scan code; if omitted, a unique compatible scan
%                   code is selected automatically
%
%   Output
%   ------
%   myProfile     : Profile object
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
    TargetProfile {mustBeMember(TargetProfile, ...
        ["Total Ion Profile", "TIP", "Base Peak Profile", "BPP"])}
    CodeScan = ''

end

validPlotCodes = unique(["0000000111", "0000000110", "0000000101", "0000000110", ...
    "1000000111", "1000000110", "1000000101", "1000000110"]);

 % Default output.
    myProfile = Profile();

% Normalize dataset identifier to string.
if isnumeric(dts) && isscalar(dts)
    dts = "Dataset" + string(dts);

elseif ischar(dts) || isstring(dts)
    dts = string(dts);

else
    error('getProfile:InvalidDataset', ...
        'dts must be a dataset name or a numeric scalar.')
end

 % Check dataset exists in object registry.
if ~any(strcmp(obj.Datasets.Name, dts))
    error('getProfile:DatasetNotFound', ...
        'Dataset "%s" does not exist.', dts)
end

 % Load dataset metadata file.
tgtFile = fullfile(obj.Path2Fin, dts, 'InfoDataset.mat');
if ~isfile(tgtFile)
    error('getProfile:MissingInfoFile', ...
        'File not found: %s', tgtFile)
end

S = load(tgtFile, 'InfoDataset');
InfoDataset = S.InfoDataset;

% Normalize scan codes to string for robust comparison.
scanCodes = string(unique(InfoDataset.ScanList.ScanCode));

% Resolve scan code automatically when not provided.
if isempty(CodeScan) || (isstring(CodeScan) && strlength(CodeScan) == 0) ...
        || (ischar(CodeScan) && isempty(CodeScan))

    canBePlot = ismember(scanCodes, validPlotCodes);
    nMatches = nnz(canBePlot);

    if nMatches == 0
        error('getProfile:NoValidScanType', ...
            'No compatible scan code was found in dataset "%s".', dts);
    elseif nMatches > 1
        error('getProfile:AmbiguousScanType', ...
            ['Several compatible scan codes were found in dataset "%s". ' ...
            'Please specify CodeScan explicitly.'], dts);
    end

    CodeScan = scanCodes(canBePlot);
else
    CodeScan = string(CodeScan);
end

if ~any(unique(InfoDataset.ScanList.ScanCode) == CodeScan)
    error('getProfile:MissingScnaType', ...
        'The scan type %s was not found in %s', tgtFile)
end

switch lower(TargetProfile)
    case {"total ion profile","tip"}
        mode = "TIP";
    case {"base peak profile","bpp"}
        mode = "BPP";
end

IdX = InfoDataset.ScanList.ScanCode == CodeScan;
switch mode
    case "TIP"
        % compute total ion profile
        XYZ = [InfoDataset.ScanList.ScanTime(IdX), InfoDataset.ScanList.TotalIonCurrent(IdX), InfoDataset.ScanList.mzAtBasePeak(IdX)];
        infoTrc.Title = sprintf('%s: Total Ion Profile', dts);
        infoTrc.FigureTitle = obj.FileID;

    case "BPP"
        % compute base peak profile
        XYZ = [InfoDataset.ScanList.ScanTime(IdX), InfoDataset.ScanList.BasePeak(IdX), InfoDataset.ScanList.mzAtBasePeak(IdX)];
        infoTrc.Title = sprintf('%s:  Base Peak Profile', dts);
        infoTrc.FigureTitle = obj.FileID;
end
infoTrc.CodeScan = string(CodeScan);

if CodeScan{1}(10) == '1'
    infoTrc.IsCentroid = false;
else
    infoTrc.IsCentroid = true;
end

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

if CodeScan{1}(1) == '1'
    infoTrc.Interpolated = true;
else
    infoTrc.Interpolated = false;
end

infoTrc.AdditionalInformation.Finnee = obj;
infoTrc.AdditionalInformation.Dataset = dts;

myProfile = Profile(infoTrc, XYZ);
end