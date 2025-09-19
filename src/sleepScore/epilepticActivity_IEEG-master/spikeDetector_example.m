IIS_det = SpikeWaveDetectorClass; % see SpikeWaveDetector.docx for details on functions and default parameters
% IIS_det.samplingRate default is 1kHz - update if different

% UPDATE the main path for extracted iEEG files here -
% files should be called CSC[ch id].mat and contain a variable calles data
dataFolder = 'C:\Users\mgeva\Documents\GitHub\rippleDetection_IEEG\example\';

channels = [1:67]; % channels to analyze

% Extract interictal activities from all channels
clear peakTimes mlink passedConditions
for ii = 1:length(channels)
    filename = fullfile(dataFolder, sprintf('CSC%d.mat',channels(ii)));
    mlink{ii} = matfile(filename);
    [peakTimes{ii}, passedConditions{ii}]= detectTimes(IIS_det, mlink{ii}.data,true);
end

% Plot IED detected on given channels
plotSpikeWaves(IIS_det, mlink{ii}.data, peakTimes{ii},1, passedConditions{ii});
