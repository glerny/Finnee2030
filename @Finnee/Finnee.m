classdef Finnee
% FINNEE  Constructor and container class for Finnee2030 datasets.
%
% This class initializes a Finnee project from raw input data or existing
% Finnee-compatible resources, validates user options, creates the output
% folder structure, dispatches the appropriate import workflow, and stores
% project metadata and dataset information.
%
% Supported modes:
%   "single"    Create a Finnee object from one input file.
%   "multiple"  Reserved for future support of multi-file workflows.
%   "replicate" Reserved for future support of replicate workflows.
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


    properties (SetAccess = private)
        FileID string = ""
        FileIn string = ""
        DateOfDataAcq datetime = NaT
        DateOfCreation datetime = NaT
        Datasets table = table()
        Path2Fin string = ""
        Type string = ""
        FinneesIn cell = {}
        Version string = "0.01.01"
        Options struct = struct()
   
    end

    methods
        function obj = Finnee(mode, varargin)
            if nargin == 0 || isempty(mode)
                mode = "single";
            end

            obj.Options.Precisions = struct( ...
                "Time", "0.2f", ...
                "Intensity", "0.0f", ...
                "MZ", "0.4f", ...
                "Other", "0.0f");
            obj.Options.canUseParallel = true;

            mode = Finnee.normalizeMode(mode);

            opts = Finnee.parseInputs(mode, varargin{:});
            opts = Finnee.resolveInteractiveInputs(mode, opts);
            Finnee.validateInputs(mode, opts);

            obj = obj.initializeEmpty(mode, opts);
            obj = obj.prepareOutputFolder(opts);

            switch mode
                case "single"
                    obj = obj.buildSingle(opts);

                case "multiple"
                    obj = obj.buildMultiple(opts);

                case "replicate"
                    obj = obj.buildReplicate(opts);

                otherwise
                    error("Finnee:InvalidMode", "Unsupported mode: %s", mode);
                    
            end

            obj.saveObject();
        end

        function obj = initializeEmpty(obj, mode, opts)
            % obj = Finnee.empty;
            obj.Type = mode;
            obj.DateOfCreation = datetime("now");
            obj.FileID = string(opts.FileID);
            obj.Datasets = table();
            obj.FinneesIn = {};
            if isfield(opts,"FinneesIn")
                obj.FinneesIn = opts.FinneesIn;
            end
            if isfield(opts,"FileIn")
                obj.FileIn = string(opts.FileIn);
            end
        end

        function obj = prepareOutputFolder(obj, opts)
            obj.Path2Fin = fullfile(opts.FolderOut, obj.FileID + ".fin");

            if exist(obj.Path2Fin, 'dir') == 7
                if opts.Overwrite
                    rmdir(obj.Path2Fin, 's');
                else
                    error("Finnee:OutputExists", ...
                        "Directory already exists: %s", obj.Path2Fin);
                end
            end

            mkdir(obj.Path2Fin);
        end

        function obj = buildSingle(obj, opts)
            [~,~,ext] = fileparts(opts.FileIn);
            ext = lower(string(ext));

            switch ext
                case ".mzml"
                    obj = obj.importMzML(opts);
                otherwise
                    error("Finnee:UnsupportedFormat", ...
                        "Unsupported input format: %s", ext);
            end
        end

        function obj = buildMultiple(obj, opts)
            error("Finnee:NotImplemented", ...
                "Multiple mode has not yet been implemented.");
        end

        function obj = buildReplicate(obj, opts)
            error("Finnee:NotImplemented", ...
                "Replicate mode has not yet been implemented.");
        end

        function saveObject(obj)
            myFinnee = obj; 
            save(fullfile(obj.Path2Fin, 'myFinnee.mat'), 'myFinnee');
        end
    end

    methods (Static, Access = private)
        function mode = normalizeMode(mode)
            mode = string(mode);
            mode = lower(strtrim(mode));

            switch mode
                case {"single","multiple","replicate"}
                otherwise
                    error("Finnee:InvalidMode", ...
                        "Mode must be 'single', 'multiple', or 'replicate'.");
            end
        end

        function opts = parseInputs(mode, varargin)
            opts = Finnee.defaultOptions(mode);

            if numel(varargin) == 1 && isstruct(varargin{1})
                user = varargin{1};
                f = fieldnames(user);
                for k = 1:numel(f)
                    opts.(f{k}) = user.(f{k});
                end
                return
            end

            if rem(numel(varargin),2) ~= 0
                error("Finnee:InvalidInput", ...
                    "Inputs must be name-value pairs or a single struct.");
            end

            for k = 1:2:numel(varargin)
                name = string(varargin{k});
                value = varargin{k+1};
                opts.(char(name)) = value;
            end

        end

        function opts = defaultOptions(mode)
            opts = struct();
            opts.FileIn = "";
            opts.FolderOut = "";
            opts.FileID = "";
            opts.Overwrite = false;
            opts.Interactive = false;
            opts.TimeLimits = [0 inf];
            opts.MzLimits = [0 inf];
            opts.RemoveSpikes = true;
            opts.SpikeSize = 1;
            opts.UseParallel = false;
            opts.ShowProgress = true;

        end

        function opts = resolveInteractiveInputs(mode, opts)
           
            switch mode
                case "single"
                    if strlength(opts.FileIn) == 0
                        [f,p] = uigetfile('*.mzML', 'Select mzML file');
                        if isequal(f,0), error("Finnee:UserCancel","File selection cancelled."); end
                        opts.FileIn = fullfile(p,f);
                    end

                    if strlength(opts.FileID) == 0
                        [~,dflt] = fileparts(opts.FileIn);
                        a = inputdlg('Enter destination name','FileID',1,{char(dflt)});
                        if isempty(a) || isempty(a{1})
                            error("Finnee:UserCancel","Name selection cancelled.");
                        end
                        opts.FileID = string(a{1});
                    end

                    if strlength(opts.FolderOut) == 0
                        p = uigetdir(pwd, 'Select output folder');
                        if isequal(p,0), error("Finnee:UserCancel","Folder selection cancelled."); end
                        opts.FolderOut = string(p);
                    end

                case {"multiple","replicate"}
                    if isempty(opts.FinneesIn)
                        opts.FinneesIn = uigetdirs();
                    end

                    if strlength(opts.FileID) == 0
                        a = inputdlg('Enter destination name','FileID',1,{'Merged_'});
                        if isempty(a) || isempty(a{1})
                            error("Finnee:UserCancel","Name selection cancelled.");
                        end
                        opts.FileID = string(a{1});
                    end

                    if strlength(opts.FolderOut) == 0
                        p = uigetdir(pwd, 'Select output folder');
                        if isequal(p,0), error("Finnee:UserCancel","Folder selection cancelled."); end
                        opts.FolderOut = string(p);
                    end
            end
        end

        function validateInputs(mode, opts)
            mustBeMember(mode, ["single","multiple","replicate"]);

            if strlength(opts.FolderOut) == 0
                error("Finnee:MissingFolderOut", "FolderOut is required.");
            end

            if strlength(opts.FileID) == 0
                error("Finnee:MissingFileID", "FileID is required.");
            end

            if numel(opts.TimeLimits) ~= 2
                error("Finnee:InvalidTimeLimits", "TimeLimits must be [tmin tmax].");
            end

            if numel(opts.MzLimits) ~= 2
                error("Finnee:InvalidMzLimits", "MzLimits must be [mzmin mzmax].");
            end

            if mode == "single"
                if strlength(opts.FileIn) == 0
                    error("Finnee:MissingFileIn", "FileIn is required for single mode.");
                end
            else
                if isempty(opts.FinneesIn)
                    error("Finnee:MissingFinneesIn", ...
                        "FinneesIn is required for multiple/replicate mode.");
                end
            end
        end
    end
end