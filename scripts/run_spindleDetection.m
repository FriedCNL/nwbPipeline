%the struct runData holds data about patients and where the different event
%types are stored
clear
% ---- UPDATE this part -


% the main path for extracted data here -
macroPath = '/Users/sldunn/HoffmanMount/data/PIPELINE_vc/ANALYSIS/MovieParadigm/570_MovieParadigm/Experiment-5/CSC_macro';
[macroFiles, macroTimestampFiles] = readCSCFilePath(macroPath);
outputPath = fullfile(fileparts(macroPath), 'spindle_detection');

if ~exist(outputPath, "dir")
    mkdir(outputPath);
end

% choose 2 consecutive channels from the same electrode
channel_index = [17,18];

% load data, bipolar re-reference
currData1 = combineCSC(macroFiles(channel_index(1), :), macroTimestampFiles);
currData2 = combineCSC(macroFiles(channel_index(2), :), macroTimestampFiles);

currData = double(currData2) - double(currData1);
currData = transpose(currData);

clear currData1 currData2


% IED detection
IIS_det = SpikeWaveDetectorClass;
IIS_det.samplingRate = 2000;

[peakTimes, passedConditions]= detectTimes(IIS_det, currData,true);

% set sleepScoring to empty for simplicity
sleepScoring = [];

%detecting the spindles
sd = SpindleDetectorClass;
returnStats = 1;
sd.samplingRate = 2000;


isVerified = sd.verifyChannelStep1(currData,sleepScoring,peakTimes);
[spindleTimes,spindleStats,spindlesStartEndTimes] = sd.detectSpindles(currData, sleepScoring, peakTimes, returnStats);
isVerified2 = sd.verifyChannelStep3(currData,spindleTimes);

%plotting the single spindles and saving the figures
sd.plotSpindlesSimple(currData, spindleTimes, outputFolder)

% scroll through spindles and their spectrograms using any key
blockSize = 4;
sd.plotSpindles(currData,spindleTimes,blockSize);
