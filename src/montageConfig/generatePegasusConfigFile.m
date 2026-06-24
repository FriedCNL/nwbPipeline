function generatePegasusConfigFile(patientNum, macroList, macroNumChannels, macroStartChannels,...
    microList, microsToDuplicateList, miscMacros,miscMacroChannels, savePath)

% SYNTAX: generatePegasusConfigFile(patientNum,macroList,macrosWithNon7,...
%     microList,miscMacros,savePath)

macroNumChannels = macroNumChannels(:)';

if ~exist('savePath','var')|| isempty(savePath)
    savePath = sprintf('%d_InitialGuess.cfg', patientNum);
end

% if ~exist('miscMacros','var')|| isempty(miscMacros)
%     miscMacros = {
%         'C3','C4','PZ','Ez',... % used to include 'GlobalMicroRef'but decided to remove
%         'EOG1','EOG2','EMG1','EMG2','A1','A2',...
%         ... 'MICROPHONE',...
%         'HR_Ref','HR','TTLRef','TTLSync',...
%         'Analogue2','Analogue3'
%         };
% end


if ~exist('microsToDuplicateList', 'var')||isempty(microsToDuplicateList)
    microsToDuplicateList = {}; %{'RAH','RMH','LAH','LMH','REC','LEC','RA','LA','RPHG','LPHG'};
end

allPossibleMicros = {'GA1','GA2','GA3','GA4','GB1','GB2','GB3','GB4','GC1','GC2','GC3','GC4'};

fid = fopen(savePath, 'w');
fid2 = fopen(strrep(savePath, '.cfg', '_MacrosOnly.cfg'), 'w');
makeBaseOfConfigFile(fid, patientNum);
makeBaseOfConfigFile(fid2, patientNum);

for i=1:length(microList)
    if ~isempty(microList{i})
        addMicrosToConfig(fid, i, microList{i}, allPossibleMicros{i}, ismember(microList{i}, microsToDuplicateList));
    end
end

if ~isempty(macroList)
    % startsAt = [0 cumsum(nChannels(1:end-1))]+96; % removed the +96 because
    % we are moving macros to sources 1-4:
    for i = 1:length(macroList)
        startAt = macroStartChannels(i) - 1;  % Convert GUI 1-based port number to Pegasus 0-based channel number
        addMacrosToConfig(fid, startAt, macroList{i}, macroNumChannels(i));
        addMacrosToConfig(fid2, startAt, macroList{i}, macroNumChannels(i));
    end

end

% if ~ismember('MICROPHONE',miscMacros)
% addMicrophoneToConfig(fid);
% end

if ~isempty(miscMacros)

    for i = 1:length(miscMacros)
        thisMiscChannel = miscMacroChannels{i};  
        if isempty(thisMiscChannel) || isnan(thisMiscChannel)
            error('Missing Port Id for misc channel: %s', miscMacros{i});
        end
        addMiscToConfig(fid, thisMiscChannel, miscMacros{i});
    end
end

for i=1:length(microList)
    if ~isempty(microList{i})
        addSpikesToConfig(fid, i, microList{i}, allPossibleMicros{i});
    end
end

addFinalPointsToConfig(fid, 1);
addFinalPointsToConfig(fid2, 1);

% Micro Window
setUpTimeWindow(fid,'Micro Window');
for i=1:length(microList)
    if ~isempty(microList{i})
        addCSCtoPlotWindow(fid, microList{i}, allPossibleMicros{i});
    end
end

setUpTimeWindow(fid,'Alternate Reference Micro Window');
for i=1:length(microList)
    if ~isempty(microList{i}) && ismember(microList{i}, microsToDuplicateList)
        addCSCtoPlotWindow(fid, microList{i}, 'AltRef');
    end
end

% Macro Window
setUpTimeWindow(fid, 'Macro Window')
setUpTimeWindow(fid2,'Macro Window')
for i=1:length(macroList)
    addCSCtoPlotWindow(fid, macroList{i}, macroNumChannels(i));
    addCSCtoPlotWindow(fid2, macroList{i}, macroNumChannels(i));
end

% Sleep Montage
sleepMacros = {'C3','C4','PZ','Ez',...
    'EOG1','EOG2','EMG1','EMG2','A1','A2','HR'};

setUpTimeWindow(fid,'Sleep Montage')
for i=1:length(sleepMacros)
    if ismember(sleepMacros{i}, miscMacros)
        addCSCtoPlotWindow(fid, sleepMacros{i}, 'Sleep Montage');
    end
