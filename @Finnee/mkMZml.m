%% DESCRIPTION

%
%% INPUT PARAMETERS
%
%
%% Copyright
% BSD 3-Clause License
% Copyright 2026 G. Erny (guillaume.erny@outlook.com)

function mkMZml(obj, dts, newFile)

if nargin < 3
    [filename, pathname, filterindex] = uiputfile( ...
        {'*.mzML','mzML files'});
    newFile = fullfile(pathname, filename);
end
newLine = '<?xml version="1.0" encoding="utf-8"?>';
fid = fopen(newFile, 'wt');
fprintf(fid, '%s\n',newLine);
fclose(fid);

path2Fin = string(obj.Path2Fin);
if strlength(path2Fin) == 0 || exist(path2Fin, 'dir') ~= 7
    error('Finnee:exportDatasetToMzML:InvalidPath2Fin', ...
        'obj.Path2Fin is missing or does not exist: %s', path2Fin);
end

datasetName = resolveDatasetName(obj, sourceDataset);
datasetFolder = fullfile(path2Fin, datasetName);
if exist(datasetFolder, 'dir') ~= 7
    error('Finnee:exportDatasetToMzML:MissingDataset', ...
        'Dataset folder not found: %s', datasetFolder);
end

metadata = load(fullfile(obj.Path2Fin, 'AquisitionData.mat')); metadata = metadata.metadata;
mzML = metadata.mzML;

% HEADERS
Head = mzML.Attributes;
fid = fopen(newFile, 'at');
newLine = mkMyLine('mzML', Head, true, 0);
fprintf(fid, '%s\n', newLine);

% BODY
Body = mzML.subElements;
for ii = 1:length(Body)
    sub1 = Body{ii};

    fsub1 = fields(sub1);
    if height(fsub1) > 1, error(''); end
    if strcmpi(fsub1{1}, 'run'), break, end
    hdg2 = fsub1{1};
    sub2 = sub1.(fsub1{1});

    if isfield(sub2, 'subElements')
        if isfield(sub2, 'Attributes')
            newLine = mkMyLine(hdg2, sub2.Attributes, true, 2);
            fprintf(fid, '%s\n', newLine);

        else
            newLine = ['  <', hdg2, '>'];
            writelines(newLine, newFile, 'WriteMode', 'append');

        end

        for jj = 1:length(sub2.subElements)
            sub3 = sub2.subElements{jj};
            fsub3 = fields(sub3);
            if height(fsub3) > 1, error(''); end

            hdg4 = fsub3{1};
            sub4 = sub3.(fsub3{1});

            if isfield(sub4, 'subElements')
                if isfield(sub4, 'Attributes')
                    newLine = mkMyLine(hdg4, sub4.Attributes, true, 4);
                    fprintf(fid, '%s\n', newLine);

                else
                    newLine = ['    <', hdg4, '>'];
                    writelines(newLine, newFile, 'WriteMode', 'append');

                end

                for kk = 1:length(sub4.subElements)
                    sub5 = sub4.subElements{kk};
                    fsub5 = fields(sub5);
                    if height(fsub5) > 1, error(''); end

                    hdg6 = fsub5{1};
                    sub6 = sub5.(fsub5{1});

                    if isfield(sub6, 'subElements')
                        if isfield(sub6, 'Attributes')
                            newLine = mkMyLine(hdg6, sub6.Attributes, true, 6);
                            fprintf(fid, '%s\n', newLine);

                        else
                            newLine = ['      <', hdg6, '>'];
                            writelines(newLine, newFile, 'WriteMode', 'append');

                        end

                        for ll = 1:length(sub6.subElements)
                            sub7 = sub6.subElements{ll};
                            fsub7 = fields(sub7);
                            if height(fsub7) > 1, error(''); end

                            hdg8 = fsub7{1};
                            sub8 = sub7.(fsub7{1});

                            if isfield(sub8, 'subElements')
                                if isfield(sub8, 'Attributes')
                                    newLine = mkMyLine(hdg8, sub8.Attributes, true, 8);
                                    fprintf(fid, '%s\n', newLine);

                                else
                                    newLine = ['        <', hdg8, '>'];
                                    writelines(newLine, newFile, 'WriteMode', 'append');

                                end

                                for mm = 1:length(sub8.subElements)
                                    sub9 = sub8.subElements{mm};
                                    fsub9 = fields(sub9);
                                    if height(fsub9) > 1, error(''); end

                                    hdg10 = fsub9{1};
                                    sub10 = sub9.(fsub9{1});

                                    if isfield(sub10, 'subElements')
                                        error('')

                                    else
                                        newLine = mkMyLine(hdg10, sub10.Attributes, false, 10);
                                        fprintf(fid, '%s\n', newLine);

                                    end
                                end
                                newLine = ['        </',hdg8,'>'];
                                fprintf(fid, '%s\n', newLine);

                            else
                                newLine = mkMyLine(hdg8, sub8.Attributes, false, 8);
                                fprintf(fid, '%s\n', newLine);

                            end
                        end
                        newLine = ['      </',hdg6,'>'];
                        fprintf(fid, '%s\n', newLine);

                    else
                        newLine = mkMyLine(hdg6, sub6.Attributes, false, 6);
                        fprintf(fid, '%s\n', newLine);

                    end
                end
                newLine = ['    </',hdg4,'>'];
                fprintf(fid, '%s\n', newLine);

            else
                newLine = mkMyLine(hdg4, sub4.Attributes, false, 4);
                fprintf(fid, '%s\n', newLine);

            end
        end
        newLine = ['  </',hdg2,'>'];
        fprintf(fid, '%s\n', newLine);


    else
        newLine = mkMyLine(hdg2, sub2.Attributes, false, 2);
        fprintf(fid, '%s\n', newLine);

    end
