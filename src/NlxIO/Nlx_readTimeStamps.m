function [computedTimeStamps, samplingInterval, largeGap] = Nlx_readTimeStamps(fileName, logPath)

% SYNTAX: [data,timeStamps,samplingInterval,chNum] = Nlx_readCSC(fileName,computeTS)
%
% This function deals with the fact that Nlx writes its data into columns
% of a matrix, but that in certain circumstances a column will not get
% filled all the way, and in that case, the remaining data in that column
% will be a duplicate of the data from the previous column. This causes
% issues with both the data itself and the timestamps if you just assume
% that the columns are of equal length.
%
% Please note that samplingInterval is in milliseconds, so an interval of
% 0.5 corresponds to an actual sampling rate of 2000 Hz.
%
% Code written by Emily Mankin and distributed under Creative Commons
% Attribution license, which means you can share, but you can't remove the
% attribution. Code is offered without warranty, but tries hard to be
% correct.

% Xin added log warning message
% Xin added check InputInverted in header.
% Xin simplified algorithm to computeTS.
% Xin change samplingInterval to matlab duration.
% Xin modified from Nlx_readCSC.m to read only timestamps. This simplifies
% IO workflow as we only need to read timestamps for a single channel. Also
% makes it easier to deal with timestamp errors, especially when we use
% parallel for loop.


if ~exist('computeTS','var') || isempty(computeTS)
    computeTS = 1;
end

if ~exist('logPath','var') || isempty(logPath)
    logPath = '';
end

if ~exist(fileName, "file")
    error("file not exist: %s", fileName);
end

% 1. Timestamps
% 2. Sc Numbers
% 3. Cell Numbers
% 4. Params
% 5. Data Points
FieldSelection(1) = 1;
FieldSelection(2) = 1;
FieldSelection(3) = 1;
FieldSelection(4) = 1;
FieldSelection(5) = 0;

ExtractHeader = 1;
ExtractMode = 1;
ModeArray=[]; %all.

[timeStamps, channelNumber, sampleFrequency, numSamples, header] = Nlx2MatCSC_v3(fileName, FieldSelection, ExtractHeader, ExtractMode, ModeArray);

[~, fname] = fileparts(fileName);
logFile = fullfile(logPath, 'unpack_log-Nlx_readTimeStamps', [fname, '.log']);
logMessage(logFile, sprintf('read timestamps from: %s.', fileName));

if length(unique(sampleFrequency))~=1
    message = [fname, ': Sampling Frequency is not uniform across data set, please proceed with caution...'];
    logMessage(logFile, message);
end

if length(unique(channelNumber))~=1
    message = [fname, ': More than one channel found. This code is not equipped for that...'];
    logMessage(logFile, message);
end

if isempty(header)
    message = [fname, ': Empty header info.'];
    logMessage(logFile, message);
end

if any(numSamples(1:end-1) < 512)
    message = sprintf('%s: blocks with missing samples: ', fname, find(numSamples(1:end-1) < 512));
    logMessage(logFile, message);
end

% converts to nSamples per millisecond to be consistent with how we store data for Black Rock
idealSamplingInterval = 1 / sampleFrequency(1);
sampleFrequency = sampleFrequency(1) * 1e-3; 
samplingInterval = milliseconds(1/sampleFrequency);


% convert ts to seconds
timeStamps = timeStamps * 1e-6; 
[computedTimeStamps, largeGap] = computeTimeStamps(timeStamps, numSamples, idealSamplingInterval);

end
