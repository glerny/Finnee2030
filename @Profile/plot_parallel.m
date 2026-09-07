function plot_parallel(obj, mode)
%PLOT_PARALLEL Plot a Profile object and use parallel extraction callbacks.
%
% plot_parallel(obj)
% plot_parallel(obj, mode)
%
% mode:
% "trace"     - plot the main 2D trace only
% "overlaymz" - plot the main trace and superpose m/z on the right axis
% "subpltmz"  - plot the main trace and m/z in two linked subplots
%
% Toolbar actions:
% - Get the MS spectrum from one point
% - Get the MS spectrum from two points (interpolated profiles only)
% - Peak picking
% - Export profile object to base workspace
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

arguments
    obj
    mode {mustBeMember(mode, ["trace","overlaymz","subpltmz"])} = "subpltmz"
end

if isempty(obj.Data) || size(obj.Data, 2) < 2
    error('Profile:plot_parallel:InvalidData', ...
        'Profile.Data must contain at least two columns.');
end

hasMzData = obj.HasMzData && size(obj.Data, 2) >= 3;
if ~hasMzData && mode ~= "trace"
    warning('Profile:plot_parallel:NoMzData', ...
        'm/z data are not available. Falling back to trace-only display.');
    mode = "trace";
end

infoX = obj.TimeAxis;
infoY = obj.IntensityAxis;
infoMz = obj.MzAxis;

foX = iGetFormat(infoX, '%0.3f');
foY = iGetFormat(infoY, '%0.3g');
foMz = iGetFormat(infoMz, '%0.4f');

fig = figure( ...
    'Name', obj.FigureTitle, ...
    'NumberTitle', 'off', ...
    'Color', 'w');

switch mode
    case "trace"
        axMain = axes('Parent', fig);
        hMain = plot(axMain, obj.Data(:,1), obj.Data(:,2), 'b-');
        grid(axMain, 'on')
        title(axMain, obj.Title, 'Interpreter', 'none');
        xlabel(axMain, iMakeAxisLabel(infoX, 'X'));
        ylabel(axMain, iMakeAxisLabel(infoY, 'Y'));
        iSetUserData(hMain, obj.Data, infoX, infoY, infoMz, foX, foY, foMz, hasMzData, "main");

    case "overlaymz"
        axMain = axes('Parent', fig);

        yyaxis(axMain, 'left')
        hMain = plot(axMain, obj.Data(:,1), obj.Data(:,2), 'b-');
        ylabel(axMain, iMakeAxisLabel(infoY, 'Y'));

        yyaxis(axMain, 'right')
        hMz = plot(axMain, obj.Data(:,1), obj.Data(:,3), 'r-');
        ylabel(axMain, iMakeAxisLabel(infoMz, 'm/z'));

        xlabel(axMain, iMakeAxisLabel(infoX, 'X'));
        title(axMain, obj.Title, 'Interpreter', 'none');
        grid(axMain, 'on')

        iSetUserData(hMain, obj.Data, infoX, infoY, infoMz, foX, foY, foMz, hasMzData, "main");
        iSetUserData(hMz, obj.Data, infoX, infoY, infoMz, foX, foY, foMz, hasMzData, "mz");

    case "subpltmz"
        t = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

        ax1 = nexttile(t, 1);
        hMain = plot(ax1, obj.Data(:,1), obj.Data(:,2), 'b-');
        grid(ax1, 'on')
        title(ax1, obj.Title, 'Interpreter', 'none');
        ylabel(ax1, iMakeAxisLabel(infoY, 'Y'));

        ax2 = nexttile(t, 2);
        hMz = plot(ax2, obj.Data(:,1), obj.Data(:,3), 'r-');
        grid(ax2, 'on')
        xlabel(ax2, iMakeAxisLabel(infoX, 'X'));
        ylabel(ax2, iMakeAxisLabel(infoMz, 'm/z'));

        linkaxes([ax1 ax2], 'x');

        iSetUserData(hMain, obj.Data, infoX, infoY, infoMz, foX, foY, foMz, hasMzData, "main");
        iSetUserData(hMz, obj.Data, infoX, infoY, infoMz, foX, foY, foMz, hasMzData, "mz");
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
    'TooltipString', 'Get the MS spectrum from one point', ...
    'ClickedCallback', @onMkSpectrum_1);

