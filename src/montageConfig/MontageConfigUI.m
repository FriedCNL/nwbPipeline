function MontageConfigUI()
% create configure file for extracelluar recordings (Neuralynx and
% Blackrock).
    scriptDir = fileparts(mfilename('fullpath'));
    addpath(genpath(fileparts(scriptDir)));
    macroTableColumns = 4;
    miscTableColumns = 3;

    % Create a figure for the UI
    f = figure('Position', [10, 10, 1500, 900], 'Name', 'Montage Setup');

    % ----------------------- Experiment Info Panel --------------------- %

    expInfoPanel = uipanel('Parent', f, 'Title', 'Experiment Info', ...
                           'Position', [0.05, 0.9, 0.45, 0.065], 'FontSize', 12);

    % Patient ID
    uicontrol('Parent', expInfoPanel, 'Style', 'text', 'String', 'Patient ID:', ...
              'Units', 'normalized', 'Position', [0.02, 0.19, 0.2, 0.6], 'HorizontalAlignment', 'left', 'FontSize', 12);
    patientIDEdit = uicontrol('Parent', expInfoPanel, 'Style', 'edit', ...
                              'Units', 'normalized', 'Position', [0.14, 0.21, 0.2, 0.6], 'FontSize', 12, ...
                              'Callback', @updateFileNames);

    % Experiment ID
    uicontrol('Parent', expInfoPanel, 'Style', 'text', 'String', 'Experiment ID:', ...
              'Units', 'normalized', 'Position', [0.45, 0.19, 0.2, 0.6], 'HorizontalAlignment', 'left', 'FontSize', 12);
    experimentIDEdit = uicontrol('Parent', expInfoPanel, 'Style', 'edit', ...
                                 'Units', 'normalized', 'Position', [0.61, 0.21, 0.2, 0.6], 'FontSize', 12, ...
                                 'Callback', @updateFileNames);

    % ----------------------- Micro Montage Panel ----------------------------- %

    montagePanel = uipanel('Parent', f, 'Title', 'Micro Channels', ...
                           'Position', [0.05, 0.125, 0.45, 0.77], 'FontSize', 12);

    % Brain labels
    brainLabels = {
        'LA';           % amygdala/anterior STG
        'LAH';
        'LMH';
        'LPH';          % middle hippocampus/middle MTG
        'LPHG';
        'LAC';          % anterior cingulate/anterior middle FG
        'LOF';         % orbitofrontal/anterior inferior FG 
        'LOF-AC';
        'LAI';
        'LPC';
        'LPT';
        'LFSG';
        'LpSMA';
        'LpSMAa';
        'LpSMAp';
        'LSMA';
        'LSTG';         % middle STG/middle STG
        'LTO';
        'RA';
        'RAH';
        'RMH';
        'RPH';
        'RPHG';
        'REC';
        'RAC';
        'ROF';
        'ROF-AC';
        'RAI';
        'RPC';
        'RPT';
        'RFSG';
        'RpSMA';
        'RpSMAa';
        'RpSMAp';
        'RSMA';
        'RSTG';
        'RTO'};
        

    miscLabels = {
        'C3';
        'C4';
        'F3';
        'F4';
        'EMG1';
        'EMG2';
        'EOG1';
        'EOG2';
        'A1';
        'A2';
     %   'MICROPHONE';
        % 'HR_Ref';
        % 'HR';
        % 'TTLRef';
        % 'TTLSync';
        'Analogue2';
        'Analogue3'};

    % Misc channels with fixed hardware port ids (preserved by Auto Port ID)
    fixedMiscPortIds = {'Analogue2', 225; 'Analogue3', 226};

    customBrainLabel = 'Custom';

    % Shared pool of user-added custom labels, shown at the top of both the
    % micro port dropdowns and the macro add-channel dropdown.
    customLabels = {};
    macroAddPrompt = 'Add channel...';
    macroCustomTrigger = 'Custom...';
    macroAddDropdown = [];  % handle to the macro add-channel dropdown

    % Brain label dropdown options: blank default first, then Custom, then labels
    brainLabelOptions = [{''}; {customBrainLabel}; brainLabels(:)];
    defaultBrainLabel = '';

    % Default headstage labels
    defaultHeadstageLabels = {'GA', 'GB', 'GC', 'GD'};

    numHeadstages = 4;
    numPortsPerHeadstage = 4;
    headstageHandles = cell(numHeadstages, numPortsPerHeadstage + 1, 4); % Handles for micros, brain labels, custom label edit, port checkbox, and headstage label
    defaultNumChannelsMicro = '8';

    for headstageIdx = 1:numHeadstages
        % GD headstage is disabled by default
        defaultHeadstageEnabled = ~strcmp(defaultHeadstageLabels{headstageIdx}, 'GD');
        row = floor((headstageIdx - 1) / 2);
        col = mod(headstageIdx - 1, 2);
        headstagePanel = uipanel('Parent', montagePanel, 'Title', ['Headstage ' num2str(headstageIdx)], ...
                            'Units', 'normalized', 'Position', [0.027 + 0.485 * col, 0.5 - 0.49 * row, 0.46, 0.48], 'FontSize', 12);

        % Headstage label
        uicontrol('Parent', headstagePanel, 'Style', 'text', 'String', 'Label:', ...
                  'Units', 'normalized', 'Position', [0.01, 0.82, 0.2, 0.1], 'HorizontalAlignment', 'left', 'FontSize', 12);
        headstageLabelEdit = uicontrol('Parent', headstagePanel, 'Style', 'edit', 'String', defaultHeadstageLabels{headstageIdx}, ...
                                  'Units', 'normalized', 'Position', [0.22, 0.85, 0.3, 0.1], 'FontSize', 12);
        % Headstage checkbox
        headstageCheckbox = uicontrol('Parent', headstagePanel, 'Style', 'checkbox', 'Value', defaultHeadstageEnabled, ...
                                 'Units', 'normalized', 'Position', [0.55, 0.85, 0.4, 0.1], 'String', 'Enable', 'FontSize', 12, ...
                                 'Callback', @(src, event)toggleHeadstageFields(headstageIdx, src));

        headstageHandles{headstageIdx, numPortsPerHeadstage + 1, 1} = headstageLabelEdit; % Store headstage label handle
        headstageHandles{headstageIdx, numPortsPerHeadstage + 1, 2} = headstageCheckbox;

        for portIdx = 1:numPortsPerHeadstage
            % Port label
            uicontrol('Parent', headstagePanel, 'Style', 'text', 'String', ['Port ' num2str(portIdx)], ...
                      'Units', 'normalized', 'Position', [0.01, 0.71 - 0.2 * (portIdx - 1), 0.12, 0.08], 'HorizontalAlignment', 'left', 'FontSize', 12);

            defaultPortEnabled = true;

            % Port checkbox
            portCheckbox = uicontrol('Parent', headstagePanel, 'Style', 'checkbox', 'Value', defaultPortEnabled, ...
                                     'Units', 'normalized', 'Position', [0.14, 0.72 - 0.2 * (portIdx - 1), 0.07, 0.08], ...
                                     'Callback', @(src, event)togglePortFields(headstageIdx, portIdx, src));

            % Number of Micros
            uicontrol('Parent', headstagePanel, 'Style', 'text', 'String', 'Micros:', ...
                      'Units', 'normalized', 'Position', [0.6, 0.72 - 0.2 * (portIdx - 1), 0.2, 0.08], 'HorizontalAlignment', 'left', 'FontSize', 12);
            microsEdit = uicontrol('Parent', headstagePanel, 'Style', 'edit', 'String', defaultNumChannelsMicro, ...
                                   'Units', 'normalized', 'Position', [0.78, 0.73 - 0.2 * (portIdx - 1), 0.1, 0.07], 'FontSize', 12, ...
                                   'Callback', @validateNumChannels);
            % Brain label
            brainLabelPopup = uicontrol('Parent', headstagePanel, 'Style', 'popupmenu', 'String', brainLabelOptions, ...
                                        'Value', find(strcmp(brainLabelOptions, defaultBrainLabel)), ...
                                        'Units', 'normalized', 'Position', [0.22, 0.70 - 0.2 * (portIdx - 1), 0.35, 0.1], 'FontSize', 12, ...
                                        'Callback', @(src, event)customBrainLabelCallback(src, headstageIdx, portIdx));

            % Custom label edit field (initially hidden)
            customLabelEdit = uicontrol('Parent', headstagePanel, 'Style', 'edit', 'String', '', ...
                                        'Units', 'normalized', 'Position', [0.22, 0.63 - 0.2 * (portIdx - 1), 0.5, 0.085], 'FontSize', 12, ...
                                        'Visible', 'off', 'Callback', @(src, event)rebuildCustomPool());

            headstageHandles{headstageIdx, portIdx, 1} = microsEdit;
            headstageHandles{headstageIdx, portIdx, 2} = brainLabelPopup;
            headstageHandles{headstageIdx, portIdx, 3} = customLabelEdit;
            headstageHandles{headstageIdx, portIdx, 4} = portCheckbox;

            if ~defaultPortEnabled
                togglePortFields(headstageIdx, portIdx, portCheckbox);
            end
        end

        if ~defaultHeadstageEnabled
            toggleHeadstageFields(headstageIdx, headstageCheckbox);
        end
    end

    % ------------------------ Channels Table Panel --------------------- %
    function [channelTable, channelPanel] = createChannelTable(f, position, columnNames, labels, title, useDropdown)
        if nargin < 6
            useDropdown = false;
        end

        channelPanel = uipanel('Parent', f, 'Title', title, ...
                               'Position', position, 'FontSize', 12);


        columnWidth = {40, 75, 70, 70};

        if useDropdown
            % Macro: dropdown on top, larger raised table, control cluster at the bottom
            tablePos     = [0.05, 0.20, 0.85, 0.72];
            dropdownPos  = [0.05, 0.93, 0.90, 0.05];
            selectAllPos = [0.05, 0.135, 0.60, 0.045];
            addRowPos    = [0.05, 0.075, 0.43, 0.05];
            removeRowPos = [0.52, 0.075, 0.43, 0.05];
            moveUpPos    = [0.05, 0.015, 0.43, 0.05];
            moveDownPos  = [0.52, 0.015, 0.43, 0.05];
        else
            tablePos     = [0.05, 0.12, 0.85, 0.83];
            selectAllPos = [0.05, 0.95, 0.50, 0.04];
            addRowPos    = [0.05, 0.06, 0.40, 0.04];
            removeRowPos = [0.55, 0.06, 0.40, 0.04];
            moveUpPos    = [0.05, 0.01, 0.40, 0.04];
            moveDownPos  = [0.55, 0.01, 0.40, 0.04];
        end

        channelTable = uitable('Parent', channelPanel, 'Units', 'normalized', ...
            'Position', tablePos, ...
            'ColumnName', columnNames, ...
            'ColumnEditable', true(1, length(columnNames)), ...
            'ColumnFormat', {'logical', 'char', 'numeric', 'numeric'}, ...
            'ColumnWidth', columnWidth(1: length(columnNames)), ...
            'CreateFcn', @(src, event)createDefaultTableData(src, event, labels), ...
            'CellSelectionCallback', @cellSelectionCallback);

        % Select all checkbox
        selectAllCheckbox = uicontrol( ...
            'Parent', channelPanel, 'Style', 'checkbox', 'String', 'Select All Channels', ...
            'Units', 'normalized', 'Position', selectAllPos, ...
            'Callback', @(src, event)selectAllRows(src, event, channelTable), 'FontSize', 12);

        % Add listeners for mouse clicks and key presses
        set(channelTable, 'KeyPressFcn', @keyPressCallback);
        set(channelTable, 'KeyReleaseFcn', @keyReleaseCallback);

        % Initialize last selected row and Shift key state
        setappdata(channelTable, 'lastSelectedRow', []);
        setappdata(channelTable, 'selectedCells', []);
        setappdata(channelTable, 'isShiftPressed', false);

        % Macro starts empty with a dropdown to add channels by label
        if useDropdown
            set(channelTable, 'Data', cell(0, length(columnNames)), ...  % start with an empty list
                'CellEditCallback', @macroLabelEdited);  % capture labels typed straight into a cell
            macroAddDropdown = uicontrol('Parent', channelPanel, 'Style', 'popupmenu', ...
                      'String', [{macroAddPrompt}; {macroCustomTrigger}; customLabels(:); labels(:)], ...
                      'Units', 'normalized', 'Position', dropdownPos, ...
                      'Callback', @(src, event)addChannelFromDropdown(src, event, channelTable), 'FontSize', 12);
        end

        % Row controls
        uicontrol('Parent', channelPanel, 'Style', 'pushbutton', 'String', 'Add Row', ...
                  'Units', 'normalized', 'Position', addRowPos, 'Callback', @(src, event)addRow(src, event, channelTable), 'FontSize', 12);
        uicontrol('Parent', channelPanel, 'Style', 'pushbutton', 'String', 'Remove Row', ...
                  'Units', 'normalized', 'Position', removeRowPos, 'Callback', @(src, event)removeRow(src, event, channelTable), 'FontSize', 12);
        uicontrol('Parent', channelPanel, 'Style', 'pushbutton', 'String', 'Move Up', ...
                  'Units', 'normalized', 'Position', moveUpPos, 'Callback', @(src, event)moveUp(src, event, channelTable), 'FontSize', 12);
        uicontrol('Parent', channelPanel, 'Style', 'pushbutton', 'String', 'Move Down', ...
                  'Units', 'normalized', 'Position', moveDownPos, 'Callback', @(src, event)moveDown(src, event, channelTable), 'FontSize', 12);
    end

    % Create the table for macro channels
    columnNames = {'', 'Label', 'Port Start', 'Port End'};
    position = [0.51, 0.125, 0.24, 0.84];
    channelTable = createChannelTable(f, position, columnNames, brainLabels, 'Macro Channels', true);


    % Create the table for misc channels
    columnNames = {'', 'Label', 'Port Id'};
    position = [0.76, 0.125, 0.20, 0.84];
    [miscChannelTable, miscPanel] = createChannelTable(f, position, columnNames, miscLabels, 'Misc Channels');

    % Auto-fill misc Port Ids continuing after the last macro channel
    uicontrol('Parent', miscPanel, 'Style', 'pushbutton', 'String', 'Auto Port ID', ...
              'Units', 'normalized', 'Position', [0.55, 0.95, 0.42, 0.045], ...
              'Callback', @(s, e)autoFillPortId(channelTable, miscChannelTable), 'FontSize', 12);

    % ------------------------- Save Config Panel ----------------------- %

    saveConfigPanel = uipanel('Parent', f, 'Title', 'Save Config', ...
                              'Position', [0.05, 0.04, 0.9, 0.08], 'FontSize', 12);

    % File name inputs
    montageFileName = uicontrol('Parent', saveConfigPanel, 'Style', 'edit', ...
                                'String', 'montage_Patient-_exp-.json', ...
                                'Units', 'normalized', 'Position', [0.01, 0.12, 0.38, 0.6], 'FontSize', 12);

    configFileName = uicontrol('Parent', saveConfigPanel, 'Style', 'edit', ...
                               'String', 'config_Patient-_exp-.cfg', ...
                               'Units', 'normalized', 'Position', [0.4, 0.12, 0.4, 0.6], 'FontSize', 12);

    % --------------------- Load and Confirm buttons -------------------- %

    uicontrol('Parent', saveConfigPanel, 'Style', 'pushbutton', 'String', 'Load', ...
              'Units', 'normalized', 'Position', [0.82, 0.1, 0.08, 0.8], 'Callback', @loadConfigFile, 'FontSize', 12);
    uicontrol('Parent', saveConfigPanel, 'Style', 'pushbutton', 'String', 'Confirm', ...
              'Units', 'normalized', 'Position', [0.91, 0.1, 0.08, 0.8], 'Callback', @saveConfig, 'FontSize', 12);

    % ---------------------- callback functions ------------------------- %

    function createDefaultTableData(hObject, ~, labels)
        numColumns = length(get(hObject, 'ColumnName'));
        data = cell(length(labels), numColumns);

        for i = 1:length(labels)
            data{i, 1} = false;
            data{i, 2} = labels{i};
    
            if numColumns == 3
                idx = find(strcmp(labels{i}, fixedMiscPortIds(:, 1)), 1);
                if ~isempty(idx)
                    data{i, 3} = fixedMiscPortIds{idx, 2};
                end
            end
        end
    
        set(hObject, 'Data', data);
    end

    function updateFileNames(~, ~)
        % Update the default file names based on Patient ID and Experiment ID
        patientID = get(patientIDEdit, 'String');
        experimentID = get(experimentIDEdit, 'String');
        set(montageFileName, 'String', ['montage_Patient-' patientID '_exp-' experimentID '.json']);
        set(configFileName, 'String', ['config_Patient-' patientID '_exp-' experimentID '.cfg']);
    end

    function validateNumChannels(hObject, ~)
        % Callback to validate input as a number between 1 and 8
        str = get(hObject, 'String');
        num = str2double(str);
        if isnan(num) || num < 0 || num > 8 || floor(num) ~= num
            errordlg('Input must be a number between 0 and 8', 'Invalid Input', 'modal');
            set(hObject, 'String', '8');  % Reset to default value of 8 if invalid
        end
    end

    function toggleHeadstageFields(headstageIdx, checkbox)
        % Enable/disable headstage fields based on checkbox state
        for portIdx = 1:numPortsPerHeadstage
            if get(checkbox, 'Value') == 1
                set(headstageHandles{headstageIdx, portIdx, 4}, 'Enable', 'on');
                togglePortFields(headstageIdx, portIdx, headstageHandles{headstageIdx, portIdx, 4});
            else
                set(headstageHandles{headstageIdx, portIdx, 4}, 'Enable', 'off');
                set(headstageHandles{headstageIdx, portIdx, 1}, 'Enable', 'off');
                set(headstageHandles{headstageIdx, portIdx, 2}, 'Enable', 'off');
                set(headstageHandles{headstageIdx, portIdx, 3}, 'Enable', 'off');
            end
        end
    end

    function togglePortFields(headstageIdx, portIdx, checkbox)
        % Enable/disable port fields based on checkbox state
        if get(checkbox, 'Value') == 1
            set(headstageHandles{headstageIdx, portIdx, 1}, 'Enable', 'on');
            set(headstageHandles{headstageIdx, portIdx, 2}, 'Enable', 'on');

            brainLabelPopup = headstageHandles{headstageIdx, portIdx, 2};
            selectedLabel = brainLabelPopup.String{brainLabelPopup.Value};
            if strcmp(selectedLabel, customBrainLabel)
                set(headstageHandles{headstageIdx, portIdx, 3}, 'Enable', 'on', 'Visible', 'on');
            else
                set(headstageHandles{headstageIdx, portIdx, 3}, 'Enable', 'on', 'Visible', 'off');
            end

            if str2double(get(headstageHandles{headstageIdx, portIdx, 1}, 'String')) == 0
                set(headstageHandles{headstageIdx, portIdx, 1}, 'String', defaultNumChannelsMicro);
            end
        else
            set(headstageHandles{headstageIdx, portIdx, 1}, 'String', '0');
            set(headstageHandles{headstageIdx, portIdx, 1}, 'Enable', 'off');
            set(headstageHandles{headstageIdx, portIdx, 2}, 'Enable', 'off');
            set(headstageHandles{headstageIdx, portIdx, 3}, 'Enable', 'off', 'Visible', 'off');
        end
    end

    function customBrainLabelCallback(src, headstageIdx, portIdx)
        % Callback for brain label selection
        selectedLabel = src.String{src.Value};
        if strcmp(selectedLabel, customBrainLabel)
            set(headstageHandles{headstageIdx, portIdx, 3}, 'Visible', 'on');
        else
            set(headstageHandles{headstageIdx, portIdx, 3}, 'Visible', 'off');
        end
        rebuildCustomPool();
    end

    function loadConfigFile(~, ~)
        % Function to load configuration file
        [file, path] = uigetfile('*.json', 'Select Configuration File');
        if isequal(file, 0)
            disp('User selected Cancel');
        else
            filename = fullfile(path, file);
            disp(['User selected ', filename]);
            config = readJson(filename);
            populateUI(config);
        end
    end

    function populateUI(config)
        % Populate the UI with loaded configuration
        set(patientIDEdit, 'String', config.PatientID);
        set(experimentIDEdit, 'String', config.ExperimentID);
        updateFileNames();

        headstages = fieldnames(config.Headstages);
        for i = 1:numHeadstages
            headstageLabel = headstages{i};
            set(headstageHandles{i, 1, 3}, 'String', headstageLabel);
            ports = config.Headstages.(headstageLabel);
            portFields = fieldnames(ports);

            if isempty(portFields)
                set(headstageHandles{i, numPortsPerHeadstage + 1, 2}, 'Value', 0);
                toggleHeadstageFields(i, headstageHandles{i, numPortsPerHeadstage + 1, 2})
                continue
            end

            for j = 1:numPortsPerHeadstage
                portData = ports.(portFields{j});
                set(headstageHandles{i, j, 1}, 'String', num2str(portData.Micros));
                set(headstageHandles{i, j, 4}, 'Value', portData.Micros > 0);
                portBrainLabel = portData.BrainLabel;
                if strcmp(portBrainLabel, 'NA')
                    portBrainLabel = '';  % 0-channel placeholder maps back to the blank entry
                end
                brainLabelPopup = headstageHandles{i, j, 2};
                optionList = brainLabelPopup.String;
                brainLabelIdx = find(strcmp(optionList, portBrainLabel));
                if isempty(brainLabelIdx)
                    brainLabelIdx = find(strcmp(optionList, customBrainLabel)); % Custom label
                    set(brainLabelPopup, 'Value', brainLabelIdx);
                    set(headstageHandles{i, j, 3}, 'String', portData.BrainLabel, 'Visible', 'on');
                else
                    set(brainLabelPopup, 'Value', brainLabelIdx);
                    set(headstageHandles{i, j, 3}, 'Visible', 'off');
                end
                togglePortFields(i, j, headstageHandles{i, j, 4});
            end
        end

        % Load macro channels
        Data = loadMacroChannels(config.macroChannels);
        set(channelTable, 'Data', [num2cell(true(size(Data, 1), 1)), Data(:, 1:macroTableColumns-1)]);
        set(channelTable, 'ColumnEditable', true(1, macroTableColumns));

        Data = loadMacroChannels(config.miscChannels);
        set(miscChannelTable, 'Data', [num2cell(true(size(Data, 1), 1)), Data(:, 1:miscTableColumns-1)]);
        set(miscChannelTable, 'ColumnEditable', true(1, miscTableColumns));

        rebuildCustomPool();  % seed shared customs from the loaded macro + micro labels
    end

    function saveConfig(~, ~)
        % Function to save config files
        patientID = get(patientIDEdit, 'String');
        experimentID = get(experimentIDEdit, 'String');
        updateFileNames();
        currentTimeTag = char(datetime('now'), '_yyyy-MM-dd_HH-mm-ss');
        montageFileNameStr = strrep(get(montageFileName, 'String'), '.json',  [currentTimeTag, '.json']);
        configFileNameStr = strrep(get(configFileName, 'String'), '.cfg', [currentTimeTag, '.cfg']);

        % Create a structure to hold the configuration
        config = struct();
        config.PatientID = patientID;
        config.ExperimentID = experimentID;
        config.Headstages = struct();

        microChannels = {};
        for headstageIdx = 1:numHeadstages
            headstageLabel = get(headstageHandles{headstageIdx, numPortsPerHeadstage + 1, 1}, 'String');
            sanitizedHeadstageLabel = matlab.lang.makeValidName(headstageLabel);  % Sanitize headstage label to make it a valid field name
            config.Headstages.(sanitizedHeadstageLabel) = struct();

            for portIdx = 1:numPortsPerHeadstage
                if strcmp(get(headstageHandles{headstageIdx, portIdx, 4}, 'Enable'), 'on')
                    if get(headstageHandles{headstageIdx, portIdx, 4}, 'Value') == 1
                        micros = get(headstageHandles{headstageIdx, portIdx, 1}, 'String');
                    else
                        micros = '0';
                    end
                    brainLabelPopup = headstageHandles{headstageIdx, portIdx, 2};
                    selectedLabel = brainLabelPopup.String{brainLabelPopup.Value};
                    if strcmp(selectedLabel, customBrainLabel)
                        brainLabel = get(headstageHandles{headstageIdx, portIdx, 3}, 'String');
                    else
                        brainLabel = selectedLabel;
                    end

                    if str2double(micros) > 0
                        % Enabled port with channels must have a brain label
                        if isempty(strtrim(brainLabel))
                            errordlg(sprintf(['Headstage %s, Port %d has %s micros but no brain label.\n', ...
                                'Set a brain label, or set micros to 0 to disable the port.'], ...
                                headstageLabel, portIdx, micros), 'Missing Brain Label', 'modal');
                            return
                        end
                    else
                        % No channels on this port: use placeholder name
                        brainLabel = 'NA';
                    end

                    config.Headstages.(sanitizedHeadstageLabel).(['Port' num2str(portIdx)]) = struct( ...
                        'Micros', str2double(micros), ...
                        'BrainLabel', brainLabel);

                    if str2double(micros) > 0
                        microChannels = [microChannels, {brainLabel}];
                    else
                        microChannels = [microChannels, {''}];
                    end
                end
            end
        end

        [macroNumChannels, macroStartChannels] = processChannelData(channelTable, 'macro');
        processChannelData(miscChannelTable, 'misc');

        macroChannels = get(channelTable, 'Data');
        miscChannels = get(miscChannelTable, 'Data');
        config.macroChannels = nestCell(macroChannels(:, 2:end));
        config.miscChannels = nestCell(miscChannels(:, 2:end));


        % Save the montage information to a JSON file
        writeJson(config, montageFileNameStr)

        % Save the configuration to .cfg file for neuralynx:
        microsToDuplicateList = [];
        generatePegasusConfigFile(str2double(patientID), ...
            macroChannels(:, 2), ...
            macroNumChannels, ...
            macroStartChannels, ...
            microChannels, ...
            microsToDuplicateList, ...
            miscChannels(:, 2), ...
            miscChannels(:, 3), ...
            configFileNameStr)

         showMessageBox(['Configuration saved to: ', newline, ...
             montageFileNameStr, newline, ...
             configFileNameStr], 'Save Successful', 400, 150);
    end

    function B = nestCell(A)
        % Assume your original n x m cell array is named 'A'
        [n, m] = size(A);  % Number of rows in the original cell array

        % Convert to n x 1 cell array where each cell contains a 1 x m cell array
        B = mat2cell(A, ones(n, 1), m);
    end


    % function channelNum = processChannelData(table, channelType)
    % 
    %     channelData = get(table, 'Data');
    %     incompleteRows = cellfun(@isempty, channelData(:, 2));
    %     channelData = channelData(~incompleteRows, :);
    % 
    %     % check for duplicated channel names:
    %     dupIdx = getDuplicates(channelData(:, 2));
    %     if ~isempty(dupIdx)
    %         errordlg([channelType, ' hase duplicated names:', sprintf(' %s', channelData{dupIdx, 2})], 'Error');
    %     end
    % 
    %     rowsWithPortStart = ~cellfun(@isempty, channelData(:, 3));
    %     channelData(rowsWithPortStart, :) = sortrows(channelData(rowsWithPortStart, :), 3);
    %     channelData(:, 1) = {true};
    % 
    %     prevIdx = 0;
    %     numChannels = size(channelData, 1);
    %     for i = 1:numChannels
    %         % automatically fill missing port index, assume each Label only
    %         % has one port and no skipped ports.
    %         if isempty(channelData{i, 3}) || isnan(channelData{i, 3})
    %             channelData{i, 3} = prevIdx + 1;
    %         end
    % 
    %         if size(channelData, 2) == 3
    %             prevIdx = channelData{i, 3};
    %             continue
    %         end
    % 
    %         if isempty(channelData{i, 4}) || isnan(channelData{i, 4})
    %             if i == size(channelData, 1) || isempty(channelData{i + 1, 3}) || isnan(channelData{i + 1, 3})
    %                 channelData{i, 4} = channelData{i, 3};
    %             else
    %                 channelData{i, 4} = channelData{i + 1, 3} - 1;
    %             end
    %         end
    %         prevIdx = channelData{i, 4};
    % 
    %         if i > 1 && channelData{i, 3} <= channelData{i - 1, 4}
    %             errorMessage = sprintf('overlap port index in macro channel: %s and %s\n', channelData{i - 1, 2}, channelData{i, 2});
    %             errordlg(errorMessage, 'Error');
    %         end
    % 
    %     end
    % 
    %     if size(channelData, 2) > 3
    %         channelNum = cell2mat(channelData(:, 4)) - cell2mat(channelData(:, 3)) + 1;
    %     else
    %         channelNum = ones(numChannels, 1);
    %     end
    % 
    %     set(table, 'Data', channelData);
    % end
    function [channelNum, startChannels] = processChannelData(table, channelType)

        channelData = get(table, 'Data');
        incompleteRows = cellfun(@isempty, channelData(:, 2));
        channelData = channelData(~incompleteRows, :);

        % Check for duplicated channel names
        dupIdx = getDuplicates(channelData(:, 2));
        if ~isempty(dupIdx)
            errordlg([channelType, ' has duplicated names:', sprintf(' %s', channelData{dupIdx, 2})], 'Error');
        end

        if strcmp(channelType, 'misc')
            for i = 1:size(channelData, 1)
                if isempty(channelData{i, 3}) || isnan(channelData{i, 3})
                    error('Missing Port Id for misc channel: %s', channelData{i, 2});
                end
            end

            channelData(:, 1) = {true};
            channelNum = ones(size(channelData, 1), 1);
            startChannels = cell2mat(channelData(:, 3));
            set(table, 'Data', channelData);
            return
        end

        % Macro channels
        rowsWithPortStart = ~cellfun(@isempty, channelData(:, 3));
        if any(~rowsWithPortStart)
            missingRows = find(~rowsWithPortStart);
            error('Missing Port Start for macro channel: %s', channelData{missingRows(1), 2});
        end

        channelData = sortrows(channelData, 3);
        channelData(:, 1) = {true};

        numChannels = size(channelData, 1);

        for i = 1:numChannels
            if isempty(channelData{i, 4}) || isnan(channelData{i, 4})
                if i == numChannels
                    error('Missing final Port End for macro channel: %s', channelData{i, 2});
                else
                    channelData{i, 4} = channelData{i + 1, 3} - 1;
                end
            end

            if channelData{i, 4} < channelData{i, 3}
                error('Port End is before Port Start for macro channel: %s', channelData{i, 2});
            end

            if i > 1 && channelData{i, 3} <= channelData{i - 1, 4}
                errorMessage = sprintf('overlap port index in macro channel: %s and %s\n', ...
                    channelData{i - 1, 2}, channelData{i, 2});
                errordlg(errorMessage, 'Error');
            end
        end

        startChannels = cell2mat(channelData(:, 3));
        channelNum = cell2mat(channelData(:, 4)) - startChannels + 1;

        set(table, 'Data', channelData);
    end

    function showMessageBox(message, title, width, height)
        % Create a custom dialog box
        d = dialog('Position', [300, 300, width, height], 'Name', title);

        % Create a text control to display the message
        uicontrol('Parent', d, ...
            'Style', 'text', ...
            'Position', [20, height-140, width-40, height-20], ...
            'String', message, ...
            'HorizontalAlignment', 'left', ...
            'FontSize', 15);

        % Create a button to close the dialog
        uicontrol('Parent', d, ...
            'Position', [width/2-60, 20, 120, 30], ...
            'String', 'Close', ...
                  'Callback', 'delete(gcf)', ...
                  'FontSize', 17);
    end

    function autoFillPortId(macroTable, miscTable)
        % Re-fill misc Port Ids sequentially, continuing the port numbering
        % after the last (highest) value used by the macro channels. Runs fresh
        % on every press; channels with a fixed hardware port id (Analogues) and
        % blank rows are left untouched.
        macroData = get(macroTable, 'Data');
        portCells = macroData(:, 3:4);  % macro Port Start / Port End
        isNum = ~cellfun(@(x) isempty(x) || (isnumeric(x) && isnan(x)), portCells);
        portVals = cell2mat(portCells(isNum));
        if isempty(portVals)
            errordlg(['No macro channel port numbers found. ', ...
                'Fill in the macro Port Start/End values first.'], 'Auto Port ID', 'modal');
            return
        end
        nextPort = max(portVals) + 1;

        miscData = get(miscTable, 'Data');
        for i = 1:size(miscData, 1)
            label = miscData{i, 2};
            if isempty(label) || ismember(label, fixedMiscPortIds(:, 1))
                continue  % keep blank rows and fixed hardware port ids
            end
            miscData{i, 3} = nextPort;
            nextPort = nextPort + 1;
        end
        set(miscTable, 'Data', miscData);
    end

    function addChannelFromDropdown(src, ~, table)
        % Add a channel row for the label selected in the dropdown
        selectedIdx = get(src, 'Value');
        if selectedIdx == 1
            return  % "Add channel..." prompt selected, nothing to add
        end
        labelList = get(src, 'String');
        label = labelList{selectedIdx};
        set(src, 'Value', 1);  % reset dropdown back to the prompt

        if strcmp(label, macroCustomTrigger)
            answer = inputdlg('Enter custom channel label:', 'Custom Channel', [1 40]);
            if isempty(answer) || isempty(strtrim(answer{1}))
                return
            end
            label = strtrim(answer{1});
        end

        data = get(table, 'Data');
        newRow = {false, label, [], []};
        data(end + 1, :) = newRow(1:size(data, 2));
        set(table, 'Data', data);

        rebuildCustomPool();  % refresh shared customs from live usage
    end

    function macroLabelEdited(~, eventdata)
        % When a macro Label cell is typed/edited, recompute the custom pool so
        % new labels appear and labels no longer used disappear.
        if isempty(eventdata.Indices) || eventdata.Indices(2) ~= 2  % Label column only
            return
        end
        rebuildCustomPool();
    end

    function rebuildCustomPool()
        % Recompute the shared custom-label pool from labels actually in use, so
        % the dropdowns can never offer a stale/unused entry. A custom label is
        % any non-blank label (in the macro table or on a micro port) that is not
        % one of the standard brainLabels.
        used = {};

        if ~isempty(macroAddDropdown) && isgraphics(macroAddDropdown)
            macroData = get(channelTable, 'Data');
            for i = 1:size(macroData, 1)
                used = appendCustomLabel(used, macroData{i, 2});
            end
        end

        for h = 1:numHeadstages
            for p = 1:numPortsPerHeadstage
                popup = headstageHandles{h, p, 2};
                if isempty(popup) || ~isgraphics(popup)
                    continue
                end
                sel = popup.String{popup.Value};
                if strcmp(sel, customBrainLabel)
                    sel = get(headstageHandles{h, p, 3}, 'String');  % typed custom text
                end
                used = appendCustomLabel(used, sel);
            end
        end

        customLabels = unique(used, 'stable');
        customLabels = customLabels(:);
        refreshLabelDropdowns();
    end

    function used = appendCustomLabel(used, lbl)
        % Append lbl to 'used' if it is a non-blank, non-standard custom label.
        if ischar(lbl)
            lbl = strtrim(lbl);
            if ~isempty(lbl) && ~strcmp(lbl, customBrainLabel) && ~any(strcmp(lbl, brainLabels))
                used{end + 1, 1} = lbl;
            end
        end
    end

    function refreshLabelDropdowns()
        % Rebuild micro and macro dropdowns so shared custom labels show at the
        % top, preserving each control's current selection.
        microOptions = [{''}; {customBrainLabel}; customLabels(:); brainLabels(:)];
        for h = 1:numHeadstages
            for p = 1:numPortsPerHeadstage
                popup = headstageHandles{h, p, 2};
                if isempty(popup) || ~isgraphics(popup)
                    continue
                end
                currentStr = popup.String{popup.Value};
                newIdx = find(strcmp(microOptions, currentStr), 1);
                if isempty(newIdx)
                    newIdx = 1;
                end
                popup.Value = 1;  % avoid transient out-of-range while swapping String
                popup.String = microOptions;
                popup.Value = newIdx;
            end
        end
        if ~isempty(macroAddDropdown) && isgraphics(macroAddDropdown)
            macroAddDropdown.String = [{macroAddPrompt}; {macroCustomTrigger}; customLabels(:); brainLabels(:)];
            macroAddDropdown.Value = 1;
        end
    end

    function addRow(~, ~, table)
        % Add a new row to the table
        data = get(table, 'Data');
        rowToAdd = find(cell2mat(data(:, 1)), 1, 'last' );

        newRow = {false, '', [], []};
        newRow = newRow(1: size(data, 2));

        if isempty(rowToAdd) || rowToAdd == size(data, 1)
            data(end + 1, :) = newRow;
        else
            data = [data(1:rowToAdd, :);
                    newRow;
                    data(rowToAdd+1:end, :)];
        end
        set(table, 'Data', data);
    end

    function removeRow(~, ~, table)
        % Remove the selected rows from the table
        data = get(table, 'Data');
        rowsToDelete = cell2mat(data(:, 1));
        if all(rowsToDelete)
            choice = questdlg(sprintf(['This will remove All macro channels.\n' ...
                'Do you want to proceed?']), ...
                'Confirmation', ...
                'Yes', 'No', 'No');

            % Handle response
            switch choice
                case 'Yes'
                    data(rowsToDelete, :) = [];
                    set(table, 'Data', data);
                case 'No'
                    return
            end
        else
            data(rowsToDelete, :) = [];
            set(table, 'Data', data);
        end
        rebuildCustomPool();  % a removed row may retire a custom label
    end

    function moveUp(~, ~, table)
        % Move the selected row up
        data = get(table, 'Data');
        data = moveUpRows(data);
        set(table, 'Data', data);
    end

    function moveDown(~, ~, table)
        % Move the selected row down
        data = get(table, 'Data');
        data = moveUpRows(data(end:-1:1, :));
        set(table, 'Data', data(end:-1:1,:));
    end

    function data = moveUpRows(data)
        selectedRows = cell2mat(data(:, 1));

        if all(selectedRows) || all(~selectedRows)
            return
        end

        selectedRowsDiff = diff([0, selectedRows(:)', 0]);
        startIdx = find(selectedRowsDiff == 1);
        endIdx = find(selectedRowsDiff == -1) - 1;
        for i = 1:length(startIdx)
            if startIdx(i) == 1
                continue
            end
            temp = data(startIdx(i) - 1, :);
            data((startIdx(i): endIdx(i)) - 1, :) = data(startIdx(i): endIdx(i), :);
            data(endIdx(i), :) = temp;
        end
    end

    function selectAllRows(hObject, ~, table)
        % Select or deselect all rows based on the select all checkbox
        data = get(table, 'Data');
        if get(hObject, 'Value')
            data(:, 1) = {true};
        else
            data(:, 1) = {false};
        end
        set(table, 'Data', data);
    end

    % function keyPressCallback(hObject, eventdata)
    %     % Check if Shift key is pressed
    %     if strcmp(eventdata.Key, 'shift')
    %         setappdata(hObject, 'isShiftPressed', true);
    %     end
    % end

    function keyPressCallback(hObject, eventdata)
        % Check if Shift key is pressed
        if strcmp(eventdata.Key, 'shift')
            setappdata(hObject, 'isShiftPressed', true);
        end

        % Handle backspace or delete key to clear selected cells
        if strcmp(eventdata.Key, 'backspace') || strcmp(eventdata.Key, 'delete')
            selectedCells = getappdata(hObject, 'selectedCells');
            data = get(hObject, 'Data');
            if ~isempty(selectedCells)
                for idx = 1:size(selectedCells, 1)
                    row = selectedCells(idx, 1);
                    col = selectedCells(idx, 2);
                    if col > 2  % only remove port index.
                        data{row, col} = [];
                    end
                end
                set(hObject, 'Data', data);
                setappdata(hObject, 'selectedCells', []);  % Clear the selected cells data
            end
        end
    end

    function keyReleaseCallback(hObject, eventdata)
        % Check if Shift key is released
        if strcmp(eventdata.Key, 'shift')
            setappdata(hObject, 'isShiftPressed', false);
        end
    end

    function cellSelectionCallback(hObject, eventdata)
        if isempty(eventdata.Indices)
            return;
        end

        selectedCells = eventdata.Indices;
        setappdata(hObject, 'selectedCells', selectedCells);

        if size(eventdata.Indices) > 1
            selectedRows = eventdata.Indices(:, 1);
            selectedCols = eventdata.Indices(:, 2);
        else
            selectedRows = eventdata.Indices(1);
            selectedCols = eventdata.Indices(2);
        end

        if any(selectedCols ~= 1)
            return;
        end
        % Handle cell selection with Shift key functionality
        isShiftPressed = getappdata(hObject, 'isShiftPressed');
        lastSelectedRow = getappdata(hObject, 'lastSelectedRow');

        data = get(hObject, 'Data');
        newValue = ~data{selectedRows(end), 1};

        if isShiftPressed
            % Determine the range of rows to select
            if isempty(lastSelectedRow)
                minRow = 1;
            else
                minRow = min([selectedRows(:)', lastSelectedRow]);
            end
            maxRow = max([selectedRows(:)', lastSelectedRow]);

            % Update the selection state for the range of rows
            data(minRow:maxRow, 1) = {newValue};
        else
            % Update the selection state for the newly selected row
            data(selectedRows, 1) = {newValue};
        end

        % Update the data and last selected row
        set(hObject, 'Data', data);
        setappdata(hObject, 'lastSelectedRow', selectedRows(end));
    end
end
