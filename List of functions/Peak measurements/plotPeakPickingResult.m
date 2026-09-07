function h = plotPeakPickingResult(result, segmentNumber, opts)
%PLOTPEAKPICKINGRESULT Plot one segment from a PeakPicking result.
%
% h = plotPeakPickingResult(result, segmentNumber)
% h = plotPeakPickingResult(result, segmentNumber, opts)

arguments
    result (1,1) struct
    segmentNumber (1,1) double {mustBeInteger, mustBePositive}
    opts.FigureHandle = []
    opts.ShowCandidatePeaks (1,1) logical = true
    opts.ShowAcceptedPeaks (1,1) logical = true
    opts.ShowPeakAreas (1,1) logical = true
    opts.ShowBaselineOutliers (1,1) logical = false
    opts.LinkAxes (1,1) logical = true
    opts.MinApexSNR (1,1) double {mustBeNonnegative} = 3
    opts.RawColor (1,3) double {mustBeGreaterThanOrEqual(opts.RawColor,0), mustBeLessThanOrEqual(opts.RawColor,1)} = [0 0 0]
    opts.BaselineColor (1,3) double {mustBeGreaterThanOrEqual(opts.BaselineColor,0), mustBeLessThanOrEqual(opts.BaselineColor,1)} = [0.85 0.15 0.15]
    opts.CorrectedColor (1,3) double {mustBeGreaterThanOrEqual(opts.CorrectedColor,0), mustBeLessThanOrEqual(opts.CorrectedColor,1)} = [0.55 0.55 0.55]
    opts.SmoothedColor (1,3) double {mustBeGreaterThanOrEqual(opts.SmoothedColor,0), mustBeLessThanOrEqual(opts.SmoothedColor,1)} = [0 0.35 0.85]
    opts.CandidateColor (1,3) double {mustBeGreaterThanOrEqual(opts.CandidateColor,0), mustBeLessThanOrEqual(opts.CandidateColor,1)} = [0.95 0.55 0.1]
    opts.AcceptedColor (1,3) double {mustBeGreaterThanOrEqual(opts.AcceptedColor,0), mustBeLessThanOrEqual(opts.AcceptedColor,1)} = [0 0.6 0.2]
    opts.OutlierColor (1,3) double {mustBeGreaterThanOrEqual(opts.OutlierColor,0), mustBeLessThanOrEqual(opts.OutlierColor,1)} = [0.7 0 0.7]
    opts.PeakAreaColor (1,3) double {mustBeGreaterThanOrEqual(opts.PeakAreaColor,0), mustBeLessThanOrEqual(opts.PeakAreaColor,1)} = [0.3 0.7 1.0]
    opts.PeakAreaAlpha (1,1) double {mustBeGreaterThanOrEqual(opts.PeakAreaAlpha,0), mustBeLessThanOrEqual(opts.PeakAreaAlpha,1)} = 0.25
end

if ~isfield(result, 'Segments') || isempty(result.Segments)
    error('plotPeakPickingResult:InvalidResult', ...
        'result must contain a non-empty field named Segments.');
end

if segmentNumber > numel(result.Segments)
    error('plotPeakPickingResult:SegmentOutOfRange', ...
        'segmentNumber exceeds the number of available segments.');
end

seg = result.Segments{segmentNumber};

requiredFields = {'X','Raw','Baseline','Corrected','Smoothed', ...
    'CandidatePeaks','AcceptedPeaks','PeakBounds'};
for ii = 1:numel(requiredFields)
    if ~isfield(seg, requiredFields{ii})
        error('plotPeakPickingResult:MissingField', ...
            'result.Segments{%d} is missing field "%s".', ...
            segmentNumber, requiredFields{ii});
    end
end

x = seg.X(:);
raw = seg.Raw(:);
baseline = seg.Baseline(:);
corrected = seg.Corrected(:);
smoothed = seg.Smoothed(:);

acceptedPeaks = seg.AcceptedPeaks;
peakBounds = seg.PeakBounds;

