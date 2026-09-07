function obj = importMzML(obj, opts)
% IMPORTMZML Import mzML data into a Finnee2030 dataset.
%
% This method reads an mzML file, extracts acquisition metadata, parses
% spectra one by one, decodes binary m/z and intensity arrays, applies
% optional filtering in time and m/z, removes spikes when requested, and
% stores scan data and summary information in the Finnee output structure.
%
% Input:
%   obj   Finnee object under construction.
%   opts  Structure containing import and filtering options.
%
% Output:
%   obj   Updated Finnee object with imported dataset information.
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

% 1 - Initialisations
tStart = tic;
opts.ActionType = 'creator';
opts.FunctionUsed = 'importMzML';
opts.FromDataset = NaN;

if ~isfield(opts, 'ShowProgress') || isempty(opts.ShowProgress)
    opts.ShowProgress = true;
end

globalMinMz = inf;
globalMaxMz = -inf;

curScan = 0;
InfoScan = struct();
InfoScan.Info = {};

ScanList = table('Size', [0 9], ...
    'VariableTypes', {'double', 'double', 'string', 'cell', 'double', ...
    'double', 'double', 'double', 'cell'}, ...
    'VariableNames', {'ScanIndex', 'ScanTime', 'ScanCode', 'AxisLabels', ...
    'BasePeak', 'mzAtBasePeak', 'TotalIonCurrent', 'NonZerosValues', 'ScanSize'});

fidRead = fopen(obj.FileIn, 'r');
if fidRead == -1
    error('Finnee:importMzML:FileOpenError', ...
        'Unable to open mzML file: %s', obj.FileIn);
end
fileReadCleaner = onCleanup(@() fcloseSafe(fidRead));

metadata.PreRun = {};
metadata.ModelRun = {};
metadata.PreRun = getNodes(fidRead, 'mzML', 'spectrum');
allfield = unpackAttributes(metadata.PreRun, {});

if any(strcmp(allfield(:, 1), 'run/startTimeStamp'))
    dt = allfield{strcmp(allfield(:, 1), 'run/startTimeStamp'), 2};
    dt = erase(dt, '"');
    dt = parseISOdates(dt);
    obj.DateOfDataAcq = dt;
end

myDatasets = struct();
myDatasets.Name{1, 1} = 'Dataset0';
myDatasets.Options4Creations{1, 1} = opts;
myDatasets.AdditionalInformation{1, 1} = {};

mkdir(fullfile(obj.Path2Fin, myDatasets.Name{1, 1}));
mkdir(fullfile(obj.Path2Fin, myDatasets.Name{1, 1}, 'Scans'));

idxScanNbr = strcmp(allfield(:, 1), 'spectrumList/count');
if any(idxScanNbr)
    ScanNbr = str2double(allfield{idxScanNbr, 2});
else
    ScanNbr = NaN;
end
if isnan(ScanNbr) || ScanNbr <= 0
    ScanNbr = 1;
end

h = [];
if opts.ShowProgress
    h = waitbar(0, 'Processing scans...', ...
        'Name', 'Finnee - importMzML');
end
waitbarCleaner = onCleanup(@() closeWaitbarSafe(h));

