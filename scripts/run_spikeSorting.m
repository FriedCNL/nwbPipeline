% run spike detection and spike sorting to the unpacked data:
clear

% add parent directory to search path so we don't need to do it manually:
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(fileparts(scriptDir)));

 expName = 'MovieParadigm';
%expName = 'Screening';

patient_id = 585;
expIds = [9];

% On Mac studio with 10 cores and 64 GB memory:
% max 4 tasks for movie paradigm (with sleep data)
% max 10 tasks for screening
numParallelJobs = 8;


% filePath = sprintf('/Users/XinNiuAdmin/HoffmanMount/data/PIPELINE_vc/ANALYSIS/%s/%d_%s_xin', expName, patient_id, expName);
filePath = sprintf('/Users/XinNiuAdmin/HoffmanMount/data/PIPELINE_vc/ANALYSIS/%s/%d_%s', expName, patient_id, expName);

% 0: overwrite all previous files.
% 1: skip existing files.
skipExist = [1, 0, 0];  % [spike detection, spike code, spike clustering]

% remove median across channels in each bundle:
runCAR = true;

% remove noises caused by power line interference:
runRemovePLI = false;

% calculate spikeCodes and reject noise spikes:
runRejectSpike = false;


% Stimulation artifact removal
runStimulationArtifactRemoval = true;
stimulationArtifactParams = struct;
stimulationArtifactParams.stimulationExps = [9]; % list of stimulation experiments to remove artifacts from (leave empty to remove from all exps)
stimulationArtifactParams.preRemovalTimeSecs = 0.05; % How much time before each stimulation to remove data from (in secs)
stimulationArtifactParams.postRemovalTimeSecs = 0.3; % How much time after each stimulation to remove data from (in secs)
stimulationArtifactParams.stimTTL = 1; % TTL value that corresponds to a stimulation
stimulationArtifactParams.testStimTTL = 32; % TTL value that corresponds to a test stimulation
stimulationArtifactParams.saveRemovedSignalSegments = 2; % Will save the artifact-removed signal of up to this number of segments. Set to 0 for no artifact-removed outputs

if (runStimulationArtifactRemoval && isempty(stimulationArtifactParams.stimulationExps))
    stimulationArtifactParams.stimulationExps = expIds;
end
stimulationArtifactParams.eventsDirs = {};

for stimulationExpIdx =  1:length(stimulationArtifactParams.stimulationExps)
    stimulationExpId = stimulationArtifactParams.stimulationExps(stimulationExpIdx);
    stimExpEventsDir = fullfile([filePath, '/Experiment', sprintf('-%d', stimulationExpId), '/CSC_events']);
    stimulationArtifactParams.eventsDirs{1, stimulationExpIdx} = stimExpEventsDir;
end


maxNumCompThreads(numParallelJobs);
batch_spikeSorting(1, 1, expIds, filePath, skipExist, runRemovePLI, runCAR, runRejectSpike, runStimulationArtifactRemoval, stimulationArtifactParams);
