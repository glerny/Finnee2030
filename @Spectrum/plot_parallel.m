function plot_parallel(obj)
%PLOT_PARALLEL Plot a Spectrum object and use parallel extraction callbacks.
%
% Centroid spectra are plotted as stick spectra.
% Profile spectra are plotted as continuous traces.
%
% Toolbar actions:
% - Extract chromatographic profile from an m/z interval
% - Export spectrum object to base workspace
%
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

if isempty(obj.Data) || size(obj.Data, 2) < 2
    error('Spectrum:plot_parallel:InvalidData', ...
        'Spectrum.Data must contain at least two columns: [m/z intensity].');
end

x = obj.Data(:, 1);
y = obj.Data(:, 2);

infoX = obj.MzAxis;
infoY = obj.IntensityAxis;

foX = iGetFormat(infoX, '%0.4f');
foY = iGetFormat(infoY, '%0.3g');

fig = figure( ...
    'Name', obj.FigureTitle, ...
    'NumberTitle', 'off', ...
    'Color', 'w');

ax = axes('Parent', fig);
hold(ax, 'on');
grid(ax, 'on');
box(ax, 'on');

if obj.IsCentroid
    hPlot = line(ax, [x x].', [zeros(size(y)) y].', ...
        'Color', [0 0 0], ...
        'LineWidth', 1.0);
else
    hPlot = plot(ax, x, y, ...
        'b-', ...
        'LineWidth', 1.0);
end

title(ax, obj.Title, 'Interpreter', 'none');
xlabel(ax, iMakeAxisLabel(infoX, 'm/z'));
ylabel(ax, iMakeAxisLabel(infoY, 'Intensity'));

ud = struct( ...
    'infoX', infoX, ...
    'infoY', infoY, ...
    'foX', foX, ...
    'foY', foY);

if isgraphics(hPlot)
    if numel(hPlot) == 1
        hPlot.UserData = ud;
    else
        for k = 1:numel(hPlot)
            hPlot(k).UserData = ud;
        end
    end
end

dcm = datacursormode(fig);
set(dcm, 'UpdateFcn', @myupdatefcn);

tb = findall(fig, 'Type', 'uitoolbar');
if isempty(tb)
    tb = uitoolbar(fig);
else
    tb = tb(1);
end

uipushtool(tb, ...
    'TooltipString', 'Extract chromatographic profile from an m/z interval', ...
    'ClickedCallback', @onMkProfile_2);

uipushtool(tb, ...
    'TooltipString', 'Export spectrum object to base workspace', ...
    'ClickedCallback', @onExportButton);

% ---------------------------------------------------------------------
% Nested callbacks
% ---------------------------------------------------------------------
    function onExportButton(~, ~)
        assignin('base', 'mySpectrum', obj);
    end

    function txt = myupdatefcn(~, event_obj)
        pos = get(event_obj, 'Position');

        txt = { ...
            sprintf('%s = %s %s', ...
                iGetField(infoX, 'label', 'm/z'), ...
                num2str(pos(1), foX), ...
                iGetField(infoX, 'Unit', '')) ...
            sprintf('%s = %s %s', ...
                iGetField(infoY, 'label', 'Intensity'), ...
                num2str(pos(2), foY), ...
                iGetField(infoY, 'Unit', '')) ...
            };
    end

    function onMkProfile_2(~, ~)
        myFinnee = iGetFinneeObject(obj);
        myDts = iGetDatasetName(obj);

        [xp, ~] = ginput(2);
        xp = sort(xp(:)).';

        execOpts = iResolveExecutionOptions(obj);

        if execOpts.ExecutionMode == "serial"
            myProfile = myFinnee.mkProfile(myDts, xp, ...
                CodeScan = obj.CodeScan, ...
                FastMode = execOpts.FastMode);
            myProfile.plot
        else
            myProfile = myFinnee.mkProfile_parallel(myDts, xp, ...
                CodeScan = obj.CodeScan, ...
                FastMode = execOpts.FastMode);
            myProfile.plot_parallel
        end
    end
end

% =========================================================================
function fmt = iGetFormat(axisInfo, defaultFmt)
fmt = defaultFmt;

if ~isstruct(axisInfo) || ~isfield(axisInfo, 'Precision')
    return
end

p = axisInfo.Precision;
if isempty(p) || ~isscalar(p) || ~isnumeric(p) || ~isfinite(p)
    return
end

fmt = sprintf('%%0.%df', p);
end

% =========================================================================
function label = iMakeAxisLabel(axisInfo, defaultLabel)
lbl = string(iGetField(axisInfo, 'label', defaultLabel));
unt = string(iGetField(axisInfo, 'Unit', ''));

if strlength(unt) > 0
    label = char(lbl + " / " + unt);
else
    label = char(lbl);
end
end

% =========================================================================
function value = iGetField(S, fieldName, defaultValue)
value = defaultValue;
if isstruct(S) && isfield(S, fieldName) && ~isempty(S.(fieldName))
    value = S.(fieldName);
end
end

% =========================================================================
function myFinnee = iGetFinneeObject(obj)
if ~isfield(obj.AdditionalInformation, 'Finnee')
    error('Spectrum:plot_parallel:MissingFinnee', ...
        'AdditionalInformation.Finnee is missing.');
end

myFinnee = obj.AdditionalInformation.Finnee;
end

% =========================================================================
function myDts = iGetDatasetName(obj)
if ~isfield(obj.AdditionalInformation, 'Dataset')
    error('Spectrum:plot_parallel:MissingDataset', ...
        'AdditionalInformation.Dataset is missing.');
end
myDts = string(obj.AdditionalInformation.Dataset);
end

% =========================================================================
function execOpts = iResolveExecutionOptions(obj)
execOpts = struct('FastMode', false, 'ExecutionMode', "parallel");

if isfield(obj.AdditionalInformation, 'FastMode') && ...
        ~isempty(obj.AdditionalInformation.FastMode)
    execOpts.FastMode = logical(obj.AdditionalInformation.FastMode);
else
    execOpts.FastMode = iAskFastMode(execOpts.FastMode, ...
        'Profile extraction options', ...
        'Do you want to use FastMode for profile extraction?');
end

if isfield(obj.AdditionalInformation, 'ExecutionModeUsed') && ...
        ~isempty(obj.AdditionalInformation.ExecutionModeUsed)
    execOpts.ExecutionMode = string(obj.AdditionalInformation.ExecutionModeUsed);
elseif isfield(obj.AdditionalInformation, 'ExecutionModeRequested') && ...
        ~isempty(obj.AdditionalInformation.ExecutionModeRequested)
    execOpts.ExecutionMode = string(obj.AdditionalInformation.ExecutionModeRequested);
end

if ~ismember(execOpts.ExecutionMode, ["serial","parallel"])
    execOpts.ExecutionMode = "parallel";
end
end

% =========================================================================
function fastMode = iAskFastMode(defaultFastMode, dlgTitle, dlgText)
answer = questdlg( ...
    dlgText, ...
    dlgTitle, ...
    'Yes', 'No', 'Cancel', ...
    iLogicalToYesNo(defaultFastMode));

if isempty(answer) || strcmp(answer, 'Cancel')
    error('Spectrum:plot_parallel:UserCancelled', ...
        'Profile extraction cancelled by user.');
end

fastMode = strcmp(answer, 'Yes');
end

% =========================================================================
function txt = iLogicalToYesNo(tf)
if tf
    txt = 'Yes';
else
    txt = 'No';
end
end