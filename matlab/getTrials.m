function trialStruct = getTrials(cfg)
% trialStruct = getTrials(cfg)
%
% Splits a MedPC session into trials and ITIs. Each trial starts with a
% trialStart event and ends with its trialEnd event; the ITI after it runs
% until the next trial starts (or the session ends). Times are in seconds
% from the start of the session.
%
% Inputs:
%   cfg: configuration struct with fields                                  [struct]
%     medFile: MedPC file (full path), or the output of readMedpc          [char/struct]
%     events: one field per event, named as you like, with the event       [struct]
%       code used in the MedPC program (e.g. cfg.events.cue1On = 2)
%     trialStart: event name(s) that start a trial, or their codes         [cell/double]
%     trialEnd: event name(s) that end a trial, or their codes. If not     [cell/double]
%       given, each trial ends at the next trialStart and events.sessionEnd
%       is required (optional)
%     trialLabel: one label per trialStart event (optional)                [cell]
%     medTime: MedPC block with the event times (optional, default: 'D')   [char]
%     medEvents: MedPC block with the event codes (optional, default: 'E') [char]
%
% Outputs:
%   trialStruct: struct with fields                                        [struct]
%     cfg: the configuration, with defaults filled in                      [struct]
%     medData: output of readMedpc                                          [struct]
%     trials: one element per trial and ITI, with fields                   [struct]
%       trialLabel: trial type, from cfg.trialLabel (only if given)        [char]
%       interval: 'trial' or 'iti'                                         [char]
%       trialStart: event that starts the interval                         [char]
%       trialEnd: event that ends the interval                             [char]
%       count: trial number (an ITI has the number of the trial before it) [double]
%       startTime: start time, in s                                        [double]
%       endTime: end time, in s                                            [double]
%       duration: in s                                                     [double]
%
% Example:
%   cfg = []; cfg.medFile = fullfile(repoRoot, 'example_data', 'example_rat_multipellet');
%   cfg.events.cue1On = 2; cfg.events.cue1Off = 3;
%   cfg.events.cue4On = 4; cfg.events.cue4Off = 5;
%   cfg.trialStart = {'cue1On','cue4On'}; cfg.trialEnd = {'cue1Off','cue4Off'};
%   cfg.trialLabel = {'1p','4p'};
%   trialStruct = getTrials(cfg);
%
% Dependencies: readMedpc (behavior_medpc), getEntry (utilities_matlab)
%
% Version history:
%   v0.1  Aug 2024  First version (get_trials)
%   v0.2  Aug 2026  Renamed to getTrials; camelCase names
%   v0.3  Sep 2026  Configurable time and event blocks (medTime, medEvents);
%                   without trialEnd, trials end at the next trialStart
%   v0.4  Oct 2026  Calls readMedpc (read_medpc was renamed)
%
% Author(s): Sergio Conde-Ocazionez
% Neuromodulation & Behavior Laboratory, Netherlands Institute for Neuroscience

MEDSAMPLERATE = 10e-3;

%---------------------- check the medFile input ----------------------------%
if ischar(cfg.medFile)
    medData = readMedpc(cfg.medFile);
elseif isstruct(cfg.medFile)
    % include here something to check if the struct has the right configuration
    medData = cfg.medFile;
end

% include defaults for different med_pc configurations, like sample rate

% the medpc output files have the D block which contains the sample number
% of the ocurrence of each event. This way, the actual time would be sample
% * 10e-3

eventList = fieldnames(cfg.events);
idList = [];
for ievent = 1:length(eventList)
    idList = cat(2,idList,cfg.events.(eventList{ievent}));
end

if ~iscell(cfg.trialStart)
    cfg.trialStart = eventList(ismember(idList,cfg.trialStart));
end

if ~isfield(cfg,'trialEnd')
    cfg.trialEnd = cfg.trialStart;
    noEndFlag = 1;
else
    if ~iscell(cfg.trialEnd)
        cfg.trialEnd = eventList(ismember(idList,cfg.trialEnd));
    end
    noEndFlag = 0;
end

if ~isfield(cfg,'medTime')
    cfg.medTime = 'D';
end
medTime = medData.(cfg.medTime);

if ~isfield(cfg,'medEvents')
    cfg.medEvents = 'E';
end
medEvents = medData.(cfg.medEvents);

trialStruct.cfg     = cfg;
trialStruct.medData = medData;

%---------------------- start event compilation ----------------------------%
startEvent = cfg.trialStart;
startTimes = [];
startIds   = [];
for ievent = 1:length(startEvent)
    eventId = cfg.events.(cfg.trialStart{ievent});
    startTimes = cat(2,startTimes,medTime(medEvents == eventId));
    startIds   = cat(2,startIds,ievent * ones(1,sum(medEvents == eventId)));
end
[~, sortSample] = sort(startTimes);
sortStartIds = startIds(sortSample);
sortStartLabel = cfg.trialStart(startIds);
%---------------------- start event compilation ----------------------------%

%------------------------ end event compilation ----------------------------%
endEvent    = cfg.trialEnd;
endTimes = [];
endIds   = [];

for ievent = 1:length(endEvent)
    eventId  = cfg.events.(cfg.trialEnd{ievent});
    endTimes = cat(2,endTimes,medTime(medEvents == eventId));
    endIds   = cat(2,endIds,ievent * ones(1,sum(medEvents == eventId)));
end
sortEndLabel = cfg.trialEnd(endIds);
%------------------------ end event compilation ----------------------------%

if noEndFlag
    endTime = medTime(medEvents == cfg.events.sessionEnd);
    endTimes = [endTimes(2:end) endTime] - 1;
end
intervalTimes = [startTimes endTimes] * MEDSAMPLERATE;

[sortTimes, sortIds] = sort(intervalTimes);
sortLabels = [sortStartLabel sortEndLabel];
sortLabels = sortLabels(sortIds)';

startEventLabels = sortLabels(1:end - 1);
endEventLabels = sortLabels(2:end);

intervalTimes = [sortTimes(1:end - 1); sortTimes(2:end)]';
duration = diff(intervalTimes,1,2);

intervalIds = [ones(1,length(startTimes)) zeros(1,length(endTimes))];
intervalStart = intervalIds(sortIds(1:end - 1))';

trialLabels = cell(length(intervalIds) - 1,1);
trialLabels(intervalStart == 1) = {'trial'};
trialLabels(intervalStart == 0) = {'iti'};

intervalCount = zeros(size(intervalTimes,1),1);
intervalCount(intervalStart == 1) = 1:sum(intervalStart == 1);
intervalCount(intervalStart == 0) = intervalCount(find(intervalStart == 0) - 1);

intervalInfo = [intervalCount intervalTimes duration];
intervalCell = [trialLabels startEventLabels endEventLabels num2cell(intervalInfo)];

intervalFields = {'interval','trialStart','trialEnd','count', ...
        'startTime','endTime','duration'};

if isfield(cfg,'trialLabel')
    trialIds = cell(size(intervalTimes,1),1);
    trialIds(intervalStart == 1) = cfg.trialLabel(sortStartIds);
    trialIds(intervalStart == 0) = trialIds(find(intervalStart == 0) - 1);
    intervalCell = [trialIds intervalCell];
    intervalFields = ['trialLabel',intervalFields];
end
trialStruct.trials = cell2struct(intervalCell,intervalFields,2);
if noEndFlag
    trialStruct.trials = getEntry(trialStruct.trials,'interval','trial');
end