end

run = Body{ii}.run;
Id2Dataset = strcmp(['Dataset', num2str(dts)], obj.Datasets.Name);
infoDataset = load(fullfile(obj.Path2Fin, obj.Datasets.Name{Id2Dataset}, 'infoDataset.mat'));
infoDataset = infoDataset.infoDataset;
fidRead = fopen(fullfile(obj.Path2Fin, obj.Datasets.Name{Id2Dataset}, 'Profiles.dat'), 'rb');
Profiles = fread(fidRead, [infoDataset.Profiles.size], "double");
fclose(fidRead);
Profiles = array2table(Profiles);
ColumnNames = {}; ColumnUnits = {};
for ii = 1:numel(infoDataset.Profiles.column)
    ColumnNames{ii}     = infoDataset.Profiles.column{ii}.name;
    ColumnLabels{ii}    = infoDataset.Profiles.column{ii}.labelUnits;
    ColumnUnits{ii}     = infoDataset.Profiles.column{ii}.units;
    ColumnFO{ii}        = infoDataset.Profiles.column{1, 1}.formatUnits;
end
Profiles.Properties.VariableNames = ColumnNames;
Profiles.Properties.VariableUnits = ColumnUnits;
Opt4Crt = obj.Datasets.Options4Creations{Id2Dataset};

newLine = mkMyLine('run', run.Attributes, true, 2);
fprintf(fid, '%s\n', newLine);
newLine = ['    <spectrumList count="', num2str(height(Profiles)), '" defaultDataProcessingRef="">'];
fprintf(fid, '%s\n', newLine);

