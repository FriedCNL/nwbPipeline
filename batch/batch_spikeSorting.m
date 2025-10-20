function batch_spikeSorting(workerId, totalWorkers, expIds, filePath, skipExist, runRemovePLI, runCAR, runSpikeReject, runStimulationArtifactRemoval, stimulationArtifactParams)
    % run spike detection and spike sorting to the unpacked data:
    % run can modify this script and run on different patients/exp when
    % at least one previous job is running (a temporary job script is created).

    if isempty(workerId) || isempty(totalWorkers)
        % run script without queue:
        workerId = 1;
        totalWorkers = 1;
    end

    if workerId > totalWorkers
        disp("workerId larger than number of workers! batch exit.");
        return
    end

    if nargin < 6
        runRemovePLI = false;
    end

    if nargin < 7
        runCAR = false;
    end

    if nargin < 8
        runStimulationArtifactRemoval = false;
        stimulationArtifactParams = struct;
    end
    stimulationArtifactParams.runStimulationArtifactRemoval = runStimulationArtifactRemoval;

    if ~exist('runSpikeReject', 'var')
        runSpikeReject = true;
    end

    %% load file names micro data:

    [microFiles, timestampFiles, expNames] = readFilePath(expIds, filePath);
    jobIds = splitJobs(size(microFiles, 1), totalWorkers, workerId);

    if isempty(jobIds)
        disp("No job assigned to batch! This is due to more workers than number of micro files.")
        return
    end

    disp(['jobIds: ', sprintf('%d ', jobIds)]);
    microFiles = microFiles(jobIds, :);

    % TO-DO: parallel jobs may not be correctly closed when running on hoffman.
    % create Unique Job Storage Locations to resolve this.
    parJobs = min(maxNumCompThreads, size(microFiles, 1));
    % Check if the parallel pool is running
    poolobj = gcp('nocreate'); % If no pool, do not create a new one
    
    % If the pool is running, delete it
    if ~isempty(poolobj)
        delete(poolobj);
        disp('Existing parallel pool deleted.');
    end
    
    parpool('local', parJobs);

    fprintf(['microFiles: \n', sprintf('%s\n', microFiles{:})]);
    %% calculate median for each bundle:
    if runCAR
        fprintf('run calculateBundleMedian in parallel on %d (out of %d) threads...\n', parJobs, maxNumCompThreads);
        calculateBundleMedian(microFiles);
        disp('calculate BundleMedian Finished!')
    end

    %% spike detection:

    expFilePath = [filePath, '/Experiment', sprintf('-%d', expIds)];
    outputPath = fullfile(expFilePath, sprintf('CSC_micro_spikes_removePLI-%d_CAR-%d_rejectNoiseSpikes-%d_removeStimulationArtifacts-%d', int8(runRemovePLI), int8(runCAR), int8(runSpikeReject), int8(runStimulationArtifactRemoval)));

    jsonStimParams = jsonencode(stimulationArtifactParams, PrettyPrint=true);
    jsonStimFname = [outputPath, '/stim_artifact_removal_params.json'];
    jsonStimFID = fopen(jsonStimFname,'w');
    fprintf(jsonStimFID, jsonStimParams);
    fclose(jsonStimFID);

    fprintf('run spike detection in parallel on %d (out of %d) threads...\n', parJobs, maxNumCompThreads);
    spikeFiles = spikeDetection(microFiles, timestampFiles, outputPath, expNames, skipExist(1), runRemovePLI, runCAR, runStimulationArtifactRemoval, stimulationArtifactParams);
    disp('Spike Detection Finished!')

    %% spike clustering:
    spikeCodeFiles = [];
    if runSpikeReject
        spikeCodeFiles = getSpikeCodes(spikeFiles, outputPath, skipExist(2));
    end
    spikeClustering(spikeFiles, spikeCodeFiles, outputPath, skipExist(3));

    disp('Spike Clustering Finished!')

end
