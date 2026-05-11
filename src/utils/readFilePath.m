function [cscFiles, timestampFiles, expNames] = readFilePath(expIds, filePath, channel)
% load all csc File names in filePath.
%
% When multiple expIds are provided, rows are matched across experiments by
% electrode channel name (the part of the filename after the G[A-D][1-4]- bank
% prefix and before the _NNN segment suffix).  This allows correct cross-session
% sorting even when a plug-swap causes the same electrode to appear under a
% different bank prefix in different sessions.  A warning (not an error) is
% printed whenever the bank prefix for a channel differs across experiments.
%
% The canonical channel order is taken from expIds(1).  Channels present in
% later experiments but absent from expIds(1) are appended at the end with a
% warning.

if nargin < 3
    channel = 'micro';
end

% ── Pass 1: collect raw data for every experiment ────────────────────────────
nExps = length(expIds);
expCscFiles      = cell(1, nExps);
expTimestampFiles = cell(1, nExps);
expKeys          = cell(1, nExps);   % electrode name per row (bank stripped)
expBanks         = cell(1, nExps);   % bank prefix per row (e.g. 'GA1')

for i = 1:nExps
    expId = expIds(i);
    cscFilePath = [filePath, sprintf('/Experiment-%d', expId)];
    if strcmp(channel, 'micro')
        cscFilePath = fullfile(cscFilePath, 'CSC_micro');
    elseif strcmp(channel, 'macro')
        cscFilePath = fullfile(cscFilePath, 'CSC_macro');
    else
        error('undefined channel type. select "micro" or "macro"');
    end

    [cscFile, timestampsFile] = readCSCFilePath(cscFilePath);
    expCscFiles{i}       = cscFile;
    expTimestampFiles{i} = timestampsFile;

    nRows = size(cscFile, 1);
    keys  = cell(nRows, 1);
    banks = cell(nRows, 1);
    for r = 1:nRows
        [keys{r}, banks{r}] = extractChannelKey(cscFile{r, 1});
    end
    expKeys{i}  = keys;
    expBanks{i} = banks;
end

% ── Build unified channel list (Exp-1 order is canonical) ────────────────────
refKeys  = expKeys{1};
refBanks = expBanks{1};
allKeys  = refKeys;   % will grow if later exps have extra channels

for i = 2:nExps
    for r = 1:length(expKeys{i})
        k = expKeys{i}{r};
        if ~any(strcmp(allKeys, k))
            fprintf('[readFilePath] Exp%d has channel "%s" not present in Exp%d — appending.\n', ...
                expIds(i), k, expIds(1));
            allKeys{end+1} = k; %#ok<AGROW>
        end
    end
end
nChannels = length(allKeys);

% ── Pass 2: build aligned output matrix ──────────────────────────────────────
cscFiles       = {};
timestampFiles = {};
expNames       = {};

for i = 1:nExps
    % Build lookup: channel key → row index in this experiment
    keyMap = containers.Map(expKeys{i}, num2cell(1:length(expKeys{i})));

    nSegs = size(expCscFiles{i}, 2);
    block = repmat({''}, nChannels, nSegs);   % default: empty (channel absent)

    for c = 1:nChannels
        k = allKeys{c};
        if isKey(keyMap, k)
            srcRow = keyMap(k);
            block(c, :) = expCscFiles{i}(srcRow, :);

            % Warn if bank prefix differs from the reference experiment
            if i > 1
                refIdx = find(strcmp(refKeys, k), 1);
                if ~isempty(refIdx) && ~strcmp(expBanks{i}{srcRow}, refBanks{refIdx})
                    fprintf('[readFilePath] Bank prefix mismatch for channel "%s": Exp%d=%s, Exp%d=%s (plug swap?)\n', ...
                        k, expIds(1), refBanks{refIdx}, expIds(i), expBanks{i}{srcRow});
                end
            end
        else
            fprintf('[readFilePath] Channel "%s" not found in Exp%d — filling with empty paths.\n', ...
                k, expIds(i));
        end
    end

    cscFiles       = [cscFiles, block]; %#ok<AGROW>
    timestampFiles = [timestampFiles, expTimestampFiles{i}]; %#ok<AGROW>
    nTsAfter = length(timestampFiles);
    expNames(end+1:nTsAfter) = {sprintf('Exp%d', expIds(i))}; %#ok<AGROW>
end

end

% ─────────────────────────────────────────────────────────────────────────────
function [key, bank] = extractChannelKey(filepath)
% Extract the electrode channel name from a CSC .mat file path.
% 'GA1-RA1_001.mat' → key='RA1', bank='GA1'
% 'GB2-RAH-EC3_005.mat' → key='RAH-EC3', bank='GB2'
    [~, stem] = fileparts(filepath);
    bank = regexp(stem, '^G[A-D][1-4]', 'match', 'once');
    key  = regexprep(stem, '^G[A-D][1-4]-', '');   % strip bank prefix
    key  = regexprep(key,  '_\d+$',         '');    % strip _NNN suffix
end
