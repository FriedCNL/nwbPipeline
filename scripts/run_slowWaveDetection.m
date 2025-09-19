%the struct runData holds data about patients and where the different event
%types are stored
clear
% ---- UPDATE this part -

% the main path for extracted data here -
% for the given example, it's in the same folder as this code:

expPath = '/Users/sldunn/HoffmanMount/data/PIPELINE_vc/ANALYSIS/MovieParadigm/570_MovieParadigm/Experiment-5/';
macroPath = fullfile(expPath,'CSC_macro');
channel = 'LA1';
outputFolder = fullfile(macroPath, 'slowWaves');

if ~exist(outputFolder, "dir")
    mkdir(outputFolder);
end

sleepScoringFileName = fullfile(expPath, 'sleep_score', ['sleepScore_' channel '_001.mat']);
[macroFiles, macroTimestampFiles] = readCSCFilePath(macroPath);

% find channel index from macroFiles
channel_index = find(contains(macroFiles(:,1),channel));

%% an example for detecting spindles directly using SpindleDetectorClass (it's the same thing the wrapper below does in batch)
%loading - sleep scoring, IIS, data
sleepScoring = load(sleepScoringFileName);
sleepScoring = sleepScoring.sleep_score_vec;
% sleepScoring = [];

%% load or perform interictal Spikes Detection
% set to none here for example
peakTimes = [];
channelName = extractChannelName(macroFiles{channel_index, 1});
currData = combineCSC(macroFiles(channel_index, :), macroTimestampFiles);

%% detect the spindles
returnStats = 1;
detector = SlowWavesDetectorClass;
detector.samplingRate = 2000;

slowWavesInds = detector.findSlowWavesStaresina(currData, sleepScoring, peakTimes);
% returns the SW peak indices


%% extract neural data around inds and plot output
SW_neural = NaN(length(slowWavesInds),detector.samplingRate*4);
win_sec =[-2,2];
for i = 1:length(slowWavesInds)
    ind1 = slowWavesInds(i) + (win_sec(1)*detector.samplingRate);
    if ind1 < 0
        continue
    end
    ind2 = slowWavesInds(i) + (win_sec(2)*detector.samplingRate)-1;
    if ind2 > length(currData)
        continue
    end
    SW_neural(i,:)=currData(ind1:ind2);
end

meanSW = nanmean(SW_neural)*-1; % flip to match Staresina 2023 sup fig 2
sdSW = nanstd(SW_neural)*-1;
t = linspace(win_sec(1),win_sec(2),length(meanSW));

figure
axes('NextPlot','add')
% plot(t,SW_neural'*-1,'color',[0 0.5 1 0.01],'DisplayName','idividual events')
plot(t,meanSW,'color','k','LineWidth',1.5, 'DisplayName','mean')
plot(t,meanSW-sdSW,"Color",'k','LineStyle','--','DisplayName','SD')
plot(t,meanSW+sdSW,"Color",'k','LineStyle','--','HandleVisibility','off')
title({expPath;[channel ' n = ' num2str(length(slowWavesInds)) ' slow waves'] }, 'Interpreter','None')
legend
set(findall(gcf,'-property','FontSize'),'FontSize',14)
xlabel('Time from SW peak (s)')
ylabel('Voltage (uV)')


%% save the output
% matObj = matfile(fullfile(outputFolder, sprintf('slowWaves_%s.mat', channelName)), "Writable", true);
% matObj.slowWavesTimes = slowWavesTimes;




