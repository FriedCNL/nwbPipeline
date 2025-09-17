function [cluster_class, handles] = readData_ASCIISpikePreClustered(filename, pathname, handles)
% This function read *_spikes.mat file with corresponding times_*.mat,

% As wave_clus also saves result as times_*.mat file. We will check
% variables in times_*.mat to load spikes accordingly. This makes it
% inconvenient to redo manual spike clustering. Consider use new name for
% manual spike clustering in the future.


handles.par = set_joint_parameters_CSC(filename); %EM: Replaced the default wave_clus parameters with those that we've been using

% HISTOGRAM PARAMETERS
for i=0:handles.par.max_clus
    handles.(['nbins' num2str(i)]) = 100;  % # of bins for the ISI histograms
    handles.(['bin_step' num2str(i)]) = 1;  % percentage number of bins to plot
end

% axes(handles.cont_data); EM: removed call to axes.
cla(handles.cont_data);

%Load spikes and parameters
spikeFile = fullfile(pathname, filename);
spikeFileObj = matfile(spikeFile, "Writable", true);

filename = strrep(filename, '_spikes', '');
timesFile = fullfile(pathname, ['times_', filename]);

if ~exist(timesFile, 'file')
    warning([timesFile, ' does not exist. Move on...'])
    cluster_class = [];
    return
end

timesFileObj = matfile(timesFile);
cluster_class = timesFileObj.cluster_class;
manualTimesFile = fullfile(pathname, ['times_manual_', filename]);

spikeFileVars = who(spikeFileObj);
timesFileVars = who(timesFileObj);
par = timesFileObj.par;
par = updateParamForCluster(par, spikeFile);

ipermut = [];
if ismember('clu', spikeFileVars) && ismember('tree', spikeFileVars)
    clu = spikeFileObj.clu;
    tree = spikeFileObj.tree;
    if ismember('ipermut', timesFileVars)
        ipermut = timesFileObj.ipermut;
    end
elseif ismember('clu', timesFileVars) && ismember('tree', timesFileVars)
    clu = timesFileObj.clu;
    tree = timesFileObj.tree;
    if ismember('ipermut', timesFileVars)
        ipermut = timesFileObj.ipermut;
    end
else
    par.inputs = size(timesFileObj.inspk, 2);
    ipermut = getInspkAux(par, timesFileObj.inspk);
    [clu, tree] = run_cluster(par);
    spikeFileObj.clu = clu;
    spikeFileObj.tree = tree;
end
fprintf('sampling rate: %d\n', par.sr);

temp = find_temp2(tree, handles);
min_clus = handles.par.min_clus;

if exist(manualTimesFile, 'file')
    message = 'This spike file has been manually sorted, do you want to load the manually sorted result?';
    title = 'Spikes manually sorted already!';
    option1 = 'Yes';
    option2 = 'No';

    % Create the dialog box
    choice = questdlg(message, title, option1, option2, option1);
    if strcmp(choice, option1)
        manualTimesFileObj = matfile(manualTimesFile);
        cluster_class = manualTimesFileObj.cluster_class;
        if ismember('temp', who(manualTimesFileObj))
            temp = manualTimesFileObj.temp;
        end
        if ismember('min_clus', who(manualTimesFileObj))
            min_clus = manualTimesFileObj.min_clus;
        end
    end
else
    manualTimesFileObj = matfile(manualTimesFile, "Writable", true);
    manualTimesFileObj.timestampsStart = timesFileObj.timestampsStart;
end

handles.min_clus = min_clus; % Todo: use min_clus_edit instead.
set(handles.min_clus_edit, 'string', num2str(min_clus));

spikeTimestamps=cluster_class(:, 2)'; % timestamps of spikes; gets loaded in line above.
numSpikes = length(spikeTimestamps);

if size(clu, 2) - 2 < numSpikes
    clu = [clu, zeros(size(clu, 1), numSpikes - size(clu, 2) + 2)];
end

if ~isempty(ipermut)
    clu = permuteClu(clu, ipermut, numSpikes);
end

spikes = spikeFileObj.spikes;
if ismember("spikeIdxRejected", who(timesFileObj))
    % times_* file created by automatic clustering:
    spikes(timesFileObj.spikeIdxRejected, :) = [];
end

classes = cluster_class(:, 1);                               
% sometimes manual curation add spikes with opposite directions so do not
% reject positive spikes. rejectPositiveSpikes was applied in automatic
% clustering so also do not need to do it here.
% classes = rejectPositiveSpikes(spikes, classes(:), handles.par); 
cluster_class(:, 1) = classes;   

clustering_results      = [];
clustering_results(:,1) = repmat(temp, length(classes),1); % GUI temperatures
clustering_results(:,2) = classes; % GUI classes
clustering_results(:,3) = repmat(temp, length(classes),1); % original temperatures
clustering_results(:,4) = classes'; % original classes
clustering_results(:,5) = repmat(min_clus, length(classes),1); % minimum number of clusters

USER_DATA = getUserData();
USER_DATA{1} = handles.par;
USER_DATA{2} = spikes;
USER_DATA{3} = spikeTimestamps(:)' * 1000;                      % convert from seconds to milliseconds.
USER_DATA{4} = clu;
USER_DATA{5} = tree;
USER_DATA{6} = classes(:)';
USER_DATA{7} = timesFileObj.inspk;
USER_DATA{8} = temp;
USER_DATA{9} = classes(:)';
USER_DATA{10} = clustering_results;
USER_DATA{11} = clustering_results;
USER_DATA{12} = ipermut;
USER_DATA{18} = par.sr;

setUserData(USER_DATA);

handles.manualTimesFile = manualTimesFile;
handles.clusterUnitType = int8(ones(1, par.max_clus)); % default is 1: single unit. other options 2: multi unit, 3: noise unit.
handles.clusterFixed = false(1, par.max_clus);

end
