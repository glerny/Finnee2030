classdef Spectrum
    %SPECTRUM Container for mass spectral data.
    %
    % A Spectrum object stores:
    % - metadata for display and plotting
    % - axis definitions
    % - the numeric spectral data
    % - additional provenance information
    %
    % DATA convention:
    % - typically [m/z, intensity]
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

    properties
        Title                   % Title of the trace
        FigureTitle             % Additional figure title / subtitle
        CodeScan                % Scan code used to build the spectrum
        IsCentroid              % True for centroid data, false for profile data
        MzAxis                  % Struct with axis metadata for m/z
        IntensityAxis           % Struct with axis metadata for intensity
        Interpolated            % True if scans share a common/interpolated m/z axis
        Data                    % Numeric data array
        AdditionalInformation   % Extra metadata / provenance
    end

    properties (Dependent)
        InfoTrc                 % Consolidated metadata structure
    end

    methods
        function obj = Spectrum(infoTrc, data2write)
            %SPECTRUM Construct a Spectrum object.
            %
            % obj = Spectrum()
            % Creates an empty/default Spectrum object.
            %
            % obj = Spectrum(infoTrc, data2write)
            % Creates a Spectrum using metadata in infoTrc and numeric data
            % in data2write.

            if nargin == 0
                obj.Title = '';
                obj.FigureTitle = '';
                obj.CodeScan = "";
                obj.IsCentroid = true;
                obj.MzAxis = struct();
                obj.IntensityAxis = struct();
                obj.Interpolated = [];
                obj.Data = [];
                obj.AdditionalInformation = struct();
                return
            end

            obj.Title = iGetStructField(infoTrc, 'Title', '');
            obj.FigureTitle = iGetStructField(infoTrc, 'FigureTitle', '');
            obj.CodeScan = string(iGetStructField(infoTrc, 'CodeScan', ""));
            obj.IsCentroid = iGetStructField(infoTrc, 'IsCentroid', true);
            obj.MzAxis = iGetStructField(infoTrc, 'MzAxis', struct());
            obj.IntensityAxis = iGetStructField(infoTrc, 'IntensityAxis', struct());
            obj.Interpolated = iGetStructField(infoTrc, 'Interpolated', []);
            obj.AdditionalInformation = iGetStructField(infoTrc, 'AdditionalInformation', struct());

            if nargin < 2 || isempty(data2write)
                obj.Data = [];
            else
                obj.Data = data2write;
            end
        end

        function infoTrc = get.InfoTrc(obj)
            %GET.INFOTRC Return metadata as a single structure.
            infoTrc = struct( ...
                'Title', obj.Title, ...
                'FigureTitle', obj.FigureTitle, ...
                'CodeScan', obj.CodeScan, ...
                'IsCentroid', obj.IsCentroid, ...
                'MzAxis', obj.MzAxis, ...
                'IntensityAxis', obj.IntensityAxis, ...
                'Interpolated', obj.Interpolated, ...
                'AdditionalInformation', obj.AdditionalInformation);
        end
    end
end

function value = iGetStructField(S, fieldName, defaultValue)
%IGETSTRUCTFIELD Safe extraction of a struct field.
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName) && ~isempty(S.(fieldName))
        value = S.(fieldName);
    end
end
