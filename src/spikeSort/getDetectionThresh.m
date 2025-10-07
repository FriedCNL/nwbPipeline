function [spikeThresh, param] = getDetectionThresh(channelFiles, runRemovePLI, runStimulationArtifactRemoval, stimulationArtifactParams, timestampFiles)
% Does the first few steps of spike detection to find the threshold. This
% allows for using the same threshold across multiple sessions. Returns
% thr, as well as a struct with other variables created so that these steps
% can be skipped in spikeDetect if the struct is passed in.

    if nargin < 2
        runRemovePLI = false;
    end
    if nargin < 3
        runStimulationArtifactRemoval = false;
    end

    param = set_parameters();
    param.removePLI = runRemovePLI;

    thr = nan(length(channelFiles), 1);
    noise_std_detect = nan(length(channelFiles), 1);
    noise_std_sorted = nan(length(channelFiles), 1);
    thrmax = nan(length(channelFiles), 1);

    for i = 1:length(channelFiles)
        if ~exist(channelFiles{i}, "file")
            warning("getDetectionThresh: file not exist: %s", channelFiles{i})
            continue
        end
        [x, samplingInterval] = readCSC(channelFiles{i}, runRemovePLI);
        % assume same sampling interval across channels.
        fprintf("getDetectionThresh: sampling frequency: %d\n", 1/samplingInterval)
        param.sr = 1/samplingInterval;
        
        if runStimulationArtifactRemoval
            [timestamps, ~] = readTimestamps(timestampFiles{i});
            stimRemovedSignal = removeStimulationArtifacts(signal, timestamps, stimulationArtifactParams);
            x = stimRemovedSignal;
        end


        [~, ~, noise_std_detect(i), noise_std_sorted(i), thr(i), thrmax(i)] = highPassFilter(x, param);
        x = [];
    end

    spikeThresh.thrmax = max(thrmax);
    spikeThresh.noise_std_detect = min(noise_std_detect);
    spikeThresh.noise_std_sorted = min(noise_std_sorted);

    % it shouldn't go less than 18. If it does, it probably found a file
    % with a long stretch of flat, and will then find millions of spikes in
    % the non-flat section.
    spikeThresh.thr = max(min(thr), 18);

end
