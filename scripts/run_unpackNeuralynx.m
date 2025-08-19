% unpack the macro and micro neuralynx data.
% this script should run with Matlab 2023a or earlier if on Mac with apple
% silicon.

clear
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(fileparts(scriptDir)));

% set unpack config fie, or let it empty to set up with unpackNeuralynxUI:
% unpackConfigFile = '/Users/XinNiuAdmin/HoffmanMount/data/PIPELINE_vc/ANALYSIS/MovieParadigm/1677_MovieParadigm/Patient-1677_Exp-28 29 32.json';


%%
if ~exist("unpackConfigFile", "var") || isempty(unpackConfigFile)
    unpackConfig = unpackNeuralynxUI();
else
    unpackConfig = readJson(unpackConfigFile);
end

filePath = unpackConfig.SelectedFolders;
expIds = unpackConfig.ExperimentIds;
outFilePath = unpackConfig.OutputFilePath;
macroPattern = unpackConfig.macroPattern;
microPattern = unpackConfig.microPattern;
eventPattern = unpackConfig.eventPattern;
montageConfigFile = unpackConfig.montageConfigFile;
skipExist = unpackConfig.skipExist;
numParallelTasks = unpackConfig.numParallelTasks;
%numParallelTasks = 8;

if ~isempty(numParallelTasks)
    delete(gcp('nocreate'))
    parpool(numParallelTasks);
end

[renameMacroChannels, renameMicroChannels] = getADChannelMap(montageConfigFile);



for i = 1:length(expIds)

    expId = expIds(i);
    expOutFilePath = [outFilePath, sprintf('/Experiment-%d/', expId)];

    if ~exist(expOutFilePath, "dir")
        mkdir(expOutFilePath);
    end

    %% list csc and event files.
    % csc files are grouped for each channel.

    groupRegPattern = '.*?(?=\_\d{1}|\.ncs)';
    suffixRegPattern = '(?<=\_)\d*';
    orderByCreateTime = true;

    ignoreFilesWithSizeBelow = 16384;

    if ~exist(fullfile(expOutFilePath, 'channelFileNames.csv'), 'file') || ~skipExist
        tic
        [groups, fileNames, channelFileNames] = groupFiles(filePath{i}, groupRegPattern, suffixRegPattern, orderByCreateTime, ignoreFilesWithSizeBelow);
        writetable(channelFileNames, fullfile(expOutFilePath, 'channelFileNames.csv'));
        toc
    end

    %% unpack Event Files:

    eventOutFilePath = [outFilePath, sprintf('/Experiment-%d/CSC_events', expId)];
    [inEventFiles, outEventFiles] = createIOFiles(eventOutFilePath, expOutFilePath, eventPattern);

    tic
    unpackEvents(inEventFiles, outEventFiles, eventOutFilePath, 1, skipExist);
    toc
    disp('event files unpack finished!')

    %% unpack macro files:

    if ~isempty(macroPattern)
        macroOutFilePath = [outFilePath, sprintf('/Experiment-%d/CSC_macro/', expId)];
        [inMacroFiles, outMacroFiles] = createIOFiles(macroOutFilePath, expOutFilePath, macroPattern, renameMacroChannels);

        tic
        unpackData(inMacroFiles, outMacroFiles, macroOutFilePath, 1, skipExist);
        toc
        disp('macro files unpack finished!')
    end

    %% unpack micro files:

    if ~isempty(microPattern)
        microOutFilePath = [outFilePath, sprintf('/Experiment-%d/CSC_micro/', expId)];
        [inMicroFiles, outMicroFiles] = createIOFiles(microOutFilePath, expOutFilePath, microPattern, renameMicroChannels);

        tic
        unpackData(inMicroFiles, outMicroFiles, microOutFilePath, 1, skipExist);
        toc
        disp('micro files unpack finished!')
    end

end
