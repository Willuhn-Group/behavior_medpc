function trialStruct = getTrials(cfg)
% trialStruct = getTrials(cfg)
%
% Splits a MedPC session into trials and ITIs. Each trial starts with a
% trialStart event and ends with its trialEnd event, or after a fixed
% duration (cfg.trialDuration); the ITI after it runs until the next trial
% starts (or the session ends). Times are in seconds from the start of the
% session.
%
% Inputs:
%   cfg: configuration struct with fields                                  [struct]
%     medFile: MedPC file (full path, char or string), or the output of    [char/struct]
%       readMedpc
%     events: one field per event, named as you like, with the event       [struct]
%       code used in the MedPC program (e.g. cfg.events.cue1On = 2)
%     trialStart: event name(s) that start a trial, or their codes   [char/cell/double]
%     trialEnd: event name(s) that end a trial, or their codes. If   [char/cell/double]
%       not given, each trial ends at the next trialStart (whichever
%       trialStart event it is) and the last one at events.sessionEnd,
%       which is then required (optional; not together with trialDuration).
%       With trialEnd, the last trial gets an ITI up to the session end if
%       events.sessionEnd is given; otherwise it has no ITI
%     trialDuration: trial length in s, for tasks where a trial is defined [double]
%       by time instead of an end event. Each trial runs from its
%       trialStart for trialDuration s; the ITI runs from there to the
%       next trialStart, or to events.sessionEnd (required) for the last
%       trial (optional; not together with trialEnd)
%     trialLabel: one label per trialStart event (optional)                [cell]
%     medTime: MedPC block with the event times (optional, default: 'D')   [char]
%     medEvents: MedPC block with the event codes (optional, default: 'E') [char]
%
% getTrials stops with a clear error (id getTrials:<reason>) when a
% required field is missing, an event name or code is not in cfg.events,
% trialLabel does not have one label per trialStart event, the time or
% event block is not in the data, or the trialStart events are not in the
% file. It warns (getTrials:blockLength) if the time and event blocks have
% different lengths, and (getTrials:longLastIti) if the last ITI, up to the
% session end, is longer than mean + 2 SD of the other ITIs.
%
% Outputs:
%   trialStruct: struct with fields                                        [struct]
%     cfg: the configuration, with defaults filled in                      [struct]
%     medData: output of readMedpc                                          [struct]
%     trials: one element per trial and ITI, with fields                   [struct]
%       trialLabel: trial type, from cfg.trialLabel (only if given)        [char]
%       interval: 'trial' or 'iti'                                         [char]
%       trialStart: event that starts the interval ('trialDuration' for    [char]
%         an ITI that starts when the trial duration is over)
%       trialEnd: event that ends the interval ('trialDuration' for a      [char]
%         trial defined by duration, 'sessionEnd' for the last ITI)
%       count: trial number (an ITI has the number of the trial before it) [double]
%       startTime: start time, in s                                        [double]
%       endTime: end time, in s                                            [double]
%       duration: in s                                                     [double]
%
% Example:
%   cfg = []; cfg.medFile = getExampleFile('example_rat_multipellet');
%   cfg.events.cue1On = 2; cfg.events.cue1Off = 3;
%   cfg.events.cue4On = 4; cfg.events.cue4Off = 5;
%   cfg.trialStart = {'cue1On','cue4On'}; cfg.trialEnd = {'cue1Off','cue4Off'};
%   cfg.trialLabel = {'1p','4p'};
%   trialStruct = getTrials(cfg);
%
%   % trials of 30 s from cue onset instead of ending at cue offset
%   cfg = rmfield(cfg, 'trialEnd'); cfg.trialDuration = 30;
%   cfg.events.sessionEnd = 100;
%   trialStruct = getTrials(cfg);
%
% With trialDuration, getTrials stops with an error if a trial starts
% before the previous one is over.
%
% Dependencies: readMedpc (behavior_medpc), getEntry (utilities_matlab)
%
% Version history:
%   v0.1  Aug 2024  First version (get_trials)
%   v0.2  Aug 2026  Renamed to getTrials; camelCase names
%   v0.3  Sep 2026  Configurable time and event blocks (medTime, medEvents);
%                   without trialEnd, trials end at the next trialStart
%   v0.4  Oct 2026  Calls readMedpc (read_medpc was renamed)
%   v0.5  Nov 2026  Trials defined by duration (cfg.trialDuration)
%   v0.6  Nov 2026  Input checks with clear errors; string paths; without
%                   trialEnd and with several trialStart events, trials end
%                   at the next trial in time order (could fail before)
%   v0.7  Nov 2026  With trialEnd and events.sessionEnd, the last trial gets
%                   an ITI up to the session end (with the longLastIti check)
%
% Author(s): Sergio Conde-Ocazionez
% Neuromodulation & Behavior Laboratory, Netherlands Institute for Neuroscience

