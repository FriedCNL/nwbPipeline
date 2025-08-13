function [inFiles, outFiles] = createIOFiles(channelOutFilePath, expOutFilePath, pattern, renameChannels)
%createIOFiles create input/output file names to unpack.
%   A single recording may have multiple segments with different files. The
%   issue is the suffix of files for a single channel may not be correctly
%   ordered. So we create the output file with suffix correctly ordered.
%   The output file has a suffix with pattern '001.mat'. File name is the
%   same as the .ncs file.

% pattern: used to select micro/macro/event files.
% renameChannels: set channel names according to montage (for iowa data).
% inFiles (channels by segments): .ncs file names to be unpacked
% outFiles(channels by segments): .mat file names to save unpacked data.

if ~exist(channelOutFilePath, "dir")
    mkdir(channelOutFilePath);
end

if nargin < 4
    renameChannels = [];
end

channelFileNames = readtable(fullfile(expOutFilePath, 'channelFileNames.csv'), Delimiter=',');
channelFileNames = table2cell(channelFileNames);

% select macro/micro files and rename output file names so that alphabetic order
% is consistent with temporal order.
% For UCLA data, the macro files always start with 'R' or 'L' in the file
% name. The micro files always start with 'G[A-D]'.
% For Iowa data, macro files have pattern: LFPx*.ncs
% micro files have pattern: PDes*.ncs
% Events files have pattern: Events*.nev
idx = cellfun(@(x)~isempty(regexp(x, pattern, 'match', 'once')), channelFileNames(:, 1));
inFileNames = channelFileNames(idx, :);

% reorder file names by numerical suffix:
formatString = @(str) regexprep(str, '(\d+)(?=\D*$)', '${sprintf(''%03d'', str2double($1))}');
formattedStrings = cellfun(formatString, inFileNames(:, 1), 'UniformOutput', false);
[~, sortOrder] = sort(formattedStrings);
inFileNames = inFileNames(sortOrder, :);

if ~isempty(renameChannels)
    %todo: replace this with in-out matching based on AD Channel #
    channels = [];
    unmatchedInFileIndices = [];
    for inFileIdx = 1 : length(inFileNames)
        currentInFilename = inFileNames{inFileIdx, 2};
        currentInFileAD = Nlx_getADChannel(currentInFilename);
        if isKey(renameChannels, currentInFileAD)
            renameChannelName = renameChannels(currentInFileAD);
            channels = [channels; renameChannelName];
        else
            unmatchedInFileIndices = [unmatchedInFileIndices; inFileIdx];
        end
    
    end
    inFiles = inFileNames(:, 2:end);
    inFiles(unmatchedInFileIndices) = [];
else
    channels = inFileNames(:, 1);
    inFiles = inFileNames(:, 2:end);
end
numFilesEachChannel = size(inFiles, 2);

suffix = arrayfun(@(y) sprintf('%03d.mat', y), 1:numFilesEachChannel, 'UniformOutput', false);
outFiles = combineCellArrays(channels, suffix);
outFiles = cellfun(@(fn) fullfile(channelOutFilePath, fn), outFiles, 'UniformOutput', false);

emptyIdx = cellfun(@isempty, inFiles(:));
outFiles(emptyIdx) = {''};

writecell(inFiles, fullfile(channelOutFilePath, 'inFileNames.csv'));
writecell(outFiles, fullfile(channelOutFilePath, 'outFileNames.csv'));

end
