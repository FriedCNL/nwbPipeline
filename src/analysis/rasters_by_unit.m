function [] = rasters_by_unit(subject, trialFolder, stimDirectory, plotResponsive, stimuliType, targetLabel, outputPath)

% stimuliType:
%       "stim": for images and audio, there will be larger time window
%       after the stimuli.
%       "response": for key response, this will give larger time window 
%       before key press,
%       "video": for video stimuli, there will be a wider time window.
% targetLabel:
%       a struct with fields G[A-D][1-8] to add target of micro electrodes 
%       in the brain.


if ~exist('stimuliType', "var")
    stimuliType = 'stim';
end

if ~exist('targetLabel', "var")
    targetLabel = [];
end

if ~exist('outputPath', "var") || isempty(outputPath)
    outputPath = trialFolder;
end

outputPath = fullfile(outputPath, ['raster_plots_', stimuliType]);

if ~exist(outputPath, "dir")
    mkdir(outputPath)
end

[clustersToPlot, sr] = getClusters(trialFolder, plotResponsive, targetLabel);
totalNumStimuli = length(clustersToPlot{1, stimuliType}{1});

eventColor = 'green';
if strcmp(stimuliType, 'video')
    clusterColLabel = 'videoNumSelective';
    rasterNCol = 3; rasterNRow = 3;    
    stimLimits = (-1000:2500:10000);
    stimHistLimits = (-1000:500:10000);
else
    clusterColLabel = 'numSelective';
    rasterNCol = 6; rasterNRow = 3;
    
    if strcmp(stimuliType, 'response')
        stimLimits = (-1000:500:500);
        stimHistLimits = (-1000:50:500);
        eventColor = 'blue';
    else
        stimLimits = (-500:500:1000);
        stimHistLimits = (-500:50:1000);
    end
end

plotsPerPage = rasterNCol * rasterNRow - 1;
pagesPerCluster =  ceil(clustersToPlot{:, clusterColLabel}/plotsPerPage); %ceil(totalNumStimuli/plotsPerPage)*ones(size(responsiveClusters, 1), 1);
pagesPerCluster(pagesPerCluster==0) = 1;
numPages = sum(pagesPerCluster);

% titleRect = [0 .9625 1 .025];

[stimTags, stimIds, stimNames] = getStimInfo(stimDirectory);
figNames = cell(1, numPages);