end

% Microphone etc
% extraPlots = {'MICROPHONE','TTLSync','HR'};
extraPlots = {'Analogue2', 'Analogue3'};

setUpTimeWindow(fid, 'Additional Plots')
for i=1:length(extraPlots)
  if ismember(extraPlots{i}, miscMacros)
        addCSCtoPlotWindow(fid, extraPlots{i}, 'Additional Plots');
  end
end
% add Events plot 
fprintf(fid,'-AddPlot "%s" "Events"\n', 'Additional Plots');
fprintf(fid,'-SetPlotEnabled "%s" "Events" True\n', 'Additional Plots');
fprintf(fid,'\n');

setUpSpikeWindow(fid);
for i=1:length(microList)
    if ~isempty(microList{i})
        addToSpikeWindow(fid, microList{i}, allPossibleMicros{i});
    end
end
addFinalPointsToConfig(fid, 2);
addFinalPointsToConfig(fid2, 2);
fclose(fid);
fclose(fid2);


function makeBaseOfConfigFile(fid, patientNum)

fprintf(fid,'#Pegasus system setup file\n');
fprintf(fid,'#Generated using Emily''s Generator\n');
fprintf(fid,'#File Generation Date:(yyyy/mm/dd hh:mm:ss) %s\n', datestr(now, 'yyyy/mm/dd HH:MM:SS'));
fprintf(fid,'\n');
fprintf(fid,'#System Options Setup\n');
fprintf(fid,'-SetSystemIdentifier "CNLNEURALYNX"\n');
fprintf(fid,'\n');
fprintf(fid,'#Acquisition Control Setup\n');
fprintf(fid,'-SetDataDirectory "E:\\ATLASData\\D%d\\"\n', patientNum);
fprintf(fid,'-SetCreateNewFilesPerRecording True\n');
fprintf(fid,'-SetMaxFileLength 2\n');
fprintf(fid,'\n');
% fprintf(fid,'-SetActiveGroundReference 32000003\n');
fprintf(fid,'#Hardware Subsystem Creation and Setup for:  AcqSystem1\n');
fprintf(fid,'-CreateHardwareSubSystem "AcqSystem1" ATLAS "32000" "192.168.3.10" "26011" "192.168.3.100" "26090"\n');
fprintf(fid,'-SetDialogPosition "Hardware" 0 42\n');
fprintf(fid,'-SetDialogVisible "Hardware" False\n');
fprintf(fid,'\n');
fprintf(fid,'#Reference Manager Setup\n');
fprintf(fid,'#Video Capture Setup\n');
fprintf(fid,'\n');
fprintf(fid,'#Acquisition Entity creation and setup for: Events\n');
fprintf(fid,'-SetNetComDataBufferingEnabled Events False\n');
fprintf(fid,'-SetNetComDataBufferSize Events 3000\n');
fprintf(fid,'\n');

function addMicrosToConfig(fid,groupNum,microName,microID,createDuplicateRecording)
switch microID(2)
    case 'A'
        thisRef = 4;%0; %1
    case 'B'
        thisRef = 5;%1; %3
    case 'C'
        thisRef = 6; %2; %5
end

