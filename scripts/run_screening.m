% before run_screening.m, make sure data is unpacked and spike sorted.

clear
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(fileparts(scriptDir)));

patient = 581;
expId = [1];

filePath = sprintf('/Users/XinNiuAdmin/HoffmanMount/data/PIPELINE_vc/ANALYSIS/Screening/%d_Screening', patient);

% set target local for each micro channel:
targetLabel.GA1 = ''; 
targetLabel.GA2 = ''; 
targetLabel.GA3 = '';
targetLabel.GA4 = ''; 
targetLabel.GB1 = '';
targetLabel.GB2 = '';
targetLabel.GB3 = '';
targetLabel.GB4 = '';
targetLabel.GC1 = '';
targetLabel.GC2 = '';
targetLabel.GC3 = '';
targetLabel.GC4 = '';

% set true to create rasters for reponse (key press):
checkResponseRaster = true;

% In mose case we only have 1 ttlLog file. If the experiment is paused by
% some reason, multiple files are craeted. Make sure log files are ordered
% correctly:
ttlLogFiles = {
    '/Users/XinNiuAdmin/Library/CloudStorage/Box-Box/Screening/D581/Screening1/581-10-Feb-2025-7-19-36/from laptop/ttlLog581-10-Feb-2025-7-19-36.mat';
    };

imageDirectory = '/Users/XinNiuAdmin/Library/CloudStorage/Box-Box/Screening/D581/Screening1/trial1';
expFilePath = [filePath, '/Experiment', sprintf('-%d', expId)];
spikeFilePath = [filePath, '/Experiment', sprintf('-%d', expId), '/CSC_micro_spikes_removePLI-1_CAR-1_rejectNoiseSpikes-1'];
outputPath = [sprintf('/Users/XinNiuAdmin/Library/CloudStorage/Box-Box/Screening Rasters/Patient%d/screening_exp', patient), sprintf('-%d', expId)];

% make sure not skip step 3 if spikeFilePath is changed.  
skipExist = [1, 1, 1];

maxNumCompThreads = 5;

%% parse TTLs:
% this will create TTL.mat and trialStruct.mat

if ~exist(fullfile(expFilePath, 'TTLs.mat'), "file") || ~skipExist(1)
    eventFile = fullfile(expFilePath, 'CSC_events/Events_001.mat');

    TTLs = parseDAQTTLs(eventFile, ttlLogFiles, expFilePath);
    disp('save TTL');
    save(fullfile(expFilePath, 'TTLs.mat'), 'TTLs');
end

if ~exist(fullfile(expFilePath, 'trialStruct.mat'), "file") || ~skipExist(2)
    load(fullfile(expFilePath, 'TTLs.mat'), 'TTLs');
    trials = parseTTLs_Screening(TTLs);
    disp('save trialStruct');
    save(fullfile(expFilePath, 'trialStruct.mat'), 'trials');
end

%%

if ~exist(fullfile(expFilePath, 'clusterCharacteristics.mat'), "file") || ~skipExist(3)
    load(fullfile(expFilePath, 'trialStruct.mat'), 'trials');
    cscFilePath = fullfile(expFilePath, '/CSC_micro');
    disp('save clusterCharacteristics...');
    tic
    [clusterCharacteristics, samplingRate] = calculateClusterCharacteristics(spikeFilePath, cscFilePath, trials, imageDirectory, checkResponseRaster);
    save(fullfile(expFilePath, 'clusterCharacteristics.mat'), 'clusterCharacteristics', 'samplingRate');
    toc
end

%%
% generate rasters plots by units for image and audio stimuli:
% rasters_by_unit(patient, expFilePath, imageDirectory, 1, 'stim', targetLabel, outputPath);
% rasters_by_unit(patient, expFilePath, imageDirectory, 0, 'stim', targetLabel, outputPath);

% generate raster plots by units for video stimuli:
% rasters_by_unit(patient, expFilePath, imageDirectory, 1, 'video', targetLabel, outputPath);
% rasters_by_unit(patient, expFilePath, imageDirectory, 0, 'video', targetLabel, outputPath);

% generate raster plots organized by image:
% rasters_by_image(patient, expFilePath, imageDirectory, targetLabel, outputPath);

% generate raster plots with response time as onset:
rasters_by_unit(patient, expFilePath, imageDirectory, 1, 'response', targetLabel, outputPath);
rasters_by_unit(patient, expFilePath, imageDirectory, 0, 'response', targetLabel, outputPath);

%%
