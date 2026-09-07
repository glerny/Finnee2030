function scan = getScan(obj, dts, scanNbr)
% GETSCAN Return one scan and its metadata from a dataset
%
%   scan = getScan(OBJ, DTS, SCANNBR) returns the scan structure
%   corresponding to scan number SCANNBR in dataset DTS.
%
%   DTS can be either a dataset name or a numeric dataset index suffix.
%
%   The output structure contains:
%       Number      - Scan number
%       TimeValue   - Scan time
%       ScanCode    - Scan code
%       File        - Full path to the binary scan file
%       XY          - Scan data read from disk
%
% BSD 3-Clause License
%
% Copyright (c) 2026, G. Erny
% All rights reserved.
%
% Author: G. Erny
% Email: guillaume.erny@gmail.com

narginchk(3, 3)
if isnumeric(dts) && isscalar(dts)
    dts = "Dataset" + string(dts);
elseif ischar(dts) || isstring(dts)
    dts = string(dts);
else
    error('getScan:InvalidDataset', ...
        'dts must be a dataset name or a numeric scalar.')
end

if ~(isnumeric(scanNbr) && isscalar(scanNbr))
    error('getScan:InvalidScanNumber', ...
        'scanNbr must be a numeric scalar.')
end

datasetIdx = find(strcmp(obj.Datasets.Name, dts), 1);
if isempty(datasetIdx)
    error('getScan:DatasetNotFound', ...
        'Dataset "%s" does not exist.', dts)
end

tgtFile = fullfile(obj.Path2Fin, dts, 'InfoDataset.mat');
if ~isfile(tgtFile)
    error('getScan:MissingInfoFile', ...
        'File not found: %s', tgtFile)
end

S = load(tgtFile, 'InfoDataset');
InfoDataset = S.InfoDataset;

scanIdx = find(InfoDataset.ScanList.ScanIndex == scanNbr, 1);
if isempty(scanIdx)
    error('getScan:ScanNotFound', ...
        'Scan number %d was not found in dataset "%s".', scanNbr, dts)
end

myLine = InfoDataset.ScanList(scanIdx, :);

scan = struct();
scan.Number = scanNbr;
scan.TimeValue = myLine.ScanTime;
scan.ScanCode = myLine.ScanCode;
scan.File = fullfile(obj.Path2Fin, dts, 'Scans', sprintf('Scan#%d.dat', scanNbr));

if ~isfile(scan.File)
    error('getScan:MissingScanFile', ...
        'Scan file not found: %s', scan.File)
end

mySize = myLine.ScanSize;
if iscell(mySize)
    mySize = mySize{1};
end

fidRead = fopen(scan.File, 'rb');
if fidRead == -1
    error('getScan:FileOpenError', ...
        'Unable to open scan file: %s', scan.File)
end

cleanupObj = onCleanup(@() fclose(fidRead));
scan.XY = fread(fidRead, mySize, 'double');
scan.AxisLabels = myLine.AxisLabels;

end