for i=1:8
    thisChannel = (groupNum-1)*8+i-1+128;
    thisStr = sprintf('%s-%s%d',microID,microName,i);
    fprintf(fid,'#Acquisition Entity creation and setup for: "%s"\n',thisStr);
    fprintf(fid,'-CreateCscAcqEnt "%s" "AcqSystem1"\n',thisStr);
    fprintf(fid,'-SetAcqEntProcessingEnabled "%s" True\n',thisStr);
    fprintf(fid,'-SetChannelNumber "%s" %d\n',thisStr,thisChannel);
    fprintf(fid,'-SetAcqEntReference "%s" 3%d00000%d\n',thisStr,modUp(groupNum,4)+1,thisRef);
    fprintf(fid,'-SetInputRange "%s" 3000\n',thisStr);
    fprintf(fid,'-SetSubSamplingInterleave "%s" 1\n',thisStr);
    fprintf(fid,'-SetDspLowCutFilterEnabled "%s" True\n',thisStr);
    fprintf(fid,'-SetDspLowCutFrequency "%s" 0.1\n',thisStr);
    fprintf(fid,'-SetDspLowCutNumberTaps "%s" 0\n',thisStr);
    fprintf(fid,'-SetDspHighCutFilterEnabled "%s" True\n',thisStr);
    fprintf(fid,'-SetDspHighCutFrequency "%s" 8000\n',thisStr);
    fprintf(fid,'-SetDspHighCutNumberTaps "%s" 256\n',thisStr);
    fprintf(fid,'-SetInputInverted "%s" True\n',thisStr);
    fprintf(fid,'-SetNetComDataBufferingEnabled "%s" False\n',thisStr);
    fprintf(fid,'-SetNetComDataBufferSize "%s" 3000\n',thisStr);
    fprintf(fid,'\n');
    if createDuplicateRecording
        thisStr = sprintf('AltRef-%s%d',microName,i);
        fprintf(fid,'#Acquisition Entity creation and setup for: "%s"\n',thisStr);
        fprintf(fid,'-CreateCscAcqEnt "%s" "AcqSystem1"\n',thisStr);
        fprintf(fid,'-SetAcqEntProcessingEnabled "%s" False\n',thisStr);
        fprintf(fid,'-SetChannelNumber "%s" %d\n',thisStr,thisChannel);
        fprintf(fid,'-SetAcqEntReference "%s" 3%d00000%d\n',thisStr,modUp(groupNum,4)+1,thisRef);
        fprintf(fid,'-SetInputRange "%s" 3000\n',thisStr);
        fprintf(fid,'-SetSubSamplingInterleave "%s" 16\n',thisStr);
        fprintf(fid,'-SetDspLowCutFilterEnabled "%s" True\n',thisStr);
        fprintf(fid,'-SetDspLowCutFrequency "%s" 0.1\n',thisStr);
        fprintf(fid,'-SetDspLowCutNumberTaps "%s" 0\n',thisStr);
        fprintf(fid,'-SetDspHighCutFilterEnabled "%s" True\n',thisStr);
        fprintf(fid,'-SetDspHighCutFrequency "%s" 500\n',thisStr);
        fprintf(fid,'-SetDspHighCutNumberTaps "%s" 256\n',thisStr);
        fprintf(fid,'-SetInputInverted "%s" True\n',thisStr);
        fprintf(fid,'-SetNetComDataBufferingEnabled "%s" False\n',thisStr);
        fprintf(fid,'-SetNetComDataBufferSize "%s" 3000\n',thisStr);
        fprintf(fid,'\n');
    end
end

function addSpikesToConfig(fid,groupNum,microName,microID)
switch microID(2)
    case 'A'
        thisRef = 1;
    case 'B'
        thisRef = 3;
    case 'C'
        thisRef = 5;
end

for i=1:8
    thisChannel = (groupNum-1)*8+i-1;
    thisStr = sprintf('%s-%s%d',microID,microName,i);
    thisStr = ['SE',thisStr];
    sprintf('#Acquisition Entity creation and setup for: "%s"\n',thisStr);
    fprintf(fid,'-CreateSpikeAcqEnt "%s" "AcqSystem1" 1\n',thisStr);
    fprintf(fid,'-SetAcqEntProcessingEnabled "%s" True\n',thisStr);
    fprintf(fid,'-SetChannelNumber "%s" %d\n',thisStr,thisChannel);
    %fprintf(fid,'-SetAcqEntReference "%s" 3200000%d\n',thisStr,thisRef);
    fprintf(fid,'-SetInputRange "%s" 400\n',thisStr);
    fprintf(fid,'-SetSubSamplingInterleave "%s" 1\n',thisStr);
    fprintf(fid,'-SetDspLowCutFilterEnabled "%s" True\n',thisStr);
    fprintf(fid,'-SetDspLowCutFrequency "%s" 600\n',thisStr);
    fprintf(fid,'-SetDspLowCutNumberTaps "%s" 256\n',thisStr);
    fprintf(fid,'-SetDspHighCutFilterEnabled "%s" True\n',thisStr);
    fprintf(fid,'-SetDspHighCutFrequency "%s" 6000\n',thisStr);
    fprintf(fid,'-SetDspHighCutNumberTaps "%s" 256\n',thisStr);
    fprintf(fid,'-SetInputInverted "%s" True\n',thisStr);
    fprintf(fid,'-SetNetComDataBufferingEnabled "%s" True\n',thisStr);
    fprintf(fid,'-SetNetComDataBufferSize "%s" 3000\n',thisStr);
    fprintf(fid,'-SetSpikeThreshold "%s" 45\n',thisStr);
    fprintf(fid,'-SetSpikeDetectionType "%s" Threshold\n',thisStr);
    fprintf(fid,'-SetSpikeSlope "%s" 0 100 160\n',thisStr);
    fprintf(fid,'-SetSpikeDualThresholding "%s" False\n',thisStr);
    fprintf(fid,'-SetSpikeRetriggerTime "%s" 750\n',thisStr);
    fprintf(fid,'-SetSpikeAlignmentPoint "%s" 8\n',thisStr);
    fprintf(fid,'-SetSubChannelEnabled "%s" 0 True\n',thisStr);
    fprintf(fid,'-SetWaveformFeature "%s" Peak 0 0 0 31 1\n',thisStr);
    fprintf(fid,'-SetWaveformFeature "%s" Valley 1 0 0 31 1\n',thisStr);
    fprintf(fid,'-SetWaveformFeature "%s" Energy 2 0 0 31 1\n',thisStr);
    fprintf(fid,'-SetWaveformFeature "%s" Height 3 0 0 31 1\n',thisStr);
    fprintf(fid,'-SetWaveformFeature "%s" NthSample 4 0 0 31 1 4\n',thisStr);
    fprintf(fid,'-SetWaveformFeature "%s" NthSample 5 0 0 31 1 16\n',thisStr);
    fprintf(fid,'-SetWaveformFeature "%s" NthSample 6 0 0 31 1 24\n',thisStr);
    fprintf(fid,'-SetWaveformFeature "%s" NthSample 7 0 0 31 1 28\n',thisStr);
    fprintf(fid,'\n');
