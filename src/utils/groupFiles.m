function [groups, fileNames, groupFileNames] = groupFiles(inputPath, groupRegPattern, suffixRegPattern, orderByCreateTime, ignoreFilesWithSizeBelow)
% groupFiles: group files based on their name pattern.
% Details:
%    This function lists files in the directory that matches specific
%    patterns and organize them into a cell array. Files in the same group
%    are listed in the same row. e.g.
%       {'dir/GA1-RA1.ncs', 'dir/GA1-RA1_0002.ncs', 'dir/GA1-RA1_0003.ncs';
%        'dir/GA1-RA2.ncs', 'dir/GA1-RA2_0002.ncs', 'dir/GA1-RA2_0003.ncs'}
%
%
% Inputs:
%    inputPath - string. The path in which the files will be grouped based
%    on their name pattern. Files in different directories will be
%    concatenated by column.
%
%    groupRegPattern - string. A regular expression used to determine the
%    group name of files in the directory. File names is decomposed to
%    `[group]_[suffix].[extension]`. Files with same group will be put in
%    the same row in the returned cell array.
%
%    suffixRegPattern - string. A regular expression used to determine the
%    suffix of files in the directory. File names is decomposed to
%    `[group]_[suffix].[extension]`.
%
%    orderByCreateTime - boolean. If true, order files in the same group
%    (row) by create data, otherwise, order by suffix. Empty suffix will be
%    first. This only works within direcotory.
%
%    ignoreFilesWithSizeBelow - int. File size in bytes. Files with smaller
%    size then this will be ignored.
%
% Outputs:
%    groups - cell [m]. group pattern extracted from file names.
%
%    fileNames - cell [m, n]. file names grouped in rows.
%
%    groupFileNames - dataTable [m, n + 1]. data table combines groups and
%    fileNames, this can be saved as .csv file to check the files combined.

% Example:
%{

%}
% See also: Nlx2MatCSC_v3, Mat2NlxCSC, combineNcsFiles

% Author:                          Xin Niu
% Email:                           xinniu@mednet.ucla.edu
% Version history revision notes:
%   created by Xin based on work by Chris Dao. Feb-22-2024.


% if true, organize files in reverse temporal order:
REVERSE_TEMPORAL_ORDER = false;


if nargin < 2 || isempty(groupRegPattern)
    groupRegPattern = '.*?(?=\_\d{1}|\.ncs)';
end

if nargin < 3 || isempty(suffixRegPattern)
    suffixRegPattern = '(?<=\_)\d*';
end

if nargin < 4 || isempty(orderByCreateTime)
    orderByCreateTime = true;
end

if nargin < 5 || isempty(ignoreFilesWithSizeBelow)
    ignoreFilesWithSizeBelow = 16384;
end


% .ncs files:
filenames = getNeuralynxFiles(inputPath, '.ncs', ignoreFilesWithSizeBelow);

fileGroup = unique(cellfun(@(x)regexp(x, groupRegPattern, 'once', 'match'), filenames, 'UniformOutput', false));
fileSuffix = unique(cellfun(@(x)regexp(x, suffixRegPattern, 'once', 'match'), filenames, 'UniformOutput', false));

idx = ~cellfun('isempty', fileSuffix);
fileSuffix(idx) = sort(cellfun(@(x) ['_', x], fileSuffix(idx), 'UniformOutput', false));

[rowMat, colMat] = meshgrid(fileSuffix, fileGroup);
groupFileNames = arrayfun(@(x, y) fullfile(inputPath, [y{:}, x{:}, '.ncs']), rowMat, colMat, 'UniformOutput', false);

% remove file if it wasn't in the original list of recording filenames
fullPathFilenames = fullfile(inputPath, filenames);
[groupFileRows,groupFileCols] = size(groupFileNames);
for groupFileRowIndex = 1:groupFileRows
    for groupFileColIndex = 1:groupFileCols
        if ~ismember(groupFileNames{groupFileRowIndex, groupFileColIndex}, fullPathFilenames)
            groupFileNames{groupFileRowIndex, groupFileColIndex} = [];
        end
    end
end

%groupFileNames = groupFileNames(ismember(groupFileNames, fullPathFilenames));

if orderByCreateTime && length(fileSuffix)>1
    % we no longer assume the temporal order of files in each channel is
    % consistent, so check the order of each channel and apply
    % it to its appropriate channel row.
    [nFileGroups, ~] = size(groupFileNames);
    for fileGroupRow = 1:nFileGroups
        fprintf("groupFiles: order files by create time for channel: %s. \n", fileGroup{fileGroupRow});
        order = orderFilesByTime(groupFileNames(fileGroupRow,:));
        groupFileNames(fileGroupRow,:) = groupFileNames(fileGroupRow, order);
    end
elseif length(fileSuffix)>1
    warning("groupFiles: order files by file name. Make sure the order is correct by checking header of raw data! \n")
end

groupFileNames = cell2table([fileGroup(:), groupFileNames]);
groupFileNames.Properties.VariableNames{1} = 'fileGroup';

% .nev files:
eventFileNames = getNeuralynxFiles(inputPath, '.nev', ignoreFilesWithSizeBelow);
eventFileNames = cellfun(@(x) fullfile(inputPath, x), eventFileNames, 'UniformOutput', false);
if length(eventFileNames) > 1
    fprintf("groupFiles: order event files by create time. \n");
    order = orderFilesByTime(eventFileNames, 1);
    eventFileNames = eventFileNames(order);
end

% assume number of events file is same as or less than (no events occurs
% during experiment) the number of segments.
if length(eventFileNames) <= size(groupFileNames, 2) -1
    eventFiles = cell(1, size(groupFileNames, 2));
    eventFiles(:) = {''}; % empty cell cause error when reading from csv.
    eventFiles{1} = 'Events';
    eventFiles(2:length(eventFileNames)+1) = eventFileNames;
    eventFiles = cell2table(eventFiles);
    eventFiles.Properties.VariableNames = groupFileNames.Properties.VariableNames;
    groupFileNames = [groupFileNames; eventFiles];
else
    warning('number of event files is larger than segments!')
end

groups = table2cell(groupFileNames(:, 1));
fileNames = table2cell(groupFileNames(:, 2:end));

end


function files = removeNonExistFile(files)
fprintf('groupFiles: check file existence...\n');
[r, c] = size(files);
files = files(:);

existIdx = cellfun(@(f)exist(f, 'file'), files);

if any(~existIdx)
    for i = find(~existIdx)
        warning('groupFiles: file missing: %s \n', files{i});
    end
end

files(~existIdx) = {''};
files = reshape(files, r, c);
end


function order = orderFilesByTime(files, isEvents)
    if nargin < 2
        isEvents = 0;
    end
    startTimes = zeros(length(files), 1);
    for i = 1:length(files)
        if ~isempty(files{i})
            startTimes(i) = Nlx_getFirstTimestamp(files{i}, isEvents);
        else
            startTimes(i) = intmax('uint64');
        end
    
    end
    [~, order] = sort(startTimes);

end
