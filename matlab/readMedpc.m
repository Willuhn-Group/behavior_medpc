function medpcData = readMedpc(filePath)
% medpcData = readMedpc(filePath)
%
% Reads a MedPC output file: the header information and every data block
% (A:, B:, ... Z:), each stored in its own field.
%
% Inputs:
%   filePath: full path of the MedPC file                                  [char]
%
% Outputs:
%   medpcData: struct with fields                                          [struct]
%     header: all the text before the first data block                     [char]
%     file: File in the header                                             [char]
%     startDate: Start Date in the header                                  [char]
%     endDate: End Date in the header                                      [char]
%     subject: Subject in the header                                       [char]
%     experiment: Experiment in the header                                 [char]
%     group: Group in the header                                           [char]
%     box: Box in the header                                               [char]
%     startTime: Start Time in the header                                  [char]
%     endTime: End Time in the header                                      [char]
%     msn: MSN in the header                                               [char]
%     minutesDuration: session duration, in minutes                        [double]
%     <block>: one field per data block (e.g. D, E), with its values       [double]
%
% Example:
%   medpcData = readMedpc(fullfile(repoRoot, 'example_data', 'example_rat_multipellet'));
%
% Dependencies: none
%
% Version history:
%   v0.1  Jun 2024  First version (read_medpc)
%   v0.2  Aug 2026  Renamed to readMedpc; camelCase names
%
% Author(s): Sergio Conde-Ocazionez
% Neuromodulation & Behavior Laboratory, Netherlands Institute for Neuroscience

fileData = fileread(filePath);                                              % read medPC file

% reads the block's labels %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
blockNames = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';                                 % default block order
blockStart = zeros(1,length(blockNames));                                 % default block indexing
for iblock = 1:length(blockNames)
    blockFlag = strfind(fileData,[blockNames(iblock) ':']);              % look for the index of the each block label
    if ~isempty(blockFlag)                                                 % if the block exists
        blockStart(iblock) = blockFlag(end);                              % strore block indexing
    end
end
[ind, order]    = sort(blockStart);                                        % order blocks based on their index
blockNames     = blockNames(order);                                       % reorder block labels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

medpcData.header = fileData(1:ind(1) - 1);                                % store header (everything before the first block label)

% finds header's labels %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
startDatePtr  = strfind(medpcData.header,'Start Date:');
endDatePtr    = strfind(medpcData.header,'End Date:');
subjectPtr    = strfind(medpcData.header,'Subject:');
experimentPtr = strfind(medpcData.header,'Experiment:');
groupPtr      = strfind(medpcData.header,'Group:');
boxPtr        = strfind(medpcData.header,'Box:');
startTimePtr  = strfind(medpcData.header,'Start Time:');
endTimePtr    = strfind(medpcData.header,'End Time:');
msnPtr        = strfind(medpcData.header,'MSN:');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% splits and stores header's data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
medpcData.file        = medpcData.header(7:startDatePtr - 3);
medpcData.startDate   = medpcData.header(startDatePtr + 12:endDatePtr - 3);
medpcData.endDate     = medpcData.header(endDatePtr + 10:subjectPtr - 3);
medpcData.subject     = medpcData.header(subjectPtr + 9:experimentPtr - 3);
medpcData.experiment  = medpcData.header(experimentPtr + 12:groupPtr - 3);
medpcData.group       = medpcData.header(groupPtr + 7:boxPtr - 3);
medpcData.box         = medpcData.header(boxPtr + 5:startTimePtr - 3);
medpcData.startTime   = medpcData.header(startTimePtr + 12:endTimePtr - 3);
medpcData.endTime     = medpcData.header(endTimePtr + 10:msnPtr - 3);
medpcData.msn         = medpcData.header(msnPtr + 5:end);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% computes session duration in minutes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
startTime = duration(medpcData.startTime);
endTime = duration(medpcData.endTime);
medpcData.minutesDuration = minutes(endTime - startTime);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% reads the data from each block %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ind = [ind length(fileData)];                                                 % this allows to pick the data up to the end of the file
for iblock = 1:length(blockNames)
    if ind(iblock) > 0                                                        % if the block exists
        blockTxt   = fileData(ind(iblock):ind(iblock + 1));                   % take data between the current block and the following one
        defLine    = [strfind(blockTxt,':') length(blockTxt)];                % find ':' indexes to define block lines
        catEvents  = [];                                                      % initialize variable
        for idef = 1:length(defLine) - 1
            locLine   = blockTxt(defLine(idef) : defLine(idef + 1));          % blocl line selection
            endNumber = strfind(locLine,'.') + 3;                             % find number's end
            if ~isempty(endNumber)
                locLine     = locLine(1:max(endNumber));
                spaceFlags  = strfind(locLine,' ');                           % find empty spaces to define individual numbers
                startNumber = spaceFlags(diff(spaceFlags) > 1) + 1;           % find the start of each number
                if max(spaceFlags) < length(locLine)                          % in case there is only one number (e.g., first block in the list)
                    startNumber = cat(2,startNumber,max(spaceFlags));
                end
                for inum = 1:length(startNumber)
                    locNum   = locLine(startNumber(inum):endNumber(inum));   % cut text number
                    catEvents = cat(2,catEvents,str2double(locNum));         % transform to double
                end
            end
        end
        medpcData.(blockNames(iblock)) = catEvents;                           % store using the block label as a field name
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