end

function addMacrosToConfig(fid,startAt,macroName,maxCh)


for i=1:maxCh
    thisChannel = startAt+i-1;
    thisStr = sprintf('%s%d', macroName, i);
    thisRef = floor(thisChannel/32); %floor(thisChannel/32)*2+1;
    fprintf(fid,'#Acquisition Entity creation and setup for: "%s"\n',thisStr);
    fprintf(fid,'-CreateCscAcqEnt "%s" "AcqSystem1"\n',thisStr);
    fprintf(fid,'-SetAcqEntProcessingEnabled "%s" True\n',thisStr);
    fprintf(fid,'-SetChannelNumber "%s" %d\n',thisStr,thisChannel);
    fprintf(fid,'-SetAcqEntReference "%s" 320000%02d\n',thisStr,thisRef);
    fprintf(fid,'-SetInputRange "%s" 3000\n',thisStr);
    fprintf(fid,'-SetSubSamplingInterleave "%s" 16\n',thisStr);
    fprintf(fid,'-SetDspLowCutFilterEnabled "%s" True\n',thisStr);
    fprintf(fid,'-SetDspLowCutFrequency "%s" 0.1\n',thisStr);
    fprintf(fid,'-SetDspLowCutNumberTaps "%s" 0\n',thisStr);
    fprintf(fid,'-SetDspHighCutFilterEnabled "%s" True\n',thisStr);
    fprintf(fid,'-SetDspHighCutFrequency "%s" 500\n',thisStr);
    fprintf(fid,'-SetDspHighCutNumberTaps "%s" 256\n',thisStr);
    fprintf(fid,'-SetInputInverted "%s" True\n',thisStr);
    fprintf(fid,'-SetNetComDataBufferingEnabled "%s" False\n',thisStr);
    fprintf(fid,'-SetNetComDataBufferSize "%s" 3000\n',thisStr);
    fprintf(fid,'\n');
end

function addMiscToConfig(fid, thisChannel, miscName)

%     miscMacros = {'C3','C4','PZ','Ez','GlobalMicroRef',...
%         'EOG1','EOG2','EMG1','EMG2','A1','A2',...
%         'MICROPHONE','TTLSync','TTLRef','HR1','HR2',...
%         'Analogue1','Analogue2'};

% Analogue defaults now defined in the generator GUI

% switch miscName
%     % case 'Analogue1'
%     %     thisChannel = 224;
%     case 'Analogue2'
%         thisChannel = 225;
%     case 'Analogue3'
%         thisChannel = 226;
%     otherwise
%         %nothing to do, thisChannel is as was sent to the function
% end

thisRef = floor(thisChannel/32);%*2+1;


