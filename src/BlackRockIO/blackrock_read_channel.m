function outFiles = blackrock_read_channel(inFile, electrodeInfoFile, skipExist, channelNames)
% Function to read Blackrock channel data.
% Blackrock data is saved in a single file containing all channels. We use
% openNSx.m to read each channel for the .ns3/.ns5/.ns6 file and save data
% separately.
% The NSx header contains bank, port, and channel number info.
% When a montage is generated and channelNames are passed through 
% we use this info to match the BR channel to the correct channelNames
% entry.
% If no channelNames passed through default chan filename is used
% G[A-D][1-4]-elec{electrode_number}_001.mat 
% ("_001" to be consistent with NLX)


if nargin < 3 || isempty(skipExist)
    skipExist = 0;
end

if nargin < 4 || isempty(channelNames)
    channelNames = [];
end

outputFilePath = fileparts(electrodeInfoFile);
electrodeInfoObj = matfile(electrodeInfoFile);
NSx = electrodeInfoObj.NSx;
channelId = NSx.MetaTags.ChannelID;
% channelIdx = channelId <= 256;
neuralChannelIdx = channelId <= 256;
% auxChannelIdx = channelID > 256; % this is true for micro, not sure about macro? do we want separate aux extraction? how does NLX code do it?

neural_electrodes_info = NSx.ElectrodesInfo(neuralChannelIdx);

n_channels = length(neural_electrodes_info);
connector_banks = [1, 2, 3, 4];
bank_mapping = {'A','B','C', 'D'};
outFiles = cell(n_channels,1);
matched_channels = cell(n_channels,1); % store to compare if any chans in names not matched

% loop over neural channels and generate output file name
for n=1:n_channels

    % read bank and connector pin info from table
    bank_num = neural_electrodes_info(n).ConnectorBank;
    bank = bank_mapping{connector_banks==bank_num};

    connector_pin = double(neural_electrodes_info(n).ConnectorPin);

    % figure out your port and channel number
    port_num = ceil(connector_pin/8); % will return value between 1 and 4
    channel_num = connector_pin - (8 * (port_num - 1)); % returns value 1-8

    % generate a default file name for cases of no channelNames passed or no matches found.
    default_chan_name = ['G' bank num2str(port_num) '-elec' num2str(neural_electrodes_info(n).ChannelID) '_001.mat'];

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
            outFiles{n} = fullfile(outputFilePath,default_chan_name);
            disp(['Despite passing channel names have not found a match, defaulting filename to: ' outFiles{n}])
        elseif length(matched_chan)>1 % if more than one match break run
            disp(['More than 1 channel matches for ' channel_pattern '- check your montage!!'])
            return
        elseif length(matched_chan)==1 % if one match, use to generate output file name
            outFiles{n} = fullfile(outputFilePath, [matched_chan{1} '_001.mat']);
            matched_channels{n} = char(matched_chan{1});
        end
    else % no channel names passed through, use default fn     
        outFiles{n} = fullfile(outputFilePath,default_chan_name);
    end

end

% remove empty cells 
matched_channels(cellfun(@(x)isempty(x),matched_channels),:)=[];
missing_chan_idx = ~ismember(channelNames,matched_channels);
% this info is reported after extraction loop below

% save outFile names to csv
writecell(outFiles(:), fullfile(fileparts(outFiles{1}), 'outFileNames.csv'));

nchan = length(outFiles);
pattern = 'G[A-D][1-4]-(.*?)[1-9]';

% extract data on each chan
parfor i = 1: nchan
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
    outFileObj.samplingIntervalSeconds = seconds(samplingInterval);
    outFileObj.BlackRockUnits = 1/4;
    movefile(tmpOutFile, outFiles{i});
end

% report if any channel names passed through have not been matched
if sum(missing_chan_idx)>0
    fprintf('\nWARNING!!\n"The following channels were passed to be extracted but have not been matched with the BR data:\n"')
    disp(channelNames(missing_chan_idx))
end

fprintf('\nDone.\n');

end