for ii = 1:height(Profiles)
    myScan = obj.getScan(dts, Profiles.Scan_Index(ii));
    [IMax, IdMax] = max(myScan.XY(:, 2));
    BpMax = myScan.XY(IdMax, 1);
    ITot = sum(myScan.XY(:, 2));

    if isempty(myScan.XY)
        txt_x = '';
        txt_y = '';

    else
        bytes = typecast(myScan.XY(:, 1), 'uint8');
        c = zlibencode(bytes);
        txt_x = base64encode(c);
        bytes = typecast(myScan.XY(:, 2), 'uint8');
        c = zlibencode(bytes);
        txt_y = base64encode(c);
    end

    newLine = ['      <spectrum index="', num2str(myScan.Index), '" id="scan=',num2str(myScan.Index+1) ,'" defaultArrayLength="', num2str(height(myScan.XY)), '">'];
    fprintf(fid, '%s\n', newLine);
    newLine = '        <cvParam cvRef="MS" accession="MS:1000579" name="MS1 spectrum" value=""/>';
    fprintf(fid, '%s\n', newLine);
    newLine = '        <cvParam cvRef="MS" accession="MS:1000511" name="ms level" value="1"/>';
    fprintf(fid, '%s\n', newLine);
    %TODO: Add control for positive/negative scan
    newLine = '        <cvParam cvRef="MS" accession="MS:1000130" name="positive scan" value=""/>';
    fprintf(fid, '%s\n', newLine);
    newLine = '        <cvParam cvRef="MS" accession="MS:1000128" name="profile spectrum" value=""/>';
    fprintf(fid, '%s\n', newLine);
    newLine = ['        <cvParam cvRef="MS" accession="MS:1000504" name="base peak m/z" value="', num2str(BpMax), '" unitCvRef="MS" unitAccession="MS:1000040" unitName="m/z"/>'];
    fprintf(fid, '%s\n', newLine);
    newLine = ['        <cvParam cvRef="MS" accession="MS:1000505" name="base peak intensity" value="', num2str(IMax), '" unitCvRef="MS" unitAccession="MS:1000131" unitName="number of detector counts"/>'];
    fprintf(fid, '%s\n', newLine);
    newLine = ['        <cvParam cvRef="MS" accession="MS:1000285" name="total ion current" value="', num2str(ITot), '"/>'];
    fprintf(fid, '%s\n', newLine);
    newLine = ['        <cvParam cvRef="MS" accession="MS:1000528" name="lowest observed m/z" value="', min(myScan.XY(:, 1)), '" unitCvRef="MS" unitAccession="MS:1000040" unitName="m/z"/>'];
    fprintf(fid, '%s\n', newLine);
    newLine = ['        <cvParam cvRef="MS" accession="MS:1000527" name="highest observed m/z" value="', max(myScan.XY(:, 1)), '" unitCvRef="MS" unitAccession="MS:1000040" unitName="m/z"/>'];
    fprintf(fid, '%s\n', newLine);
    newLine = '        <cvParam cvRef="MS" accession="MS:1000796" name="spectrum title" value=""/>';
    fprintf(fid, '%s\n', newLine);
    newLine = '        <scanList count="1">';
    fprintf(fid, '%s\n', newLine);
    newLine = '          <cvParam cvRef="MS" accession="MS:1000795" name="no combination" value=""/>';
    fprintf(fid, '%s\n', newLine);
    newLine = '          <scan>';
    fprintf(fid, '%s\n', newLine);
    newLine = ['            <cvParam cvRef="MS" accession="MS:1000016" name="scan start time" value="', num2str(myScan.Time), '" unitCvRef="UO" unitAccession="UO:0000031" unitName="minute"/>'];
    fprintf(fid, '%s\n', newLine);
    newLine = '          </scan>';
    fprintf(fid, '%s\n', newLine);
    newLine = '        </scanList>';
    fprintf(fid, '%s\n', newLine);
    newLine = '        <binaryDataArrayList count="2">';
    fprintf(fid, '%s\n', newLine);
    newLine = ['          <binaryDataArray encodedLength="' num2str(length(txt_x)), '">'];
    fprintf(fid, '%s\n', newLine);
    newLine = '            <cvParam cvRef="MS" accession="MS:1000523" name="64-bit float" value=""/>';
    fprintf(fid, '%s\n', newLine);
    newLine = '            <cvParam cvRef="MS" accession="MS:1000574" name="zlib compression" value=""/>';
    fprintf(fid, '%s\n', newLine);
    newLine = '            <cvParam cvRef="MS" accession="MS:1000514" name="m/z array" value="" unitCvRef="MS" unitAccession="MS:1000040" unitName="m/z"/>';
    fprintf(fid, '%s\n', newLine);
    newLine = ['            <binary>', txt_x, '</binary>'];
    fprintf(fid, '%s\n', newLine);
    newLine = '          </binaryDataArray>';
    fprintf(fid, '%s\n', newLine);
    newLine = ['          <binaryDataArray encodedLength="' num2str(length(txt_y)), '">'];
    fprintf(fid, '%s\n', newLine);
    newLine = '            <cvParam cvRef="MS" accession="MS:1000523" name="64-bit float" value=""/>';
    fprintf(fid, '%s\n', newLine);
    newLine = '            <cvParam cvRef="MS" accession="MS:1000574" name="zlib compression" value=""/>';
    fprintf(fid, '%s\n', newLine);
    newLine = '            <cvParam cvRef="MS" accession="MS:1000515" name="intensity array" value="" unitCvRef="MS" unitAccession="MS:1000131" unitName="number of detector counts"/>';
    fprintf(fid, '%s\n', newLine);
    newLine = ['            <binary>', txt_y, '</binary>'];
    fprintf(fid, '%s\n', newLine);
    newLine = '          </binaryDataArray>';
    fprintf(fid, '%s\n', newLine);
    newLine = '        </binaryDataArrayList>';
    fprintf(fid, '%s\n', newLine);
    newLine = '      </spectrum>';
    fprintf(fid, '%s\n', newLine);

