% unpack the macro and micro blackrock data.

% define filePath, experiment id and outFilePath here or comment it will trigger a UI to
% select paths and experiment id:
clear
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(fileparts(scriptDir)));

skipExist = 1;
expIds = 2;
filePath = {...
    '/Volumes/DATA/BRData/SubjectData/581/EXP2_Movie24_Control_Vid/20250210-162916',...
    };

outFilePath = '/Users/XinNiuAdmin/HoffmanMount/data/PIPELINE_vc/ANALYSIS/MovieParadigm/581_MovieParadigm/';
montageConfigFile = '/Volumes/DATA/BRData/SubjectData/581/montage_Patient-581_exp-1_2025-02-10_11-08-16.json';

% montageConfigFile = [];
[renameMacroChannels, renameMicroChannels] = createChannels(montageConfigFile);

for i = 1: length(filePath)

    expFilePath = fullfile(outFilePath, sprintf('Experiment-%d', expIds(i)));

    % unpack event file:
    eventFile = dir(fullfile(filePath{i}, '*.nev'));
    if length(eventFile) > 1 || isempty(eventFile)
        warning('zero or multiple .nev files detected!\n unpack event for %s is skipped.', filePath{i});
        continue
    end
    inFile = fullfile(filePath{i}, eventFile.name);
    outputFile = fullfile(expFilePath, "CSC_events/Events_001.mat");
    unpackBlackRockEvent(inFile, outputFile, skipExist);
    disp('unpack event finished!')

    % unpack micro channels:
    microFile = dir(fullfile(filePath{i}, '*.ns5'));
    if length(microFile) > 1 || isempty(microFile)
        warning('zero or multiple .ns5 files detected!\n unpack micro for %s is skipped.', filePath{i});
        continue
    end

    inFile = fullfile(filePath{i}, microFile.name);
    unpackBlackRock(inFile, expFilePath, renameMicroChannels, skipExist);
    disp('unpack micro channels finished!')

    % unpack macro channels:
    macroFile = dir(fullfile(filePath{i}, '*.ns3'));
    if length(macroFile) > 1 || isempty(macroFile)
        warning('zero or multiple .ns3 files detected!\n unpack macro for %s is skipped.', filePath{i});
        continue
    end

    inFile = fullfile(filePath{i}, macroFile.name);
    % unpackBlackRock(inFile, expFilePath, renameMacroChannels, skipExist);
    disp('unpack macro channels finished!')

end
