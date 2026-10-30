function medBehavior = medEvents(cfg)
% medBehavior = medEvents(cfg)
%
% Reads a MedPC file and extracts, for each event, its positions in the
% event sequence, its times and, if requested, its bouts. Times are in
% seconds from the start of the session.
%
% Inputs:
%   cfg: configuration struct with fields                                  [struct]
%     file: full path of the MedPC file                                    [char]
%     events: one field per event with its MedPC code, as in getTrials    [struct]
%     medTime: MedPC block with the event times (optional, default: 'D')   [char]
%     medEvents: MedPC block with the event codes (optional, default: 'E') [char]
%     boutEvents: one field per event to split into bouts (optional),      [struct]
%       each with
%       interBout: minimum time between bouts, in s                        [double]
%       minBoutDur: minimum bout duration, in s                            [double]
%
% Outputs:
%   medBehavior: struct with fields                                        [struct]
%     cfg: the configuration, with the file data (readMedpc) in cfg.data   [struct]
%     sequence: event codes in the order they occurred                     [double]
%     eventTimes: time of each code in sequence, in s                      [double]
%     trigger.<event>: positions of the event in sequence                  [double]
%     timeStamps.<event>: times of the event, in s                         [double]
%     bout.<event>: start, duration and triggCount of each bout            [struct]
%       (events in cfg.boutEvents; empty if the event never occurs)
%     fileType: 'medpc'                                                    [char]
%
% Example:
%   cfg = []; cfg.file = getExampleFile('example_rat_multipellet');
%   cfg.events.mag = 16;
%   cfg.boutEvents.mag.interBout = 1; cfg.boutEvents.mag.minBoutDur = 1;
%   medBehavior = medEvents(cfg);
%
% Dependencies: readMedpc (behavior_medpc), extractBouts (utilities_matlab)
%
% Version history:
%   v0.1  Sep 2026  First version
%   v0.2  Sep 2026  Reads the file itself (cfg.file); output fields renamed
%                   (eventTimes, timeStamps, bout)
%
% Author(s): Sergio Conde-Ocazionez
% Neuromodulation & Behavior Laboratory, Netherlands Institute for Neuroscience


cfg = checkCfg(cfg);
cfg.data = readMedpc(cfg.file);
medBehavior.cfg = cfg;
medBehavior.sequence = cfg.data.(cfg.medEvents);
medBehavior.eventTimes = cfg.data.(cfg.medTime) * 1e-2; % medpc resolution is 10ms

eventLabels = fieldnames(cfg.events);
for ievent = 1:numel(eventLabels)
    localEvent = eventLabels{ievent};   % event label
    eventFlags = medBehavior.sequence == medBehavior.cfg.events.(localEvent);

    if any(eventFlags)
        eventTimes = medBehavior.eventTimes(eventFlags);
        medBehavior.trigger.(localEvent) = find(eventFlags);
        medBehavior.timeStamps.(localEvent) = eventTimes;

        if ismember(localEvent,cfg.boutEvents.boutLabels)  
            boutList = extractBouts(eventTimes, ...
                cfg.boutEvents.(localEvent).interBout, ...
                cfg.boutEvents.(localEvent).minBoutDur);
            medBehavior.bout.(localEvent).start = boutList.boutStart;
            medBehavior.bout.(localEvent).duration = boutList.duration;
            medBehavior.bout.(localEvent).triggCount = boutList.triggCount;
        end
    else
        medBehavior = addDefaults(medBehavior,localEvent);
    end
end
medBehavior.fileType = 'medpc';

function medBehavior = addDefaults(medBehavior,localEvent)
medBehavior.trigger.(localEvent) = [];
medBehavior.timeStamps.(localEvent) = [];
medBehavior.bout.(localEvent).start = [];
medBehavior.bout.(localEvent).duration = [];
medBehavior.bout.(localEvent).triggCount = [];

function cfg = checkCfg(cfg)

if ~isfield(cfg,'medTime')
    cfg.medTime = 'D';
end

if ~isfield(cfg,'medEvents')
    cfg.medEvents = 'E';
end

if isfield(cfg,'boutEvents')
    cfg.boutEvents.boutLabels = fieldnames(cfg.boutEvents);
else
    cfg.boutEvents.boutLabels = {};
end
