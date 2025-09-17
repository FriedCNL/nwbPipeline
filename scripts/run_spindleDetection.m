clear

% the main path for extracted data here -
macroPath = '/Users/sldunn/HoffmanMount/data/PIPELINE_vc/ANALYSIS/MovieParadigm/570_MovieParadigm/Experiment-5/CSC_macro';
[macroFiles, macroTimestampFiles] = readCSCFilePath(macroPath);
outputPath = fullfile(fileparts(macroPath), 'spindle_detection');

if ~exist(outputPath, "dir")
    mkdir(outputPath);
end

% in the MGS 2023 paper I don't think there was bipolar re-ref for spindle
% detection.
% However Staresina 2023 compares sleep event detection with different
% re-ref schemes (bipolar, WM, uni) and shows little difference in
% detection rates. They use bipolar re-ref for main results.

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