MEDSAMPLERATE = 10e-3;

cfg = checkCfg(cfg);

%-------------------------- load the MedPC data ----------------------------%
if ischar(cfg.medFile)
    medData = readMedpc(cfg.medFile);
else
    medData = cfg.medFile;                      % output of readMedpc
end

if isfield(cfg,'trialDuration')
    checkTrialDuration(cfg);
    noEndFlag = 0;
elseif ~isfield(cfg,'trialEnd')
    cfg.trialEnd = cfg.trialStart;
    noEndFlag = 1;
else
    noEndFlag = 0;
end

if ~isfield(cfg,'medTime')
    cfg.medTime = 'D';
end
if ~isfield(cfg,'medEvents')
    cfg.medEvents = 'E';
end
checkMedData(medData, cfg);
medTime   = medData.(cfg.medTime);
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
if isempty(startTimes)
    error('getTrials:noTrials', ...
        'None of the trialStart events (%s) is in the file: there are no trials.', ...
        strjoin(cfg.trialStart, ', '));
end
%---------------------- start event compilation ----------------------------%

%------------------------ end event compilation ----------------------------%
lastIti = isfield(cfg,'trialDuration');         % true when the last trial gets an ITI up to the session end
if isfield(cfg,'trialDuration')
    % each trial ends trialDuration s after its start; the last ITI ends
    % at the session end
    durationSamples = round(cfg.trialDuration / MEDSAMPLERATE);
    endTimes        = startTimes + durationSamples;
    sessionEndTime  = max(medTime(medEvents == cfg.events.sessionEnd));
    checkTrialTimes(startTimes, durationSamples, sessionEndTime, cfg.trialDuration, MEDSAMPLERATE);
    endTimes     = [endTimes sessionEndTime];
    sortEndLabel = [repmat({'trialDuration'}, 1, numel(startTimes)) {'sessionEnd'}];