fprintf(fid,'#Acquisition Entity creation and setup for: "%s"\n', miscName);
fprintf(fid,'-CreateCscAcqEnt "%s" "AcqSystem1"\n', miscName);
if ismember(miscName,...
        {'Analogue2','Analogue3','EOG1','EOG2','EMG1','EMG2',...
        'A1','A2','TTLSync','TTLRef'}) %HR2, TTLRef
    fprintf(fid,'-SetAcqEntProcessingEnabled "%s" False\n', miscName);
else
    fprintf(fid,'-SetAcqEntProcessingEnabled "%s" True\n', miscName);
end
fprintf(fid,'-SetChannelNumber "%s" %d\n', miscName, thisChannel);

switch miscName
    case 'MICROPHONE'
        fprintf(fid,'-SetAcqEntReference "%s" 330000%02d\n',miscName,thisRef);
    case {'HR','TTLSync'}
        fprintf(fid,'-SetAcqEntReference "%s" %d\n',miscName,thisChannel-1);
    otherwise
        fprintf(fid,'-SetAcqEntReference "%s" 320000%02d\n',miscName,thisRef);
end

if ismember(miscName,{'MICROPHONE','GlobalMicroRef'})
    fprintf(fid,'-SetInputRange "%s" 5000\n',miscName);
    fprintf(fid,'-SetSubSamplingInterleave "%s" 1\n',miscName);
elseif ismember(miscName,{'Analogue2'})
    fprintf(fid,'-SetInputRange "%s" 800\n',miscName);
    fprintf(fid,'-SetSubSamplingInterleave "%s" 1\n',miscName);
elseif ismember(miscName,{'Analogue3'})
    fprintf(fid,'-SetInputRange "%s" 1500\n',miscName);
    fprintf(fid,'-SetSubSamplingInterleave "%s" 1\n',miscName);
else
    fprintf(fid,'-SetInputRange "%s" 3000\n',miscName);
    fprintf(fid,'-SetSubSamplingInterleave "%s" 16\n',miscName);
end
fprintf(fid,'-SetDspLowCutFilterEnabled "%s" True\n',miscName);
fprintf(fid,'-SetDspLowCutFrequency "%s" 0.1\n',miscName);
fprintf(fid,'-SetDspLowCutNumberTaps "%s" 0\n',miscName);
fprintf(fid,'-SetDspHighCutFilterEnabled "%s" True\n',miscName);
if ismember(miscName,{'MICROPHONE', 'GlobalMicroRef', 'Analogue2', 'Analogue3'})
    fprintf(fid,'-SetDspHighCutFrequency "%s" 8000\n',miscName);
else
    fprintf(fid,'-SetDspHighCutFrequency "%s" 500\n',miscName);
end
fprintf(fid,'-SetDspHighCutNumberTaps "%s" 256\n',miscName);
fprintf(fid,'-SetInputInverted "%s" True\n',miscName);
fprintf(fid,'-SetNetComDataBufferingEnabled "%s" False\n',miscName);
fprintf(fid,'-SetNetComDataBufferSize "%s" 3000\n',miscName);
fprintf(fid,'\n');

function addMicrophoneToConfig(fid)
fprintf(fid,'#Acquisition Entity creation and setup for: "MICROPHONE"\n');
fprintf(fid,'-CreateCscAcqEnt "MICROPHONE" "AcqSystem1"\n');
fprintf(fid,'-SetAcqEntProcessingEnabled "MICROPHONE" True\n');
fprintf(fid,'-SetChannelNumber "MICROPHONE" 255\n');
fprintf(fid,'-SetAcqEntReference "MICROPHONE" 37000007\n');
fprintf(fid,'-SetInputRange "MICROPHONE" 500\n');
fprintf(fid,'-SetSubSamplingInterleave "MICROPHONE" 1\n');
fprintf(fid,'-SetDspLowCutFilterEnabled "MICROPHONE" True\n');
fprintf(fid,'-SetDspLowCutFrequency "MICROPHONE" 0.1\n');
fprintf(fid,'-SetDspLowCutNumberTaps "MICROPHONE" 0\n');
fprintf(fid,'-SetDspHighCutFilterEnabled "MICROPHONE" True\n');
fprintf(fid,'-SetDspHighCutFrequency "MICROPHONE" 8000\n');
fprintf(fid,'-SetDspHighCutNumberTaps "MICROPHONE" 256\n');
fprintf(fid,'-SetInputInverted "MICROPHONE" False\n');
fprintf(fid,'-SetNetComDataBufferingEnabled "MICROPHONE" False\n');
fprintf(fid,'-SetNetComDataBufferSize "MICROPHONE" 3000\n');
fprintf(fid,'\n');

