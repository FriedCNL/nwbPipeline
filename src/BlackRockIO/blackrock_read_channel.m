function outFiles = blackrock_read_channel(inFile, electrodeInfoFile, skipExist, channelNames)
% Function to read Blackrock channel data.
% Blackrock data is saved in a single file containing all channels. We use
% openNSx.m to read each channel for the .ns3/.ns5/.ns6 file and save data
% separately.
%
% The NSx header contains bank, port, and channel number info.
% When a montage is generated and channelNames are passed through 
% we use this info to match the BR channel to the correct channelNames 
% entry.
% If no channelNames passed through default chan filename is used (ie the
% label in the header table + rec num)
% Can also pass analogue input channels in through channelNames (eg
% {'ainp1','ainp2'} to extract those directly
%
% This code assumes that the micros are always in channels 1 to 128 and the
% macros are 129 to 256, and that these neural channels will always be the
% first rows in any given nsX file. If this is not the case there may be a
% mismatch in file names when a montage is input
%

if nargin < 3 || isempty(skipExist)
    skipExist = 0;
end

if nargin < 4 || isempty(channelNames)
    channelNames = [];
end

% determine if neural or analogue unpacking
if contains(channelNames,'ainp')
    unpack_type = 'analogue';
else
    unpack_type = 'neural';
end

% determine if macro or micro based on file type
[~, ~, ext] = fileparts(inFile);
if strcmp(ext,'.ns5')
    data_type = 'micro';
elseif strcmp(ext, '.ns3')
    data_type = 'macro';
end

% determine rec number 
tokens = regexp(inFile, '-(\d{3})\.[^.]+$', 'tokens');
if ~isempty(tokens)
    rec_num = tokens{1}{1};
else
    rec_num = '001';
end

% get header info
outputFilePath = fileparts(electrodeInfoFile);
electrodeInfoObj = load(electrodeInfoFile);
electrode_table = struct2table(electrodeInfoObj.NSx.ElectrodesInfo);

%% select electrodes (neural or analogue) and create appropriate file paths
% outFiles is the output file path for each nsx_chan that will be read from
%   the data file
% nsx_chans is the indices for each channel in the data file 
% also returns any missing channel names (from montage or rec)
if isempty(channelNames) % no channels passed just extract all
    labels = cellfun(@(s) regexp(s, '[A-Za-z0-9]+', 'match', 'once'), electrode_table.Label, 'UniformOutput', false);
    outFiles = fullfile(outputFilePath,labels);  
    outFiles = strcat(outFiles,['_' rec_num]);
    outFiles = strcat(outFiles, '.mat');  
    nsx_chans = 1:height(electrode_table);
    channel_in_montage_but_not_rec = [];
    channel_in_rec_but_not_montage = [];
    pattern = '*';
else
    switch unpack_type
        case 'neural'
            neural_electrode_table = electrode_table(electrode_table.ChannelID <= 256,:);
            switch data_type
                case 'micro'
                    [outFiles, nsx_chans,channel_in_montage_but_not_rec,channel_in_rec_but_not_montage] = create_micro_filenames(channelNames,outputFilePath, rec_num,neural_electrode_table);
                    pattern = 'G[A-D][1-4]-(.*?)[1-8]';
                case 'macro'
                    [outFiles, nsx_chans,channel_in_montage_but_not_rec,channel_in_rec_but_not_montage] = create_macro_filenames(channelNames,outputFilePath, rec_num,neural_electrode_table);
                    pattern = '[A-Za-z]-(.*?)[1-10]';
            end
            
        case 'analogue'
            [outFiles, nsx_chans,channel_in_montage_but_not_rec,channel_in_rec_but_not_montage] = create_analogue_filenames(channelNames,outputFilePath, rec_num,electrode_table);
            pattern = 'ainp';
    end
end


% save outFile names to csv
writecell(outFiles(:), fullfile(fileparts(outFiles{1}), 'outFileNames.csv'));

% extract ouside parfor to prevent overhead warning
channelIDs = electrode_table.ChannelID;
bank = electrode_table.ConnectorBank;
pin = electrode_table.ConnectorPin;
resolution = electrode_table.Resolution;
units = electrode_table.AnalogUnits;
units = cellfun(@(s) regexp(s, '[A-Za-z0-9]+', 'match', 'once'), units, 'UniformOutput', false);
%% extract data on each chan
parfor i = nsx_chans
    if skipExist && exist(outFiles{i}, 'file')
        fprintf('skip existing file: %s\n', outFiles{i});
        continue
    end

    [~, outFile] = fileparts(outFiles{i});
    if isempty(outFile)
        continue
    end

    % skip micro channel with empty channel name:
    match = regexp(outFile, pattern, 'tokens', 'once');
 
    if ~isempty(match)
        if isempty(match{1}) || strcmp(match{1}, '''''') || strcmp(match{1}, '''') || strcmp(match{1}, ' ') || strcmp(match{1}, '""') || strcmp(match{1}, '" "')
            warning('skip empty channel: %s', outFiles{i});
            continue
        end
    end

    fprintf('writing data to: %s\n', outFiles{i});

    try
        NSx = openNSx('report','read', inFile, 'channels', i, 'precision', 'int16');
    catch e
        warning('error occurs reading channel: %d', i);
        disp(e);
        disp(e.stack);
        continue
    end

    data = NSx.Data;
    samplingInterval = seconds(1) / NSx.MetaTags.SamplingFreq;

    tmpOutFile = strrep(outFiles{i}, '.mat', 'tmp.mat');
    if exist(tmpOutFile, 'file')
        delete(tmpOutFile)
    end
    outFileObj = matfile(tmpOutFile);
    outFileObj.data = data;
    outFileObj.samplingInterval = samplingInterval;
    %outFileObj.samplingIntervalSeconds = seconds(samplingInterval);
    outFileObj.BlackRockUnits = resolution(i);
    outFileObj.ChannelID = channelIDs(i);
    outFileObj.ConnectorBank = bank(i);
    outFileObj.ConnectorPin = pin(i);
    outFileObj.UnitsAfterConv = units{i};
    movefile(tmpOutFile, outFiles{i});
end


% report (and log) channels in montage but not recorded
if ~isempty(channel_in_montage_but_not_rec)
    fprintf('\n\nWARNING!!!\n\nThe following channels were in the montage but have not been matched with the BR data:\n');
    disp(channel_in_montage_but_not_rec);
    write_missing_channels( ...
        channel_in_montage_but_not_rec, ...
        outputFilePath, ...
        ['channels_in_montage_but_not_rec__' unpack_type '.txt'], ...
        'Channels in montage but not found in data:' );
end

% report (and log) channels recorded but not in montage
if ~isempty(channel_in_rec_but_not_montage)
    fprintf('\n\nWARNING!!\n\nThe following channels were recorded but have not been matched with a channel in the montage:\n');
    disp(channel_in_rec_but_not_montage);
    write_missing_channels( ...
        channel_in_rec_but_not_montage, ...
        outputFilePath, ...
        ['channels_in_rec_but_not_montage__' unpack_type '.txt'], ...
        'Channels recorded in data but are not in montage:' );
end

end
% EOF







%% subfuncs
function [outFiles,nsx_chans,channel_in_montage_but_not_rec,channel_in_rec_but_not_montage] = create_micro_filenames(channelNames,outputFilePath, rec_num,electrode_table)

n_channels = height(electrode_table);
connector_banks = [1, 2, 3, 4, 9]; % 9 is analogue input bank
bank_mapping = {'A','B','C', 'D','X'};
outFiles = cell(n_channels,1);
labels = cellfun(@(s) regexp(s, '[A-Za-z0-9]+', 'match', 'once'), electrode_table.Label, 'UniformOutput', false);
% for logging missing channels
matched_channels = cell(n_channels,1); % store to compare if any chans in names not matched
channel_in_montage_but_not_rec = cell(n_channels,1);
channel_in_rec_but_not_montage = cell(n_channels,1);

for n=1:n_channels

    % read bank and connector pin info from table
    bank_num = electrode_table.ConnectorBank(n);
    bank = bank_mapping{connector_banks==bank_num};

    connector_pin = double(electrode_table.ConnectorPin(n));

    % figure out your port and channel number
    port_num = ceil(connector_pin/8); % will return value between 1 and 4
    channel_num = connector_pin - (8 * (port_num - 1)); % returns value 1-8

    % if channelNames have been passed through
    if ~isempty(channelNames)

        % generate a regex pattern and search through the channel names for a match
        channel_pattern = ['G' bank num2str(port_num) '-(.*?)' num2str(channel_num)];

        chan_name_match = false(length(channelNames),1);
        for k=1:length(channelNames)
            match = regexp(channelNames{k}, channel_pattern,'once');
            if match==1
                chan_name_match(k) = match;
            end
        end
        matched_chan = channelNames(chan_name_match);

        if isempty(matched_chan) % if no match found, use default fn
            channel_in_rec_but_not_montage{n} =  labels{n};
        elseif length(matched_chan)>1 % if more than one match break run
            disp(['More than 1 channel matches montage for ' channel_pattern '- check your montage!!'])
            return
        elseif length(matched_chan)==1 % if one match, use to generate output file name
            outFiles{n} = fullfile(outputFilePath, [matched_chan{1} '_' rec_num '.mat']);
            matched_channels{n} = char(matched_chan{1});
        end
    else % no channel names found to match this channel, log here
        channel_in_montage_but_not_rec{n} = labels{n};
    end

end

% remove empty cells 
matched_channels(cellfun(@(x)isempty(x),matched_channels),:)=[];
channel_in_montage_but_not_rec = channelNames(~ismember(channelNames,matched_channels));
channel_in_rec_but_not_montage(cellfun(@(x)isempty(x),channel_in_rec_but_not_montage),:)=[];
% missing channel info is reported after extraction loop

% neural data always comes first in files (I think!) ie chan 1-128 for micros
nsx_chans = 1:n_channels;

end
% end create_micro_filenames

function [outFiles, nsx_chans,channel_in_montage_but_not_rec,channel_in_rec_but_not_montage] = create_macro_filenames(channelNames,outputFilePath, rec_num,electrode_table)

%% extract info from channelNames

% probe names and channel numbers
tokens = regexp(channelNames, '^([^\d]+)(\d+)$', 'tokens', 'once');
N = numel(tokens);
montage_channel_names = cell(N,1);
montage_channel_nums = zeros(N,1);
for i = 1:N
    % tokens{i} is a 1×2 cell: { '<letters>', '<digits>' }
    montage_channel_names{i} = tokens{i}{1};
    montage_channel_nums(i) = str2double(tokens{i}{2});
end

% first electrode number for each probe
[unique_names, ~, idx] = unique(montage_channel_names);
min_probe_channel = cell(numel(unique_names),2);
for k = 1:numel(unique_names)
    mask = (idx == k);
    min_probe_channel{k,1} = unique_names{k};
    min_probe_channel{k,2} = min(montage_channel_nums(mask));
end


%% loop and generate file names
n_channels = height(electrode_table);
outFiles = cell(n_channels,1);
% for logging missing channels
labels = cellfun(@(s) regexp(s, '[A-Za-z0-9]+', 'match', 'once'), electrode_table.Label, 'UniformOutput', false);
matched_channels = cell(n_channels,1); % store to compare if any chans in names not matched
channel_in_montage_but_not_rec = cell(n_channels,1);
channel_in_rec_but_not_montage = cell(n_channels,1);


for n = 1:n_channels
    
    channelID = electrode_table.ChannelID(n) - 128; % because macro channels are always 129-256
    % find the recorded channel number in the montage input
    montage_match = montage_channel_nums == channelID;

    if sum(montage_match)==0 % cannot find in montage, log here
        channel_in_rec_but_not_montage{n} = labels{n};
    elseif sum(montage_match) > 1 % more than one match, something must be wrong with montage
        disp(['More than 1 channel matches montage for ' channelNames{n} '- check your montage!!'])
        return
    elseif sum(montage_match) == 1 % match found in montage
        % get the electrode name
        elec_name = montage_channel_names{montage_match}; 
        % figure out channel num between 1 and n_total_on_probe
        min_chan = min_probe_channel{strcmp(min_probe_channel(:,1),elec_name),2}; 
        elec_num = channelID - min_chan + 1;

        outFiles{n} = fullfile(outputFilePath,[elec_name num2str(elec_num) '_' rec_num '.mat']);

        matched_channels{n} = channelNames{montage_match};
    end
end

% remove empty cells 
matched_channels(cellfun(@(x)isempty(x),matched_channels),:)=[];
channel_in_montage_but_not_rec = channelNames(~ismember(channelNames,matched_channels));
channel_in_rec_but_not_montage(cellfun(@(x)isempty(x),channel_in_rec_but_not_montage),:)=[];
% missing channel info is reported after extraction loop

% neural data always comes first in files (I think!) ie chan 129-256 for
% macros, which is in rows 1-128 in header table
nsx_chans = 1:n_channels;

end
% end create_macro_filenames


function  [outFiles,nsx_chans,channel_in_montage_but_not_rec,channels_in_rec_but_not_montage] = create_analogue_filenames(channelNames,outputFilePath, rec_num,electrode_table)

n_channels = length(electrode_table);
outFiles = cell(n_channels,1);
nsx_chans = NaN(1, n_channels);
labels = cellfun(@(s) regexp(s, '[A-Za-z0-9]+', 'match', 'once'), electrode_table.Label, 'UniformOutput', false);
% for logging missing channels
matched_channels = cell(n_channels,1); % store to compare if any chans in names not matched
channel_in_montage_but_not_rec = cell(n_channels,1);

for n = 1:length(channelNames)
     % find row in table
    row_num = find(contains(electrode_table.Label,channelNames{n}));  
    if isempty(row_num)
        channel_in_montage_but_not_rec{n} = labels{row_num};
    else
        nsx_chans(n) = row_num;
        matched_channels{n} = labels{row_num};
        % generate filename
        outFiles{n} = fullfile(outputFilePath,[channelNames{n} '_' rec_num '.mat']);
    end
end

% remove empty elements
matched_channels(cellfun(@(x)isempty(x),matched_channels)) = [];
channel_in_montage_but_not_rec(cellfun(@(x)isempty(x),channel_in_montage_but_not_rec)) = [];

% find all ainp channels that were recorded but not requested to extract
ainp_labels = labels(electrode_table.ConnectorBank==9);
channels_in_rec_but_not_montage =  ainp_labels(~ismember(ainp_labels,matched_channels));


end
% end create_analogue_filenames


function write_missing_channels(chList, outputDir, fileName, headerText)
% Writes out a text file listing channels, but only if chList is nonempty.
%
%   chList     = cell‑array of channel names
%   outputDir  = folder to write into
%   fileName   = name of the .txt file to create
%   headerText = one‐line header for the file

    if isempty(chList)
        return
    end

    % ensure output folder exists
    if ~exist(outputDir,'dir')
        mkdir(outputDir);
    end

    fullPath = fullfile(outputDir, fileName);
    fid = fopen(fullPath, 'w');
    if fid == -1
        error('Could not open log file "%s" for writing.', fullPath);
    end

    % write header
    fprintf(fid, '%s\n\n', headerText);

    % write each channel
    for i = 1:numel(chList)
        fprintf(fid, '%s\n', chList{i});
    end

    fclose(fid);
    fprintf('Wrote missing‐channel log: %s\n', fullPath);
end
% end write_missing_channels