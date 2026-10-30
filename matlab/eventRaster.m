function rasterData = eventRaster(trials, cfg)
% rasterData = eventRaster(trials, cfg)
%
% Plots a raster of event times with one row per trial. Entries that share
% a trial number (field count, e.g. a trial and the ITI after it) are
% joined into one row, with time 0 at the start of the trial. Rows are
% grouped in sections, stacked from bottom to top, separated by a line and
% labelled on the y axis.
%
% Inputs:
%   trials: trials from addEvent (eventList.trials), or eventList itself.  [struct]
%     Needs the fields count and startTime (from getTrials) and
%     <event>Times for each event, so run addEvent with latency = true.
%     Use getEntry first to plot only some entries (e.g. only ITIs).
%   cfg: configuration struct with fields, or only the event name(s)     [struct/char/cell]
%     (then the defaults are used, e.g. eventRaster(trials, 'mag'))
%     events: name or names of the events to plot, as in cfg.events of     [char/cell]
%       getTrials
%     sectionBy: trials field that defines the sections, e.g.              [char]
%       'trialLabel'. Every row then shows all cfg.events (optional,
%       default: one section per event, showing only that event)
%     sectionOrder: values of cfg.sectionBy, from bottom to top            [cell]
%       (optional, default: order of first appearance)
%     colors: one RGB row per event (optional, default: lines)             [double]
%
% Outputs:
%   rasterData: one element per section, with fields                       [struct]
%     section: section label (event name or cfg.sectionBy value)           [char]
%     events: events drawn in this section                                 [cell]
%     trialNumbers: trial number (count) of each row, bottom to top        [double]
%     entries: indices in trials joined into each row                      [cell]
%     times: event times in s from the start of the trial, one row per     [cell]
%       plot row and one column per event in events
%     rows: y position of each row in the plot                             [double]
%
% With cfg.sectionBy, a section has one row per trial with that value,
% including trials without any of the events. Without it, the section of
% an event has one row per trial in which that event occurs at least once.
% The raster is drawn in the current axes.
%
% Example:
%   evConfig = []; evConfig.events = {'magCue1','magCue4','mag'};
%   evConfig.latency = true;
%   eventList = addEvent(trialStruct, evConfig);
%   cfg = []; cfg.events = {'magCue1','magCue4','mag'};
%   cfg.sectionBy = 'trialLabel';
%   figure; eventRaster(eventList, cfg);
%
% Dependencies: none
%
% Version history:
%   v0.1  Oct 2026  First version
%   v0.2  Oct 2026  cfg can be only the event name(s)
%
% Author(s): Sergio Conde-Ocazionez
% Neuromodulation & Behavior Laboratory, Netherlands Institute for Neuroscience

TICKHEIGHT = 0.8;   % fraction of a row covered by each tick

if isfield(trials, 'trials')
    trials = trials.trials;                     % eventList from addEvent
end
if ~isstruct(cfg)
    cfg = struct('events', {cfg});              % only the event name(s)
end
cfg     = checkCfg(cfg, trials);
events  = cfg.events;
nEvents = numel(events);

