function outputFiles = spikeDetection(cscFiles, timestampFiles, outputPath, experimentName, skipExist, runRemovePLI, runCAR)
%spikeDetection Summary of this function goes here
%   cscFiles cell(m, n). m: number of channels. n: number of files in each
%   channel. spikes detected from file in each row will be combined.


if nargin < 4 || isempty(experimentName)
    experimentName = repmat({''}, length(timestampFiles), 1);
end

if nargin < 5
    skipExist = true;
end

if nargin < 6
    runRemovePLI = false;
end

if nargin < 7
    runCAR = true;
end

saveXfDetect = false;
clearRemovePLI = true;

makeOutputPath(cscFiles, outputPath, skipExist);
nSegments = length(timestampFiles);
outputFiles = cell(1, size(cscFiles, 1));

parfor i = 1: size(cscFiles, 1)

    channelFiles = cscFiles(i,:);

    if all(cellfun(@(x)~exist(x, "file"), cscFiles(i, :)))
        warning('csc file not exist %s\n', cscFiles{i, :});
        continue
    end

    spikeFilename = createSpikeFileName(channelFiles{1});
    tempSpikeFilename = ['temp_', spikeFilename];

    spikeFilename = fullfile(outputPath, spikeFilename);
    tempSpikeFilename = fullfile(outputPath, tempSpikeFilename);

    outputFiles{i} = spikeFilename;

    if exist(spikeFilename, "file") && skipExist
        continue
    end

    if exist(tempSpikeFilename, "file")
        delete(tempSpikeFilename);
    end

    fprintf(['spike detection: \n', sprintf('%s \n', channelFiles{:})])

    matobj = matfile(tempSpikeFilename, 'Writable', true);
    % add placeholders so variables still exist even when no spikes are
    % detected in any recordings (I think these vars are meant to be in this 
    % format in that case) since addition of isempty(spikes) clause below 
    % would mean they are not present at all - SD
    matobj.spikes = single([]);      
    matobj.spikeTimestamps = [];     
    matobj_empty = true;
    % spikes = cell(nSegments, 1);
    xfDetect = cell(nSegments, 1);
    ExpNameId = cell(nSegments, 1);
    % spikeTimestamps = cell(nSegments, 1);
    duration = 0;

    [outputStruct, param] = getDetectionThresh(channelFiles, runRemovePLI);
    timestampsStart = NaN;
    for j = 1: nSegments
        if ~exist(channelFiles{j}, "file")
            fprintf(['missing file in spike detection: \n', sprintf('%s \n', channelFiles{j})]);
            continue
        end

        signal = readCSC(channelFiles{j}, runRemovePLI, clearRemovePLI, runCAR);
        if isempty(signal)
            warning(sprintf('spikeDetection: error reading file: \n%s \n', channelFiles{j}));
            continue;
        end

        [timestamps, ~] = readTimestamps(timestampFiles{j});
        % duration = duration + dur;

        if j == 1 || isnan(timestampsStart)
            timestampsStart = min(timestampsStart, timestamps(1));
        elseif timestampsStart > timestamps(1)
            warning('spikeDetection: timestamp files not correctly ordered!');
            fprintf('%s\n', timestampFiles);
        end

        % duration includes gaps between experiments, which is necessary
        % for spikeHist calculation in getSpikeCodes. This take huge
        % memory.
        duration = timestamps(end) - timestampsStart;
        timestamps = timestamps - timestampsStart;
        if saveXfDetect
            [spikes, index, ~, xfDetect{j}] = amp_detect_AS(signal, param, outputStruct);
        else
            [spikes, index, ~] = amp_detect_AS(signal, param, outputStruct);
        end

        % set unused variables to emtpy to save memory usage:
        signal = []

        tsSingle = single(timestamps);
        if length(unique(tsSingle)) == length(timestamps)
            disp('convert timestamps to single precision.')
            timestamps = tsSingle;
        end

        ExpNameId{j} = repmat(j, 1, length(index));
        spikeTimestamps = timestamps(index);
        timestamps = [];

        try
            if isempty(spikes)
                % nothing to write or append—just continue
                % added to deal with cases where first recording has no
                % spikes detected but subsequent recordings do
                continue
            end
            if matobj_empty
                fprintf('spikeDetection: write spikes:\n channel: %s\n%s\n', channelFiles{j}, tempSpikeFilename);
                matobj.spikes = single(spikes);
                matobj.spikeTimestamps = spikeTimestamps(:);
                matobj_empty = false;
            else
                fprintf('spikeDetection: append spikes:\n channel: %s\n%s\n', channelFiles{j}, tempSpikeFilename);
                matobj.spikes(end+1:end+size(spikes, 1), :) = single(spikes);
                matobj.spikeTimestamps(end+1:end+numel(spikeTimestamps), 1) = spikeTimestamps(:);
            end
        catch ME
            catchErr(tempSpikeFilename, spikeFilename, ME)
        end

        spikes = [];
        spikeTimestamps = [];

    end

    % in case server connection is lost:
    try
        matobj.param = param;
        matobj.ExpNameId = int8([ExpNameId{:}]);
        matobj.ExpName = experimentName;
        matobj.timestampsStart = timestampsStart;
        matobj.outputStruct = outputStruct;
        matobj.duration = duration;

        if saveXfDetect
            matobj.xfDetect = [xfDetect{:}];
        end
        fprintf('save success, rename spike file name to:\n %s\n', spikeFilename);
        movefile(tempSpikeFilename, spikeFilename);
    catch ME
        catchErr(tempSpikeFilename, spikeFilename, ME)
    end
end

outputFiles = outputFiles(cellfun(@(x)~isempty(x), outputFiles));

end

function catchErr(tempSpikeFilename, spikeFilename, ME)
    if exist(tempSpikeFilename, "file")
        delete(tempSpikeFilename);
    end
    if exist(spikeFilename, "file")
        delete(spikeFilename);
    end
    warning(sprintf('spikeDetection: error writing file %s\n:', spikeFilename))
    fprintf('Error message: %s\n', ME.message);
end