if obj.Interpolated
    enableState = 'on';
    tipText = 'Get the MS spectrum from two points';
else
    enableState = 'off';
    tipText = 'Two-point spectrum extraction requires interpolated data';
end

uipushtool(tb, ...
    'TooltipString', tipText, ...
    'Enable', enableState, ...
    'ClickedCallback', @onMkSpectrum_2);

uipushtool(tb, ...
    'TooltipString', 'Peak picking', ...
    'ClickedCallback', @onPeakPicking);

uipushtool(tb, ...
    'TooltipString', 'Export profile object to base workspace', ...
    'ClickedCallback', @onExportButton);

% ---------------------------------------------------------------------
% Nested callbacks
% ---------------------------------------------------------------------
    function onExportButton(~, ~)
        assignin('base', 'myProfile', obj);
    end

    function txt = myupdatefcn(~, event_obj)
        pos = get(event_obj, 'Position');
        tgt = get(event_obj, 'Target');
        ud = tgt.UserData;

        txt = {};
        txt{end+1} = sprintf('%s = %s %s', ...
            iGetField(ud.infoX, 'label', 'X'), ...
            num2str(pos(1), ud.foX), ...
            iGetField(ud.infoX, 'Unit', ''));

        switch ud.traceRole
            case "main"
                txt{end+1} = sprintf('%s = %s %s', ...
                    iGetField(ud.infoY, 'label', 'Y'), ...
                    num2str(pos(2), ud.foY), ...
                    iGetField(ud.infoY, 'Unit', ''));

                if ud.hasMzData
                    idx = iNearestPointIndex(ud.profileData(:,1), pos(1));
                    txt{end+1} = sprintf('%s = %s %s', ...
                        iGetField(ud.infoMz, 'label', 'm/z'), ...
                        num2str(ud.profileData(idx, 3), ud.foMz), ...
                        iGetField(ud.infoMz, 'Unit', ''));
                end

            case "mz"
                txt{end+1} = sprintf('%s = %s %s', ...
                    iGetField(ud.infoMz, 'label', 'm/z'), ...
                    num2str(pos(2), ud.foMz), ...
                    iGetField(ud.infoMz, 'Unit', ''));
        end
    end

    function onMkSpectrum_1(~, ~)
        [xp, ~] = ginput(1);

        myFinnee = iGetFinneeObject(obj);
        myDts = iGetDatasetName(obj);
        execOpts = iResolveExecutionOptions(obj);

        if execOpts.ExecutionMode == "serial"
            mySpectrum = myFinnee.mkSpectrum(myDts, xp, ...
                CodeScan = obj.CodeScan, ...
                FastMode = execOpts.FastMode);
            mySpectrum.plot
        else
            mySpectrum = myFinnee.mkSpectrum_parallel(myDts, xp, ...
                CodeScan = obj.CodeScan, ...
                FastMode = execOpts.FastMode);
            mySpectrum.plot_parallel
        end
    end

    function onMkSpectrum_2(~, ~)
        if ~obj.Interpolated
            error('Profile:plot_parallel:NotInterpolated', ...
                'Two-point spectrum extraction is only available for interpolated profiles.');
        end

        [xp, ~] = ginput(2);
        xp = sort(xp(:)).';

        myFinnee = iGetFinneeObject(obj);
        myDts = iGetDatasetName(obj);
        execOpts = iResolveExecutionOptions(obj);

        if execOpts.ExecutionMode == "serial"
            mySpectrum = myFinnee.mkSpectrum(myDts, xp, ...
                CodeScan = obj.CodeScan, ...
                FastMode = execOpts.FastMode);
            mySpectrum.plot
        else
            mySpectrum = myFinnee.mkSpectrum_parallel(myDts, xp, ...
                CodeScan = obj.CodeScan, ...
                FastMode = execOpts.FastMode);
            mySpectrum.plot_parallel
        end
    end

    function onPeakPicking(~, ~)
        sampleRates = {'low', 'normal', 'high', 'ultra'};
        [idxRate, tfRate] = listdlg( ...
            'PromptString', {'Select SampleScanRate for peak picking:'}, ...
            'SelectionMode', 'single', ...
            'ListString', sampleRates, ...
            'InitialValue', 2, ...
            'Name', 'Peak picking');

        if tfRate == 0 || isempty(idxRate)
            return
        end

        sampleScanRate = string(sampleRates{idxRate});
        % 
        myFig = ancestor(src, 'figure');
        figure(myFig);
        drawnow;


        [xp, ~] = ginput(2);

        xp = sort(xp(:)).';

        XY = obj.Data(obj.Data(:,1) >= xp(1) & obj.Data(:,1) <= xp(2), 1:3);

        peakResult = PeakPicking(XY, ...
            SampleScanRate = sampleScanRate);

        showPeakPickingWindow(peakResult);
    end

    function showPeakPickingWindow(peakResult)
        minApexSNR = 3;

        if nargin < 1
            error('showPeakPickingWindow:NotEnoughInputs', ...
                'One input is required: peakResult.');
        end

        if ~isstruct(peakResult) || ~isfield(peakResult, 'Segments') || ~isfield(peakResult, 'Peaks')
            error('showPeakPickingWindow:InvalidPeakResult', ...
                'peakResult must be the structure returned by PeakPicking.');
        end

        segments = peakResult.Segments;
        peakTable = peakResult.Peaks;

        if istable(peakTable) && ~isempty(peakTable) ...
                && ismember('ApexSNR', peakTable.Properties.VariableNames)
            keepGlobal = isfinite(peakTable.ApexSNR) & peakTable.ApexSNR >= minApexSNR;
            peakTable = peakTable(keepGlobal, :);
        end

        figPP = figure( ...
            'Name', 'Peak picking diagnostics', ...
            'NumberTitle', 'off', ...
            'Color', 'w', ...
            'Units', 'normalized', ...
            'Position', [0.06 0.08 0.88 0.82], ...
            'Toolbar', 'figure', ...
            'MenuBar', 'figure');

        drawnow

        pLeft = uipanel( ...
            'Parent', figPP, ...
            'Units', 'normalized', ...
            'Position', [0.02 0.44 0.46 0.53], ...
            'Title', sprintf('Original signal (ApexSNR >= %.1f)', minApexSNR), ...
            'BackgroundColor', 'w');

        pRight = uipanel( ...
            'Parent', figPP, ...
            'Units', 'normalized', ...
            'Position', [0.52 0.44 0.46 0.53], ...
            'Title', sprintf('Peak limits (ApexSNR >= %.1f)', minApexSNR), ...
            'BackgroundColor', 'w');

        pBottom = uipanel( ...
            'Parent', figPP, ...
            'Units', 'normalized', ...
            'Position', [0.02 0.03 0.96 0.36], ...
            'Title', sprintf('Peak results (ApexSNR >= %.1f)', minApexSNR), ...
            'BackgroundColor', 'w');

        drawnow

        if isempty(segments)
            ax1 = axes('Parent', pLeft, 'Units', 'normalized', 'Position', [0.08 0.12 0.88 0.80]);
            text(ax1, 0.5, 0.5, 'No segments detected.', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', 12);
            axis(ax1, 'off')

            ax2 = axes('Parent', pRight, 'Units', 'normalized', 'Position', [0.08 0.12 0.88 0.80]);
            text(ax2, 0.5, 0.5, 'No processed signal available.', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', 12);
            axis(ax2, 'off')

            uitable( ...
                'Parent', pBottom, ...
                'Units', 'normalized', ...
                'Position', [0.01 0.02 0.98 0.95], ...
                'Data', cell(0,0), ...
                'ColumnName', {}, ...
                'RowName', []);
            return
        end

        axLeft = axes( ...
            'Parent', pLeft, ...
            'Units', 'normalized', ...
            'Position', [0.08 0.12 0.88 0.80], ...
            'Box', 'on', ...
            'FontName', 'Helvetica', ...
            'FontSize', 10);

        axRight = axes( ...
            'Parent', pRight, ...
            'Units', 'normalized', ...
            'Position', [0.08 0.12 0.88 0.80], ...
            'Box', 'on', ...
            'FontName', 'Helvetica', ...
            'FontSize', 10);

        cla(axLeft, 'reset')
        cla(axRight, 'reset')
        hold(axLeft, 'on')
        hold(axRight, 'on')
        grid(axLeft, 'on')
        grid(axRight, 'on')
        box(axLeft, 'on')
        box(axRight, 'on')

        colors = lines(max(numel(segments), 1));

        for iSeg = 1:numel(segments)
            seg = segments{iSeg};

            if ~isfield(seg, 'X') || isempty(seg.X)
                continue
            end

            thisColor = colors(iSeg, :);

            acceptedPeaks = [];
            peakBounds = [];

            if isfield(seg, 'AcceptedPeaks') && istable(seg.AcceptedPeaks)
                acceptedPeaks = seg.AcceptedPeaks;
            end

            if isfield(seg, 'PeakBounds') && istable(seg.PeakBounds)
                peakBounds = seg.PeakBounds;
            end

            if istable(acceptedPeaks) && ~isempty(acceptedPeaks) ...
                    && ismember('ApexSNR', acceptedPeaks.Properties.VariableNames)
                keepSeg = isfinite(acceptedPeaks.ApexSNR) & acceptedPeaks.ApexSNR >= minApexSNR;
                acceptedPeaks = acceptedPeaks(keepSeg, :);

                if istable(peakBounds) && ~isempty(peakBounds)
                    nKeep = min(height(peakBounds), numel(keepSeg));
                    peakBounds = peakBounds(keepSeg(1:nKeep), :);
                end
            end

            if isfield(seg, 'Raw') && ~isempty(seg.Raw)
                plot(axLeft, seg.X, seg.Raw, '-', 'Color', thisColor, 'LineWidth', 1.0);
            end

            if isfield(seg, 'Baseline') && ~isempty(seg.Baseline)
                plot(axLeft, seg.X, seg.Baseline, '--', 'Color', thisColor * 0.6, 'LineWidth', 1.0);
            end

            if istable(acceptedPeaks) && ~isempty(acceptedPeaks) ...
                    && isfield(seg, 'Raw') && ~isempty(seg.Raw)
                xApex = acceptedPeaks.ApexTime;
                yApex = interp1(seg.X, seg.Raw, xApex, 'linear', 'extrap');
                plot(axLeft, xApex, yApex, 'v', ...
                    'LineStyle', 'none', ...
                    'MarkerEdgeColor', thisColor, ...
                    'MarkerFaceColor', thisColor, ...
                    'MarkerSize', 6);
            end

            if isfield(seg, 'Corrected') && ~isempty(seg.Corrected)
                plot(axRight, seg.X, seg.Corrected, '-', 'Color', thisColor, 'LineWidth', 1.0);
            end

            if isfield(seg, 'Smoothed') && ~isempty(seg.Smoothed)
                plot(axRight, seg.X, seg.Smoothed, ':', 'Color', thisColor * 0.5 + 0.5, 'LineWidth', 1.2);
            end

            if istable(acceptedPeaks) && ~isempty(acceptedPeaks)
                plot(axRight, acceptedPeaks.ApexTime, acceptedPeaks.ApexIntensity, 'o', ...
                    'LineStyle', 'none', ...
                    'MarkerEdgeColor', thisColor, ...
                    'MarkerFaceColor', thisColor, ...
                    'MarkerSize', 5);
            end

            if istable(peakBounds) && ~isempty(peakBounds)
                yl = ylim(axRight);
                for ii = 1:height(peakBounds)
                    x1 = peakBounds.LeftTime(ii);
                    x2 = peakBounds.RightTime(ii);

                    line(axRight, [x1 x1], yl, 'Color', thisColor, 'LineStyle', '--', 'LineWidth', 0.8);
                    line(axRight, [x2 x2], yl, 'Color', thisColor, 'LineStyle', '--', 'LineWidth', 0.8);

                    if istable(acceptedPeaks) && height(acceptedPeaks) >= ii
                        xa = acceptedPeaks.ApexTime(ii);
                        ya = acceptedPeaks.ApexIntensity(ii);
                        plot(axRight, [x1 xa x2], [ya ya ya], '-', ...
                            'Color', thisColor, 'LineWidth', 0.8);
                    end
                end
            end
        end

        hold(axLeft, 'off')
        hold(axRight, 'off')

        title(axLeft, 'Original trace and baseline', 'Interpreter', 'none')
        xlabel(axLeft, 'X')
        ylabel(axLeft, 'Intensity')

        title(axRight, 'Corrected trace and peak boundaries', 'Interpreter', 'none')
        xlabel(axRight, 'X')
        ylabel(axRight, 'Corrected intensity')

        drawnow

        if istable(peakTable)
            tableData = peakTable;
        else
            tableData = struct2table(peakTable);
        end

        uitable( ...
            'Parent', pBottom, ...
            'Units', 'normalized', ...
            'Position', [0.01 0.02 0.98 0.95], ...
            'Data', tableData{:,:}, ...
            'ColumnName', tableData.Properties.VariableNames, ...
            'RowName', []);
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
function idx = iNearestPointIndex(x, x0)
[~, idx] = min(abs(x - x0));
end

% =========================================================================
function iSetUserData(h, profileData, infoX, infoY, infoMz, foX, foY, foMz, hasMzData, traceRole)
h.UserData = struct( ...
    'profileData', profileData, ...
    'infoX', infoX, ...
    'infoY', infoY, ...
    'infoMz', infoMz, ...
    'foX', foX, ...
    'foY', foY, ...
    'foMz', foMz, ...
    'hasMzData', hasMzData, ...
    'traceRole', traceRole);
end

% =========================================================================
function myFinnee = iGetFinneeObject(obj)
if ~isfield(obj.AdditionalInformation, 'Finnee')
    error('Profile:plot_parallel:MissingFinnee', ...
        'AdditionalInformation.Finnee is missing.');
end
myFinnee = obj.AdditionalInformation.Finnee;
end

% =========================================================================
function myDts = iGetDatasetName(obj)
if ~isfield(obj.AdditionalInformation, 'Dataset')
    error('Profile:plot_parallel:MissingDataset', ...
        'AdditionalInformation.Dataset is missing.');
end
myDts = string(obj.AdditionalInformation.Dataset);
end

% =========================================================================
function execOpts = iResolveExecutionOptions(obj)
execOpts = struct('FastMode', false, 'ExecutionMode', "parallel");

if isprop(obj, 'AdditionalInformation') && isstruct(obj.AdditionalInformation)
    if isfield(obj.AdditionalInformation, 'FastMode') && ~isempty(obj.AdditionalInformation.FastMode)
        execOpts.FastMode = logical(obj.AdditionalInformation.FastMode);
    else
        execOpts.FastMode = iAskFastMode(execOpts.FastMode, ...
            'Spectrum extraction options', ...
            'Do you want to use FastMode for spectrum extraction?');
    end

    if isfield(obj.AdditionalInformation, 'ExecutionModeUsed') && ...
            ~isempty(obj.AdditionalInformation.ExecutionModeUsed)
        execOpts.ExecutionMode = string(obj.AdditionalInformation.ExecutionModeUsed);
    elseif isfield(obj.AdditionalInformation, 'ExecutionModeRequested') && ...
            ~isempty(obj.AdditionalInformation.ExecutionModeRequested)
        execOpts.ExecutionMode = string(obj.AdditionalInformation.ExecutionModeRequested);
    end
else
    execOpts.FastMode = iAskFastMode(execOpts.FastMode, ...
        'Spectrum extraction options', ...
        'Do you want to use FastMode for spectrum extraction?');
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
    error('Profile:plot_parallel:UserCancelled', ...
        'Spectrum extraction cancelled by user.');
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