%----------------- join entries of the same trial (count) ------------------%
[trialNumbers, ~, groupIdx] = unique([trials.count], 'stable');
nGroups      = numel(trialNumbers);
groupStart   = accumarray(groupIdx(:), [trials.startTime]', [], @min);   % e.g. cue onset
groupEntries = arrayfun(@(igroup) find(groupIdx == igroup)', 1:nGroups, 'UniformOutput', false);

% event times of every trial, relative to its start: trials x events
groupTimes = cell(nGroups, nEvents);
for igroup = 1:nGroups
    for ievent = 1:nEvents
        timeField = [events{ievent} 'Times'];
        t = [];
        for ientry = groupEntries{igroup}
            t = [t, trials(ientry).startTime + trials(ientry).(timeField)(:)' ...
                - groupStart(igroup)];                                        %#ok<AGROW>
        end
        groupTimes{igroup, ievent} = t;
    end
end

%------------- sections: which trials and events go in each ---------------%
if isfield(cfg, 'sectionBy')
    sectionLabels = cfg.sectionOrder;
    firstEntry    = cellfun(@(x) x(1), groupEntries);
    groupValue    = toLabels({trials(firstEntry).(cfg.sectionBy)});
    sectionGroups = cellfun(@(label) find(strcmp(groupValue, label)), sectionLabels, ...
        'UniformOutput', false);
    sectionEvents = repmat({1:nEvents}, 1, numel(sectionLabels));
else
    sectionLabels = events;
    sectionGroups = arrayfun(@(ievent) find(~cellfun(@isempty, groupTimes(:,ievent)))', ...
        1:nEvents, 'UniformOutput', false);
    sectionEvents = num2cell(1:nEvents);
end
nSections = numel(sectionLabels);

%------------------------------ draw raster --------------------------------%
rasterData = struct('section', sectionLabels, 'events', [], 'trialNumbers', [], ...
    'entries', [], 'times', [], 'rows', []);
holdState   = ishold;
hold on
lineHandles = gobjects(1, nEvents);             % one handle per event, for the legend

rowOffset     = 0;
sectionCenter = nan(1, nSections);
for isection = 1:nSections
    groupRows = sectionGroups{isection};
    nRows     = numel(groupRows);
    rows      = rowOffset + (1:nRows);
    if nRows == 0
        warning('eventRaster:emptySection', 'Section %s has no rows.', sectionLabels{isection});
    end

    % one vertical tick per event, all ticks of an event in a single line object
    for ievent = sectionEvents{isection}
        xTicks = [];
        yTicks = [];
        for irow = 1:nRows
            t = groupTimes{groupRows(irow), ievent};
            xTicks = [xTicks [t; t; nan(size(t))]];                                  %#ok<AGROW>
            yTicks = [yTicks [rows(irow) - TICKHEIGHT/2; rows(irow) + TICKHEIGHT/2; NaN] ...
                * ones(size(t))];                                                    %#ok<AGROW>
        end
        if ~isempty(xTicks)
            lineHandles(ievent) = plot(xTicks(:), yTicks(:), '-', 'Color', cfg.colors(ievent,:));
        end
    end

    if isection < nSections
        yline(rowOffset + nRows + 0.5, 'k-', 'LineWidth', 1);           % section separator
    end
    if nRows > 0
        sectionCenter(isection) = rowOffset + (nRows + 1)/2;
    end

    rasterData(isection).events       = events(sectionEvents{isection});
    rasterData(isection).trialNumbers = trialNumbers(groupRows);
    rasterData(isection).entries      = groupEntries(groupRows);
    rasterData(isection).times        = groupTimes(groupRows, sectionEvents{isection});
    rasterData(isection).rows         = rows;
    rowOffset = rowOffset + nRows;
end

%------------------------------ axes labels --------------------------------%
labelled = ~isnan(sectionCenter);
ylim([0 rowOffset + 1])
yticks(sectionCenter(labelled))
yticklabels(sectionLabels(labelled))
set(gca, 'TickLabelInterpreter', 'none')
xlabel 'Time from trial start (s)'
box off

drawn = isgraphics(lineHandles);
if isfield(cfg, 'sectionBy') && sum(drawn) > 1     % colors are per event: name them
    legend(lineHandles(drawn), events(drawn), 'Interpreter', 'none', 'Location', 'eastoutside')
end

if ~holdState
    hold off
end

function cfg = checkCfg(cfg, trials)

if ~isfield(cfg, 'events')
    error('eventRaster:missingField', 'cfg.events is required');
end
cfg.events = toLabels(cfg.events);

if ~isfield(trials, 'count') || ~isfield(trials, 'startTime')
    error('eventRaster:missingField', ...
        'trials needs the fields count and startTime (created by getTrials).');
end
for ievent = 1:numel(cfg.events)
    if ~isfield(trials, [cfg.events{ievent} 'Times'])
        error('eventRaster:missingTimes', ...
            'trials has no field %sTimes. Run addEvent with this event and latency = true.', ...
            cfg.events{ievent});
    end
end

if isfield(cfg, 'sectionBy')
    if ~isfield(trials, cfg.sectionBy)
        error('eventRaster:missingField', 'trials has no field %s (cfg.sectionBy).', cfg.sectionBy);
    end
    if isfield(cfg, 'sectionOrder')
        cfg.sectionOrder = toLabels(cfg.sectionOrder);
    else
        cfg.sectionOrder = unique(toLabels({trials.(cfg.sectionBy)}), 'stable');
    end
end

if ~isfield(cfg, 'colors')
    cfg.colors = lines(numel(cfg.events));
elseif size(cfg.colors, 1) < numel(cfg.events)
    error('eventRaster:colors', 'cfg.colors needs one RGB row per event in cfg.events.');
end

function labels = toLabels(values)
% char, string, cell or numeric values -> 1 x n cell of char

if ischar(values) || isstring(values)
    labels = cellstr(values);
elseif ~iscell(values)
    labels = num2cell(values);
else
    labels = values;
end
labels = cellfun(@(v) char(string(v)), labels, 'UniformOutput', false);
labels = labels(:)';
