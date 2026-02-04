function [computedTimeStamps, largeGap] = computeTimeStamps(timeStamps, numSamples, idealSamplingInterval)
% timeStamps, numSamples are returned by Nlx2MatCSC_v3. 

% timeStamps: (seconds) the start timestamps of each block (512 samples)
% numSamples: number of samples in each block (usually 512 except for the
% last block).
% sampleFrequency: Hz.

% check if timeStamps has large gaps:
timeStampsDiff = diff(timeStamps);
largeGap = false;
if max(timeStampsDiff) > 2 * median(timeStampsDiff)
    largeGap = true;
end

sampleIdx = cumsum([1; numSamples(:)]);
computedTimeStamps = nan(1, sampleIdx(end) - 1);

for i = 1:length(timeStamps)
    startSample = sampleIdx(i);
    endSample = sampleIdx(i+1)-1;
    startTS = timeStamps(i);
    if i < length(timeStamps)
        samplingInterval = (timeStamps(i+1) - timeStamps(i))/numSamples(i);
    else
        samplingInterval = idealSamplingInterval;        
    end

    theseTS = ((1:numSamples(i))-1) * samplingInterval + startTS;
    computedTimeStamps(startSample: endSample) = theseTS;
end
