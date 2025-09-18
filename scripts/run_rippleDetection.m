clear

% the main path for extracted data here -
macroPath = '/Users/sldunn/HoffmanMount/data/PIPELINE_vc/ANALYSIS/MovieParadigm/570_MovieParadigm/Experiment-5/CSC_macro';
[macroFiles, macroTimestampFiles] = readCSCFilePath(macroPath);
outputFigureFolder = fullfile(fileparts(macroPath), 'ripple_detection');

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
rd = RippleDetector_class;
rd.samplingRate = 2000;

[ripplesTimes, ripplesStartEnd] = rd.detectRipple(currData, sleepScoring, peakTimes);


% plot ripples and save to output folder
% rd.plotRipples(currData,ripplesTimes,outputFigureFolder);
