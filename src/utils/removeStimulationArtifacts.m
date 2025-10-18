function stimRemoveSignal = removeStimulationArtifacts(originalSignal, originalTimestamps, stimulationArtifactParams)
    stimRemoveSignal = originalSignal;

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

