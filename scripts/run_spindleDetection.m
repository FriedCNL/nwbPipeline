%the struct runData holds data about patients and where the different event
%types are stored
clear
% ---- UPDATE this part -

% IDE detection
IIS_det = SpikeWaveDetectorClass;

% the main path for extracted data here -
% for the given example, it's in the same folder as this code:

base_path = 'F:\566\Experiment-8';
data_p_path = fullfile(base_path, 'CSC_macro');
outputFolder = fullfile(base_path, 'Spindles');

if ~exist(outputFolder, "dir")
    mkdir(outputFolder);
end

sleepScoringFileName = fullfile(base_path, 'sleep_score/sleepScore_LAC4_001.mat');

[macroFiles, macroTimestampFiles] = readCSCFilePath(data_p_path);

% channel_index1 = 37;
% channel_index2 = 38;


%% an example for detecting spindles directly using SpindleDetectorClass (it's the same thing the wrapper below does in batch)


%loading - sleep scoring, IIS, data
% sleepScoring = load(sleepScoringFileName);
% sleepScoring = sleepScoring.sleep_score_vec;
sleepScoring = [];

%% load or perform interictal Spikes Detection

[numElectrodes, ~] = size(macroFiles);
for iElectrode = 2:numElectrodes
    bipolar_channel1 = iElectrode - 1;
    bipolar_channel2 = iElectrode;
    
    % peakTimes = [];
    channelName = extractChannelName(macroFiles{bipolar_channel1, 1});
    channelName2 = extractChannelName(macroFiles{bipolar_channel2, 1});

    nonNumPart1 = regexp(channelName, '^[A-Za-z]+', 'match', 'once'); % Extract letters
    nonNumPart2 = regexp(channelName2, '^[A-Za-z]+', 'match', 'once'); % Extract letters

    % If non-numeric parts are different, skip this iteration
    if ~strcmp(nonNumPart1, nonNumPart2)
        continue;
    end
    
    currData1 = combineCSC(macroFiles(bipolar_channel1, :), macroTimestampFiles);
    currData2 = combineCSC(macroFiles(bipolar_channel2, :), macroTimestampFiles);
    
    % bipolar referencing
    currData = currData1 - currData2;
    clear currData1 currData2;
    
    % yyding test
    [peakTimes, peakStats]= detectTimes(IIS_det, double(currData.'), true);
    if isempty(peakTimes)
        continue;
    end

    %% detect the spindles
    returnStats = 1;
    sd = SpindleDetectorClass;
    sd.spindleRangeMin = 11;
    sd.samplingRate = 2000;
    % [spindlesTimes,spindleStats,spindlesStartEndTimes] = sd.detectSpindles(currData, sleepScoring, peakTimes, returnStats);
    
    % savePath = fullfile(outputFolder, sprintf('spindles_%s.mat', channelName));
    % matObj = matfile(savePath, "Writable", true);
    % matObj.spindlesTimes = spindlesTimes;
    % matObj.spindleStats = spindleStats;
    % matObj.spindlesStartEndTimes = spindlesStartEndTimes;
end


%plotting the single spindles and saving the figures
%sd.plotSpindlesSimple(currData, spindlesTimes, outputFolder)

% scroll through spindles and their spectrograms using any key
%blockSize = 4;
% sd.plotSpindles(currData,spindlesTimes,blockSize);



