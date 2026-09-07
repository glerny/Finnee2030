classdef Profile
%PROFILE Container for chromatographic profile data.
%
% A Profile object stores:
% - metadata for display and plotting
% - axis definitions
% - the numeric profile data
% - additional provenance information
%
% DATA convention:
% - if HasMzData == false: [time, intensity]
% - if HasMzData == true : [time, intensity, mz]
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
    Title % Title of the trace
    FigureTitle % Additional figure title / subtitle
    CodeScan % Scan code used to build the profile
    IsCentroid % True for centroid data, false for profile data
    HasMzData % True when third column contains m/z information
    TimeAxis % Struct with axis metadata for time
    IntensityAxis % Struct with axis metadata for intensity
    MzAxis % Struct with axis metadata for m/z
    Interpolated % True if scans share a common/interpolated m/z axis
    Data % Numeric data array
    AdditionalInformation % Extra metadata/provenance
end

properties (Dependent)
    InfoTrc % Get back the data of the Axis
end

methods

    function obj = Profile(infoTrc, data4profile)
        %PROFILE Construct a Profile object.
        %
        % obj = Profile()
        % Creates an empty/default Profile object.
        %
        % obj = Profile(infoTrc, data4profile)
        % Creates a Profile using metadata in infoTrc and numeric data
        % in data4profile.

        if nargin == 0
            obj.Title = '';
            obj.FigureTitle = '';
            obj.CodeScan = "";
            obj.IsCentroid = true;
            obj.HasMzData = false;
            obj.TimeAxis = struct();
            obj.IntensityAxis = struct();
            obj.MzAxis = struct();
            obj.Interpolated = [];
            obj.Data = [];
            obj.AdditionalInformation = struct();
            return
        end

        obj.Title = infoTrc.Title;
        obj.FigureTitle = infoTrc.FigureTitle;
        obj.CodeScan = infoTrc.CodeScan;
        obj.IsCentroid = infoTrc.IsCentroid;
        obj.HasMzData = infoTrc.HasMzData;
        obj.TimeAxis = infoTrc.TimeAxis;
        obj.IntensityAxis = infoTrc.IntensityAxis;
        obj.MzAxis = infoTrc.MzAxis;
        obj.Interpolated = infoTrc.Interpolated;
        obj.Data = data4profile;
        obj.AdditionalInformation = infoTrc.AdditionalInformation;
    end

    function infoTrc = get.InfoTrc(obj)
        %GET.INFOTRC Return metadata as a single structure.
        infoTrc = struct( ...
            'Title', obj.Title, ...
            'FigureTitle', obj.FigureTitle, ...
            'CodeScan', obj.CodeScan, ...
            'IsCentroid', obj.IsCentroid, ...
            'HasMzData', obj.HasMzData, ...
            'TimeAxis', obj.TimeAxis, ...
            'IntensityAxis', obj.IntensityAxis, ...
            'MzAxis', obj.MzAxis, ...
            'Interpolated', obj.Interpolated, ...
            'AdditionalInformation', obj.AdditionalInformation);
    end
end
end