% IED detection with macro iEEG data:
% run script for Maya's repo: https://github.com/mgevasagiv/epilepticActivity_IEEG
% Soraya Dunn
close all;
clear


macroPath = '/Users/sldunn/HoffmanMount/data/PIPELINE_vc/ANALYSIS/MovieParadigm/565_MovieParadigm/Experiment-7/CSC_macro';
[macroFiles, macroTimestampFiles] = readCSCFilePath(macroPath);
channels = [41:47]; % channels to analyze


IIS_det = SpikeWaveDetectorClass; % see SpikeWaveDetector.docx for details on functions and default parameters
% IIS_det.samplingRate default is 1kHz - update if different
IIS_det.samplingRate = 2000;
IIS_det.useEnv = true;     % default: true
IIS_det.useAmp = true;    % default: false
IIS_det.useGrad = true;   % default: false
IIS_det.useConjAmpGrad = false;  % default: true
IIS_det.useConjAmpEnv = false;  % default: false
IIS_det.isDisjunction = false;  % default: false


% Extract interictal activities from all channels
for ii = 1:length(channels)
    data = combineCSC(macroFiles(channels(ii), :), macroTimestampFiles);
    [peakTimes{ii}, passedConditions{ii}]= detectTimes(IIS_det, double(transpose(data)),true);
end

% Plot IED detected on given channels
plotSpikeWaves(IIS_det, transpose(data), peakTimes{ii},1, passedConditions{ii});
