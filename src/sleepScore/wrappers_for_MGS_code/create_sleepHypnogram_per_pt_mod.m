function create_sleepHypnogram_per_pt(macroFiles, macroTimestampFiles, outputPath, skipExist)

if ~exist('skipExist','var')
    skipExist = 1;
end

if ~exist(outputPath, "dir")
    mkdir(outputPath);
end

% Basic statistics of sleep oscillations
% Whole sleep spectrogram - to see SWS\Spindles periods
% Generating spectrograms for *all* channels

dataTable = cell2table(macroFiles);
writetable(dataTable, fullfile(outputPath, 'inFiles.csv'), 'WriteVariableNames', false);

maxNumCompThreads(8); 
parfor i = 1:size(macroFiles, 1)
    
    [~, fname] = fileparts(macroFiles{i, 1});
    figureName = fullfile(outputPath, [fname, '.png']);

    if exist(figureName, "file") && skipExist
        continue;
    end

    data = combineCSC(macroFiles(i, :), macroTimestampFiles);
    plotHypnogram_perChannel(data, 2000, figureName)
    fprintf('done.\n');
    % PrintActiveFigs(outputPath);

end

