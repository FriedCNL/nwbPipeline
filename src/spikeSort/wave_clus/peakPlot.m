function peakPlot(handles)

USER_DATA = get(handles.wave_clus_figure,'userdata');
cluster_class = USER_DATA{6};
clustersToShow = unique(cluster_class);
clustersToShow(clustersToShow==0)=[];

ax = handles.spikeRaster;
cla(ax);
spikes = USER_DATA{2};
spk_times = USER_DATA{3}*1e-3;

[~,peakIndex] = max(abs(spikes),[],2);
peakIndex = mode(peakIndex);

plot(ax,spk_times(cluster_class==0),spikes(cluster_class==0,peakIndex),'.','color',.85*[1 1 1],'markersize',4)

if ~isempty(clustersToShow)

    clusteredSpikes = arrayfun(@(c)spikes(cluster_class==c,:),...
        clustersToShow,'uniformoutput',0);
    peaks = cellfun(@(c)c(:,peakIndex),clusteredSpikes,'uniformoutput',0);
    % widths = cellfun(@(c)getWidths(c,peakIndex),clusteredSpikes,'uniformoutput',0);
    ts = arrayfun(@(c)spk_times(cluster_class==c),...
        clustersToShow,'uniformoutput',0);

    hold(ax,'on');
    colors = [ ...
        0 0 1 ;  % 1  blue % don't need black first for aux! Otherwise it misindexes and repeats green on aux
        1 0 0 ;  % 2  red
        0 1 0 ;  % 3  green
        0.00 0.60 0.60 ;  % 4  teal  (dark cyan)
        0.70 0.70 0.00 ;  % 5  mustard (dark yellow)
        0.55 0.27 0.07 ;  % 6  brown
        0.50 0.00 0.50 ;  % 7  purple
        0.93 0.57 0.13 ;  % 8  orange
        0.40 0.55 0.65 ;  % 9  slate / gray-blue
        0.83 0.68 0.21 ;  % 10 gold
        0.30 0.30 0.30 ;  % 11 dark gray
        0.20 0.80 0.80 ; % 12 aqua-green
    ];
    % colors = ['b' 'r' 'g' 'c' 'm' 'y' 'b' 'r' 'g' 'c' 'm' 'y' 'b' 'k' 'b' 'r' 'g' 'c' 'm' 'y' 'b' 'r' 'g' 'c' 'm' 'y' 'b' 'k' 'b' 'r' 'g' 'c' 'm' 'y' 'b' 'r' 'g' 'c' 'm' 'y' 'b'];
    nColors = size(colors,1);
    %chatGPT
    for k = 1:numel(ts)
        colIdx = mod(clustersToShow(k)-1, nColors) + 1; % % cluster-1 → blue row
        % colIdx = mod(clustersToShow(k), nColors-1);   % cluster-1 → blue row
        plot(ax, ts{k}, peaks{k}, '.', ...
            'Color', colors(colIdx,:), 'MarkerSize', 8);
    end
    % cellfun(@(t,p,c)plot(ax,t,p,'.','color',c,'markersize',8),ts,peaks,colors(1:length(ts)));

    maxPeak = max(cell2mat(peaks)); minPeak = min(cell2mat(peaks));
    maxTime = max(spk_times);
    set(ax,'ylim',[min([0 1.2*minPeak]) max([1.2*maxPeak 1])])
    set(ax,'xlim',[0 max([maxTime 1])]);
    if 0; % plot spike widths over time? % isempty(get(handles.cont_data,'children'))
        % if cont_data has data in it, the xlim should already be scaled to be
        % the same. If not, set it to the max time of spikes.

        % and, might as well take advantage of that empty space. Plot spike
        % width vs time.
        ax2 = handles.cont_data; hold(ax2,'on');
        cellfun(@(t,p,c)plot(ax2,t,p,'.','color',c,'markersize',12),ts,widths,colors(1:length(ts)));

        maxWidth = max(cell2mat(widths));
        set(ax2,'ylim',[0 1.2*maxWidth])
        linkaxes([ax ax2],'x')
    end

end

function w = getWidths(spikes,peakIndex)
locMin = diff(sign(diff(spikes')))'>0;
locMin = [ones(size(locMin,1),1) locMin ones(size(locMin,1),1)];
localMinInd_Pre = nan(size(spikes,1),1);localMinV_Pre = localMinInd_Pre;
localMinInd_Post = nan(size(spikes,1),1);
w = localMinInd_Pre;
for i = 1:length(localMinInd_Pre)
    localMinInd_Pre(i) = find(locMin(i,1:peakIndex-1),1,'last');
    localMinV_Pre(i) = spikes(i,localMinInd_Pre(i));
    localMinInd_Post(i) = find(locMin(i,peakIndex+1:end),1,'first')+peakIndex;
    halfHeight = (spikes(i,peakIndex) - localMinV_Pre(i))/2;
    [~,halfHeightPreInd] = min(abs(spikes(i,localMinInd_Pre(i):peakIndex)-halfHeight));
    halfHeightPreInd = halfHeightPreInd+localMinInd_Pre(i);
    [~,halfHeightPostInd] = min(abs(spikes(i,peakIndex:localMinInd_Post(i))-halfHeight));
    halfHeightPostInd = halfHeightPostInd+peakIndex-1;
    w(i) = halfHeightPostInd-halfHeightPreInd;
end
w = spikes(:,peakIndex)./w; % this line converted to height to width
%     ratio instead of just half width. But now we just reject spikes with
%     high height to width ratio before clustering, so no need to
%     compute/plot here.
f = figure; subplot(421); histogram(w);
subplot(422); inds = find(w>2 & w<10); if length(inds)>500,inds = randsample(inds,500);end; plot(spikes(inds,:)'); title('2-10')
subplot(423); plot(spikes(w<20 & w>10,:)'); title('10-20')
subplot(424); plot(spikes(w>20,:)'); title('>20');
subplot(425); plot(spikes(w<0,:)');title('<0')
subplot(426); plot(spikes(w<2 & w>0,:)'); title('0-2')

[n, c] = histcounts(w);
zeroSets = continuousRunsOfTrue(n<.02*max(n));
inds = zeroSets(:,2)-zeroSets(:,1) < 3; zeroSets(inds,:) = [];
meanPointOfZeros = mean(c(zeroSets),2);
[~,peakInd] = max(n); peakVal = c(peakInd);
lowEnd = meanPointOfZeros(find(meanPointOfZeros<peakVal,1,'last'));
if isempty(lowEnd), lowEnd = c(1); end
highEnd = meanPointOfZeros(find(meanPointOfZeros>peakVal,1,'first'));
if isempty(highEnd),highEnd = c(end); end
subplot(427); bar(c(1:end-1),n); hold on; plot(lowEnd,5,'ro'); plot(highEnd,5,'ro');

% w = localMinInd_Post-localMinInd_Pre; % this line would take width
% defined from pre peak minimum to post peak minimum. But I think half
% width as defined by w above is a better measure.
