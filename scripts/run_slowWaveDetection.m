%the struct runData holds data about patients and where the different event
%types are stored
clear
% ---- UPDATE this part -

% the main path for extracted data here -
% for the given example, it's in the same folder as this code:

base_path = 'F:\566\Experiment-8';
data_p_path = fullfile(base_path, 'CSC_macro');
outputFolder = fullfile(base_path, 'slowWaves');

if ~exist(outputFolder, "dir")
    mkdir(outputFolder);
end

sleepScoringFileName = fullfile(base_path, 'sleep_score/sleepScore_LAC4_001.mat');
[macroFiles, macroTimestampFiles] = readCSCFilePath(data_p_path);
channel_index = 25;

%% an example for detecting spindles directly using SpindleDetectorClass (it's the same thing the wrapper below does in batch)

%loading - sleep scoring, IIS, data
% sleepScoring = load(sleepScoringFileName);
% sleepScoring = sleepScoring.sleep_score_vec;
sleepScoring = [];

%% load or perform interictal Spikes Detection

peakTimes = [];
channelName = extractChannelName(macroFiles{channel_index, 1});
currData = combineCSC(macroFiles(channel_index, :), macroTimestampFiles);

%% detect the spindles
returnStats = 1;
detector = SlowWavesDetectorClass;
detector.samplingRate = 2000;

slowWavesTimes = detector.findSlowWavesStaresina(currData, sleepScoring, peakTimes);

matObj = matfile(fullfile(outputFolder, sprintf('slowWaves_%s.mat', channelName)), "Writable", true);
matObj.slowWavesTimes = slowWavesTimes;

%plotting the single spindles and saving the figures
detector.plotSpindlesSimple(currData, slowWavesTimes, outputFolder)

% scroll through spindles and their spectrograms using any key
blockSize = 4;
% detector.plotSpindles(currData, spindlesTimes, blockSize);