function addFinalPointsToConfig(fid,part)
switch part
    case 1
        fprintf(fid,'#Main Window Setup\n');
        fprintf(fid,'-SetDialogPosition Main -16 0\n');
        fprintf(fid,'-SetDialogVisible Main True\n');
        fprintf(fid,'\n');
        fprintf(fid,'#System Status Dialog Setup\n');
        fprintf(fid,'-SetSystemStatusShowDetails True\n');
        fprintf(fid,'-SetDialogPosition Status 5 55\n');
        fprintf(fid,'-SetSystemStatusMessageFilter Fatal on\n');
        fprintf(fid,'-SetSystemStatusMessageFilter Error on\n');
        fprintf(fid,'-SetSystemStatusMessageFilter Warning on\n');
        fprintf(fid,'-SetSystemStatusMessageFilter Notice off\n');
        fprintf(fid,'-SetSystemStatusMessageFilter Data off\n');
        fprintf(fid,'-SetDialogVisible Status True\n');
        fprintf(fid,'\n');
        fprintf(fid,'#Properties Display Setup\n');
        fprintf(fid,'-SetDialogPosition Properties 1374 790\n');
        fprintf(fid,'-SetDialogVisible Properties True\n');
        fprintf(fid,'\n');
        fprintf(fid,'#Event Dialog Setup\n');
        fprintf(fid,'-SetDialogPosition Events 0 42\n');
        fprintf(fid,'-SetDialogVisible Events True\n');
        fprintf(fid,'-SetEventStringImmediateMode Off\n');
        fprintf(fid,'-SetEventStringSingleKeyMode Off\n');
        fprintf(fid,'-SetEventDisplayTTLValueFormat Binary\n');
        fprintf(fid,'\n');