end
newLine = '    </spectrumList>';
fprintf(fid, '%s\n', newLine);
newLine = '  </run>';
fprintf(fid, '%s\n', newLine);
newLine = '</mzML>';
fprintf(fid, '%s\n', newLine);
fclose(fid);

    function newLine = mkMyLine(enTete, strc, isopen, nb_blk)
        newLine = '';
        for if1 = 1:nb_blk
            newLine = [newLine, ' '];

        end
        newLine = [newLine, '<', enTete];

        fstrc = fieldnames(strc);
        for if1 = 1:height(fstrc)
            tag = strrep(fstrc{if1}, '_colon_', ':');
            content = num2str(strc.(fstrc{if1}));
            if ~isempty(content)
                if content(1) == '"', content = content(2:end); end
            end
            if ~isempty(content)
                if content(end) == '"', content = content(1:end-1); end
            end

            newLine = [newLine, ' ', tag, '="', content, '"'];
        end

        if isopen
            newLine = [newLine, '>'];

        else
            newLine = [newLine, '/>'];
        end
    end

end

function datasetName = resolveDatasetName(obj, sourceDataset)
if isnumeric(sourceDataset) || islogical(sourceDataset)
    if ~isscalar(sourceDataset) || ~isfinite(sourceDataset)
        error('Finnee:exportDatasetToMzML:InvalidDatasetIndex', ...
            'Numeric sourceDataset must be a finite scalar.');
    end
    idx = round(double(sourceDataset));
    if idx ~= double(sourceDataset) || idx < 0
        error('Finnee:exportDatasetToMzML:InvalidDatasetIndex', ...
            'Numeric sourceDataset must be a non-negative integer.');
    end
    datasetName = "Dataset" + string(idx);
    return
end

if isstring(sourceDataset) || ischar(sourceDataset)
    txt = strtrim(string(sourceDataset));
    if strlength(txt) == 0
        error('Finnee:exportDatasetToMzML:InvalidDatasetName', ...
            'String sourceDataset cannot be empty.');
    end
    val = str2double(txt);
    if ~isnan(val) && isfinite(val) && val >= 0 && round(val) == val
        datasetName = "Dataset" + string(round(val));
        return
    end
    datasetName = txt;
    return
end

error('Finnee:exportDatasetToMzML:InvalidSourceDataset', ...
    'sourceDataset must be an integer index or a dataset name string.');
end