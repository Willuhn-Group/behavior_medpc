function [histData,eventList] = eventHistogram(eventList,cfg)

% cfg.og = eventList.cfg;
cfg = checkCfg(cfg);

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
for iEvent = 1:numel(cfg.events)
    varName = strcat(cfg.events{iEvent},'Times');
    histField = strcat(cfg.events{iEvent},'Hist');
    for iEntry = 1:length(eventList.trials)
        entryData = eventList.trials(iEntry).(varName);
        if ~isempty(entryData)
            trialHist = histcounts(entryData,histData.binEdges);
            eventList.trials(iEntry).(histField) = trialHist;
            eventList.trials(iEntry).binEdges = histData.binEdges;
        end
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


function cfg = checkCfg(cfg)
if ~isfield(cfg,'events')
  cfg.event = cfg.og.events;
else
    if ~iscell(cfg.events)
        cfg.events = {cfg.events};
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