while true

    % Get and decipher each spectrum
    mySpectra = getNodes(fidRead, 'spectrum', 'spectrum');
    if isempty(fieldnames(mySpectra))
        break
    end

    if isempty(metadata.ModelRun)
        metadata.ModelRun = mySpectra;
    end

    [info, dataSpectra] = classifyMzMLSpectrum(mySpectra);
    [isOK, myCode] = verifyMzMLInfo(info);

    if ~isOK
        error('Finnee:importMzML:InvalidSpectrumClassification', ...
            ['Inconsistent spectrum classification for spectrum index %d ' ...
            '(label: %s). Conflicting centroid/profile, polarity, or MS level flags were detected.'], ...
            info.index, string(info.Label));
    end

    [myScan, info] = mkSpectra(info, dataSpectra);

    if opts.ShowProgress && ~isempty(h) && isgraphics(h)
        frac = min(max((info.index + 1) / ScanNbr, 0), 1);
        waitbar(frac, h, sprintf('Processing scans... %d/%d', info.index + 1, ScanNbr));
        drawnow limitrate;
    end

    if info.ScanStartTime.Value < opts.TimeLimits(1) || info.ScanStartTime.Value > opts.TimeLimits(2)
        continue;
    end

    % Remove m/z values outside requested range
    Id2Rem = myScan(:, 1) < opts.MzLimits(1) | myScan(:, 1) > opts.MzLimits(2);
    myScan(Id2Rem, :) = [];

    % Filter spikes if requested
    if ~isempty(myScan) && opts.RemoveSpikes
        spkSz = opts.SpikeSize;
        myScan = spikesRemoval(myScan, spkSz);
    end

    % Remove excess trailing zeros
    if ~isempty(myScan)
        provMat = [myScan(2:end, 2); 0];
        provMat(:, 2) = myScan(:, 2);
        provMat(:, 3) = [0; myScan(1:end-1, 2)];
        myScan = myScan(sum(provMat, 2) > 0, :);
    end

    if ~isempty(myScan)
        globalMinMz = min(globalMinMz, min(myScan(:, 1)));
        globalMaxMz = max(globalMaxMz, max(myScan(:, 1)));
        [MaxVal, IdMax] = max(myScan(:, 2));
        mzAtBasePeak = myScan(IdMax, 1);
        totalIonCurrent = sum(myScan(:, 2));
        nonZeroValues = nnz(myScan(:, 2));
        scanSize = size(myScan);
    else
        MaxVal = 0;
        mzAtBasePeak = NaN;
        totalIonCurrent = 0;
        nonZeroValues = 0;
        scanSize = [0, 2];
    end

    % Internal scan indexing in Finnee output
    info.index = curScan;

    addVector = {curScan, info.ScanStartTime.Value, myCode, info.Axis, ...
        MaxVal, mzAtBasePeak, totalIonCurrent, nonZeroValues, scanSize};
    ScanList = [ScanList; addVector];

    % Record spectrum
    fileName = fullfile(obj.Path2Fin, myDatasets.Name{1, 1}, ...
        'Scans', ['Scan#', num2str(info.index), '.dat']);
    info.path2Dat = fileName;

    [fidWriteDat, errmsg] = fopen(fileName, 'wb');
    if fidWriteDat == -1
        error('Finnee:importMzML:ScanWriteError', ...
            'Unable to create scan file "%s": %s', fileName, errmsg);
    end

    writeCleaner = onCleanup(@() fcloseSafe(fidWriteDat));
    fwrite(fidWriteDat, myScan(:), "double");
    clear writeCleaner

    InfoScan.Info{end+1} = info;
    curScan = curScan + 1;
end

myDatasets = struct2table(myDatasets);
obj.Datasets = myDatasets;

InfoScan.Finnee = obj;
InfoDataset = struct();
InfoDataset.Finnee = obj;
InfoDataset.Options = opts;
InfoDataset.ScanList = ScanList;

if isfinite(globalMinMz)
    InfoDataset.MzRangeDetected = [globalMinMz, globalMaxMz];
else
    InfoDataset.MzRangeDetected = [NaN, NaN];
end

InfoDataset.dateofcreation = datetime("now");
InfoDataset.ComputingTime = toc(tStart);

