#!/bin/bash
# =========================================
# Script Name: runbatch_spikeSorting.sh
# Description: submit matlab batch jobs to SGE 
# Usage: qsub ./runbatch_spikeSorting.sh
# Parameters:
#   - expName: str, This should be consistent to the file path in unpacked data.
#   - patientId: str, This should be consistent to the file path in unpacked data.
#   - expIds: matlab array, Define experiments to run spike sorting at line 78.
#   - skipExists: 1 by 3 logical matlab array, whether to skip: spikeDetection, spikeCode, spikeClustering.
#   - mode: str, 'spikeSorting' or 'extractLFP', Select the operation mode.
# =========================================


## Set the SGE parameters (#$ is not a comment, and will be processed before the shell variables are evaluated)
#$ -cwd
# Use the current working directory for the job execution

#$ -o $HOME/sgelog/job-$JOB_ID/task_$TASK_ID.txt
# Redirect the standard output and standard error to a specific file
# $JOB_ID and $TASK_ID are environment variables provided by the scheduler
# created before job execution (in submission).
# It will be same as $SGE_TASK_ID, which is created in job execution

#$ -j y
# Merge standard error with the job log (standard output)

#$ -l h_rt=10:00:00,h_data=40G
# Request resources: hours of runtime (h_rt) and memory (h_data)
# Data limit applies to each task individually, no need to change if submit more tasks.
# 40G for spike sort, 80G for lfp extraction. single thread

#$ -pe shared 1
# Request N core in a shared parallel environment. Adjust memory request (h_data) and change
# maxThreads (at line 56) if you require more cores.

# Email address to notify
#$ -M $USER@mail
# Set the email address to notify. $USER is an environment variable for the username

# #$ -m bea
# Uncomment to receive email notifications at the beginning (b), end (e), and if the job is aborted (a)

#$ -t 1:15:1
# Array job specification: run tasks with IDs from 1 to N, with a step of 1 (i.e., 1, 2, 3, ..., N)
# Each task will have a unique $SGE_TASK_ID


## Set the experiment parameters ==========
#expName="MovieParadigm"
expName="ABCD"
#expName="Screening"

patientId="579"
expIds="[3]" 
# patientId="1721"
# expIds="[92:94]" 
# patientId="1728"
# expIds="[43:47, 50]" 
# patientId="1717"
# expIds="[49:52, 54]" 
# patientId="1677"
# expIds="[28,29,32]" 

runRemovePLI="0"
runCAR="1"
runSpikeReject="1"

# stimulation artifact rejection parameters
runStimulationArtifactRemoval="0"
stimulationArtifactPreRemovalTimeSecs="0.05"
stimulationArtifactPostRemovalTimeSecs="0.3"
stimTTL="1";

# if expIds is updated, do not skipExist any steps so that threshold for spike detection is same across experiments
skipExist="[0, 0, 0]"  # [spike detection, spike code, spike clustering]
mode="spikeSorting"  # Change to "extractLFP" to run extractLFP

# skipExist="[0, 0]"  # [micro, macro]
# mode="extractLFP"  # Change to "extractLFP" to run extractLFP

maxThreads="1"

## load the job environment:
. /u/local/Modules/default/init/modules.sh
# To see which versions of matlab are available use: module av matlab
module load matlab/R2023b
codePath="/u/home/x/xinniu/nwbPipeline"


#### DO NOT EDIT THINGS BELOW

total_tasks=$(( ($SGE_TASK_LAST - $SGE_TASK_FIRST) / $SGE_TASK_STEPSIZE + 1 ))

## echo job info on joblog:
echo "Job $JOB_ID started on:   " `hostname -s`
echo "Job $JOB_ID started on:   " `date `
echo "removePLI $runRemovePLI, CAR: $runCAR"
echo " "
echo "Start Matlab"
echo "run $mode, task id: $SGE_TASK_ID, total tasks: $total_tasks"

## run matlab function:
matlab  -nosplash -nodisplay <<EOF
    addpath(genpath('${codePath}'));
    expIds = ${expIds};
    skipExist = ${skipExist};
    runRemovePLI = ${runRemovePLI};
    runCAR = ${runCAR};
    runSpikeReject = ${runSpikeReject};
    workingDir = getDirectory();
    filePath = fullfile(workingDir, '${expName}/${patientId}_${expName}');

    runStimulationArtifactRemoval = ${runStimulationArtifactRemoval};
    stimulationArtifactParams = struct;
    stimulationArtifactParams.preRemovalTimeSecs = ${stimulationArtifactPreRemovalTimeSecs};
    stimulationArtifactParams.postRemovalTimeSecs = ${stimulationArtifactPostRemovalTimeSecs};
    stimulationArtifactParams.stimTTL = ${stimTTL};
    stimulationArtifactParams.eventsDir = fullfile([filePath, '/Experiment', sprintf('-%d', expIds), '/CSC_events']);

    maxNumCompThreads($maxThreads);
    if strcmp('${mode}', 'spikeSorting')
        disp("run spike sorting");
        batch_spikeSorting($SGE_TASK_ID, $total_tasks, expIds, filePath, skipExist, runRemovePLI, runCAR, runSpikeReject, runStimulationArtifactRemoval, stimulationArtifactParams);
    elseif strcmp('${mode}', 'extractLFP')
        disp("run extract LFP");
        batch_extractLFP($SGE_TASK_ID, $total_tasks, expIds, filePath, skipExist);
    else
        error('Unknown mode: ${mode}');
    end

    system(['find ', filePath, ' -user $USER -exec chmod 775 {} \;']);
    exit
EOF

## echo job info on joblog:
echo "Job $JOB_ID ended on:   " `hostname -s`
echo "Job $JOB_ID ended on:   " `date `
echo " "

# mkdir -p $HOME/sgelog/$expName-$patientId/job-$mode-$JOB_ID
# mv $HOME/sgelog/job-$JOB_ID/task_$SGE_TASK_ID.txt $HOME/sgelog/$expName-$patientId/job-$mode-$JOB_ID/task_$SGE_TASK_ID.txt
