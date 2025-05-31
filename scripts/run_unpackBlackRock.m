% unpack the macro and micro blackrock data.

clear
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(fileparts(scriptDir)));

%%% define run parameters %%%
skipExist = 1;
pID = '581';
exp_name = 'MovieParadigm'; % Screening
expIds = 4;
unpack_micro = 1;
unpack_macro = 1;
unpack_analogue = 1; 
analogue_channels = {'ainp1', 'ainp2'};
filePath = {...
    '/Volumes/DATA/BRData/SubjectData/581/EXP4_Movie_24_Pre_Sleep/20250211-092357',...
    % % '/Volumes/DATA/BRData/SubjectData/581/EXP5_Movie_24_Sleep/20250211-193335',... 
    };
montageConfigFile =  'montage_Patient-581_exp-2_2025-05-29_14-49-24.json'; %'/Users/sldunn/HoffmanMount/data/PIPELINE_vc/ANALYSIS/Screening/570_Screening/Experiment-1/montage_Patient-570_exp-1_2025-04-22_17-14-27.json'; 

%%% end run parameters %%%



%% BR data extraction

outFilePath = ['/Users/sldunn/HoffmanMount/data/PIPELINE_vc/ANALYSIS/' exp_name '/' pID '_' exp_name];

% montageConfigFile = [];
[renameMacroChannels, renameMicroChannels] = createBRChannels(montageConfigFile);

for i = 1: length(filePath)

    expFilePath = fullfile(outFilePath, sprintf('Experiment-%d', expIds(i)));

    % unpack event file:
    eventFile = dir(fullfile(filePath{i}, '*.nev'));
    if isempty(eventFile)
        warning('zero .nev files detected!\n unpack event for %s is skipped.', filePath{i});
        continue
    end
    inFile = fullfile(filePath{i}, eventFile.name);
    outputFile = fullfile(expFilePath, "CSC_events/Events_001.mat");
    unpackBlackRockEvent(inFile, outputFile, skipExist);
    disp('unpack event finished!')

    if unpack_micro
        % unpack micro channels:
        microFile = dir(fullfile(filePath{i}, '*.ns5'));
        if isempty(microFile)
            warning('zero .ns5 files detected!\n unpack micro for %s is skipped.', filePath{i});
            continue
        end
        for j = 1:length(microFile)
            inFile = fullfile(filePath{i}, microFile(j).name);
            unpackBlackRock(inFile, expFilePath, renameMicroChannels, skipExist);
            disp([microFile(j).name ': unpack micro channels finished!'])
        end
    end

    if unpack_analogue
        % unpack analogue microphone channels
        microFile = dir(fullfile(filePath{i}, '*.ns5'));
        if isempty(microFile)
            warning('zero .ns5 files detected!\n unpack analogue for %s is skipped.', filePath{i});
            continue
        end
        for j = 1:length(microFile)
            inFile = fullfile(filePath{i}, microFile(j).name);
            unpackBlackRock(inFile, expFilePath, analogue_channels, skipExist);
            disp([microFile(j).name ': unpack analogue channels finished!'])
        end
    end

    if unpack_macro
        % unpack macro channels:
        macroFile = dir(fullfile(filePath{i}, '*.ns3'));
        if isempty(macroFile)
            warning('zero .ns3 files detected!\n unpack macro for %s is skipped.', filePath{i});
            continue
        end
        for j = 1:length(macroFile)
            inFile = fullfile(filePath{i}, macroFile(j).name);
            unpackBlackRock(inFile, expFilePath, renameMacroChannels, skipExist);
            disp([macroFile(j).name ': unpack macro channels finished!'])
        end
    end
end
% EOS



%% subfunc
function [macroChannels, microChannels] = createBRChannels(montageConfigFile)
% read montage json file and save macro and micro channel names as cell
% arrays. 
% For micro this is in the format: G[A-D][1-4]_{area}[1-8]
% For macro: {area}[1-total_number_of_channels] 
%                  (i.e. the clinical montage channel number)


if isempty(montageConfigFile)
    [macroChannels, microChannels] = deal([]);
    return
end

montageConfig = readJson(montageConfigFile);
Data = loadMacroChannels(montageConfig.macroChannels);

labels = Data(:,1);
starts = cell2mat(Data(:,2));
ends   = cell2mat(Data(:,3));
% pre‑allocate
total = sum(ends - starts + 1);
macroChannels = cell(total,1);
idx = 1;
for i = 1:numel(labels)
    for v = starts(i):ends(i)
        macroChannels{idx} = sprintf('%s%d', labels{i}, v);
        idx = idx + 1;
    end
end
%macroChannels = {};
% for i = 1: size(Data, 1)
%     numChannels = Data{i, 3} - Data{i, 2} + 1;
%     startIdx = Data{i, 2};
%     for j = 1: numChannels
%         macroChannels(startIdx+j-1) = {[Data{i, 1}, num2str(j)]};
%     end
% end
% macroChannels = macroChannels(:);

microChannels = {};
microConfig = montageConfig.Headstages;
headStages = fieldnames(microConfig);
for i = 1: length(headStages)
    ports = fieldnames(microConfig.(headStages{i}));
    for j = 1: length(ports)
        channel = microConfig.(headStages{i}).(ports{j});
        numChannel = channel.Micros;
        brainLabel = channel.BrainLabel;
        if strcmp(brainLabel, '')
            channels = cell(1, numChannel);
        else
            channels = arrayfun(@(idx) [headStages{i}, num2str(j), '-', brainLabel, num2str(idx)], 1: numChannel, 'UniformOutput', false);
        end
        microChannels = [microChannels; channels(:)];
    end
end
end
