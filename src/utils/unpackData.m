function outFileNames = unpackData(inFileNames, outFileNames, outFilePath, verbose, skipExist)
% unpackData(inFileNames, outFilePath, verbose): read neuralynx file and
% save to .mat files.

% inFileName: datatable(m, n). '.ncs' files for one experiment. Should have
% same timestamps.

% timestamps: Unix time samplingInterval: matlab duration object.
% samplingRate can be calculate as: seconds(1)/samplingInterval.

% This function uses library developed by Ueli Rutishauser:
% https://www.urut.ch/new/serendipity/index.php?/pages/nlxtomatlab.html As
% this function calls mex files complied in intel/amd machine, it will not
% work on mac with Matlab >= 2023b which run natively on apple silicon.


if nargin < 4 || isempty(verbose)
    verbose = 1;
end

if nargin < 5
    skipExist = 1;
end

checkExistFileIsValid = false;

makeOutputPath(inFileNames(:), outFilePath, skipExist)

% TO DO: probably don't want to hard code timestamp file name.
timestampFileName = 'lfpTimeStamps';

% compute stampstamp for the first channel in each segment.
% each segment has a suffix with pattern '001'. We need precompute when to
% cmopute timestamps as deciding within parfor will cause issues.
suffix = regexp(outFileNames(1,:), '(?<=_)\d{3}(?=.mat)', 'match', 'once');

logFile = fullfile(outFilePath, 'unpack_log-unpackData', 'unpackData.log');

if ~skipExist
    fprintf('remove all old unpacked mat files in: %s\n', outFilePath);
    cellfun(@delete, fullfile(outFilePath, {dir(fullfile(outFilePath, 'G*_00*.mat')).name}));
    cellfun(@delete, fullfile(outFilePath, {dir(fullfile(outFilePath, 'R*_00*.mat')).name}));
    cellfun(@delete, fullfile(outFilePath, {dir(fullfile(outFilePath, 'L*_00*.mat')).name}));
end

% unpack ncs files:
for segment = 1: size(inFileNames, 2)

    dataLength = zeros(1, size(inFileNames, 1));
    parfor i = 1:size(inFileNames, 1)
        [~, ~, ext] = fileparts(inFileNames{i, segment});

        if ~strcmp(ext, '.ncs')
            warning('input file is not ncs!')
            continue
        end
    
        [~, outFileName, ~] = fileparts(outFileNames{i, segment});
        outFileName = fullfile(outFilePath, [outFileName, '.mat']);
    
        if skipExist && exist(outFileName, "file")
            if checkExistFileIsValid
                isCorrupted = checkMatFileCorruption(outFileName);
                if ~isCorrupted
                    dataLength(i) = checkDataLength(outFileName);
                    continue
                end
            else
                continue
            end
        end
    
        if verbose
            fprintf('unpack: %s\nto: %s\n', inFileNames{i, segment}, outFileName);
        end
    
        [signal, ADBitVolts, samplingInterval, ~] = Nlx_readCSC(inFileNames{i, segment}, outFilePath);
        saveCSC(signal, ADBitVolts, samplingInterval, outFileName);

        dataLength(i) = length(signal);
        outFileNames{i, segment} = outFileName;
    end

    % read timestamps on the first file with max length:
    timestampFullFile = fullfile(outFilePath, [timestampFileName, '_', suffix{segment}]);
    
    if ~(skipExist && exist(timestampFullFile, "file"))
        if max(dataLength) == 0
            fprintf('unpackData: no files processed for segment %d, skipping timestamps.\n', segment);
            continue
        end
        completeFileIndex = find(dataLength == max(dataLength));
        startIndx = 1;
        while startIndx <= length(completeFileIndex)
            [computedTimeStamps, samplingInterval, largeGap] = Nlx_readTimeStamps(inFileNames{completeFileIndex(startIndx), segment}, outFilePath);
            if ~largeGap
                saveTimestamps(computedTimeStamps, samplingInterval, timestampFullFile, inFileNames{completeFileIndex(startIndx), segment})
                break
            elseif startIndx == length(completeFileIndex)
                warning("large gap found in timestamps file: %s", inFileNames{completeFileIndex(startIndx), segment});
                timestampFullFile = strrep(timestampFullFile, '.mat', 'largeGap.mat');
                saveTimestamps(computedTimeStamps, samplingInterval, timestampFullFile, inFileNames{completeFileIndex(startIndx), segment})
            end
            startIndx = startIndx + 1;
        end
    else
        timestampFileObj = matfile(timestampFullFile, "Writable", false);
        computedTimeStamps = timestampFileObj.timeStamps;
    end

    % fill channels with missing samples with -inf:
    incompleteFileIndex = find(dataLength ~= max(dataLength) & dataLength ~= 0);
    for idx = incompleteFileIndex
        message = sprintf('fill missing samples in: %s', outFileNames{idx, segment});
        logMessage(logFile, message, 1);
        [signal, ADBitVolts, ~, ~] = Nlx_readCSC(inFileNames{idx, segment}, outFilePath);
        [incompleteTimeStamps, samplingInterval] = Nlx_readTimeStamps(inFileNames{idx, segment}, outFilePath);

        % signal = interp1(incompleteTimeStamps, single(signal), computedTimeStamps, 'nearest', 'extrap');
        signal = fillMissingData(computedTimeStamps, incompleteTimeStamps, signal);
        saveCSC(signal, ADBitVolts, samplingInterval, outFileNames{idx, segment});
    end

end
