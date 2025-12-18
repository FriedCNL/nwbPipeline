function sleep_score_vec = sleepScoring_iEEG_wrapper_mod(macroFiles, macroTimestampFiles, outputPath, manualValidation)

if (~exist('manualValidation','var'))
    manualValidation = 0;
end

if ~exist(outputPath, "dir")
    mkdir(outputPath);
end

params.lowCut = .5;
params.highCut = 4;
params.ds_SR = 200;
sleepScore_obj = sleepScoring_iEEG;

for i = 1:size(macroFiles, 1)
    data = combineCSC(macroFiles(i, :), macroTimestampFiles);
    [~, LocalHeader.origName] = fileparts(macroFiles{i, 1});
    % LocalHeader.channel_id = i;
    sleepScore_obj.useClustering_for_scoring = 1;

    if manualValidation
        manualValidationSleepScoring_mod(sleepScore_obj, data, LocalHeader, outputPath);
    else
        [sleep_score_vec] = evaluateDelta(sleepScore_obj, data, LocalHeader, outputPath);
    end
end

end