if istable(acceptedPeaks) && ~isempty(acceptedPeaks) ...
        && ismember('ApexSNR', acceptedPeaks.Properties.VariableNames)
    keep = isfinite(acceptedPeaks.ApexSNR) & acceptedPeaks.ApexSNR >= opts.MinApexSNR;
    acceptedPeaks = acceptedPeaks(keep, :);

    if istable(peakBounds) && ~isempty(peakBounds)
        nKeep = min(height(peakBounds), numel(keep));
        peakBounds = peakBounds(keep(1:nKeep), :);
    end
end

if isempty(opts.FigureHandle) || ~isgraphics(opts.FigureHandle, 'figure')
    h.Figure = figure('Color', 'w');
else
    h.Figure = opts.FigureHandle;
    figure(h.Figure);
end

clf(h.Figure);

h.TiledLayout = tiledlayout(h.Figure, 2, 1, ...
    'TileSpacing', 'compact', 'Padding', 'compact');

h.AxesRaw = nexttile(h.TiledLayout, 1);
hold(h.AxesRaw, 'on')

h.RawLine = plot(h.AxesRaw, x, raw, '-', ...
    'Color', opts.RawColor, 'LineWidth', 1.0, ...
    'DisplayName', 'Raw');

h.BaselineLine = plot(h.AxesRaw, x, baseline, '-', ...
    'Color', opts.BaselineColor, 'LineWidth', 1.2, ...
    'DisplayName', 'Baseline');

if opts.ShowBaselineOutliers && isfield(seg, 'BaselineOutlier') && ~isempty(seg.BaselineOutlier)
    idxOut = find(seg.BaselineOutlier(:));
    h.BaselineOutlierMarkers = plot(h.AxesRaw, x(idxOut), raw(idxOut), 'o', ...
        'Color', opts.OutlierColor, ...
        'MarkerFaceColor', 'none', ...
        'DisplayName', 'Baseline outliers');
else
    h.BaselineOutlierMarkers = gobjects(0);
end

if opts.ShowAcceptedPeaks && ~isempty(acceptedPeaks)
    apexX = acceptedPeaks.ApexTime;
    apexY = interp1(x, raw, apexX, 'linear', 'extrap');
    h.RawAcceptedMarkers = plot(h.AxesRaw, apexX, apexY, 'v', ...
        'Color', opts.AcceptedColor, ...
        'MarkerFaceColor', opts.AcceptedColor, ...
        'DisplayName', sprintf('Accepted apex (ApexSNR >= %.1f)', opts.MinApexSNR));
else
    h.RawAcceptedMarkers = gobjects(0);
end

ylabel(h.AxesRaw, 'Raw intensity')
title(h.AxesRaw, sprintf('Segment %d - raw signal and baseline', segmentNumber))
grid(h.AxesRaw, 'on')
box(h.AxesRaw, 'on')
legend(h.AxesRaw, 'show', 'Location', 'best')
hold(h.AxesRaw, 'off')

h.AxesProcessed = nexttile(h.TiledLayout, 2);
hold(h.AxesProcessed, 'on')

if opts.ShowPeakAreas && ~isempty(peakBounds)
    h.PeakAreas = gobjects(height(peakBounds), 1);
    for ii = 1:height(peakBounds)
        idx1 = peakBounds.LeftIndex(ii);
        idx2 = peakBounds.RightIndex(ii);

        idx1 = max(1, min(numel(x), idx1));
        idx2 = max(1, min(numel(x), idx2));

        if idx2 < idx1
            continue
        end

        xx = x(idx1:idx2);
        yy = corrected(idx1:idx2);

        h.PeakAreas(ii) = area(h.AxesProcessed, xx, yy, ...
            'FaceColor', opts.PeakAreaColor, ...
            'FaceAlpha', opts.PeakAreaAlpha, ...
            'EdgeColor', 'none', ...
            'HandleVisibility', 'off');
    end
else
    h.PeakAreas = gobjects(0);
end

h.CorrectedLine = plot(h.AxesProcessed, x, corrected, '-', ...
    'Color', opts.CorrectedColor, 'LineWidth', 1.0, ...
    'DisplayName', 'Corrected');

