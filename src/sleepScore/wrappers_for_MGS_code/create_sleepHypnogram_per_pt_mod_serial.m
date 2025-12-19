function create_sleepHypnogram_per_pt_mod_serial(macroFiles, macroTimestampFiles, outputPath, skipExist, fs)
% Serial version of create_sleepHypnogram_per_pt_mod.
%
% macroFiles: cell array (nCh x nRecs) of CSC file paths
% macroTimestampFiles: timestamps file(s) as expected by combineCSC/readCSCFilePath
% outputPath: folder to save PNGs + inFiles.csv
% skipExist: if 1, skip channels with existing PNG
% fs: sampling rate passed to plotHypnogram_perChannel_mod (default 2000)

if ~exist('skipExist','var') || isempty(skipExist)
    skipExist = 1;
end
if ~exist('fs','var') || isempty(fs)
    fs = 2000;
end

if ~exist(outputPath, "dir")
    mkdir(outputPath);
end

% cluster-safe plotting
set(0, 'DefaultFigureVisible', 'off');

% provenance: list input files
dataTable = cell2table(macroFiles);
writetable(dataTable, fullfile(outputPath, 'inFiles.csv'), 'WriteVariableNames', false);

nCh = size(macroFiles, 1);
for i = 1:nCh
    [~, fname] = fileparts(macroFiles{i, 1});
    figureName = fullfile(outputPath, [fname, '.png']);

    if exist(figureName, "file") && skipExist
        continue;
    end

    data = combineCSC(macroFiles(i, :), macroTimestampFiles);
    plotHypnogram_perChannel_mod(data, fs, figureName);
    fprintf('[%d/%d] %s done.\n', i, nCh, fname);
end

end
