%% MedPC output analysis example
% 
% 
% This is an example of how to use the toolbox to do exploratory behavioral 
% analysis from the MedPC output file. 

clear; clc
% Find the repo from this script's location. When run section by section,
% mfilename points to a temporary copy, so use the file open in the Editor.
scriptFile = mfilename('fullpath');
repoRoot   = fileparts(fileparts(scriptFile));
if ~isfolder(fullfile(repoRoot, 'example_data'))
    % run section by section: mfilename points to a temporary copy,
    % so use the file open in the Editor instead
    repoRoot = fileparts(fileparts(matlab.desktop.editor.getActiveFilename));
end
addpath(fullfile(repoRoot, 'matlab'));

% behavior_medpc uses getEntry, wfig and avg_err_shade from utilities_matlab
% https://github.com/Willuhn-Group/utilities_matlab
if ~exist('getEntry', 'file') || ~exist('wfig', 'file') || ~exist('avg_err_shade', 'file')
    error('multipelletExample:missingDependency', ...
        ['utilities_matlab is not on the MATLAB path.\n' ...
         'Clone https://github.com/Willuhn-Group/utilities_matlab and run addpath(genpath(<its folder>)).']);
end

refFile = fullfile(repoRoot, 'example_data', 'example_rat_multipellet');
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
rasterCfg.colors    = [0 .45 .74; 0 .45 .74; 0 0 0]; % cue entries blue, ITI entries black

wfig(1); clf
eventRaster(eventBeh, rasterCfg);
xline(5, 'r--', 'pellet');

%% trial-based event histogram

histCfg = [];
histCfg.events = 'mag';
histCfg.plotFlag = true;
histCfg.figNumber = 2;
histCfg.histBins = 0:35;

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

%% Rastergram of magazine entries: cue + ITI
evConfig         = [];
evConfig.events  = {'magCue1','magCue4','mag'};
evConfig.latency = true;
eventAll = addEvent(trialStruct,evConfig);

wfig(6); clf
eventRaster(eventAll, {'magCue1','magCue4','mag'});
xline(5, 'r--', 'pellet');

%% Only the ITIs
itiTrials = getEntry(eventAll.trials,'interval','iti');
wfig(7); clf
eventRaster(itiTrials, 'mag');      % time 0 = cue offset