save(fullfile(obj.Path2Fin, 'AquisitionData.mat'), 'metadata');
save(fullfile(obj.Path2Fin, myDatasets.Name{1}, 'InfoDataset.mat'), 'InfoDataset');
save(fullfile(obj.Path2Fin, myDatasets.Name{1}, 'InfoScan.mat'), 'InfoScan');

    function [myInfo, dataSpectra] = classifyMzMLSpectrum(metaRun)
        myInfo = struct();
        myInfo.Representation = "unknown";
        myInfo.MSLevel = NaN;
        myInfo.ScanRole = "unknown";
        myInfo.Acquisition = "unknown";
        myInfo.Fragmentation = "unknown";
        myInfo.Dimension = "1D-MS";
        myInfo.HasIonMobility = false;
        myInfo.HasImaging = false;
        myInfo.HasChromatography = false;
        myInfo.IsDIA = false;
        myInfo.IsDDA = false;
        myInfo.IsTargeted = false;
        myInfo.IsMS1 = false;
        myInfo.IsMSn = false;
        myInfo.IsProfile = false;
        myInfo.IsCentroid = false;
        myInfo.IsPositiveScan = false;
        myInfo.IsNegativeScan = false;
        myInfo.Is2D = false;
        myInfo.Label = "";
        myInfo.index = "";
        myInfo.ScanStartTime = struct();
        myInfo.IonInjectionTime = struct();
        myInfo.isolationWindow = [];
        myInfo.interpol2MasterMz = false;
        myInfo.fullMasterMz = {};
        myInfo.shortMasterMz = {};
        myInfo.Axis = cell(1, 2);

        dataSpectra = struct();

        myInfo.index = str2double(erase(metaRun.spectrum.Attributes.index, '"'));
        myInfo.Label = string(metaRun.spectrum.Attributes.id);
        dataSpectra.DSL = str2double(erase(metaRun.spectrum.Attributes.defaultArrayLength, '"'));

        for if1 = 1:numel(metaRun.spectrum.subElements)
            mFN = fieldnames(metaRun.spectrum.subElements{if1});
            if numel(mFN) > 1
                assignin('base', 'metaRun', metaRun);
                error('Finnee:importMzML:UnexpectedSpectrumSubElement', ...
                    ['A spectrum subelement contains %d fields, but exactly one field was expected. ' ...
                    'Spectrum index: %d.'], numel(mFN), myInfo.index);
            end

            switch mFN{1}
                case 'cvParam'
                    myAttribute = metaRun.spectrum.subElements{if1}.cvParam.Attributes;

                    if ~strcmp(myAttribute.cvRef, 'MS')
                        assignin('base', 'metaRun', metaRun);
                        error('Finnee:importMzML:InvalidCvRef', ...
                            'Expected cvRef "MS" but found "%s" for accession "%s".', ...
                            string(myAttribute.cvRef), string(myAttribute.accession));
                    end

                    switch myAttribute.accession
                        case 'MS:1000511'
                            Level = str2double(erase(myAttribute.value, '"'));
                            if Level == 1
                                myInfo.IsMS1 = true;
                            else
                                myInfo.IsMSn = true;
                            end
                            myInfo.MSLevel = Level;

                        case 'MS:1000579'
                            myInfo.IsMS1 = true;

                        case 'MS:1000130'
                            myInfo.IsPositiveScan = true;

                        case 'MS:1000128'
                            myInfo.IsProfile = true;

                        case 'MS:1000127'
                            myInfo.IsCentroid = true;

                        case 'MS:1000505'
                            % base peak intensity will be recalculated

                        case 'MS:1000504'
                            % base peak m/z will be recalculated

                        case 'MS:1000285'
                            % TIC will be recalculated

                        case 'MS:1000796'
                            % title duplication, ignored

                        case {'MS:1000528', 'MS:1000527'}
                            % lowest/highest observed m/z, not used

                        case 'MS:1000580'
                            myInfo.IsMSn = true;
                            myInfo.MSLevel = 2;

                        otherwise
                            error('Finnee:importMzML:UnsupportedSpectrumCvParam', ...
                                'Unsupported spectrum cvParam accession "%s" in spectrum index %d.', ...
                                string(myAttribute.accession), myInfo.index);
                    end

                case 'scanList'
                    count = str2double(erase(metaRun.spectrum.subElements{if1}.scanList.Attributes.count, '"'));
                    if count ~= 1
                        error('Finnee:importMzML:UnsupportedScanListCount', ...
                            'Expected scanList count equal to 1, but found %d in spectrum index %d.', ...
                            count, myInfo.index);
                    end

                    for if2 = 1:numel(metaRun.spectrum.subElements{if1}.scanList.subElements)
                        scanList = metaRun.spectrum.subElements{if1}.scanList.subElements{if2};

                        if isfield(scanList, 'cvParam')
                            switch scanList.cvParam.Attributes.accession
                                case 'MS:1000795'
                                    % no combination, ignored
                                otherwise
                                    error('Finnee:importMzML:UnsupportedScanListCvParam', ...
                                        'Unsupported scanList cvParam accession "%s" in spectrum index %d.', ...
                                        string(scanList.cvParam.Attributes.accession), myInfo.index);
                            end

                        elseif isfield(scanList, 'scan')
                            for if3 = 1:numel(scanList.scan.subElements)
                                scan = scanList.scan.subElements{if3};

                                if isfield(scan, 'cvParam')
                                    switch scan.cvParam.Attributes.accession
                                        case 'MS:1000016'
                                            myInfo.ScanStartTime.Value = str2double(erase(scan.cvParam.Attributes.value, '"'));
                                            switch scan.cvParam.Attributes.unitAccession
                                                case 'UO:0000031'
                                                    myInfo.ScanStartTime.Units = 'minute';
                                                otherwise
                                                    error('Finnee:importMzML:UnsupportedScanTimeUnit', ...
                                                        'Unsupported scan start time unit accession "%s" in spectrum index %d.', ...
                                                        string(scan.cvParam.Attributes.unitAccession), myInfo.index);
                                            end

                                        case 'MS:1000616'
                                            % preset scan configuration, ignored

                                        case 'MS:1000512'
                                            % filter string, ignored

                                        case 'MS:1000800'
                                            % resolving power, ignored

                                        case 'MS:1000927'
                                            myInfo.IonInjectionTime.Value = str2double(erase(scan.cvParam.Attributes.value, '"'));
                                            switch scan.cvParam.Attributes.unitAccession
                                                case 'UO:0000031'
                                                    myInfo.IonInjectionTime.Units = 'minute';
                                                case 'UO:0000028'
                                                    myInfo.IonInjectionTime.Units = 'millisecond';
                                                otherwise
                                                    error('Finnee:importMzML:UnsupportedInjectionTimeUnit', ...
                                                        'Unsupported ion injection time unit accession "%s" in spectrum index %d.', ...
                                                        string(scan.cvParam.Attributes.unitAccession), myInfo.index);
                                            end

                                        otherwise
                                            error('Finnee:importMzML:UnsupportedScanCvParam', ...
                                                'Unsupported scan cvParam accession "%s" in spectrum index %d.', ...
                                                string(scan.cvParam.Attributes.accession), myInfo.index);
                                    end

                                elseif isfield(scan, 'scanWindowList')
                                    for if4 = 1:numel(scan.scanWindowList.subElements)
                                        scanWindowList = scan.scanWindowList.subElements{if4};

                                        if ~isfield(scanWindowList, 'scanWindow')
                                            error('Finnee:importMzML:InvalidScanWindowStructure', ...
                                                'scanWindowList does not contain a scanWindow element in spectrum index %d.', ...
                                                myInfo.index);
                                        end

                                        for if5 = 1:numel(scanWindowList.scanWindow.subElements)
                                            scanWindow = scanWindowList.scanWindow.subElements{if5};

                                            switch scanWindow.cvParam.Attributes.accession
                                                case {'MS:1000500', 'MS:1000501'}
                                                    % upper/lower scan window bounds, ignored
                                                otherwise
                                                    error('Finnee:importMzML:UnsupportedScanWindowCvParam', ...
                                                        'Unsupported scanWindow cvParam accession "%s" in spectrum index %d.', ...
                                                        string(scanWindow.cvParam.Attributes.accession), myInfo.index);
                                            end
                                        end
                                    end

                                else
                                    error('Finnee:importMzML:UnsupportedScanSubElement', ...
                                        'Unsupported element found inside scanList/scan for spectrum index %d.', ...
                                        myInfo.index);
                                end
                            end

                        else
                            error('Finnee:importMzML:UnsupportedScanListSubElement', ...
                                'Unsupported element found inside scanList for spectrum index %d.', ...
                                myInfo.index);
                        end
                    end

                case 'precursorList'
                    count = str2double(erase(metaRun.spectrum.subElements{if1}.precursorList.Attributes.count, '"'));
                    if count ~= 1
                        error('Finnee:importMzML:UnsupportedPrecursorListCount', ...
                            'Expected precursorList count equal to 1, but found %d in spectrum index %d.', ...
                            count, myInfo.index);
                    end

                    if numel(metaRun.spectrum.subElements{if1}.precursorList.subElements) ~= 1
                        error('Finnee:importMzML:InvalidPrecursorListStructure', ...
                            'Expected exactly one precursor entry in precursorList for spectrum index %d.', ...
                            myInfo.index);
                    end

                    precursorElements = metaRun.spectrum.subElements{if1}.precursorList.subElements{1}.precursor.subElements;
                    for if3 = 1:numel(precursorElements)
                        precursor = precursorElements{if3};

                        if isfield(precursor, 'isolationWindow')
                            for if4 = 1:numel(precursor.isolationWindow.subElements)
                                accession = precursor.isolationWindow.subElements{if4}.cvParam.Attributes.accession;
                                value = str2double(erase(precursor.isolationWindow.subElements{if4}.cvParam.Attributes.value, '"'));

                                switch accession
                                    case 'MS:1000827'
                                        myInfo.isolationWindow(1) = value;
                                    case 'MS:1000828'
                                        myInfo.isolationWindow(2) = -value;
                                    case 'MS:1000829'
                                        myInfo.isolationWindow(3) = value;
                                    otherwise
                                        error('Finnee:importMzML:UnsupportedIsolationWindowCvParam', ...
                                            'Unsupported isolationWindow cvParam accession "%s" in spectrum index %d.', ...
                                            string(accession), myInfo.index);
                                end
                            end

                        elseif isfield(precursor, 'selectedIonList')
                            selectedCount = str2double(erase(precursor.selectedIonList.Attributes.count, '"'));
                            if selectedCount ~= 1
                                error('Finnee:importMzML:UnsupportedSelectedIonListCount', ...
                                    'Expected selectedIonList count equal to 1, but found %d in spectrum index %d.', ...
                                    selectedCount, myInfo.index);
                            end

                            if numel(precursor.selectedIonList.subElements) ~= 1
                                error('Finnee:importMzML:InvalidSelectedIonListStructure', ...
                                    'Expected exactly one selectedIon entry in spectrum index %d.', ...
                                    myInfo.index);
                            end

                            selectedIonSub = precursor.selectedIonList.subElements{1}.selectedIon.subElements;
                            if numel(selectedIonSub) ~= 1
                                error('Finnee:importMzML:UnsupportedSelectedIonCount', ...
                                    'Expected exactly one cvParam inside selectedIon for spectrum index %d.', ...
                                    myInfo.index);
                            end

                            selectedMz = str2double(erase(selectedIonSub{1}.cvParam.Attributes.value, '"'));
                            if isempty(myInfo.isolationWindow)
                                error('Finnee:importMzML:MissingIsolationWindow', ...
                                    'selectedIonList was found before isolationWindow information in spectrum index %d.', ...
                                    myInfo.index);
                            end

                            if selectedMz == myInfo.isolationWindow(1)
                                myInfo.IsDDA = true;
                            else
                                error('Finnee:importMzML:InconsistentPrecursorDefinition', ...
                                    ['Selected ion m/z (%.10g) does not match isolation window target m/z (%.10g) ' ...
                                    'in spectrum index %d.'], ...
                                    selectedMz, myInfo.isolationWindow(1), myInfo.index);
                            end

                        elseif isfield(precursor, 'activation')
                            % reserved for future use

                        else
                            error('Finnee:importMzML:UnsupportedPrecursorSubElement', ...
                                'Unsupported precursor subelement encountered in spectrum index %d.', ...
                                myInfo.index);
                        end
                    end

                case 'binaryDataArrayList'
                    count = str2double(erase(metaRun.spectrum.subElements{if1}.binaryDataArrayList.Attributes.count, '"'));
                    if count ~= 2
                        error('Finnee:importMzML:UnexpectedBinaryArrayCount', ...
                            'Expected exactly 2 binary data arrays, but found %d in spectrum index %d.', ...
                            count, myInfo.index);
                    end
                    dataSpectra.binaryDataArrayList = metaRun.spectrum.subElements{if1}.binaryDataArrayList.subElements;

                otherwise
                    error('Finnee:importMzML:UnsupportedSpectrumSubElement', ...
                        'Unsupported top-level spectrum subelement "%s" in spectrum index %d.', ...
                        string(mFN{1}), myInfo.index);
            end
        end
    end

    function [Check, Code] = verifyMzMLInfo(myInfo)
        Check = true;
        Code = '0000000000';

        if myInfo.IsCentroid && myInfo.IsProfile
            Check = false;
        end

        if myInfo.IsPositiveScan && myInfo.IsNegativeScan
            Check = false;
        end

        if myInfo.IsMS1 && myInfo.IsMSn
            Check = false;
        end

        if Check
            if myInfo.IsProfile, Code(10) = '1'; end
            if myInfo.IsPositiveScan, Code(9) = '1'; end
            if myInfo.IsMS1, Code(8) = '1'; end
            if myInfo.IsMSn, Code(7) = num2str(myInfo.MSLevel); end
        end
    end

    function [Scan, inf] = mkSpectra(inf, data)
        Encoding = struct();
        Encoding.binaryDataType = '';
        Encoding.compression = '';
        Encoding.DataType = '';
        Scan = [];

        nArrays = numel(data.binaryDataArrayList);
        switch nArrays
            case 2
                for if1 = 1:2
                    encodedLength = str2double(erase( ...
                        data.binaryDataArrayList{if1}.binaryDataArray.Attributes.encodedLength, '"')); %#ok<NASGU>

                    for if2 = 1:numel(data.binaryDataArrayList{if1}.binaryDataArray.subElements)
                        enc = data.binaryDataArrayList{if1}.binaryDataArray.subElements{if2};

                        if isfield(enc, 'cvParam')
                            switch enc.cvParam.Attributes.accession
                                case 'MS:1000523'
                                    Encoding.binaryDataType = '64_bit_float';

                                case 'MS:1000574'
                                    Encoding.compression = 'zlib';

                                case 'MS:1000514'
                                    Encoding.DataType = 'mz_array';
                                    inf.Axis{1}.unitName = erase(enc.cvParam.Attributes.unitName, '"');

                                case 'MS:1000515'
                                    Encoding.DataType = 'intensity_array';
                                    inf.Axis{2}.unitName = erase(enc.cvParam.Attributes.unitName, '"');

                                otherwise
                                    error('Finnee:importMzML:UnsupportedBinaryArrayCvParam', ...
                                        'Unsupported binaryDataArray cvParam accession "%s" in spectrum index %d.', ...
                                        string(enc.cvParam.Attributes.accession), inf.index);
                            end

                        elseif isfield(enc, 'binary')
                            if strcmp(Encoding.binaryDataType, '64_bit_float') && ...
                                    strcmp(Encoding.compression, 'zlib') && ...
                                    strcmp(Encoding.DataType, 'mz_array')

                                input = enc.binary.Content;
                                output = base64decode(input);
                                output = zlibdecode(output);
                                Scan(:, 1) = typecast(uint8(output), 'double');

                            elseif strcmp(Encoding.binaryDataType, '64_bit_float') && ...
                                    strcmp(Encoding.compression, 'zlib') && ...
                                    strcmp(Encoding.DataType, 'intensity_array')

                                input = enc.binary.Content;
                                output = base64decode(input);
                                output = zlibdecode(output);
                                Scan(:, 2) = typecast(uint8(output), 'double');

                            else
                                error('Finnee:importMzML:UnsupportedBinaryEncoding', ...
                                    ['Unsupported binary encoding combination in spectrum index %d. ' ...
                                    'Expected 64-bit float, zlib compression, and either mz_array or intensity_array.'], ...
                                    inf.index);
                            end

                        else
                            error('Finnee:importMzML:InvalidBinaryArrayStructure', ...
                                'Unexpected element encountered inside binaryDataArray in spectrum index %d.', ...
                                inf.index);
                        end
                    end
                end

            otherwise
                error('Finnee:importMzML:UnexpectedBinaryArrayContainer', ...
                    'Expected 2 binary data arrays, but found %d in spectrum index %d.', ...
                    nArrays, inf.index);
        end
    end

    function dt = parseISOdates(x)
        % PARSEISODATES Convert mixed ISO-8601 date strings to datetime.

        x = string(x);
        dt = NaT(size(x));

        fmts = [ ...
            "yyyy-MM-dd'T'HH:mm:ssX"
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"
            "yyyy-MM-dd'T'HH:mm:ssXXX"
            "yyyy-MM-dd'T'HH:mm:ss.SSSX"
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXX" ];

        for if3 = 1:numel(fmts)
            if all(~isnat(dt))
                break;
            end
            try
                dt = datetime(x, ...
                    'InputFormat', fmts(if3), ...
                    'TimeZone', 'UTC');
            catch
            end
        end

        if any(isnat(dt))
            error('Finnee:importMzML:InvalidTimestamp', ...
                'Unable to parse one or more ISO-8601 timestamps from the mzML metadata.');
        end

        dt.TimeZone = 'UTC';
    end

    function closeWaitbarSafe(hFig)
        if ~isempty(hFig) && isgraphics(hFig)
            close(hFig);
        end
    end

    function fcloseSafe(fid)
        if ~isempty(fid) && isnumeric(fid) && fid > 0
            try
                fclose(fid);
            catch
            end
        end
    end

end