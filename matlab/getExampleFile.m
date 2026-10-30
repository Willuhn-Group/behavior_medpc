function filePath = getExampleFile(fileName)
% filePath = getExampleFile(fileName)
%
% Returns the full path of a file in this repo's example_data folder and
% checks that the utilities_matlab functions used by behavior_medpc are on
% the MATLAB path. Example scripts use it so they run from any folder, also
% section by section.
%
% Inputs:
%   fileName: name of a file in example_data (optional; without it, the    [char]
%     path of the example_data folder is returned)
%
% Outputs:
%   filePath: full path of the file, or of the example_data folder         [char]
%
% Example:
%   refFile = getExampleFile('example_rat_multipellet');
%   medData = readMedpc(refFile);
%
% Dependencies: none (checks that getEntry, wfig, avgErrorShade and
%   extractBouts from utilities_matlab are on the path)
%
% Version history:
%   v0.1  Oct 2026  First version (moved out of multipelletExample.m)
%
% Author(s): Sergio Conde-Ocazionez
% Neuromodulation & Behavior Laboratory, Netherlands Institute for Neuroscience

UTILITIES = {'getEntry', 'wfig', 'avgErrorShade', 'extractBouts'};  % used by behavior_medpc

%------------------------- example data path -------------------------------%
% this file is in <repo>/matlab, so the repo is one folder up
repoRoot = fileparts(fileparts(mfilename('fullpath')));
filePath = fullfile(repoRoot, 'example_data');
if nargin > 0
    filePath = fullfile(filePath, fileName);
    if ~isfile(filePath)
        error('getExampleFile:fileNotFound', 'There is no file %s in %s.', ...
            fileName, fullfile(repoRoot, 'example_data'));
    end
end

%------------------------ utilities_matlab check ---------------------------%
missing = UTILITIES(~cellfun(@(name) exist(name, 'file') > 0, UTILITIES));
if ~isempty(missing)
    error('getExampleFile:missingDependency', ...
        ['utilities_matlab is not on the MATLAB path (missing: %s).\n' ...
         'Clone https://github.com/Willuhn-Group/utilities_matlab and run addpath(genpath(<its folder>)).'], ...
        strjoin(missing, ', '));
end
