% combine events:


eventFiles = {
    '/Users/XinNiuAdmin/HoffmanMount/data/PIPELINE_vc/ANALYSIS/Screening/1789_Screening/Experiment-28/CSC_events/Events_001.mat';
    '/Users/XinNiuAdmin/HoffmanMount/data/PIPELINE_vc/ANALYSIS/Screening/1789_Screening/Experiment-29/CSC_events/Events_001.mat';
    };


outputPath = '/Users/XinNiuAdmin/HoffmanMount/data/PIPELINE_vc/ANALYSIS/Screening/1789_Screening/Experiment-28-29/CSC_events/';
outputFileName = 'Events_001.mat';

if ~exist(outputPath, "dir")
    mkdir(outputPath);
end

TTLs = cell(1, length(eventFiles));
timestamps = cell(1, length(eventFiles));

for i = 1:length(eventFiles)
    eventFileObj = matfile(eventFiles{i});
    TTLs{i} =  eventFileObj.TTLs;
    timestamps{i} = eventFileObj.timestamps;
end

TTLs = [TTLs{:}];
timestamps = [timestamps{:}];

outFileObj = matfile(fullfile(outputPath, outputFileName));
outFileObj.TTLs=  TTLs;
outFileObj.timestamps = timestamps;
