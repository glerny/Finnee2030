function infoDataset(obj, dts)
% INFODATASET Display information about a dataset in the Finnee folder
%
%   infoDataset(OBJ) lists all datasets available in the Finnee folder.
%   infoDataset(OBJ, DTS) displays detailed information for the selected
%   dataset DTS.
%
%   This function reads the corresponding InfoDataset.mat file and prints
%   dataset metadata, creation date, and scan-type summary.
%
% BSD 3-Clause License
%
% Copyright (c) 2026, G. Erny
% All rights reserved.
%
% Author: G. Erny
% Email: guillaume.erny@gmail.com


narginchk(1, 2)
if nargin == 1, dts = []; end

fprintf('\n ######################################################################### \n')
if isempty(dts)
    fprintf('The finnee folder %s contains %i dataset(s)\n', obj.FileID, height(obj.Datasets))

    for ii = 1:height(obj.Datasets)
        fprintf('\t %s \n', obj.Datasets.Name{ii})
    end

else
    if isnumeric(dts), dts = "Dataset" + num2str(dts); end
    fprintf('Finnee folder: %s\n\n', obj.FileID)
    TgDtx = find(strcmp(obj.Datasets.Name, dts));

    if isempty(TgDtx)
         fprintf('\t%s does not exist\n', dts)

    else
        tgtFile = fullfile(obj.Path2Fin, dts, 'InfoDataset.mat');
        load(tgtFile, 'InfoDataset')
        fprintf('\t%s was created the %s\n', dts, string(InfoDataset.dateofcreation))

        switch InfoDataset.Options.ActionType
            case 'creator'
                fprintf('\tUsing the function %s and the datafile %s\n', InfoDataset.Options.FunctionUsed, InfoDataset.Options.FileIn)

            otherwise
                error('Unsupported ActionType: %s', string(InfoDataset.Options.ActionType))

        end
        scanTypes = unique(InfoDataset.ScanList.ScanCode);
        fprintf('\tThe %s contains\n', dts);

        for ii = 1:numel(scanTypes)
            switch scanTypes{ii}
                case "0000000111"
                    myString = '\t\t%i MS1 scans recorded in positive mode, as profile scans\n';

                case "0000002011"
                    myString = '\t\t%i MS2 scans recorded in positive mode, as profile scans\n';

                otherwise
                    error('Unsupported ScanCode: %s', scanTypes(ii))

            end

            fprintf(myString, sum(strcmp(InfoDataset.ScanList.ScanCode, scanTypes{ii})));
            fprintf('\t\t\tScan code: %s\n', scanTypes{ii});
        end    
    end
end
fprintf('\n ######################################################################### \n\n')