%         fprintf(fid,'# Plot Window Setup for "Micro Window"\n');
%         fprintf(fid,'-CreatePlotWindow Time "Micro Window"\n');
%         fprintf(fid,'-SetPlotWindowSpreadType "Micro Window" Spread\n');
%         fprintf(fid,'-SetPlotWindowPlotType "Micro Window" Sweep\n');
%         fprintf(fid,'-SetPlotWindowTimeframe "Micro Window" 5000\n');
%         fprintf(fid,'-SetPlotWindowHistoryTimeframe "Micro Window" 30\n');
%         fprintf(fid,'-SetPlotWindowShowGridLines "Micro Window" True\n');
%         fprintf(fid,'-SetPlotWindowBackgroundColor "Micro Window" 255 255 255\n');
%         fprintf(fid,'-SetPlotWindowPosition "Micro Window" 42 848 1451 755\n');
%         fprintf(fid,'-SetPlotWindowOverlay "Micro Window" False\n');
%         fprintf(fid,'-SetPlotWindowShowTitleBar "Micro Window" True\n');
%         fprintf(fid,'\n');
%         fprintf(fid,'# Plot addition and setup for "Micro Window"\n');
    case 2
        fprintf(fid,'#Audio Output Dialog Setup\n');
        fprintf(fid,'-SetDialogPosition Audio 0 42\n');
        fprintf(fid,'-SetDialogVisible Audio False\n');
        fprintf(fid,'\n');
        fprintf(fid,'#TTL Response Dialog Setup\n');
        fprintf(fid,'-SetDialogPosition TTLResponse 0 42\n');
        fprintf(fid,'-SetDialogVisible TTLResponse False\n');
        fprintf(fid,'\n');
        fprintf(fid,'#Audio Device Setup for Primary Sound Driver\n');
        fprintf(fid,'-SetAudioSource "Primary Sound Driver" Left None\n');
        fprintf(fid,'-SetAudioVolume "Primary Sound Driver" Left 100\n');
        fprintf(fid,'-SetAudioMute "Primary Sound Driver" Left Off\n');
        fprintf(fid,'-SetAudioSource "Primary Sound Driver" Right None\n');
        fprintf(fid,'-SetAudioVolume "Primary Sound Driver" Right 100\n');
        fprintf(fid,'-SetAudioMute "Primary Sound Driver" Right Off\n');
        fprintf(fid,'\n');
        fprintf(fid,'#Audio Device Setup for AcqSystem1_Audio0\n');
        fprintf(fid,'-SetAudioSource "AcqSystem1_Audio0" Left None\n');
        fprintf(fid,'-SetAudioVolume "AcqSystem1_Audio0" Left 100\n');
        fprintf(fid,'-SetAudioMute "AcqSystem1_Audio0" Left Off\n');
        fprintf(fid,'-SetAudioSource "AcqSystem1_Audio0" Right None\n');
        fprintf(fid,'-SetAudioVolume "AcqSystem1_Audio0" Right 100\n');
        fprintf(fid,'-SetAudioMute "AcqSystem1_Audio0" Right Off\n');
        fprintf(fid,'\n');
        fprintf(fid,'#Audio Device Setup for AcqSystem1_Audio1\n');
        fprintf(fid,'-SetAudioSource "AcqSystem1_Audio1" Left None\n');
        fprintf(fid,'-SetAudioVolume "AcqSystem1_Audio1" Left 100\n');
        fprintf(fid,'-SetAudioMute "AcqSystem1_Audio1" Left Off\n');
        fprintf(fid,'-SetAudioSource "AcqSystem1_Audio1" Right None\n');
        fprintf(fid,'-SetAudioVolume "AcqSystem1_Audio1" Right 100\n');
        fprintf(fid,'-SetAudioMute "AcqSystem1_Audio1" Right Off\n');
        fprintf(fid,'#Digital IO Device Creation and Setup for: AcqSystem1_0\n');
        fprintf(fid,'-SetDigitalIOPortDirection "AcqSystem1_0" 0 Input\n');
        fprintf(fid,'-SetDigitalIOUseStrobeBit "AcqSystem1_0" 0 False\n');
        fprintf(fid,'-SetDigitalIOEventsEnabled "AcqSystem1_0" 0 True\n');
        fprintf(fid,'-SetDigitalIOPulseDuration "AcqSystem1_0" 0 15\n');
        fprintf(fid,'-SetDigitalIOPortDirection "AcqSystem1_0" 1 Input\n');
        fprintf(fid,'-SetDigitalIOUseStrobeBit "AcqSystem1_0" 1 False\n');
        fprintf(fid,'-SetDigitalIOEventsEnabled "AcqSystem1_0" 1 True\n');
        fprintf(fid,'-SetDigitalIOPulseDuration "AcqSystem1_0" 1 15\n');
        fprintf(fid,'-SetDigitalIOPortDirection "AcqSystem1_0" 2 Input\n');
        fprintf(fid,'-SetDigitalIOUseStrobeBit "AcqSystem1_0" 2 False\n');
        fprintf(fid,'-SetDigitalIOEventsEnabled "AcqSystem1_0" 2 True\n');
        fprintf(fid,'-SetDigitalIOPulseDuration "AcqSystem1_0" 2 15\n');
        fprintf(fid,'-SetDigitalIOPortDirection "AcqSystem1_0" 3 Input\n');
        fprintf(fid,'-SetDigitalIOUseStrobeBit "AcqSystem1_0" 3 False\n');
        fprintf(fid,'-SetDigitalIOEventsEnabled "AcqSystem1_0" 3 True\n');
        fprintf(fid,'-SetDigitalIOPulseDuration "AcqSystem1_0" 3 15\n');
        fprintf(fid,'-SetDigitalIOInputScanDelay "AcqSystem1_0" 1\n');
        fprintf(fid,'\n');
        fprintf(fid,'#Subject Dialog Setup\n');
        fprintf(fid,'-SetDialogPosition Subject 133 175\n');
        fprintf(fid,'-SetDialogVisible Subject False\n');
        fprintf(fid,'\n');

end


function addCSCtoPlotWindow(fid,microName,extraInfo)
if ischar(extraInfo)
    if strcmp(extraInfo(1),'G')
        whichWindow = 'Micro Window';
        extraInfo = [extraInfo,'-'];
        maxCh = 8;
        addSuffix = 1;
    elseif strcmp(extraInfo,'AltRef')
         whichWindow = 'Alternate Reference Micro Window';
        extraInfo = [extraInfo,'-'];
        maxCh = 8;
        addSuffix = 1;
    else
        whichWindow = extraInfo;
        extraInfo = '';
        maxCh = 1;
        addSuffix = 0;
    end
else
    whichWindow = 'Macro Window';
    maxCh = extraInfo;
    extraInfo = '';
    addSuffix = 1;