h.SmoothedLine = plot(h.AxesProcessed, x, smoothed, '-', ...
    'Color', opts.SmoothedColor, 'LineWidth', 1.3, ...
    'DisplayName', 'Gaussian smoothed');

if opts.ShowCandidatePeaks && ~isempty(seg.CandidatePeaks)
    h.CandidateMarkers = plot(h.AxesProcessed, ...
        seg.CandidatePeaks.ApexTime, ...
        seg.CandidatePeaks.ApexIntensity, 'o', ...
        'Color', opts.CandidateColor, ...
        'MarkerFaceColor', 'w', ...
        'LineWidth', 1.0, ...
        'DisplayName', 'Candidate maxima');
else
    h.CandidateMarkers = gobjects(0);
end

if opts.ShowAcceptedPeaks && ~isempty(acceptedPeaks)
    h.AcceptedMarkers = plot(h.AxesProcessed, ...
        acceptedPeaks.ApexTime, ...
        acceptedPeaks.ApexIntensity, '^', ...
        'Color', opts.AcceptedColor, ...
        'MarkerFaceColor', opts.AcceptedColor, ...
        'LineWidth', 1.0, ...
        'DisplayName', sprintf('Accepted peaks (ApexSNR >= %.1f)', opts.MinApexSNR));

    h.AcceptedLabels = gobjects(height(acceptedPeaks), 1);
    for ii = 1:height(acceptedPeaks)
        if ismember('ApexSNR', acceptedPeaks.Properties.VariableNames)
            labelText = sprintf(' #%d (%.1f)', ...
                acceptedPeaks.PeakNumber(ii), acceptedPeaks.ApexSNR(ii));
        else
            labelText = sprintf(' #%d', acceptedPeaks.PeakNumber(ii));
        end

        h.AcceptedLabels(ii) = text( ...
            h.AxesProcessed, ...
            acceptedPeaks.ApexTime(ii), ...
            acceptedPeaks.ApexIntensity(ii), ...
            labelText, ...
            'Color', opts.AcceptedColor, ...
            'FontSize', 9, ...
            'FontWeight', 'bold', ...
            'VerticalAlignment', 'bottom', ...
            'HorizontalAlignment', 'left');
    end
else
    h.AcceptedMarkers = gobjects(0);
    h.AcceptedLabels = gobjects(0);
end

if ~isempty(peakBounds)
    h.LeftBoundLines = gobjects(height(peakBounds), 1);
    h.RightBoundLines = gobjects(height(peakBounds), 1);
    yLimProcessed = [min([0; corrected; smoothed]), max([corrected; smoothed])];
    if diff(yLimProcessed) == 0
        yLimProcessed = yLimProcessed + [-0.5 0.5];
    end

    for ii = 1:height(peakBounds)
        xLeft = peakBounds.LeftTime(ii);
        xRight = peakBounds.RightTime(ii);

        h.LeftBoundLines(ii) = plot(h.AxesProcessed, [xLeft xLeft], yLimProcessed, '--', ...
            'Color', [0.3 0.3 0.3], 'HandleVisibility', 'off');
        h.RightBoundLines(ii) = plot(h.AxesProcessed, [xRight xRight], yLimProcessed, '--', ...
            'Color', [0.3 0.3 0.3], 'HandleVisibility', 'off');
    end
else
    h.LeftBoundLines = gobjects(0);
    h.RightBoundLines = gobjects(0);
end

xlabel(h.AxesProcessed, 'X')
ylabel(h.AxesProcessed, 'Processed intensity')
title(h.AxesProcessed, sprintf('Segment %d - corrected, smoothed, and detected peaks (ApexSNR >= %.1f)', ...
    segmentNumber, opts.MinApexSNR))
grid(h.AxesProcessed, 'on')
box(h.AxesProcessed, 'on')
legend(h.AxesProcessed, 'show', 'Location', 'best')
hold(h.AxesProcessed, 'off')

if opts.LinkAxes
    linkaxes([h.AxesRaw, h.AxesProcessed], 'x');
end
end