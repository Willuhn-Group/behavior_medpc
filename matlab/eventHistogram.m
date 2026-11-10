function [histData,eventList] = eventHistogram(eventList,cfg)
% [histData, eventList] = eventHistogram(eventList, cfg)
%
% Computes, for each trial, the histogram of the times of one or more
% events, and optionally plots their mean and SEM across trials.
%
% Inputs:
%   eventList: output of addEvent, run with latency = true                 [struct]
%   cfg: configuration struct with fields                                  [struct]
%     events: name or names of the events (required)                       [char/cell]
%     histBins: number of bins from 0 to the longest entry, or the bin     [double]
%       edges, in s (optional, default: 10)
%     select: request to select trials first, as in getEntry (optional)    [struct]
%     plotFlag: true to plot the mean histogram (optional, default: false) [logical]
%     color: plot color (optional, default: 'k')                           [char/double]
%     figNumber: figure to plot in (optional, default: new figure)         [double]
%
% Outputs:
%   histData: struct with fields                                           [struct]
%     binEdges: bin edges, in s                                            [double]
%     <event>Hist: histogram of each trial, one cell per trial             [cell]
%     graph: output of avgErrorShade (only if plotted)                     [struct]
%   eventList: the input, with the selection applied and the fields        [struct]
%     <event>Hist and binEdges added to each trial
%
% Trials without the event count as zeros. Bins after the end of a trial
% also count as zeros, so with trials of different durations keep the bins
% within the shortest one.
%
% Example:
%   histCfg = []; histCfg.events = 'mag'; histCfg.histBins = 0:30;
%   histCfg.select.trialLabel = '4p'; histCfg.select.interval = 'iti';
%   histCfg.plotFlag = true;
%   [histData, list4p] = eventHistogram(eventList, histCfg);
%
% Dependencies: getEntry, wfig, avgErrorShade (utilities_matlab)
%
% Version history:
%   v0.1  Sep 2026  First version
%   v0.2  Sep 2026  Bin edges as input; bin centers fixed
%   v0.3  Oct 2026  Plot color (cfg.color); returns the plot (histData.graph)
%   v0.4  Oct 2026  Uses avgErrorShade (avg_err_shade was renamed)
%   v0.5  Nov 2026  Trials without the event count as zeros; cfg.events is
%                   required
%
% Author(s): Sergio Conde-Ocazionez
% Neuromodulation & Behavior Laboratory, Netherlands Institute for Neuroscience

cfg = checkCfg(cfg, eventList);

if isfield(cfg,'select')
    eventList.trials = getEntry(eventList.trials,cfg.select);
end

maxDuration = max([eventList.trials.duration]);
if isscalar(cfg.histBins)
    histData.binEdges = linspace(0,maxDuration,cfg.histBins);
else
    histData.binEdges = cfg.histBins;
end
binCenters = histData.binEdges(1:end-1) + diff(histData.binEdges)/2;

% DEAL WITH PLOTING MULTIPLE EVENTS (DIFFERENT FIGS, SUBPANELS...)

% compute event trial-based histograms
for ievent = 1:numel(cfg.events)
    varName = strcat(cfg.events{ievent},'Times');
    histField = strcat(cfg.events{ievent},'Hist');
    for ientry = 1:length(eventList.trials)
        entryData = eventList.trials(ientry).(varName);
        if isempty(entryData)
            trialHist = zeros(1,numel(histData.binEdges) - 1);   % no events: all bins 0
        else
            trialHist = histcounts(entryData,histData.binEdges);
        end
        eventList.trials(ientry).(histField) = trialHist;
        eventList.trials(ientry).binEdges = histData.binEdges;
    end
    histData.(histField) = {eventList.trials.(histField)}';

    if cfg.plotFlag
        plotHist.xdata = binCenters;
        plotHist.ydata = cat(1,histData.(histField){:});
        plotHist.color = cfg.color;
        if isfield(cfg,'figNumber')
            wfig(cfg.figNumber);
        else
            wfig;
        end
        histData.graph = avgErrorShade(plotHist);
        box off
        xlabel 'Bin Center (s)'
        ylabel 'Event count'
    end
end


function cfg = checkCfg(cfg, eventList)
if ~isfield(cfg,'events')
    error('eventHistogram:missingField', 'cfg.events is required');
end
if ~iscell(cfg.events)
    cfg.events = {cfg.events};
end
for ievent = 1:numel(cfg.events)
    if ~isfield(eventList.trials, [cfg.events{ievent} 'Times'])
        error('eventHistogram:missingTimes', ...
            'eventList has no field %sTimes. Run addEvent with this event and latency = true.', ...
            cfg.events{ievent});
    end
end
if ~isfield(cfg,'histBins')
    cfg.histBins = 10; % 10 bins as default
end
if ~isfield(cfg,'plotFlag')
    cfg.plotFlag = false; 
end
if ~isfield(cfg,'color')
    cfg.color = 'k'; 
end