end
for i=1:maxCh
    if addSuffix
    thisStr = sprintf('%s%s%d',extraInfo,microName,i);
    else
      thisStr = sprintf('%s%s',extraInfo,microName);
    end
    fprintf(fid,'-AddPlot "%s" "%s"\n',whichWindow,thisStr);
    fprintf(fid,'-SetPlotEnabled "%s" "%s" True\n',whichWindow,thisStr);
    if ismember(whichWindow,{'Micro Window','Macro Window','Alternate Reference Micro Window'})
        fprintf(fid,'-SetTimePlotZoomFactor "%s" "%s" 32\n',whichWindow,thisStr);
        fprintf(fid,'-SetPlotWaveformColor "%s" "%s" 25 25 112\n',whichWindow,thisStr);
    end
    fprintf(fid,'\n');
end

function setUpTimeWindow(fid,windowName)

fprintf(fid,'# Plot Window Setup for "%s"\n',windowName);
fprintf(fid,'-CreatePlotWindow Time "%s"\n',windowName);
fprintf(fid,'-SetPlotWindowSpreadType "%s" Spread\n',windowName);
fprintf(fid,'-SetPlotWindowPlotType "%s" Sweep\n',windowName);
fprintf(fid,'-SetPlotWindowTimeframe "%s" 5000\n',windowName);
fprintf(fid,'-SetPlotWindowHistoryTimeframe "%s" 30\n',windowName);
fprintf(fid,'-SetPlotWindowShowGridLines "%s" True\n',windowName);
switch windowName
    case 'Macro Window'
        fprintf(fid,'-SetPlotWindowBackgroundColor "%s" 232 242 237\n',windowName);
    case 'Micro Window'
        fprintf(fid,'-SetPlotWindowBackgroundColor "%s" 255 255 255\n',windowName);
    case 'Alternate Reference Micro Window'
        fprintf(fid,'-SetPlotWindowBackgroundColor "%s" 230 217 255\n',windowName);
end
fprintf(fid,'-SetPlotWindowPosition "%s" 14 807 1449 746\n',windowName);
fprintf(fid,'-SetPlotWindowOverlay "%s" False\n',windowName);
fprintf(fid,'-SetPlotWindowShowTitleBar "%s" True\n',windowName);
fprintf(fid,'# Plot addition and setup for "%s"\n',windowName);
fprintf(fid,'\n');

function setUpSpikeWindow(fid)
fprintf(fid,'# Plot Window Setup for "Spike Window 1"\n');
fprintf(fid,'-CreatePlotWindow Spike "Spike Window 1"\n');
fprintf(fid,'-SetPlotWindowPlotType "Spike Window 1" WaveformFeature\n');
fprintf(fid,'-SetPlotWindowShowIcons "Spike Window 1" True\n');
fprintf(fid,'-SetPlotWindowShowTextValues "Spike Window 1" True\n');
fprintf(fid,'-SetPlotWindowNumberFeaturePlotsMaximizedView "Spike Window 1" 1\n');
fprintf(fid,'-SetPlotWindowNumberFeaturePlotsNormalView "Spike Window 1" 1\n');
fprintf(fid,'-SetPlotWindowPosition "Spike Window 1" 1473 50 1083 393\n');
fprintf(fid,'-SetPlotWindowOverlay "Spike Window 1" False\n');
fprintf(fid,'-SetPlotWindowShowTitleBar "Spike Window 1" True\n');
fprintf(fid,'\n');
fprintf(fid,'# Plot addition and setup for "Spike Window 1"\n');

function addToSpikeWindow(fid,microName, microID)
for i=1:8
    thisStr = sprintf('SE%s-%s%d', microID, microName, i);
    fprintf(fid,'-AddPlot "Spike Window 1" "%s"\n',thisStr);
    fprintf(fid,'-SetPlotEnabled "Spike Window 1" "%s" True\n',thisStr);
    for d = 0:31
        fprintf(fid,'-SetClusterDisplay "Spike Window 1" "%s" %d On\n',thisStr,d);
    end
    fprintf(fid,'-SetFeaturePlotSources "Spike Window 1" "%s" 0 0 1\n',thisStr);
    fprintf(fid,'-SetFeaturePlotView "Spike Window 1" "%s" 0 -32767 32767 32767 -32767\n',thisStr);
    fprintf(fid,'\n');
end
