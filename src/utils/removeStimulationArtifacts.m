function stimRemoveSignal = removeStimulationArtifacts(originalSignal, originalTimestamps, stimulationArtifactParams, currentExpID)
    stimRemoveSignal = originalSignal;

    % Check if the current experiment is a removal-targeted experiment and
    % get the corresponding eventsDir if so
    experimentIndex = 1;
    if nargin > 3
        experimentIndex = find(stimulationArtifactParams.stimulationExps == currentExpID);
    end
    % If no experiment index found, tis is not a removal-targeted
    % experiment, so just return the original signal
    if isempty(experimentIndex)
        return;
    end

    eventsDir = stimulationArtifactParams.eventsDirs{1, experimentIndex(1)};
    
    % Load start and end timestamps for all stim artifacts if we are doing stim
    % artifact removal
    eventsFiles = dir(fullfile([eventsDir '/Events*.mat']));

    fullEventsTimestamps = [];
    fullEventsTTLs = [];
    for eventIdx = 1:length(eventsFiles)
        eventsFile = fullfile([eventsFiles(eventIdx).folder '/'  eventsFiles(eventIdx).name]);
        eventsLoad = load(eventsFile);
        fullEventsTimestamps = [fullEventsTimestamps eventsLoad.timestamps];
        fullEventsTTLs = [fullEventsTTLs eventsLoad.TTLs];

    end

    stimArtifactStartTimestamps = fullEventsTimestamps(fullEventsTTLs == stimulationArtifactParams.stimTTL | fullEventsTTLs == stimulationArtifactParams.testStimTTL);
    stimulationArtifactParams.stimArtifactEndTimestamps = stimArtifactStartTimestamps + stimulationArtifactParams.postRemovalTimeSecs;
    stimulationArtifactParams.stimArtifactStartTimestamps = stimArtifactStartTimestamps - stimulationArtifactParams.preRemovalTimeSecs;

    %timeDiffEps = 20*1e-6; % CSC times should be shifted ~+16micro from TTL times, make check 20 to be safe
    timeDiffEps = mode(diff(originalTimestamps)) / 2 + (4e-6);
    stimStartTSMatch = arrayfun(@(x) findTimestampIndex(x, originalTimestamps, timeDiffEps, 1, length(originalTimestamps)), stimulationArtifactParams.stimArtifactStartTimestamps);
    stimEndTSMatch = arrayfun(@(x) findTimestampIndex(x, originalTimestamps, timeDiffEps, 1, length(originalTimestamps)), stimulationArtifactParams.stimArtifactEndTimestamps);
    numStimMatches = length(stimStartTSMatch);
    for stimMatchIndex = 1:numStimMatches
        stimStartIndex = stimStartTSMatch(stimMatchIndex);
        stimEndIndex = stimEndTSMatch(stimMatchIndex);
        if stimStartIndex <= 0 && stimEndIndex <= 0
            continue
        elseif stimStartIndex <= 0
            stimStartIndex = 1;
        elseif stimEndIndex <= 0
            stimEndIndex = length(originalTimestamps);
        end

        timestampEndpoints = [originalTimestamps(stimStartIndex) originalTimestamps(stimEndIndex)];
        signalEndpoints = [originalSignal(stimStartIndex) originalSignal(stimEndIndex)];
        timeSlice = originalTimestamps(stimStartIndex:stimEndIndex);
        interpData = interp1(timestampEndpoints, signalEndpoints, timeSlice);
        stimRemoveSignal(stimStartIndex:stimEndIndex) = interpData;

    end



end