parfor i = 1:numPages

    figNames{i} = fullfile(outputPath, ['rasters_', stimuliType, '_p' num2str(i) '.pdf']);
    figure('Name', ['Page ',num2str(i)], ...
        'units','normalized', ...
        'position',[0.0238    0.0736    0.8    0.9],...
        'PaperUnits','inches', ...
        'PaperPosition',[0 0 11 8.5], ...
        'PaperOrientation','landscape', ...
        'Visible', 'off');
    set(gcf, 'Color', 'white');
    disp([num2str(i) ' of ' num2str(numPages)]);

    cumSumClusters = [0; cumsum(pagesPerCluster)];
    unitToPlot = find(i - cumSumClusters > 0, 1, 'last');
    posInPage = i - cumSumClusters(unitToPlot);
    nPagesInUnit = cumSumClusters(unitToPlot + 1) - cumSumClusters(unitToPlot);
    clusterInfo = struct2table(clustersToPlot{unitToPlot, stimuliType}{1});
    % clusterInfo = sortrows(clusterInfo, 'score', 'descend');
    numRespSpikes = zeros(height(clusterInfo), 1);
    for k = 1:height(clusterInfo)
        spkTimes = clusterInfo{k, 'spikes'};
        if iscell(spkTimes) && length(spkTimes) == 1, spkTimes = spkTimes{1}; end
        numRespSpikes(k) = sum(cellfun(@(x) sum(x >= 0 & x <= stimLimits(end)), spkTimes));
    end
    clusterInfo.numRespSpikes = numRespSpikes;
    clusterInfo = sortrows(clusterInfo, {'score', 'numRespSpikes'}, {'descend', 'descend'});
   

    % plot spike waveforms:
    axes1 = axes(gcf, 'Position', getAxisRect(0, 1));
    plot(axes1, (1:74)/sr*1000, clustersToPlot{unitToPlot, 'allWaveforms'}{1}', 'Color', 'blue');
    hold(axes1, 'on');
    plot(axes1, (1:74)/sr*1000, clustersToPlot{unitToPlot, 'meanWaveform'}{1}, 'Color', 'black', 'LineWidth', 1.5);
    hold(axes1, 'off');
    thisUnitWaveDuration = clustersToPlot{unitToPlot, 'waveDuration'};
    if thisUnitWaveDuration > .65
        title(axes1, ['Spike Width: ', num2str(round(thisUnitWaveDuration, 2)), ' ms (P)']);
    else
        title(axes1, ['Spike Width: ', num2str(round(thisUnitWaveDuration, 2)), ' ms (I)']);
    end
    xlim(axes1, [0, 74/sr*1000]);

    % plot histgram of inter spike intervals:
    axes2 = axes(gcf, 'Position', getAxisRect(0, 2));
    ISITimes = 1000*diff(clustersToPlot{unitToPlot, 'allTimes'}{1}); 
    ISITimes(ISITimes>100)=[];
    histogram(axes2, ISITimes, 0:5:100);
    xlim(axes2, [0 100]);

    unitsToPlot = (posInPage-1)*plotsPerPage + (1:plotsPerPage);
    unitsToPlot(unitsToPlot > totalNumStimuli) = [];

    for j = 1:length(unitsToPlot)

        stimId = clusterInfo{unitsToPlot(j), 'stimId'};
        stimLookupIdx = stimId == stimIds;

        if all(stimLookupIdx==0)
            warning('no matched stimID found.');
            continue
        end

        if sum(stimLookupIdx) > 1
            warning('more than one stim found with ID: %d\n', stimId);
        end

        stimName = stimNames{stimLookupIdx}; % this will return the first stim if multiple stim with stimId found (which should not happen)
        stimFile = fullfile(stimDirectory, stimName);

        if isempty(stimName)
            continue
        end
        fprintf('stimulus (%d): %s\n', find(stimLookupIdx), stimName)
        
        % plot stim (image/sound wave) at the top of each rectangle
        % position:
        stimAxes = axes(gcf, 'Position', getAxisRect(j, 1, rasterNCol, rasterNRow));
        if endsWith(stimName, '.jpg') || endsWith(stimName, '.png')
            try
                image = imread(stimFile);
                image = imresize(image, .2);
                imshow(image, 'Parent', stimAxes);
            catch
                warning('image: %s is not load successfully\n', stimFile);
            end
        else
            try
                [y, Fs] = audioread(stimFile);
                plot(stimAxes, 1000/Fs*(1:length(y)), y(:, 1));
                xlim(stimAxes, [stimLimits(1), stimLimits(end)]);
            catch
                warning('audio is not loaded successfully: %s\n', stimFile)
            end
        end

        responseOnset = [];
        if any(strcmp('responseOnset', fieldnames(clusterInfo)))% isfield(clusterInfo, 'responseOnset')
            responseOnset = clusterInfo{unitsToPlot(j), 'responseOnset'};
        end
        if iscell(responseOnset)
            responseOnset = mean(cell2mat(responseOnset));
        else
            responseOnset = mean(responseOnset);
        end

        stimTag = stimTags{stimLookupIdx};
        stimTag = stimTag(1: min(20, length(stimTag)));
        axesTitle = [strrep(stimTag, '_', '\_'), sprintf(': (%.2f), %d ms', clusterInfo{unitsToPlot(j), 'score'}, round(responseOnset))];
        title(stimAxes, axesTitle, 'FontSize', 8,'Interpreter','tex');

        % plot rasters:
        rasterAxes = axes(gcf, 'Position', getAxisRect(j, 2 , rasterNCol, rasterNRow));
        if iscell(clusterInfo{unitsToPlot(j), 'spikes'}) && length(clusterInfo{unitsToPlot(j), 'spikes'}) == 1
            spikeTimes = clusterInfo{unitsToPlot(j), 'spikes'}{1};
        else
            spikeTimes = clusterInfo{unitsToPlot(j), 'spikes'};
        end

        hold(rasterAxes, 'on');
        for k = 1:length(spikeTimes)
            if numel(spikeTimes{k}) > 0
                trialSpikeTimes = spikeTimes{k};
                trialSpikeTimes(trialSpikeTimes < stimLimits(1) | trialSpikeTimes > stimLimits(end)) = [];
                spikeTimesToPlot = [trialSpikeTimes, trialSpikeTimes];
                thisTrialVertPos = repmat([k-.4, k+.4], numel(trialSpikeTimes), 1);
                plot(rasterAxes, spikeTimesToPlot', thisTrialVertPos', 'Color', 'black');
            end
        end
        yLimit = [.6, length(spikeTimes)+.4];
        ylim(rasterAxes, yLimit);
        xlim(rasterAxes, [stimLimits(1), stimLimits(end)]); 
        xticks(rasterAxes, stimLimits);
        
        % add vertical line at onset time:
        plot(rasterAxes, [0, 0], yLimit, 'Color', eventColor);

        if ~isempty(responseOnset) && ~strcmp(stimuliType, 'response')
            plot(rasterAxes, [responseOnset, responseOnset], yLimit, 'Color', 'red');
        end
        hold(rasterAxes, 'off');

        histAxes = axes(gcf, 'Position', getAxisRect(j, 3, rasterNCol, rasterNRow));
        allSpikeTimes = vertcat(spikeTimes{:});

        histogram(histAxes, allSpikeTimes, stimHistLimits);
        xlim(histAxes, [stimHistLimits(1), stimHistLimits(end)]);
        xticks(histAxes, stimLimits);
    end

    thisTitle = [cell2mat(clustersToPlot{unitToPlot, 'cluster_region'}), sprintf(' Unit %d (%d/%d)', clustersToPlot{unitToPlot, 'cluster_num'}, posInPage, nPagesInUnit)];
    annotation('textbox', [0 .9625 1 .025], ...
        'units', 'normalized', ...
        'String', thisTitle, ...
        'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 15, ...
        'FontWeight', 'bold', ...
        'Interpreter', 'tex');

    xtickangle(findobj(gcf, 'type', 'axes'), 0);
    print(gcf,'-dpdf', '-r100', '-vector', figNames{i});

end

if plotResponsive
    merge_fn = ['Rasters_p' num2str(subject), '_', stimuliType, '_responsiveUnits'];
else
    merge_fn = ['Rasters_p' num2str(subject) '_', stimuliType, '_allUnits'];
end

mergeSegments = [1:50:length(figNames), length(figNames)+1];
for i = 2:length(mergeSegments)
    filenames1 = figNames(mergeSegments(i-1): (mergeSegments(i)-1));
    if length(filenames1) > 1
        mergePdfs(filenames1, fullfile(outputPath, sprintf('%s_%d_%d.pdf', merge_fn, mergeSegments(i-1), (mergeSegments(i)-1))));
    else
        movefile(filenames1{1}, fullfile(outputPath, sprintf('%s_%d_%d.pdf', merge_fn, mergeSegments(i-1), (mergeSegments(i)-1))))
    end
    cellfun(@delete, filenames1);
end

end



