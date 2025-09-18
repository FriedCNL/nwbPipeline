% IED detection with macro iEEG data:
% run script for Maya's repo: https://github.com/mgevasagiv/epilepticActivity_IEEG
% Soraya Dunn
close all;
clear


% macroPath = '/Users/sldunn/HoffmanMount/data/PIPELINE_vc/ANALYSIS/MovieParadigm/565_MovieParadigm/Experiment-7/CSC_macro';
macroPath = '/Users/sldunn/HoffmanMount/data/PIPELINE_vc/ANALYSIS/MovieParadigm/570_MovieParadigm/Experiment-5/CSC_macro';
[macroFiles, macroTimestampFiles] = readCSCFilePath(macroPath);
% channels = [41:47]; % channels to analyze
channels = [17];

IIS_det = SpikeWaveDetectorClass; % see SpikeWaveDetector.docx for details on functions and default parameters
% IIS_det.samplingRate default is 1kHz - update if different
IIS_det.samplingRate = 2000;

IIS_det.useEnv = true;     % default: true
IIS_det.useAmp = false;    % default: false
IIS_det.useGrad = true;   % default: false
IIS_det.useConjAmpGrad = false;  % default: true
IIS_det.useConjAmpEnv = false;  % default: false
IIS_det.isDisjunction = true;  % default: false - but methods in MGS 2023 paper suggest should be true (as it is OR, not AND) 
                                                % but setting to true means the amp only and grad only threshold crossings (on the 'high' thresholds, not the threshold used for conj) would also be included as IEDs
                                                % so to prevent this (ie to follow the methods in the paper exactly set these thresholds to inf)    
IIS_det.SDthresholdAmp  = Inf;   % disables Amp-only OR term
IIS_det.SDthresholdGrad = Inf;   % disables Grad-only OR term
IIS_det.minLengthSpike = 3; % ms; default 5 (value not specifically metioned in paper, decreased to catch event below [570 exp5 ~ 45 min]) 

returnStats = 1;
sleepScoreVec = []; % empty, for example

% Extract interictal activities from all channels
for ii = 1:length(channels)
    data = combineCSC(macroFiles(channels(ii), :), macroTimestampFiles);
    [peakTimes{ii}, passedConditions{ii}]= detectTimes(IIS_det, double(transpose(data)),returnStats);
end

% Plot IED detected on given channels
% plotSpikeWaves(IIS_det, transpose(data), peakTimes{ii},1, passedConditions{ii});

% plotting tool to see workings of IED detection
suspectTimesMs = 45.4062*60*1000; % timepoint of something that came up in ripple det that I thought looked sus
debugPlotIEDMetrics(IIS_det, transpose(data(1:4500*IIS_det.samplingRate)), [], suspectTimesMs)