%% MedPC output analysis example
% 
% 
% This is an example of how to use the toolbox to do exploratory behavioral 
% analysis from the MedPC output file. 

clear; clc
% behavior_medpc/matlab and utilities_matlab must be on the MATLAB path
% (README, Installation). getExampleFile finds the example data and stops
% with a clear message if utilities_matlab is missing.
refFile = getExampleFile('example_rat_multipellet');
% medData = readMedpc(refFile);

% Configuration
% We start by defining a configuration struct. So far, this struct must have 
% at least the following fields:
% % 
% * _*medFile*_: full path of the file to be analyzed [char] 

%%
cfg          = [];
cfg.medFile  = refFile;
% % 
% * _*events*_: this field contains as many fields as events you want to include 
% in the analysis. It can iclude, for example, cues, outcomes, levers, trial start, 
% etc. You can define the name os thse fields on your convenience. 

% FSCV_Conflict_01 % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% \ E = Event identity time stamps
cfg.events.sessStart = 1;    % \ 1 - Session start
cfg.events.cue1On    = 2;    % \ 2 - Cue1p ON
cfg.events.cue1Off   = 3;    % \ 3 - Cue1p OFF
cfg.events.cue4On    = 4;    % \ 4 - Cue4p ON
cfg.events.cue4Off   = 5;    % \ 5 - Cue4p OFF
cfg.events.anyPellet = 6;    % \ 6 - Any Pellet
cfg.events.drop1p    = 7;    % \ 7 - 1p Pellet drop
cfg.events.drop4p    = 8;    % \ 8 - 4p first pellet
cfg.events.irLightOn = 9;    % \ 9 - IR light ON
cfg.events.magCue1   = 10;   % \ 10 - Mag during 1p Cue
cfg.events.magCue4   = 11;   % \ 11 - Mag during 4p Cue
cfg.events.subs4p    = 12;   % \ 12 - 4p subsequent pellets
cfg.events.mag       = 16;   % \ 16 - Mag entry any time
cfg.events.sessionEnd = 100;  % \ 100 - End of session
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % 
% * _*trial*_: which has felds defining the key events. These include events 
% that mark the start and the end of the trial

cfg.trialLabel = {'1p','4p'};
cfg.trialStart = {'cue1On','cue4On'};
cfg.trialEnd   = {'cue1Off','cue4Off'};

% Create main trial structure
% We can use that configuration to create the main trial structure. This struct 
% organizes choronologicaly the trials and ITIs. The trials are defined by start-end 
% pairs. The ITI are defined from the end event of the trial and the start event 
% of the next trial (or end of the session in case of the last trial).
% 

%% 
% This struct is the backbone of the analysis. The times listed in this structure 
% will be the reference to the trial based analysis: counting behavioral events, 
% latencies, etc.
% The last trial's ITI runs to the session end (cfg.events.sessionEnd). In
% this session that ITI is about twice as long as the others, so getTrials
% warns about it (getTrials:longLastIti).

trialStruct = getTrials(cfg);

%% Add selected variables (from the cfg.events)
% After having the main trial struct, you can add behavioral variables (events) 
% to that structure by listing the field names defined in the event configuration 
% and corresponding to the variables of your interest. In this example, we are 
% adding the 'mag' variable, which indicates a maganize entry. 

evConfig        = []; 
evConfig.events = {'magCue1'};
eventCount = addEvent(trialStruct,evConfig);

%% Add selected variables (from the cfg.events) and include additional behavioral measures

evConfig            = [];
evConfig.events     = {'magCue1','magCue4','mag'};
evConfig.latency    = true; % default = 'false'
evConfig.firstEvent = true; % default = 'false'
eventBeh = addEvent(trialStruct,evConfig);

%% Rastergram of magazine entries: cue + ITI

rasterCfg           = [];
rasterCfg.events    = {'magCue1','magCue4','mag'};
rasterCfg.sectionBy = 'trialLabel';                 % 1p at the bottom, 4p on top

wfig(1); clf
eventRaster(eventBeh, rasterCfg);
xline(5, 'r--', 'pellet');

%% trial-based event histogram: magazine entries after the cue (ITI)

histCfg = [];
histCfg.events = 'mag';
histCfg.plotFlag = true;
histCfg.figNumber = 2;
histCfg.histBins = 0:1:30;          % 1 s bins; every ITI lasts at least 30 s
histCfg.select.interval = 'iti';    % 'mag' is only logged outside the cue

histCfg.select.trialLabel = '4p';
histCfg.color = 'k';
[histData4p,list4p] = eventHistogram(eventBeh,histCfg);

%% add a second histogram
histCfg.select.trialLabel = '1p';
histCfg.color = 'r';
[histData1p,list1p] = eventHistogram(eventBeh,histCfg);

%% Extract data of interest

entry                 = [];
entry.count           = [5 15];
entry.contrast.count  = 'range';
entry.interval        = 'iti';
[eventSel,requestConfig] = getEntry(eventBeh.trials,entry);
%% Extract bouts from time stamps vector
iIti = 2;
minInterval = 1;
minDuration = 1;

trialTimes = eventSel(iIti).magTimes;
boutList = extractBouts(trialTimes,minInterval,minDuration);
disp(boutList)

%% Add bouts to event struct

evConfig = [];
evConfig.events = {'mag'};
boutCfg.minDuration = 1;
boutCfg.minInterval = 1;
evConfig.bouts = boutCfg;   
evConfig.latency = true;
evConfig.firstEvent = true;

eventBout = addEvent(trialStruct,evConfig);

%% Rastergram of the ITIs only (time 0 = cue offset)
itiTrials = getEntry(eventBeh.trials,'interval','iti');

rasterCfg           = [];
rasterCfg.events    = 'mag';
rasterCfg.sectionBy = 'trialLabel';
wfig(3); clf
eventRaster(itiTrials, rasterCfg);


%% Trials defined by duration instead of an end event
% Many tasks define a trial by time rather than by an end event. With
% cfg.trialDuration, each trial runs from its trialStart for that many
% seconds; the ITI runs from there to the next trialStart, or to
% events.sessionEnd for the last trial. In this example, trials of 30 s
% from cue onset (cfg.trialEnd above uses cue offset to show short trials).
% getTrials warns here that the last ITI is much longer than the others:
% this session ends about 35 s after the last trial.

durCfg               = rmfield(cfg, 'trialEnd');   % trialEnd and trialDuration exclude each other
durCfg.trialDuration = 30;                         % s
trialStructDur = getTrials(durCfg);

evConfig         = [];
evConfig.events  = {'magCue1','magCue4','mag'};
evConfig.latency = true;
eventDur = addEvent(trialStructDur,evConfig);

rasterCfg           = [];
rasterCfg.events    = {'magCue1','magCue4','mag'};
rasterCfg.sectionBy = 'trialLabel';
wfig(4); clf
eventRaster(eventDur, rasterCfg);
xline(durCfg.trialDuration, 'k--', 'trial end');