else
    endEvent    = cfg.trialEnd;
    endTimes = [];
    endIds   = [];

    for ievent = 1:length(endEvent)
        eventId  = cfg.events.(cfg.trialEnd{ievent});
        endTimes = cat(2,endTimes,medTime(medEvents == eventId));
        endIds   = cat(2,endIds,ievent * ones(1,sum(medEvents == eventId)));
    end
    sortEndLabel = cfg.trialEnd(endIds);
    if isempty(endTimes) && ~noEndFlag
        error('getTrials:noTrialEnds', 'None of the trialEnd events (%s) is in the file.', ...
            strjoin(cfg.trialEnd, ', '));
    end

    % last ITI: from the last trialEnd to the session end, if the session
    % end is defined (otherwise the last trial has no ITI)
    if ~noEndFlag && isfield(cfg.events,'sessionEnd')
        sessionEndTime = max(medTime(medEvents == cfg.events.sessionEnd));
        if isempty(sessionEndTime)
            warning('getTrials:noLastIti', ...
                'The sessionEnd event (cfg.events.sessionEnd) is not in the file: the last trial has no ITI.');
        elseif sessionEndTime < max(endTimes)
            error('getTrials:sessionEndBeforeTrialEnd', ...
                'The session ends (%.2f s) before the last trial does (%.2f s). Check the file or cfg.trialEnd.', ...
                sessionEndTime * MEDSAMPLERATE, max(endTimes) * MEDSAMPLERATE);
        else
            endTimes     = [endTimes sessionEndTime];
            sortEndLabel = [sortEndLabel(:)' {'sessionEnd'}];
            lastIti      = true;
        end
    end
end
%------------------------ end event compilation ----------------------------%

if noEndFlag
    % each trial ends 1 sample before the next trial starts (in time order,
    % whichever trialStart event it is), the last one 1 sample before the
    % session ends
    sessionEndTime = medTime(medEvents == cfg.events.sessionEnd);
    if isempty(sessionEndTime)
        error('getTrials:noSessionEnd', ...
            'The sessionEnd event (cfg.events.sessionEnd) is not in the file.');
    end
    [sortedStarts, startOrder] = sort(startTimes);
    endTimes     = [sortedStarts(2:end) sessionEndTime] - 1;
    sortEndLabel = [sortStartLabel(startOrder(2:end)) repmat({'sessionEnd'}, 1, numel(sessionEndTime))];
end
if isfield(cfg,'trialDuration')
    % ends before starts, so a trial that starts exactly when the previous
    % one ends is sorted after it (sort keeps the order of equal times)
    boundaryTimes   = [endTimes startTimes];
    boundaryLabels  = [sortEndLabel(:)' sortStartLabel(:)'];
    boundaryIsStart = [zeros(1,length(endTimes)) ones(1,length(startTimes))];
else
    boundaryTimes   = [startTimes endTimes];
    boundaryLabels  = [sortStartLabel sortEndLabel];
    boundaryIsStart = [ones(1,length(startTimes)) zeros(1,length(endTimes))];
end
intervalTimes = boundaryTimes * MEDSAMPLERATE;

[sortTimes, sortIds] = sort(intervalTimes);
sortLabels = boundaryLabels(sortIds)';

startEventLabels = sortLabels(1:end - 1);
endEventLabels = sortLabels(2:end);

intervalTimes = [sortTimes(1:end - 1); sortTimes(2:end)]';
duration = diff(intervalTimes,1,2);

intervalIds = boundaryIsStart;
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
if lastIti
    checkLastIti(trialStruct.trials);
end

function cfg = checkCfg(cfg)
% required fields, event names and codes; returns trialStart and trialEnd
% as 1 x n cells of event names

if ~isstruct(cfg)
    error('getTrials:cfg', 'cfg must be a struct (see help getTrials).');
end
required = {'medFile', 'events', 'trialStart'};
missing  = required(~isfield(cfg, required));
if ~isempty(missing)
    error('getTrials:missingField', 'cfg.%s is required.', strjoin(missing, ' and cfg.'));
end

if isstring(cfg.medFile)
    cfg.medFile = char(cfg.medFile);            % "path" works like 'path'
end
if ~ischar(cfg.medFile) && ~isstruct(cfg.medFile)
    error('getTrials:medFile', ...
        'cfg.medFile must be the path of a MedPC file or the output of readMedpc.');
end

if ~isstruct(cfg.events) || isempty(fieldnames(cfg.events))
    error('getTrials:events', ...
        'cfg.events must be a struct with one field per event (e.g. cfg.events.cue = 2).');
end
eventNames = fieldnames(cfg.events)';
eventCodes = cellfun(@(name) cfg.events.(name), eventNames, 'UniformOutput', false);
notNumeric = eventNames(~cellfun(@isnumeric, eventCodes));
if ~isempty(notNumeric)
    error('getTrials:events', 'cfg.events.%s must be a MedPC event code (a number).', ...
        strjoin(notNumeric, ', cfg.events.'));
end

cfg.trialStart = checkEventNames(cfg.trialStart, 'trialStart', eventNames, eventCodes);
if isfield(cfg, 'trialEnd')
    cfg.trialEnd = checkEventNames(cfg.trialEnd, 'trialEnd', eventNames, eventCodes);
end

if isfield(cfg, 'trialLabel')
    if ischar(cfg.trialLabel) || isstring(cfg.trialLabel)
        cfg.trialLabel = cellstr(cfg.trialLabel);
    end
    if numel(cfg.trialLabel) ~= numel(cfg.trialStart)
        error('getTrials:trialLabel', ...
            'cfg.trialLabel needs one label per trialStart event: %d label(s) for %d event(s) (%s).', ...
            numel(cfg.trialLabel), numel(cfg.trialStart), strjoin(cfg.trialStart, ', '));
    end
end

if ~isfield(cfg, 'trialEnd') && ~isfield(cfg, 'trialDuration') && ~isfield(cfg.events, 'sessionEnd')
    error('getTrials:missingField', ...
        ['Without cfg.trialEnd, each trial ends at the next trialStart and the last one at ' ...
         'the session end: cfg.events.sessionEnd is required.']);
end

function names = checkEventNames(value, fieldName, eventNames, eventCodes)
% event name(s) or MedPC code(s) -> 1 x n cell of names in cfg.events

if ischar(value) || isstring(value)
    value = cellstr(value);
end
if iscell(value)
    unknown = value(~ismember(value, eventNames));
    if ~isempty(unknown)
        error('getTrials:unknownEvent', 'cfg.%s: %s is not in cfg.events (events: %s).', ...
            fieldName, strjoin(unknown, ', '), strjoin(eventNames, ', '));
    end
    names = value(:)';
elseif isnumeric(value)
    allCodes = cell2mat(cellfun(@(code) code(:)', eventCodes, 'UniformOutput', false));
    unknown  = value(~ismember(value, allCodes));
    if ~isempty(unknown)
        error('getTrials:unknownEvent', 'cfg.%s: code %s is not in cfg.events.', ...
            fieldName, num2str(unknown(:)'));
    end
    names = eventNames(cellfun(@(code) any(ismember(code, value)), eventCodes));
else
    error('getTrials:unknownEvent', 'cfg.%s must be event name(s) or MedPC code(s).', fieldName);
end

function checkMedData(medData, cfg)
% the time and event blocks must exist in the MedPC data

blockNames = fieldnames(medData);
blockNames = blockNames(cellfun(@(name) numel(name) == 1, blockNames))';   % A, B, ... Z
for blockField = {'medTime', 'medEvents'}
    block = cfg.(blockField{1});
    if ~isfield(medData, block)
        error('getTrials:missingBlock', 'The MedPC data has no %s block (cfg.%s). Blocks: %s.', ...
            block, blockField{1}, strjoin(blockNames, ', '));
    end
end
if numel(medData.(cfg.medTime)) ~= numel(medData.(cfg.medEvents))
    warning('getTrials:blockLength', ...
        ['The %s block (times, %d values) and the %s block (event codes, %d values) have ' ...
         'different lengths; times and codes may not match.'], cfg.medTime, ...
        numel(medData.(cfg.medTime)), cfg.medEvents, numel(medData.(cfg.medEvents)));
end

function checkTrialDuration(cfg)
% cfg checks for trials defined by duration

if isfield(cfg,'trialEnd')
    error('getTrials:trialEndAndDuration', ...
        'Give either cfg.trialEnd or cfg.trialDuration, not both.');
end
if ~isnumeric(cfg.trialDuration) || ~isscalar(cfg.trialDuration) || ~(cfg.trialDuration > 0)
    error('getTrials:trialDuration', 'cfg.trialDuration must be one positive number, in s.');
end
if ~isfield(cfg.events,'sessionEnd')
    error('getTrials:missingField', ...
        'cfg.events.sessionEnd is required with cfg.trialDuration (the last ITI ends there).');
end
if isfield(cfg.events,'trialDuration')
    error('getTrials:reservedName', ...
        ['''trialDuration'' labels the end of trials defined by duration; ' ...
         'rename the event cfg.events.trialDuration.']);
end

function checkTrialTimes(startTimes, durationSamples, sessionEndTime, trialDuration, sampleRate)
% trials defined by duration must not overlap or run past the session end

if isempty(sessionEndTime)
    error('getTrials:noSessionEnd', 'The sessionEnd event (cfg.events.sessionEnd) is not in the file.');
end
sortedStarts = sort(startTimes);
iOverlap = find(sortedStarts(2:end) < sortedStarts(1:end-1) + durationSamples, 1);
if ~isempty(iOverlap)
    error('getTrials:trialOverlap', ...
        ['Trial %d starts %.2f s after trial %d, before its %g s (cfg.trialDuration) are over. ' ...
         'Check the MedPC program or cfg.trialDuration.'], iOverlap + 1, ...
        (sortedStarts(iOverlap + 1) - sortedStarts(iOverlap)) * sampleRate, iOverlap, trialDuration);
end
if ~isempty(sortedStarts) && sortedStarts(end) + durationSamples > sessionEndTime
    error('getTrials:trialAfterSessionEnd', ...
        'The last trial is not over (cfg.trialDuration = %g s) when the session ends.', trialDuration);
end

function checkLastIti(trials)
% sanity check: warn if the last ITI (up to the session end) is unusually long

itiDurations = [trials(strcmp({trials.interval},'iti')).duration];
if numel(itiDurations) < 4                     % fewer than 3 ITIs to compare with
    return
end
previous = itiDurations(1:end-1);
limit    = mean(previous) + 2*std(previous);
if itiDurations(end) > limit
    warning('getTrials:longLastIti', ...
        ['The last ITI (%.1f s, up to the session end) is longer than the others ' ...
         '(mean %.1f s, SD %.1f s). Check the session end (cfg.events.sessionEnd).'], ...
        itiDurations(end), mean(previous), std(previous));
end


