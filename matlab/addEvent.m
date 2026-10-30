function eventList = addEvent(trialEntry,cfg)
% eventList = addEvent(trialEntry, cfg)
%
% Adds behavioral events to the trials and ITIs from getTrials: for each
% event, how many times it occurs in each entry and, if requested, the
% times, the first occurrence and the bouts. Times are in seconds from the
% start of each entry.
%
% Inputs:
%   trialEntry: output of getTrials                                         [struct]
%   cfg: configuration struct with fields                                  [struct]
%     events: names of the events to add, as in cfg.events of getTrials    [cell]
%     latency: true to add the event times, <event>Times                   [logical]
%       (optional, default: false)
%     firstEvent: true to add the first event time, <event>First (NaN if   [logical]
%       there is none) (optional, default: false)
%     bouts: bout settings, one value per event in cfg.events (optional)    [struct]
%       minInterval: minimum time between bouts, in s                      [double]
%       minDuration: minimum bout duration, in s                           [double]
%
% Outputs:
%   eventList: struct with fields                                          [struct]
%     cfg: the configuration                                               [struct]
%     dataCfg: the configuration of getTrials                              [struct]
%     medData: output of readMedpc                                          [struct]
%     trials: the trials of getTrials plus, for each event:                [struct]
%       <event>Count: number of events in the entry                        [double]
%       <event>Times, <event>First: if requested                           [double]
%       <event>Bouts, <event>BoutStart, <event>BoutEnd,                    [double]
%       <event>BoutDuration: if cfg.bouts is given
%
% Example:
%   evConfig = []; evConfig.events = {'magCue1','magCue4','mag'};
%   evConfig.latency = true; evConfig.firstEvent = true;
%   eventList = addEvent(trialStruct, evConfig);
%
% Dependencies: extractBouts (utilities_matlab), only with cfg.bouts
%
% Version history:
%   v0.1  Aug 2026  First version
%   v0.2  Sep 2026  Configurable time and event blocks; event bouts (cfg.bouts)
%
% Author(s): Sergio Conde-Ocazionez
% Neuromodulation & Behavior Laboratory, Netherlands Institute for Neuroscience


MEDSAMPLERATE = 10e-3;

cfg = checkCfg(cfg); % check input data and requestes fields

eventList.cfg = rmfield(cfg,'inputFields');
eventList.dataCfg = trialEntry.cfg;
eventList.medData = trialEntry.medData;

medTime = trialEntry.medData.(trialEntry.cfg.medTime);
medEvents = trialEntry.medData.(trialEntry.cfg.medEvents);

trials = trialEntry.trials;
eventRequest = cfg.events;

for ievent = 1:length(eventRequest)
    eventLabel = eventRequest{ievent};
    eventFlags = medEvents == trialEntry.cfg.events.(eventLabel);
    eventTimes = medTime(eventFlags) * MEDSAMPLERATE;
    for ientry = 1:size(trials,1)
        
        entryFlags = eventTimes >= trials(ientry).startTime & ...
            eventTimes < trials(ientry).endTime;
        entryTimes = eventTimes(entryFlags) - trials(ientry).startTime;
        
        % count events. 
        trials(ientry).([eventLabel 'Count']) = numel(entryTimes);

        % compute event latency if requested
        if cfg.latency
            trials(ientry).([eventLabel 'Times']) = entryTimes;
        end

        % extract first event if requested
        if cfg.firstEvent
            firstEvent  = min(entryTimes);
            if isempty(firstEvent); firstEvent = NaN; end
            trials(ientry).([eventLabel 'First']) = firstEvent;
        end

        % extract event bouts
        if isfield(cfg,'bouts') && ~isempty(entryTimes)
            boutList = extractBouts(entryTimes, ...
                cfg.bouts.minInterval(ievent), ...
                cfg.bouts.minDuration(ievent));
            nBouts = height(boutList);
            
            trials(ientry).([eventLabel 'Bouts']) = nBouts;
            trials(ientry).([eventLabel 'BoutStart']) = boutList.boutStart;
            trials(ientry).([eventLabel 'BoutEnd']) = boutList.boutEnd;
            trials(ientry).([eventLabel 'BoutDuration']) = boutList.duration;
        end
    end
end

eventList.trials = trials;

function cfg = checkCfg(cfg)

cfg.inputFields = {'latency','firstEvent'};

for ifield = 1:numel(cfg.inputFields)
    localField = cfg.inputFields{ifield};
    if ~isfield(cfg,localField)
        cfg.(localField) = false;
    end
end